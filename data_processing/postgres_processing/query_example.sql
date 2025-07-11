-- Добавляем колонку для хранения центроида в таблицу 'offices'
ALTER TABLE offices ADD COLUMN centroid_geom GEOMETRY(Point, 4326);

-- Заполняем новую колонку рассчитанными центроидами для каждого офиса
UPDATE offices
SET centroid_geom = ST_Centroid(geom);

-- Создаем пространственный индекс на колонке с центроидами в таблице 'offices'
CREATE INDEX idx_offices_centroid_geom ON offices USING GIST (centroid_geom);


-- Добавляем новые колонки в test_dataset для подсчета офисов в разных радиусах
ALTER TABLE test_dataset ADD COLUMN num_offices_100m INTEGER DEFAULT 0;
ALTER TABLE test_dataset ADD COLUMN num_offices_250m INTEGER DEFAULT 0;
ALTER TABLE test_dataset ADD COLUMN num_offices_500m INTEGER DEFAULT 0;
ALTER TABLE test_dataset ADD COLUMN num_offices_1000m INTEGER DEFAULT 0;

-- Рассчитываем и обновляем количество офисов в радиусе 100м
UPDATE test_dataset AS td
SET num_offices_100m = COALESCE(counts.count_val, 0)
FROM (
    SELECT
        loc.id,
        COUNT(off.id) AS count_val -- Считаем количество офисов
    FROM
        test_dataset AS loc
    JOIN
        offices AS off
        -- Используем предварительно рассчитанный и индексированный центроид офиса
        ON ST_DWithin(loc.geom::geography, off.centroid_geom::geography, 100)
    GROUP BY
        loc.id
) AS counts
WHERE td.id = counts.id;

-- Рассчитываем и обновляем количество офисов в радиусе 250м
UPDATE test_dataset AS td
SET num_offices_250m = COALESCE(counts.count_val, 0)
FROM (
    SELECT
        loc.id,
        COUNT(off.id) AS count_val
    FROM
        test_dataset AS loc
    JOIN
        offices AS off
        ON ST_DWithin(loc.geom::geography, off.centroid_geom::geography, 250)
    GROUP BY
        loc.id
) AS counts
WHERE td.id = counts.id;

-- Рассчитываем и обновляем количество офисов в радиусе 500м
UPDATE test_dataset AS td
SET num_offices_500m = COALESCE(counts.count_val, 0)
FROM (
    SELECT
        loc.id,
        COUNT(off.id) AS count_val
    FROM
        test_dataset AS loc
    JOIN
        offices AS off
        ON ST_DWithin(loc.geom::geography, off.centroid_geom::geography, 500)
    GROUP BY
        loc.id
) AS counts
WHERE td.id = counts.id;

-- Рассчитываем и обновляем количество офисов в радиусе 1000м
UPDATE test_dataset AS td
SET num_offices_1000m = COALESCE(counts.count_val, 0)
FROM (
    SELECT
        loc.id,
        COUNT(off.id) AS count_val
    FROM
        test_dataset AS loc
    JOIN
        offices AS off
        ON ST_DWithin(loc.geom::geography, off.centroid_geom::geography, 1000)
    GROUP BY
        loc.id
) AS counts
WHERE td.id = counts.id;
