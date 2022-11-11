--=============== MODULE 5: WORKING WITH POSTGRESQL =======================================

--======== MAIN PART ==============

--TASK №1
--Create sql query to the payment table and use window functions to add calculated columns:
--  Number all payments from 1 to N by date
--  Number payments for each customer, payment sorting should be by date
--  Calculate the cumulative total of all payments for each customer, 
--    sorting should be first by payment date and then by payment amount from smallest to largest
--  Number the payments for each customer by value of payment from highest to lowest
--    so that payments with the same value have the same number value.

select customer_id, payment_id, payment_date, amount, 
       ROW_NUMBER() OVER (ORDER BY payment_date) as column_1,
       ROW_NUMBER() OVER (PARTITION BY customer_id order by payment_date) as column_2,
       coalesce(sum(amount) over (partition by customer_id order by payment_date 
                rows between unbounded preceding and current row), 
                0) as column_3,
       coalesce(sum(amount) over (partition by customer_id order by payment_date, amount), 
                0) as column_3_another,
       DENSE_RANK() OVER (PARTITION BY customer_id order by amount desc) as column_4
from payment
order by customer_id, column_4;

--TASK №2
--Use a window function to display for each customer the cost of payment 
--and the cost of payment from the previous row, with a default value of 0.0, sorted by date.

select customer_id, payment_id, payment_date,
       amount AS "current_amount", 
       LAG(amount, 1, 0.00) OVER (PARTITION BY customer_id order by payment_date) AS "last_amount"
from payment
order by customer_id, payment_date

--TASK №3
--Using a window function, determine how much each next customer payment is more or less than the current one.

select customer_id, payment_id, payment_date, 
       amount - LEAD(amount, 1) OVER (PARTITION BY customer_id order by payment_date) AS "diff_amount"
from payment
order by customer_id, payment_date

--TASK №4
--Use a window function for each customer to display their last rent payment.

SELECT customer_id, payment_id, last_payment, amount
FROM (
         SELECT customer_id,
                payment_id,
                payment_date,
                amount,
                MAX(payment_date) OVER (PARTITION BY customer_id) as last_payment
         FROM payment
     ) t
WHERE payment_date = last_payment
ORDER BY customer_id;

--======== ADDITIONAL PART ==============

--TASK №1
--Use a window function to display the total sales for each employee for August 2005
--with a running total for each employee and for each sale date (excluding time) sorted by date.

select t.staff_id, last_payment::date as "date", t.daily_sum, t.month_sum
from (
      select staff_id,
      payment_date,
      MAX(payment_date) over (partition by payment_date::date, staff_id) as last_payment,
      coalesce(sum(amount) over (partition by staff_id, payment_date::date order by (payment_date)
               rows between unbounded preceding and current row), 
               0) as daily_sum,
      coalesce(sum(amount) over (partition by staff_id order by (payment_date)
               rows between unbounded preceding and current row), 
               0) as month_sum
      from payment 
      where (payment_date::date - '2005_08_01') >=0 and 
            (payment_date::date - '2005_08_01') <31
     ) t
where payment_date = last_payment

--TASK №2
--On August 20, 2005, a promotion was held in stores: the buyer of every hundredth payment received
--additional discount on the next rental. Use window function to display all customers,
--who received a discount on the day of the promotion

select w.customer_id, w.payment_date, w.payment_number
from(
     select 
            customer_id,
            payment_date,
            ROW_NUMBER() OVER (ORDER BY payment_date) as payment_number
     from payment
     where payment.payment_date::date = '2005_08_20') w
where w.payment_number % 100 = 0


--TASK №3
--For each country, identify and output with a single SQL query:
-- 1. the buyer who rented the most films
-- 2. the buyer who rented films for the largest amount
-- 3. the buyer who last rented the film

with vsp as
(with customer_country as
(select c.first_name || ' ' || c.last_name as full_name,
        c3.country as country_new,
        c.customer_id as cust_id,
        COUNT(p.rental_id) as count_rental,
        SUM(p.amount) as amount_rental,
        MAX(p.payment_date) as last_payment
 from customer c 
 left join address a on a.address_id = c.address_id 
 left join city c2 on c2.city_id = a.city_id 
 left join country c3 on c3.country_id = c2.country_id
 left join payment p on p.customer_id = c.customer_id
 group by c3.country_id, c.customer_id)  
select 
       country_new,
       full_name,
       count_rental,
       max(count_rental) over (partition by country_new) as country_count_rental,
       amount_rental,
       max(amount_rental) over (partition by country_new) as country_amount_rental,
       last_payment,
       max(last_payment) over (partition by country_new) as country_last_payment
from customer_country
) 
select vsp1.country_new,
       vsp1.full_name,
       vsp2.full_name,
       vsp3.full_name
from vsp as vsp1
cross join vsp as vsp2
cross join vsp as vsp3
where vsp1.country_new   = vsp2.country_new and
      vsp1.country_new   = vsp3.country_new and
      vsp1.count_rental  = vsp1.country_count_rental and 
      vsp2.amount_rental = vsp2.country_amount_rental and 
      vsp3.last_payment  = vsp3.country_last_payment