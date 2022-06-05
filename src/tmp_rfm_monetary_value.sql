-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_monetary_value;-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_monetary_value (
    user_id INT NOT NULL PRIMARY KEY,
    monetary_value INT NOT NULL CHECK(
        monetary_value >= 1
        AND monetary_value <= 5
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

payment_summary_cte AS (
    SELECT
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
        ntile(5) OVER (
            ORDER BY
                payment_summary ASC
        ) AS monetary_value
    FROM
        payment_summary_cte
)

INSERT INTO
    de.analysis.tmp_rfm_monetary_value (user_id, monetary_value)
SELECT
    user_id,
    monetary_value
FROM
    monetary_value_cte;
