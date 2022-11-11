--=========== MODULE 2. Working with databases ===================================
--= REMEMBER TO SET THE CORRECT CONNECTION AND SELECT THE PUBLIC SCHEME===========
SET search_path TO public;

--======== MAIN PART ==============

--TASK №1
--Output unique city names from the table 'city'.

select distinct city from city

--TASK №2
--Modify the query from the previous task so that the query only outputs cities,
--whose names start with “L” and end with “a”, and the names do not contain spaces.

select distinct city 
from city 
where city like 'L%a' and not city like '% %'

--TASK №3
--Display from the table 'payment' the payments information that were made
--between June 17, 2005 and June 19, 2005 inclusively, 
--and the amount of which exceeds 1.00.
--Payments should be sorted by payment date.

select * from payment
where payment_date::date between '17-06-2005' and '19-06-2005' and amount > 1.0
order by payment_date

--TASK №4
--Display information about the last 10 payments for movie rentals.

select * from payment 
order by payment_date desc
fetch first 10 rows only

--TASK №5
--Display the following customer information:
--  1. Last name and first name (in one column separated by a space)
--  2. Email
--  3. The length of the email field value
--  4. The date the customer record was last updated (no time)
--Give each column a name in Russian.

select concat_ws(' ', last_name, first_name) "Фамилия Имя",
       email "Электронная почта",
       length(email) "Длина поля email",
       date(last_update) "Дата последнего обновления"
from customer

--TASK №6
--Display in one query only active buyers whose names are KELLY or WILLIE.
--All letters in the last name and first name must be converted from upper case to lower case.

select lower(last_name), lower(first_name), activebool
from customer
where activebool and first_name in ('KELLY', 'WILLIE')

--========ADDITIONAL PART ==============

--TASK №1
--Display in one query information about movies that have an "R" rating 
--and the rental price is from 0.00 to 3.00 inclusive,
--and films rated "PG-13" and rental value greater than or equal to 4.00.

select * from film
where (rating = 'R' and rental_rate >= 0.0 and rental_rate <= 3.0) or 
      (rating = 'PG-13' and rental_rate >= 4.0)

--TASK №2
--Get information about the three movies with the longest movie description.

select * from film
order by length(description) desc
limit 3

--TASK №3
--Display each customer's Email, dividing the Email value into 2 separate columns:
--the first column must have the value before the @,
--the second column should have the value after the @.

select customer_id, email, 
       split_part(email, '@', 1) "email before @", 
       split_part(email, '@', 2) "email after @"
from customer

--TASK №4
--Rewrite the query from the previous task, correct the values ​​in the new columns:
--the first letter must be uppercase, the others lowercase.

select customer_id, email, 
       concat(upper(left(split_part(email, '@', 1) ,1)),lower(substr(split_part(email, '@', 1),2))) "email before @", 
       concat(upper(left(split_part(email, '@', 2) ,1)),lower(substr(split_part(email, '@', 2),2))) "email after @"
from customer

select customer_id, email, 
       overlay(upper(split_part(email, '@', 1)) placing lower(split_part(email, '@', 1)) from 2) "email before @",
       overlay(upper(split_part(email, '@', 2)) placing lower(split_part(email, '@', 2)) from 2) "email after @"
from customer

