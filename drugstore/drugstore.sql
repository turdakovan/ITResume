-- 1, 2, 3 выручка, валовая прибыль, маржинальность
SELECT round(sum(dr_kol * dr_croz - dr_sdisc))  AS revenue,
       round(sum((dr_kol * dr_croz - dr_sdisc)) - sum((dr_kol * dr_czak))) AS gross_profit,
       round(CAST((sum((dr_kol * dr_croz - dr_sdisc)) - sum((dr_kol * dr_czak))) * 100.0 / sum((dr_kol * dr_croz - dr_sdisc)) AS numeric), 2) AS marginality
FROM sales s 


-- 4.Количество уникальных чеков
SELECT count(DISTINCT dr_nchk) AS cnt_cheque
FROM sales


-- 5. Средний чек
SELECT round(avg(sum_in_cheque)) as avg_cheque
FROM (
    select sum(dr_kol * dr_croz - dr_sdisc) as sum_in_cheque
    from sales
    group by dr_nchk) as q
   
	
-- 6 Количество проданных уникальных товаров
SELECT count(DISTINCT dr_ndrugs) AS cnt
FROM sales s 
	

-- 7 Наполняемость чека (кол-во чеков / кол-во проданных упаковок)
SELECT round(avg(fill_every_cheque)::NUMERIC, 2) AS fill_cheque
FROM (
	  SELECT count(dr_nchk) over(PARTITION BY dr_nchk) / 
	            sum(dr_kol) over(PARTITION BY dr_nchk) AS fill_every_cheque
      FROM sales) AS q

 -- 8 Распределение количества чеков по времени суток
SELECT extract(HOUR FROM dr_tim) AS time_of_day,
  	   count(DISTINCT dr_nchk) AS cnt_cheque
FROM sales
GROUP BY time_of_day


-- Rolling retention

WITH one AS (
SELECT 
	   card,
	   min(date_trunc('MONTH',datetime)::date) OVER(PARTITION BY card) AS cohort,
	   datetime::date - min(datetime::date) OVER(PARTITION BY card) AS lifetime
FROM bonuscheques
WHERE card LIKE '20002%'
ORDER BY card, cohort, lifetime)

-- длинная таблица rolling retention

SELECT cohort,
	   0 AS lifetime,
	   round(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END) * 100.0 
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2) AS Retention
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       7,
       round(count(DISTINCT CASE WHEN lifetime >= 7 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2)
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       14,
       round(count(DISTINCT CASE WHEN lifetime >= 14 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2)
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       30,
       round(count(DISTINCT CASE WHEN lifetime >= 30 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2)
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       90,
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 90 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2)
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       180,
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 180 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2)
FROM one
GROUP BY cohort
UNION 
SELECT cohort,
       365,
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 365 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2)
FROM one
GROUP BY cohort
ORDER BY cohort, lifetime

-- rolling retention широкая таблица

SELECT cohort,
       round(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END) * 100.0 
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2) AS "0",
       round(count(DISTINCT CASE WHEN lifetime >= 6 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2) AS "1 week",
              
       round(count(DISTINCT CASE WHEN lifetime >= 13 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2) AS "2 week",
              
       round(count(DISTINCT CASE WHEN lifetime >= 30 THEN card END) * 100.0
              / count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 2) AS "1 month",
              
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 90 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2) AS "3 month",
              
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 180 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2) AS "6 month",
              
       round(COALESCE(count(DISTINCT CASE WHEN lifetime >= 365 THEN card END) * 100.0
              / NULLIF(count(DISTINCT CASE WHEN lifetime >= 0 THEN card END), 0), 0), 2) AS "12 month"
FROM one
GROUP BY cohort



