--=============== MODULE 3. SQL FUNDAMENTALS =======================================
--== REMEMBER TO SET THE CORRECT CONNECTION AND SELECT THE PUBLIC SCHEME ===========
SET search_path TO public;

--======== MAIN PART ==============

--TASK №1
--Output for each buyer his address of residence,
--city ​​and country of residence.

select c.first_name, c.last_name, a.address, c2.city, c3.country 
from customer c 
left join address a using (address_id)
left join city c2 using (city_id)
left join country c3 using (country_id)

--TASK №2
--Count the number of customers for each store using an SQL query.

select store_id, COUNT(c.customer_id) as number_buyers
from store 
left join customer c using (store_id)
group by store_id

--Modify the query and display only stores with more than 300 buyers.
--Hint: use filtering by grouped rows using the aggregation function.

select store_id, COUNT(c.customer_id) as number_buyers_more300
from store 
left join customer c using (store_id)
group by store_id
having COUNT(c.customer_id) > 300

-- Modify the query by adding information about the city of the store,
-- the surname and name of the seller who works in this store.

WITH COUNT_BUYERS AS (select store_id, COUNT(c.customer_id) as number_buyers_more300
                  from store 
                  left join customer c using (store_id)
                  group by store_id
                  having COUNT(c.customer_id) > 300)
SELECT st.store_id, COUNT_BUYERS.number_buyers_more300, c.city, s.last_name, s.first_name
from store st
inner join COUNT_BUYERS 
          on st.store_id = COUNT_BUYERS.store_id
left join address a
          on st.address_id = a.address_id
left join staff s
          on st.store_id = s.store_id
left join city c
          on a.city_id = c.city_id

--TASK №3
--Display TOP-5 buyers,
--who rented the most films of all time

with top as (select customer_id, count(rental_id) as n_rents
              from rental
              group by customer_id)
select c.last_name, c.first_name, top.n_rents
from customer c
inner join top using (customer_id)
order by top.n_rents desc
limit 5

--TASK №4
--Count for each customer:
-- 1. the number of films he has rented
-- 2. total cost of rental payments for all films (round to the nearest integer)
-- 3. the minimum film rental payment
-- 4. the maximum film rental payment

with top as (select r.customer_id, 
                    count(r.rental_id) as n_rents,
                    sum(p.amount)::int4 as total_cost,
                    min(p.amount) as min_cost,
                    max(p.amount) as max_cost
             from rental r
             left join payment p on r.rental_id = p.rental_id 
             group by r.customer_id)
select c.last_name, 
       c.first_name, 
       top.n_rents number_of_films,
       top.total_cost,
       top.min_cost,
       top.max_cost
from customer c
inner join top using (customer_id)

--TASK №5
--Using the data from the 'city' table, make all possible pairs of cities in one query,
--should be no pairs with the same city names.
--Hint: use the Cartesian product.
 
select c1.city city_1,
       c2.city city_2
from city c1
cross join city c2
where c1.city <> c2.city 

--TASK №6
--Calculate for each customer the average number of days it takes for a customer to return films
--using from the 'rental' table the date the movie was rented out (field rental_date),
--and the return date of the movie (field return_date)

with count_days as (select round(avg(return_date::date - rental_date::date), 2) as mean_days,
                           customer_id 
                    from rental 
                    group by customer_id)
select c.last_name, c.first_name, count_days.mean_days
from customer c 
inner join count_days using (customer_id)

--======== ADDITIONAL PART ==============

--TASK №1
--Display for each movie how many times it was rented and the value of the total cost of renting a movie for all time.

with info_movie as (select f.film_id film_id2,
                           count(p.payment_id) times_rented,
                           sum(COALESCE(p.amount, 0)) total_cost
                    from film f
                    full outer join inventory i on f.film_id = i.film_id 
                    full outer join rental r on r.inventory_id = i.inventory_id 
                    full outer join payment p on r.rental_id = p.rental_id 
                    group by f.film_id)
select f.title, info_movie.times_rented, info_movie.total_cost 
from film f 
full outer join info_movie on f.film_id = info_movie.film_id2

--TASK №2
--Modify the previous query to display films that have never been rented.

with info_movie as (select f.film_id film_id2,
                           count(p.payment_id) times_rented,
                           sum(COALESCE(p.amount, 0)) total_cost
                    from film f
                    full outer join inventory i on f.film_id = i.film_id 
                    full outer join rental r on r.inventory_id = i.inventory_id 
                    full outer join payment p on r.rental_id = p.rental_id 
                    group by f.film_id)
select f.title, info_movie.times_rented, info_movie.total_cost 
from film f 
full outer join info_movie on f.film_id = info_movie.film_id2
where info_movie.times_rented = 0
order by f.title

--TASK №3
--Count the number of sales made by each salesperson. Add a "Bonus" calculated column.
--If the number of sales exceeds 7300, then the value in the column will be "Yes", otherwise it should be "No".

select s.last_name,
       s.first_name,
       count(p.payment_id),
       CASE
           WHEN count(p.payment_id) > 7300 THEN 'Yes'
           ELSE 'No'
       end as bonus
from staff s
full outer join payment p on s.staff_id = p.staff_id 
group by s.staff_id -- 8057 + 7992 = 16049

select s.last_name,
       s.first_name,
       count(p.payment_id),
       CASE
           WHEN count(p.payment_id) > 7300 THEN 'Yes'
           ELSE 'No'
       end as bonus
from staff s
left join rental r on s.staff_id = r.staff_id 
left join payment p on r.rental_id = p.rental_id 
group by s.staff_id -- 8044 + 8005 = 16049

select * from payment -- 16049

select * from rental where staff_id = 1 --= 8040

select * from payment where staff_id = 1 --= 8057
