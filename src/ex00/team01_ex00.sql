WITH last_rates AS (
    SELECT c.id,
        c.name AS currency_name,
        COALESCE(c.rate_to_usd, 1) AS last_rate
    FROM currency AS c
    WHERE c.updated IN (
            select MAX(c2.updated)
            FROM currency AS c2
        )
    GROUP BY c.id,
        c.name,
        c.rate_to_usd
)
SELECT COALESCE(u.name, 'not defined') AS name,
    COALESCE(u.lastname, 'not defined') AS lastname,
    b."type" AS type,
    sum(b.money) AS volume,
    COALESCE(lr.currency_name, 'not defined') AS currency_name,
    COALESCE(lr.last_rate, 1) AS last_rate_to_usd,
    (COALESCE(lr.last_rate, 1) * sum(b.money))::REAL AS total_volume_in_usd
FROM "user" AS u
    FULL JOIN balance AS b ON u.id = b.user_id
    LEFT JOIN last_rates As lr ON lr.id = b.currency_id
GROUP BY u.id,
    b."type",
    b.user_id,
    b.currency_id,
    lr.currency_name,
    lr.last_rate
ORDER BY 1 DESC,
    2,
    3;