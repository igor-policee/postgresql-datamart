# Проект 1. Витрина RFM

## 1.1. Описание целевой витрины

### Заказчик
- Компания - разработчик приложения доставки еды.

### Название и расположение витрины
- База данных компании. Ссылка на витрину: analysis.dm_rfm_segments.

### Назначение витрины
- Витрина для RFM-классификации пользователей приложения.

### Описание бизнес - логики
RFM — способ сегментации клиентов, при котором анализируют их лояльность: как часто, на какие суммы и когда в последний раз тот или иной клиент покупал что-то. На основе этого выбирают клиентские категории, на которые стоит направить маркетинговые усилия.

Каждого клиента оценивают по трём факторам:

- Recency (пер. «давность») — сколько времени прошло с момента последнего заказа. Измеряется по последнему заказу. Клиенты должны быть распределены по шкале от одного до пяти, где значение 1 - клиенты, которые либо вообще не делали заказов, либо делали их очень давно, а 5 — те, кто заказывал относительно недавно.
- Frequency (пер. «частота») — количество заказов. Клиенты должны быть распределены по шкале от одного до пяти, где значение 1 - это клиенты с наименьшим количеством заказов, а 5 — с наибольшим.
- Monetary Value (пер. «денежная ценность») — сумма затрат клиента. Клиенты должны быть распределены по шкале от одного до пяти, где значение 1 получат клиенты с наименьшей суммой, а 5 — с наибольшей.

Количество клиентов в каждом сегменте должно быть одинаково разделено на 5 равных частей. 

### Описание полей витрины
- user_id - id пользователя.
- recency - число от 1 до 5.
- frequency - число от 1 до 5.
- monetary_value - число от 1 до 5.

### Срез данных
- Нужны данные с начала 2021 года.
- Для анализа выбираются успешно выполненные заказы. Эти заказы имеют статус "Closed".

### Частота обновления данных
- Обновления не нужны.

### Источники данных
- База данных компании. Схема данных "production".

## 1.2. Структура исходных данных.

Для построения витрины потребуются следующие таблицы и атрибуты:
- production.orders.order_id
- production.orders.user_id
- production.orders.order_ts
- production.orders.payment
- production.orderstatuses.id
- production.orderstatuses.key

## 1.3. Качество данных

- Данные в таблице production.orders, на основании которых строится витрина, не содержат значений типа NULL и дублей, распределение цен в колонке payment не содержит выбросов.
- Все таблицы схемы production имеют primary key.
- Внешние ключи есть у таблиц orderitems, orderstatuslog.
- Атрибуты всех таблиц схемы production, кроме users.name, имеют ограничение на значения типа NULL.
- Таблицы orderitems и orders имеют ограничения типа CHECK на числовые данные, отвечающие за цены.
- Типы данных отвечают бизнес - логике.

На основе этой информации можно сделать вывод о достаточно высоком качестве данных в схеме production. 
С моей точки зрения, целостность данных можно доработать, создав дополнительные связи между таблицами orderstatuses и orders отношением один ко многим.

## 1.4. Подготовка витрины данных

### 1.4.1. VIEW для таблиц из схемы production в схеме analysis

Заказчиком было обозначено дополнительное требование: при расчете витрины обращаться только к объектам из схемы analysis. 
Чтобы не дублировать данные (данные находятся в этой же базе), будем делать VIEW. Таким образом, VIEW будут находиться в схеме analysis и вычитывать данные из схемы production. 

SQL-скрипты для создания шести VIEW (по одному на каждую таблицу) в схеме analysis.

```SQL
CREATE OR REPLACE VIEW de.analysis.orderitems AS
SELECT * FROM de.production.orderitems;
   
CREATE OR REPLACE VIEW de.analysis.orders AS
SELECT * FROM de.production.orders;
   
CREATE OR REPLACE VIEW de.analysis.orderstatuses AS
SELECT * FROM de.production.orderstatuses;
   
CREATE OR REPLACE VIEW de.analysis.orderstatuslog AS
SELECT * FROM de.production.orderstatuslog;
   
CREATE OR REPLACE VIEW de.analysis.products AS
SELECT * FROM de.production.products;
   
CREATE OR REPLACE VIEW de.analysis.users AS
SELECT * FROM de.production.users;
```

### 1.4.2. DDL-запрос для создания витрины.

SQL-скрипт для создания целевой витрины в схеме analysis.

```SQL
CREATE TABLE IF NOT EXISTS de.analysis.dm_rfm_segments (
    "user_id" int,
    "recency" smallint,
    "frequency" smallint,
    "monetary_value" smallint
);
```

### 1.4.3. SQL запрос для заполнения витрины

SQL-скрипты для расчета показателей и заполнения целевой витрины.

```SQL
-- Расчет целевых показателей и выделение в CTE
WITH filter_orders_cte AS (
    SELECT
        o.order_id AS order_id,
        o.user_id AS user_id,
        o.order_ts AS order_ts,
        o.payment AS payment
    FROM
        analysis.orders o
        LEFT JOIN analysis.orderstatuses o2 ON o.status = o2.id
    WHERE
        o2."key" = 'Closed'
        AND extract(year FROM o.order_ts) >= 2021
),

last_order_cte AS (
    SELECT
        row_number() over (
            ORDER BY
                current_date - max(order_ts :: date) DESC
        ) AS row_id,
        cast(count(1) over () AS double precision) AS total_row_count,
        user_id AS user_id,
        max(order_ts :: date) AS last_order_date,
        current_date - max(order_ts :: date) AS last_order_day_interval
    FROM
        filter_orders_cte
    GROUP BY
        user_id
),

recency_cte AS (
    SELECT
        user_id AS user_id,
        case
            WHEN row_id <= (total_row_count / 5) * 1 THEN 1
            WHEN (total_row_count / 5) * 1 < row_id
            AND row_id <= (total_row_count / 5) * 2 THEN 2
            WHEN (total_row_count / 5) * 2 < row_id
            AND row_id <= (total_row_count / 5) * 3 THEN 3
            WHEN (total_row_count / 5) * 3 < row_id
            AND row_id <= (total_row_count / 5) * 4 THEN 4
            ELSE 5
        end AS recency
    FROM
        last_order_cte
),

orders_count_cte AS (
    SELECT
        row_number() over (
            ORDER BY
                count(order_id) ASC
        ) AS row_id,
        cast(count(1) over () AS double precision) AS total_row_count,
        user_id AS user_id,
        count(order_id) AS orders_count
    FROM
        filter_orders_cte
    GROUP BY
        user_id
),

frequency_cte AS (
    SELECT
        user_id AS user_id,
        case
            WHEN row_id <= (total_row_count / 5) * 1 THEN 1
            WHEN (total_row_count / 5) * 1 < row_id
            AND row_id <= (total_row_count / 5) * 2 THEN 2
            WHEN (total_row_count / 5) * 2 < row_id
            AND row_id <= (total_row_count / 5) * 3 THEN 3
            WHEN (total_row_count / 5) * 3 < row_id
            AND row_id <= (total_row_count / 5) * 4 THEN 4
            ELSE 5
        end AS frequency
    FROM
        orders_count_cte
),

payment_summary_cte AS (
    SELECT
        row_number() over (
            ORDER BY
                sum(payment) ASC
        ) AS row_id,
        cast(count(1) over () AS double precision) AS total_row_count,
        user_id AS user_id,
        sum(payment) AS payment_summary
    FROM
        filter_orders_cte
    GROUP BY
        user_id
),

monetary_value_cte AS (
    SELECT
        user_id AS user_id,
        case
            WHEN row_id <= (total_row_count / 5) * 1 THEN 1
            WHEN (total_row_count / 5) * 1 < row_id
            AND row_id <= (total_row_count / 5) * 2 THEN 2
            WHEN (total_row_count / 5) * 2 < row_id
            AND row_id <= (total_row_count / 5) * 3 THEN 3
            WHEN (total_row_count / 5) * 3 < row_id
            AND row_id <= (total_row_count / 5) * 4 THEN 4
            ELSE 5
        end AS monetary_value
    FROM
        payment_summary_cte
),

to_fill_in_cte AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary_value
    FROM
        recency_cte
        LEFT JOIN frequency_cte USING(user_id)
        LEFT JOIN monetary_value_cte USING(user_id)
)

-- Загрузка данных в витрину
INSERT INTO
    de.analysis.dm_rfm_segments (user_id, recency, frequency, monetary_value)
SELECT
    user_id,
    recency,
    frequency,
    monetary_value
FROM
    to_fill_in_cte;
```
