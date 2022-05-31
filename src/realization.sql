-- Создание шести VIEW (по одному на каждую таблицу) в схеме analysis
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

-- Создание целевой витрины в схеме analysis
CREATE TABLE IF NOT EXISTS de.analysis.dm_rfm_segments (
    "user_id" int,
    "recency" smallint,
    "frequency" smallint,
    "monetary_value" smallint
);

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
