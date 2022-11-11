--=============== MODULE 6. POSTGRESQL =======================================

--======== MAIN PART ==============

--TASK №1
--Write an SQL query that displays all information about movies
--with special attribute "Behind the Scenes"

-- explain analyze -- 0.35ms
select film_id, title, special_features from film 
where special_features @> '{"Behind the Scenes"}'

--TASK №2
--Write 2 more movie search options with "Behind the Scenes" attribute,
--using other SQL functions or statements to look up a value in an array.

-- explain analyze -- 0.35ms
select film_id, title, special_features from film 
where array_position(special_features, 'Behind the Scenes') is not null

-- explain analyze -- 0.26ms
select film_id, title, special_features from film 
where 'Behind the Scenes' = any(special_features)

--TASK №3
--For each buyer, count how many films he rented
--with the special attribute "Behind the Scenes".

--Prerequisite for completing the task: use the query from task 1,
--placed in CTE. CTE must be used to solve the task.

-- explain analyze -- 7.5ms
with cte as (select film_id, title, special_features from film 
where special_features @> '{"Behind the Scenes"}')
select r.customer_id, count(i.film_id)
from cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id 
group by r.customer_id
order by r.customer_id 

--TASK №4
--For each buyer, count how many films he rented
--with the special attribute "Behind the Scenes".

--Prerequisite for completing the task: use the query from task 1,
--placed in a subquery to be used to solve the job.

-- explain analyze -- 7.5ms
select r.customer_id, count(i.film_id)
from (select film_id, title, special_features from film 
where special_features @> '{"Behind the Scenes"}') cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id 
group by r.customer_id
order by r.customer_id 

--TASK №5
--Create a materialized view with the query from the previous job
--and write a query to update the materialized view

CREATE MATERIALIZED VIEW mv 
AS (select r.customer_id, count(i.film_id)
from (select film_id, title, special_features from film 
where special_features @> '{"Behind the Scenes"}') cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id 
group by r.customer_id
order by r.customer_id )
WITH NO DATA

REFRESH MATERIALIZED VIEW mv

--TASK №6
--Use explain analyze to analyze the speed of query execution
-- from the previous tasks and answer the questions:

--1. What operator or function of the SQL language used when doing homework,
--   is faster for searching a value in an array
--2. Which option works faster:
--   CTE or subquery

-- Answer 1:
-- Actual time(ANY) = 0.26ms
-- Actual time(@>) = Actual_time(array_position) = 0.35ms
-- It appears that ANY operator is faster than @> opeartor and array_position function

-- Answer 2:
-- Actual time(CTE) = 7.5ms
-- Actual time(subquery) = 7.5ms
-- It appears that CTE works as fast as subquery

--======== ADDITIONAL PART ==============

--TASK №1

--explain analyze -- 39.5ms
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

-- Question 1: Execute explain analyze command. 
--             Find the bottlenecks of the query and describe them.
-- Answer 1:   Explain analyze shows that the query consists of 11 nested levels.
--             Total actial time is 39.5ms. 
--             It mostly consists of:
--              1. Nested Loop Left Join (10 ms) -- inv subquery
--              2. Nested Loop Left Join (10 ms) -- ren subquery
--              3. Sort (8ms) -- sorting by count

explain analyze -- 8ms
select c.first_name || ' ' || c.last_name, count(i.film_id) as "count"
from (select film_id, title, special_features from film 
where special_features @> '{"Behind the Scenes"}') cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id 
join customer c on r.customer_id = c.customer_id
group by c.customer_id
order by "count" desc

-- Question 2: Compare this request with the request from 4th task (presented above)
-- Answer 2: The first request returns 600 rows, the second request returns 599 rows (row ([NULL], 0) is missing).
--           The second request is faster than the first request.
--           The differences between the first and the second query:
--           1. Joining tables "film", "inventory", "rental", "customer".
--              First query:  customer JOIN (rental JOIN (inventory JOIN film))
--              Second query: ((film JOIN inventory) JOIN rental) JOIN customer
--           2. Search "Behind the Scenes"
--              First query:  unnest array, search value "Behind the Scenes" in column
--              Second query: search value "Behind the Scenes" in array
--           3. Group by customer_id
--              First query:  window by customer_id, distinct by customer name
--              Second query: group by customer_id

-- Question 3: Make a line-by-line description of explain analyze of the optimized query (in Russian).

Сортировка 599 строк, 44 столбцов. Текущее время 7.882 мс
  Сортировка по count(i.film_id), порядок сортировки DESC -- по убыванию, метод сортировки quicksort
  ->  Временная hash таблица для группировки 599 строк, 44 столбцов. Текущее время 7.778 мс
        Группировка по c.customer_id
        -> Строки таблицы "customer" записываются в hash таблицу, 8612 строк и 19 столбцов. Текущее время 6.693 мс
		   условие для JOIN: r.customer_id = c.customer_id
              -> Строки таблицы "inventory" записываются в hash таблицу, 8612 строк и 4 столбца. Текущее время 5.401 мс
			     условие для JOIN: i.film_id = film.film_id
                    -> Строки таблицы "rental" записываются в hash таблицу, 16005 строк и 4 столбца. Текущее время 3.711 мс
					   условие для JOIN: r.inventory_id = i.inventory_id
                          -> Сканирование таблицы "rental", 16005 строк и 6 столбцов. Текущее время 0.749 мс
                          -> hash таблица, 4581 строк и 6 столбцов. Текущее время 0.629 мс
                                -> Сканирование таблицы "inventory", 4581 строк и 6 столбцов. Текущее время 0.282 мс
                    -> hash таблица, 538 строк и 4 столбца. Текущее время 0.348 мс
                          -> Сканирование таблицы "film", 538 строк и 4 столбца. Текущее время 0.305 мс
						     Фильтр special_features @> '{"Behind the Scenes"}'::text[] удалил 462 строки
              -> hash таблица, 599 строк и 17 столбцов. Текущее время 0.122 мс
                    -> Сканирование таблицы "customer", 599 строк и 17 столбцов. Текущее время 0.055 мс
Время на планирование: 0.508 мс
Время на выполнение: 8.003 мс

--TASK №2
--Using window function print for each employee
--details of the employee's very first sale.

SELECT employee, q.rental_id, q.amount, q.payment_date, q.customer_id
FROM (
         SELECT s.staff_id, s.first_name || ' ' || s.last_name as employee, s.store_id,
                p.amount, p.customer_id, p.payment_date, p.rental_id,
                min(p.payment_date) over (partition by s.staff_id) as first_sale
         FROM staff s
         left join payment p on s.staff_id = p.staff_id 
     ) q
WHERE q.payment_date = first_sale

--TASK №3
--For each store, define and display the following analytical indicators in one SQL query:
-- 1. the day on which the most films were rented (day in year-month-day format)
-- 2. number of films rented that day
-- 3. the day on which the films for the smallest amount were sold (day in the format year-month-day)
-- 4. the amount of the sale on that day

with count_films as
(select s.store_id,
        r.rental_date::date as "day",
        COUNT(r.rental_id) as max_rented,
        SUM(p.amount) as sum_amount,
        MAX(COUNT(r.rental_id)) over (partition by s.store_id) as max_max_rented,
        MIN(SUM(p.amount)) over (partition by s.store_id) as min_min_films
from store s
left join customer c  on s.store_id = c.store_id 
left join rental r    on c.customer_id = r.customer_id 
left join payment p   on r.rental_id = p.rental_id 
left join inventory i on r.inventory_id = i.inventory_id 
left join film f      on i.film_id = f.film_id 
group by s.store_id, "day") 
select cf1.store_id, cf1."day" day_max_films, cf1.max_rented max_films, 
       cf2."day" day_min_profit, cf2.sum_amount min_profit
from count_films as cf1
left join count_films as cf2 on cf1.store_id = cf2.store_id
where cf1.max_rented = cf1.max_max_rented and cf2.sum_amount = cf2.min_min_films


