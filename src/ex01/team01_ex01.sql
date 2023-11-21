DELETE FROM currency
WHERE (
        currency.updated = '2022-01-08 13:29'
        AND currency.rate_to_usd = 0.79
    )
    OR (
        currency.updated = '2022-01-01 13:29'
        AND currency.rate_to_usd = 0.85
    );

insert into currency
values (100, 'EUR', 0.85, '2022-01-01 13:29');
insert into currency
values (100, 'EUR', 0.79, '2022-01-08 13:29');

WITH before_after_rate AS (
    SELECT b.user_id,
        c.id AS currency_id,
        c.name AS currency_name,
        b.money AS balance_money,
        (
            SELECT currency.rate_to_usd
            FROM currency
            WHERE c.id = currency_id
                AND c.name = currency.name
                AND currency.updated < b.updated
                AND b.currency_id = currency.id
            ORDER BY currency.rate_to_usd
            LIMIT 1
        ) AS before_rate_usd,
        (
            SELECT currency.rate_to_usd
            FROM currency
            WHERE c.id = currency_id
                AND c.name = currency.name
                AND currency.updated > b.updated
                AND b.currency_id = currency.id
            ORDER BY currency.rate_to_usd
            LIMIT 1
        ) AS after_rate_usd
    FROM currency AS c
        INNER JOIN balance AS b ON b.currency_id = c.id
    GROUP BY b.user_id,
        c.name,
        b.updated,
        c.id,
        b.user_id,
        b.currency_id,
        b.money
)
SELECT COALESCE(u.name, 'not defined') AS name,
    COALESCE(u.lastname, 'not defined') AS lastname,
    bar.currency_name,
    (
        bar.balance_money * COALESCE(bar.before_rate_usd, bar.after_rate_usd)
    )::real AS currency_in_usd
FROM "user" AS u
    RIGHT JOIN before_after_rate AS bar ON bar.user_id = u.id
ORDER BY 1 DESC,
    2,
    3;

WITH foo AS (
    SELECT b.updated balance_update,
        (
            SELECT CASE
                    WHEN EXISTS(
                        SELECT b.updated
                        FROM currency c
                        WHERE c.updated < b.updated
                            AND c.id = b.currency_id
                    ) THEN (
                        SELECT c2.updated
                        FROM balance b2
                            JOIN currency c2 on b.currency_id = c2.id
                        WHERE c2.updated < b.updated
                        ORDER BY 1 DESC
                        LIMIT 1
                    )
                END
        ) currency_update, money, b.user_id
    FROM balance b
),
boo AS (
    SELECT b.updated balance_update,
        (
            SELECT CASE
                    WHEN NOT EXISTS(
                        SELECT b.updated
                        FROM currency c
                        WHERE c.updated < b.updated
                            AND c.id = b.currency_id
                    ) THEN (
                        SELECT c2.updated
                        FROM balance b2
                            JOIN currency c2 on b.currency_id = c2.id
                        WHERE c2.updated > b.updated
                        ORDER BY 1
                        LIMIT 1
                    )
                END
        ) currency_update, money, b.user_id
    FROM balance b
    ORDER BY 3 DESC
),
together AS (
    SELECT *
    FROM foo
    WHERE currency_update IS NOT NULL
    UNION
    SELECT *
    FROM boo
    WHERE currency_update IS NOT NULL
),
just_little_bit AS (
    SELECT COALESCE(u.name, 'not defined') name,
        COALESCE(u.lastname, 'not defined') lastname,
        c3.name currency_name,
        t.*
    FROM "user" u
        FULL JOIN balance b3 on u.id = b3.user_id
        FULL JOIN currency c3 on b3.currency_id = c3.id
        FULL JOIN together t ON t.balance_update = b3.updated
        AND t.currency_update = c3.updated
        AND t.money = b3.money
        AND b3.user_id = t.user_id
)
SELECT jlb.name,
    jlb.lastname,
    jlb.currency_name,
    jlb.money * c4.rate_to_usd currency_in_usd
FROM just_little_bit jlb
    JOIN currency c4 ON c4.updated = jlb.currency_update
    AND c4.name = jlb.currency_name
ORDER BY 1 DESC,
    2,
    3;