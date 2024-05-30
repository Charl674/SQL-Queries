-- Recursive Common Table Expression (CTE) to identify valid transaction dates
WITH RECURSIVE valid_dates AS (
    -- Select user ID, age, minimum transaction date, and maximum transaction date for each user
    SELECT 
        u.id AS user_id, 
        u.age, 
        MIN(CAST(m.timestamp AS DATE)) AS min_txn_date, 
        MAX(CAST(m.timestamp AS DATE)) AS max_txn_date
    FROM 'userz.csv' u
    LEFT JOIN 'mobilemoney.csv' m ON u.id = m.caller_id
    -- Filter out transactions with zero amount
    WHERE m.amount <> 0
    GROUP BY u.id, u.age
),

-- Recursive CTE to generate a continuous date range for each user between their first and last transaction dates
date_range AS (
    -- Initialize with the minimum transaction date
    SELECT 
        user_id, 
        min_txn_date AS txn_date, 
        max_txn_date
    FROM valid_dates

    UNION ALL

    -- Recursively add one day to the transaction date until the maximum transaction date is reached
    SELECT 
        dr.user_id, 
        DATE_ADD(dr.txn_date, INTERVAL 1 DAY) AS txn_date, 
        dr.max_txn_date
    FROM date_range dr
    WHERE dr.txn_date < dr.max_txn_date
)

-- Final query to aggregate transaction data on a daily basis
SELECT 
    dr.user_id, 
    u.age, 
    dr.txn_date,
    -- Calculate the total transaction volume for each user on each date
    COALESCE(SUM(m.amount), 0) AS volume,
    -- Count the number of transactions for each user on each date
    COUNT(m.amount) AS txn_count
FROM date_range dr
LEFT JOIN 'userz.csv' u ON dr.user_id = u.id
LEFT JOIN 'mobilemoney.csv' m ON u.id = m.caller_id AND CAST(m.timestamp AS DATE) = dr.txn_date
-- Group by user ID, age, and transaction date to ensure correct aggregation
GROUP BY dr.user_id, u.age, dr.txn_date
-- Order the results by user ID and transaction date for better readability
ORDER BY dr.user_id, dr.txn_date;
