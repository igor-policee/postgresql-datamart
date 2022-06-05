-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_recency;

-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_recency (
    user_id INT NOT NULL PRIMARY KEY,
    recency INT NOT NULL CHECK(
        recency >= 1
        AND recency <= 5
    )
);
-- Список пользователей, у которых нет закрытых заказов
WITH no_closed_orders_cte AS (
    SELECT
        u.id AS user_id,
        '2021-01-01' :: timestamp AS order_ts -- Устанавливаем минимальную дату для ранжирования
    FROM
        analysis.users u
        LEFT JOIN analysis.orders o ON u.id = o.user_id
        INNER JOIN analysis.orderstatuses o2 ON o.status = o2.id
    GROUP BY
        u.id
    HAVING
        'Closed' != ALL(array_agg(o2."key"))
),
-- Список пользователей, у которых есть закрытые заказы
with_closed_orders_cte AS (
    SELECT
        u.id AS user_id,
        max(o.order_ts) AS order_ts
    FROM
        analysis.users u
        LEFT JOIN analysis.orders o ON u.id = o.user_id
        INNER JOIN analysis.orderstatuses o2 ON o.status = o2.id
    WHERE
        u.id NOT IN (
            SELECT
                user_id
            FROM
                no_closed_orders_cte
        )
        AND o2."key" = 'Closed'
    GROUP BY
        u.id
),

-- Объединение результатов и заполнение таблицы
last_orders_cte AS (
    SELECT
        user_id,
        order_ts
    FROM
        with_closed_orders_cte
    UNION
    SELECT
        user_id,
        order_ts
    FROM
        no_closed_orders_cte
),
recency_cte AS (
    SELECT
        user_id,
        ntile(5) OVER (
            ORDER BY
                order_ts ASC
        ) AS recency
    FROM
        last_orders_cte
)

INSERT INTO
    de.analysis.tmp_rfm_recency (user_id, recency)
SELECT
    user_id,
    recency
FROM
    recency_cte;
