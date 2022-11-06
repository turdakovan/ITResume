
-- Часть 1. Топовые mcc-группы

WITH one AS (
-- считаем суммы транзакций в каждом месяце в каждой группе group_name
-- а также считаем по скольким группам были заказы в каждом месяце
	SELECT 
	group_name,
	EXTRACT(MONTH FROM transaction_date) AS month_transaction,
	sum(transaction_value) AS tr_sum,
	count(group_name) OVER(PARTITION BY EXTRACT(MONTH FROM transaction_date)) AS cnt_group_in_month
	FROM purchases p 
	LEFT JOIN mcc_codes mc ON p.mcc_code_id = mc.mcc_code_id
	AND p.transaction_date BETWEEN mc.valid_from AND mc.valid_to
	LEFT JOIN mcc_groups mg ON mc.group_id = mg.group_id
	WHERE EXTRACT(YEAR FROM transaction_date) = 2019
	GROUP BY group_name, month_transaction 
	ORDER BY month_transaction, group_name
),

two AS (
    -- выбираем группу, месяц, сумму транзакций абсолютную и относительную разницы между суммой
    -- транзакции и следующей записью суммы транзакции (т.е. со вторым местом по сумме транзакции)
    -- в каждом месяце
    -- А также считаем число строк в каждом месяце, чтобы в итоговый результат попало только 
    -- по 1 записи с каждого месяца (т.е. записи с rn=1)
	SELECT 
	group_name,
	month_transaction,
	tr_sum,
	CASE WHEN cnt_group_in_month = 1 THEN NULL
	     ELSE tr_sum - LEAD(tr_sum) OVER(PARTITION BY month_transaction ORDER BY tr_sum DESC, group_name)
	END AS abs_diff,
	CASE WHEN cnt_group_in_month = 1 THEN NULL
	ELSE round((tr_sum - LEAD(tr_sum) OVER(PARTITION BY month_transaction ORDER BY tr_sum DESC, group_name)) :: NUMERIC / tr_sum, 2)
	END AS rel_diff,
	ROW_NUMBER() OVER(PARTITION BY month_transaction ORDER BY tr_sum DESC) AS rn_tr_sum
	FROM one
	ORDER BY month_transaction, group_name
),

three AS (
-- создаём cte со всеми месяцами в году
	SELECT generate_series(1, 12) AS month_transaction
)


-- соединяем cte со всеми месяцами three с сte two
SELECT 
group_name,
tr.month_transaction,
to_char(tr_sum, '9999990.00') AS tr_sum,
to_char(abs_diff, '9999990.00') AS abs_diff,
to_char(rel_diff, '9999990.00' ) AS rel_diff
FROM three tr
    LEFT JOIN two t ON tr.month_transaction = t.month_transaction
WHERE rn_tr_sum = 1 OR rn_tr_sum IS NULL 
ORDER BY tr.month_transaction, group_name



-- Часть 2. Самые дорогие транзакции

WITH years AS (
-- генерируем года 2019 и 2020 каждый по 3 раза
	SELECT 2019 AS year_
	UNION ALL 
	SELECT 2020 AS year_
	UNION ALL 
	SELECT 2019 AS year_
	UNION ALL 
	SELECT 2020 AS year_
	UNION ALL 
	SELECT 2019 AS year_
	UNION ALL 
	SELECT 2020 AS year_
),

group_name_years_3_times AS (
-- соединяем сте years и mcc_groups с помощью cross join
SELECT *,
ROW_NUMBER() OVER(PARTITION BY year_, group_name) AS row_n
FROM years, mcc_groups
),


one AS (
-- выбираем название группы, год, величину транзакции и ранжируем транзакции в каждом году в каждой группе 
	SELECT 
	group_name,
	EXTRACT (YEAR FROM transaction_date) AS year_transaction,
	transaction_value,
	row_number() OVER (PARTITION BY group_name, EXTRACT(YEAR FROM transaction_date) ORDER BY transaction_value DESC) AS rn
	FROM mcc_groups mg 
	LEFT JOIN mcc_codes mc ON mg.group_id = mc.group_id 
	LEFT JOIN purchases p ON mc.mcc_code_id = p.mcc_code_id
	AND p.transaction_date BETWEEN mc.valid_from AND mc.valid_to
)

-- соединяем сгенерированные года с сте one
SELECT
gny.group_name,
to_char(year_, '9999') AS year,
row_n AS rn,
transaction_value
FROM group_name_years_3_times gny
LEFT JOIN one o ON gny.row_n = o.rn
  AND gny.year_ = o.year_transaction
  AND gny.group_name = o.group_name
ORDER BY gny.group_name, rn, year
 
 