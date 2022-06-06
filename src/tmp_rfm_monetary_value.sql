-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_monetary_value;

-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_monetary_value (
    user_id INT NOT NULL PRIMARY KEY,
    monetary_value INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5)
);

-- Заполнение таблицы
WITH monetary_value_cte AS (
    SELECT
        u.id AS user_id,
        NTILE (5) OVER (ORDER BY sum(o.payment) NULLS FIRST) AS monetary_value
    FROM
        analysis.users AS u
        LEFT JOIN analysis.orders AS o ON u.id = o.user_id
        AND o.status = 4
        AND EXTRACT (YEAR FROM o.order_ts) >= 2021
    GROUP BY
        u.id
)

INSERT INTO
    de.analysis.tmp_rfm_monetary_value (user_id, monetary_value)
SELECT
    user_id,
    monetary_value
FROM
    monetary_value_cte;
