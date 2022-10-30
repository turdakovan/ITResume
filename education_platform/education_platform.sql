
-- Задача 1. 
-- Метрика n-day retention: обычный ретеншен 0, 1, 3, 7, 14 и 30 дня - это поможет 
-- нам понять активность пользователей. Считать метрику нужно по когортам: 
-- в зависимости от месяца регистрации.

WITH one AS (
	SELECT ue.user_id,
		   ue.entry_at :: DATE AS date_entry,
		   EXTRACT(MONTH FROM u.date_joined :: DATE) AS month_reg,
		   EXTRACT(DAY FROM AGE(ue.entry_at, u.date_joined)) AS lifetime
	FROM userentry ue
		JOIN users u ON ue.user_id = u.id
    WHERE EXTRACT(YEAR FROM u.date_joined) = 2022
    	AND ue.user_id > 94
    	AND u.company_id != 1
),
-- считаем кол-во уникальных пользователей в каждый лайтфайм каждого месяца
two AS (
	SELECT month_reg,
	       lifetime,
	       COUNT(DISTINCT user_id) AS cnt_users
	FROM one
	GROUP BY month_reg, lifetime
)

-- делаем PIVOT и считаем retention

SELECT 
   month_reg,
   COALESCE(ROUND(max(CASE WHEN lifetime = 0 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END)), 2) AS "0",
   COALESCE(ROUND(max(CASE WHEN lifetime = 1 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END), 2), 0) AS "1",
   COALESCE(ROUND(max(CASE WHEN lifetime = 3 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END), 2), 0) AS "3",
   COALESCE(ROUND(max(CASE WHEN lifetime = 7 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END), 2), 0) AS "7",
   COALESCE(ROUND(max(CASE WHEN lifetime = 14 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END), 2), 0) AS "14",
   COALESCE(ROUND(max(CASE WHEN lifetime = 30 THEN cnt_users END) * 100.0 / max(CASE WHEN lifetime = 0 THEN cnt_users END), 2), 0) AS "30"
FROM two
GROUP BY month_reg



-- Задача 2.
-- Метрика rolling retention: в сущности, эта метрика для нас более показательна - 
-- человек вполне может зайти на платформу не в 7, а в 8 день. Это основная метрика для
-- оценки активности пользователей и удержания. Здесь аналогично - считаем по когортам.

WITH one AS (
	SELECT ue.user_id,
	   EXTRACT(MONTH FROM date_joined) AS month_reg,
	   EXTRACT(DAY FROM AGE(entry_at, date_joined)) AS lifetime
	FROM userentry ue 
		JOIN users u ON ue.user_id = u.id
	WHERE EXTRACT(YEAR FROM date_joined) = 2022
  	AND ue.user_id > 94
  	AND u.company_id != 1
)

SELECT month_reg,
    round(count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "0",
    round(count(DISTINCT CASE WHEN lifetime >= 1 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "1",
    round(count(DISTINCT CASE WHEN lifetime >= 3 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "3",
    round(count(DISTINCT CASE WHEN lifetime >= 7 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "7",
    round(count(DISTINCT CASE WHEN lifetime >= 14 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "14",
    round(count(DISTINCT CASE WHEN lifetime >= 30 THEN user_id END) * 100.0 / count(DISTINCT CASE WHEN lifetime >= 0 THEN user_id END),2) AS "30"
FROM one
GROUP BY month_reg



-- Задача 3.
-- Среднее и медианное число решаемых задач и тестов (за все время) - 
-- эта метрика поможет понять, нужно ли нам ограничивать количество задач и тестов.

WITH one AS (
	 -- число тестов, которые решил пользователь
	SELECT t.user_id,
		   count(DISTINCT t.test_id) AS cnt_tests
	FROM teststart t 
		JOIN testresult t2 ON t.user_id = t2.user_id 
	GROUP BY t.user_id
),

-- число, задач, которые решил пользователь
two AS (
	SELECT c.user_id,
		   count(DISTINCT c.problem_id) AS cnt_problems
	FROM coderun c 
		JOIN codesubmit c2 ON c.user_id = c2.user_id
	GROUP BY c.user_id 
)

-- находим среднее и медиану от общего числа задач и тестов, которые решил пользователь
SELECT round(avg(total_cnt), 2) AS avg_total_cnt,
       percentile_disc(0.5) WITHIN GROUP (ORDER BY total_cnt) AS median_total_cnt
FROM (
	SELECT 
	   	  COALESCE(cnt_tests, 0) + COALESCE(cnt_problems, 0) AS total_cnt 
	FROM one o
		FULL JOIN two t ON o.user_id = t.user_id
	) AS q
	

	
--Задача 4.
-- Снова среднее и медиану, но в этот раз только по правильно решенным задачам - 
-- как вариант, мы можем ограничивать количество только правильно решенных задач.
	
WITH one AS (
	-- число задач, которые верно решил пользователь
	SELECT c.user_id,
		   count(DISTINCT c.problem_id) AS cnt_problems
	FROM codesubmit c 
	WHERE is_false = 0
	GROUP BY c.user_id
)


SELECT round(avg(cnt_problems), 2) AS avg_cnt_problems,
	   percentile_disc(0.5) WITHIN GROUP (ORDER BY cnt_problems) AS median_cnt_problems
FROM one



-- Задача 5.
-- Среднее и медианное значение по количеству попыток (общее - отдельно, неправильных попыток - отдельно)
--  для решения одной задачи. Это поможет принять решение об ограничении на количество попыток.

WITH one AS (
	-- считаем уникальное кол-во всех задач и уникальное кол-во неправильно решенных задач
	SELECT user_id,
		   count(DISTINCT problem_id ) AS all_cnt_problems,
		   count(DISTINCT CASE WHEN is_false = 1 THEN problem_id END) AS false_cnt_problems
	FROM codesubmit c
	GROUP BY user_id
	
)

-- считаем среднее и медиану
SELECT round(avg(all_cnt_problems),2) AS avg_all_cnt_problems,
	   round(avg(false_cnt_problems),2) AS avg_false_cnt_problems,
	   percentile_disc(0.5) WITHIN GROUP (ORDER BY all_cnt_problems) AS median_all_cnt_problems,
	   percentile_disc(0.5) WITHIN GROUP (ORDER BY false_cnt_problems) AS median_false_cnt_problems 
FROM one



-- Задача 6.
-- Сколько монет в среднем списывает пользователь за весь срок жизни? 
-- Сколько монет ему начисляется? Какая дельта между этими двумя метриками? 
-- Это позволит понять, сколько вообще потенциально пользователи «вырабатывают» денег у 
-- нас на платформе. Зная курс 1 коина к рублю, мы можем легко конвертировать
-- потраченные монеты в реальные деньги - это даст нам какой-то ориентир при формировании стоимости подписки.


SELECT avg(sum_bonus) AS avg_sum_bonus,
	   avg(solution_cost) AS avg_solution_cost,
	   avg(sum_bonus) - avg(solution_cost) AS delta
FROM (
SELECT user_id,
	   sum(bonus) AS sum_bonus,
	   sum(solution_cost) AS solution_cost
FROM problem p 
	JOIN codesubmit c ON p.id = c.problem_id
GROUP BY user_id) AS q
	
	

-- Задача 7.
-- Среднее значение - это хорошо, но распределение итогового баланса
-- также очень интересно, потому что там могут возникать очень неожиданные
-- результаты. Как минимум, оценить стоит. Предлагаю посчитать перцентили с
-- шагом в 0.1. То есть считаем баланс каждого пользователя, а потом смотрим на перцентили

WITH one AS (
SELECT sum(CASE WHEN type_id = 2 THEN value end) AS up,
 	   sum(CASE WHEN type_id = 1 THEN value end) AS down
FROM "transaction" t
GROUP BY user_id)

SELECT decl, 
       percentile_disc(decl) within group (order by one.up) AS up_decl,
       percentile_disc(decl) within group (order by one.down) AS down_decl
FROM one, generate_series(0.1, 0.9, 0.1) as decl
GROUP BY decl



-- Задача 8.
-- Количество купленных подсказок и решений.
-- Интересно, сколько их купили в сумме (отдельно - подсказки, 
-- отдельно - решения), а также в среднем на 1 пользователя.

-- кол-во купленных подсказок cnt_tips, решений cnt_decision к задачам и их сумма
SELECT count(CASE WHEN type_id = 24 THEN id END) AS cnt_tips,
       count(CASE WHEN type_id = 25 THEN id END) AS cnt_decision,
       count(CASE WHEN type_id = 25 OR type_id = 24 THEN id END) AS sum_tips_decision
FROM "transaction" t;

-- в среднем на 1 пользователя приходится купленных задач или решений
SELECT round(avg(cnt_tips_decision), 2) AS avg_tips_decision
FROM (
	SELECT count(CASE WHEN type_id = 25 OR type_id = 24 THEN id END) AS cnt_tips_decision
	FROM "transaction" t
	GROUP BY user_id) AS q


	
-- Задача 9
-- Количество открытых задач и тестов. Интересно, сколько в сумме купили закрытые задачи
-- и тесты (отдельно - задачи, отдельно - тесты), а также в среднем на 1 пользователя.
-- Также стоит посмотреть, сколько людей купили хотя бы 1 задачу/тест, а сколько решали
-- только бесплатные (но при этом решали хотя бы 1 задачу/тест).

-- Количество открытых задач и тестов.
SELECT
	  count(CASE WHEN is_visible = 1 AND t.type_id = 23 THEN 1 END) cnt_open_task,
	  count(CASE WHEN is_visible = 1 AND t.type_id = 27 THEN 1 END) cnt_open_tests,
	  count(CASE WHEN is_visible = 0 AND t.type_id = 23 THEN 1 END) cnt_close_task,
	  count(CASE WHEN is_visible = 0 AND t.type_id = 27 THEN 1 END) cnt_close_task
FROM "transaction" t 
	JOIN transactiontype t2 ON t.type_id = t2."type"

-- в среднем на 1 пользователя
SELECT round(avg(cnt_open_task),2) AS avg_open_task,
	   round(avg(cnt_open_tests),2) AS avg_open_tests,
	   round(avg(cnt_close_task),2) AS avg_close_task,
	   round(avg(cnt_close_tests),2) AS avg_close_tests
FROM (
	SELECT 
		  count(CASE WHEN is_visible = 1 AND t.type_id = 23 THEN 1 END) cnt_open_task,
	      count(CASE WHEN is_visible = 1 AND t.type_id = 27 THEN 1 END) cnt_open_tests,
	      count(CASE WHEN is_visible = 0 AND t.type_id = 23 THEN 1 END) cnt_close_task,
	      count(CASE WHEN is_visible = 0 AND t.type_id = 27 THEN 1 END) cnt_close_tests
    FROM "transaction" t 
	    JOIN transactiontype t2 ON t.type_id = t2."type"
	GROUP BY t.user_id) AS q
	
-- Купили хотя бы 1 задачу или тест cnt_task_or_test
-- решали только бесплатные	задачи или тесты cnt_free_task_or_test
SELECT 
	   count(CASE WHEN t.type_id = 23 OR t.type_id = 27 THEN 1 END) cnt_task_or_test,
	   count(CASE WHEN (t.type_id = 23 OR t.type_id = 27) AND t.value = 0 THEN 1 END) cnt_free_task_or_test
FROM "transaction" t 



-- Задача 10
-- Как связана дата захода на платформу и активность пользователя.
-- Под активностью я имею ввиду попытка решить задачу/тест. 
-- Надо посмотреть - какой % заходов не сопровождается активностью.

WITH one AS (
-- зашли и не решали в этот же день тесты или задачи
	SELECT count(DISTINCT user_id) AS cnt_not_solve
	FROM userentry
	WHERE entry_at::date NOT IN (SELECT created_at::date FROM testresult)
  	  AND entry_at::date NOT IN (SELECT created_at::date FROM codesubmit)
)

-- находим процент пользователей, которые зашли и не решали тесты и задачи от общего числа пользователей
SELECT 
	  round((SELECT cnt_not_solve FROM one)*100.0 / count(DISTINCT user_id), 2) AS percent_not_solve
FROM userentry 



-- Задача 11
-- Надо также посчитать MAU/DAU/WAU - это позволит в целом понять 
-- ситуацию по активности. Считаем просто на основании захода на платформу.


-- DAU
SELECT round(avg(cnt_users), 2) AS dau
FROM (
	  SELECT count(DISTINCT user_id) AS cnt_users
	  FROM userentry u
	  WHERE EXTRACT(YEAR FROM entry_at) = 2022
 	  GROUP BY entry_at::date
 	  ) AS q


 -- MAU
SELECT round(avg(cnt_users), 2) AS mau
FROM (
	SELECT count(DISTINCT user_id) AS cnt_users
	FROM userentry u 
	WHERE EXTRACT (YEAR FROM entry_at) = 2022
	GROUP BY EXTRACT(MONTH FROM entry_at)
	) AS q
	
	
-- WAU
SELECT round(avg(cnt_users), 2) AS wau
FROM (
	SELECT count(DISTINCT user_id) AS cnt_users
	FROM userentry u 
	WHERE EXTRACT (YEAR FROM entry_at) = 2022
	GROUP BY EXTRACT(WEEK FROM entry_at)
) AS q



-- Задача 12. Распределение активности по дням

SELECT day_num,
	   CASE WHEN day_num = 1 THEN 'Понедельник'
	        WHEN day_num = 2 THEN 'Вторник'
	        WHEN day_num = 3 THEN 'Среда'
	   	    WHEN day_num = 4 THEN 'Четверг'
	        WHEN day_num = 5 THEN 'Пятница'
	        WHEN day_num = 6 THEN 'Суббота'
	        WHEN day_num = 7 THEN 'Воскресенье'
	   END AS "День недели",
	   round(cnt_users * 100.0 / sum(cnt_users) OVER (), 1) AS percent_from_all
FROM (
	SELECT EXTRACT(isodow FROM entry_at) AS day_num,
	   	   count(DISTINCT user_id) AS cnt_users
	FROM userentry u
	WHERE EXTRACT(YEAR FROM entry_at) = 2022
	GROUP BY day_num) AS q
	
	

-- Задача 13. Распределение активности по времени суток

WITH one AS (
-- округляем до часа, извлекаем часы и считаем кол-во уникальных пользователей
	  SELECT EXTRACT(HOUR FROM date_trunc('HOUR', entry_at)) AS hours,
	         count(DISTINCT user_id) AS cnt_users	   
	  FROM userentry u 
      WHERE EXTRACT(YEAR FROM entry_at) = 2022
	  GROUP BY hours)
-- считаем процент от общего кол-ва пользователей	
SELECT hours,
	   round(cnt_users * 100.0 / sum(cnt_users) OVER (), 1) AS percent_from_all
FROM one
	