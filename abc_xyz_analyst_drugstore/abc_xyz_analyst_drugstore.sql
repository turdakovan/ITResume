-- ABC анализ

WITH preparation_abc_groups AS (
	SELECT dr_ndrugs,
	       round(sum(revenue_without_disc - disc)) AS revenue, -- выручка
	       sum(dr_kol) AS sum_amount,                          -- количество
	       round(sum(profit_without_disc - disc)) AS profit    -- прибыль
    FROM (
	      SELECT dr_nchk,
                 dr_ndrugs,
                 dr_kol,
	             sum(dr_sdisc) AS disc,
	             sum(dr_kol * dr_croz) AS revenue_without_disc,
	             sum(dr_kol * (dr_croz - dr_czak)) AS profit_without_disc
          FROM sales s 
          GROUP BY dr_nchk, dr_ndrugs, dr_kol
          ) AS q
    GROUP BY dr_ndrugs
    ),

abc_groups AS (
SELECT dr_ndrugs,
	   CASE WHEN sum(revenue) over(ORDER BY revenue DESC) / sum(revenue) OVER() <= 0.8 THEN 'A'
	        WHEN sum(revenue) over(ORDER BY revenue DESC) / sum(revenue) OVER() <= 0.95 THEN 'B'
	        ELSE 'C'
	   END AS revenue_abc,
	       
	   CASE WHEN sum(sum_amount) OVER(ORDER BY sum_amount DESC) / sum(sum_amount) OVER() <= 0.8 THEN 'A'
            WHEN sum(sum_amount) OVER(ORDER BY sum_amount DESC) / sum(sum_amount) OVER() <= 0.95 THEN 'B'
            ELSE 'C'
       END AS amount_abc,
           
       CASE WHEN sum(profit) OVER(ORDER BY profit DESC) / sum(profit) OVER() <= 0.8 THEN 'A'
            WHEN sum(profit) OVER(ORDER BY profit DESC) / sum(profit) OVER() <= 0.95 THEN 'B'
            ELSE 'C'
       END AS profit_abc
FROM preparation_abc_groups
    ),
    
    
-- XYZ анализ
    
-- считаем сумму продаж по неделям для товаров, где разница между продажами 7 дней и более и товар продавался 4 раза и более
xyz_sales_week AS (
	SELECT dr_ndrugs,
       	   EXTRACT(WEEK FROM dr_dat) AS week,
           sum(dr_kol * dr_croz) AS sales
    FROM sales s 
    WHERE dr_ndrugs IN (
                 -- выбираем товары где разница между продажами 7 дней и более и товар продавался более 4 раза и более
    	         SELECT DISTINCT dr_ndrugs
                 FROM (
	                    SELECT dr_ndrugs,
                               dr_dat,
                        LEAD(dr_dat) OVER(PARTITION BY dr_ndrugs ORDER BY dr_dat) - dr_dat AS diff,
                        count(dr_dat) OVER (PARTITION BY dr_ndrugs) AS cnt_been_sold
                        FROM sales s
                      ) AS q
                 WHERE diff >= 7 AND cnt_been_sold >= 4
                 )
	GROUP BY dr_ndrugs, week
	ORDER BY week, sales DESC
	),
	
-- определяем xyz-группу
	-- коэфф вариации - это стандартное отклонение * 100% / среднее 
	-- если коэфф вариации от 0% до 10% - то группа X, от 10% до 25% - то группа Y, если от 25% - то Z
xyz_group AS (
	SELECT dr_ndrugs,
		   CASE WHEN stddev(sales) * 100.0 / avg(sales) < 10.0 THEN 'X'
		        WHEN stddev(sales) * 100.0 / avg(sales) < 25.0 THEN 'Y'
		        ELSE 'Z'
		   END AS xyz_sales
    FROM xyz_sales_week
	GROUP BY dr_ndrugs
	)
     
-- соедниняем CTE abc-групп с CTE с xyz-группами с помощью left join чтобы не потерялись товары	
SELECT a.dr_ndrugs AS product,
       amount_abc,
       profit_abc,
       revenue_abc,
       xyz_sales
FROM abc_groups a
    LEFT JOIN xyz_group x ON a.dr_ndrugs = x.dr_ndrugs
ORDER BY amount_abc, profit_abc, revenue_abc, xyz_sales
    