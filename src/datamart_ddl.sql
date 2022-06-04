-- Удаление витрины
DROP TABLE IF EXISTS de.analysis.dm_rfm_segments;

-- Создание витрины
CREATE TABLE IF NOT EXISTS de.analysis.dm_rfm_segments (
    "user_id" int NOT NULL PRIMARY KEY,
    "recency" smallint NOT NULL CHECK(1 <= "recency" AND "recency" <= 5),
    "frequency" smallint NOT NULL CHECK(1 <= "frequency" AND "frequency" <= 5),
    "monetary_value" smallint NOT NULL CHECK(1 <= "monetary_value" AND "monetary_value" <= 5)
);
