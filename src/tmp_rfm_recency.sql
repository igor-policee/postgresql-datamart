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

-- Заполнение таблицы
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
)

INSERT INTO
    de.analysis.tmp_rfm_recency (user_id, recency)
SELECT
    user_id,
    recency
FROM
    recency_cte;
