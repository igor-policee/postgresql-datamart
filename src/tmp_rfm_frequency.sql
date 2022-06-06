-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_frequency;

-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_frequency (
    user_id INT NOT NULL PRIMARY KEY,
    frequency INT NOT NULL CHECK(frequency >= 1 AND frequency <= 5)
);

-- Заполнение таблицы
WITH frequency_cte AS (
    SELECT
        u.id AS user_id,
        NTILE (5) OVER (ORDER BY count(o.order_id) NULLS FIRST) AS frequency
    FROM
        analysis.users AS u
        LEFT JOIN analysis.orders AS o ON u.id = o.user_id
        AND o.status = 4
        AND EXTRACT (YEAR FROM o.order_ts) >= 2021
    GROUP BY
        u.id
)

INSERT INTO
    de.analysis.tmp_rfm_frequency (user_id, frequency)
SELECT
    user_id,
    frequency
FROM
    frequency_cte;
