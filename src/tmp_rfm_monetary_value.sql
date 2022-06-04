-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_monetary_value;

-- Создание таблицы
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
        AND extract(year FROM o.order_ts) >= 2021
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
)

INSERT INTO
	de.analysis.tmp_rfm_monetary_value (user_id, monetary_value)
SELECT
	user_id,
	monetary_value
FROM
	monetary_value_cte
