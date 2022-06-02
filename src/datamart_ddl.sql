-- Удаление витрины

DROP TABLE IF EXISTS de.analysis.dm_rfm_segments;

-- Создание витрины

CREATE TABLE IF NOT EXISTS de.analysis.dm_rfm_segments (
    "user_id" int,
    "recency" smallint,
    "frequency" smallint,
    "monetary_value" smallint
);
