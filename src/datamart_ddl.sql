-- Удаление витрины
DROP TABLE IF EXISTS de.analysis.dm_rfm_segments;

-- Создание витрины
CREATE TABLE IF NOT EXISTS de.analysis.dm_rfm_segments (
    "user_id" int NOT NULL PRIMARY KEY,
    "recency" smallint NOT NULL CHECK("recency" IN (1, 2, 3, 4, 5)),
    "frequency" smallint NOT NULL CHECK("frequency" IN (1, 2, 3, 4, 5)),
    "monetary_value" smallint NOT NULL CHECK("monetary_value" IN (1, 2, 3, 4, 5))
);
