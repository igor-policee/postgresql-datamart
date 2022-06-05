-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_frequency;

-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_frequency (
    user_id INT NOT NULL PRIMARY KEY,
    frequency INT NOT NULL CHECK(
        frequency >= 1
        AND frequency <= 5
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
        AND extract(
            year
            FROM
                o.order_ts
        ) >= 2021
),

orders_count_cte AS (
    SELECT
        user_id AS user_id,
        count(order_id) AS orders_count
    FROM
        filter_orders_cte
    GROUP BY
        user_id
),

frequency_cte AS (
    SELECT
        user_id,
        ntile(5) OVER (
            ORDER BY
                orders_count ASC
        ) AS frequency
    FROM
        orders_count_cte
)

INSERT INTO
    de.analysis.tmp_rfm_frequency (user_id, frequency)
SELECT
    user_id,
    frequency
FROM
    frequency_cte;
