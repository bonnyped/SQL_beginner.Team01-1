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
        c.id,
        b.updated,
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