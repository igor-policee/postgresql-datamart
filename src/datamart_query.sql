-- Очистка таблицы
TRUNCATE TABLE de.analysis.dm_rfm_segments;

-- Заполнение таблицы
INSERT INTO
    de.analysis.dm_rfm_segments (user_id, recency, frequency, monetary_value)
SELECT
	trr.user_id as user_id,
	trr.recency as recency,
	trf.frequency as frequency,
	trmv.monetary_value as monetary_value
FROM
	de.analysis.tmp_rfm_recency trr
	INNER JOIN de.analysis.tmp_rfm_frequency trf USING (user_id)
	INNER JOIN de.analysis.tmp_rfm_monetary_value trmv USING (user_id);

/*
Первые десять строк из полученной витрины, отсортированные по user_id

|user_id|recency|frequency|monetary_value|
|-------|-------|---------|--------------|
|0      |1      |3        |4             |
|1      |4      |3        |3             |
|2      |2      |3        |5             |
|3      |2      |3        |3             |
|4      |4      |3        |3             |
|5      |4      |5        |5             |
|6      |1      |3        |5             |
|7      |4      |2        |2             |
|8      |1      |1        |3             |
|9      |1      |2        |2             |

 */
