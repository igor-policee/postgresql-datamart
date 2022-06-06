-- Удаление таблицы
DROP TABLE IF EXISTS de.analysis.tmp_rfm_recency;

-- Создание таблицы
CREATE TABLE de.analysis.tmp_rfm_recency (
    user_id INT NOT NULL PRIMARY KEY,
    recency INT NOT NULL CHECK(recency >= 1 AND recency <= 5)
);

-- Заполнение таблицы
WITH recency_cte AS (
    SELECT
        u.id AS user_id,
        NTILE (5) OVER (ORDER BY max(o.order_ts) NULLS FIRST) AS recency
    FROM
        analysis.users AS u
        LEFT JOIN analysis.orders AS o ON u.id = o.user_id
        AND o.status = 4
        AND EXTRACT (YEAR FROM o.order_ts) >= 2021
    GROUP BY
        u.id
)

INSERT INTO
    de.analysis.tmp_rfm_recency (user_id, recency)
SELECT
    user_id,
    recency
FROM
    recency_cte;
