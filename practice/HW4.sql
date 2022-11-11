--=============== MODULE 4. GO DEEPER IN SQL =======================================

--======== MAIN PART ==============

--TASK №1
--Design a database containing three dictionaries:
--  language (English, French, etc.);
--  nationality (Slavs, Anglo-Saxons, etc.);
--  countries (Russia, Germany, etc.).
--Two tables with relationships: language-nationality and nationality-country, many-to-many relationships. An example of a table with relationships is film_actor.
--Requirements for reference tables:
--  the primary key constraints.
--  entity identifier must be assigned by autoincrement;
--  entity names should not contain null values, duplicates in entity names should not be allowed.
--Requirements for tables with links:
--  the constraints on primary and foreign keys.

--CREATE THE TABLE languages

CREATE TABLE languages (
  language_id     serial PRIMARY KEY,
  "language"      varchar(30) UNIQUE NOT NULL,
  year_created    int
);

--INPUT DATA INTO THE TABLE languages

INSERT INTO languages("language", year_created) 
VALUES 
	   ('Russian',   500),
	   ('English',   450),
	   ('French' , -1000),
	   ('German' ,   700),
	   ('Chinese', -1400)

--CREATE THE TABLE nations

CREATE TABLE nations (
  nation_id       serial PRIMARY KEY,
  nation          varchar(30) UNIQUE NOT NULL
);

--INPUT DATA INTO THE TABLE nations

INSERT INTO nations(nation) 
VALUES 
	   ('Russians'),
	   ('Tatars'),
	   ('English'),
	   ('Scots'),
	   ('French'),
	   ('Algerian')

--CREATE THE TABLE countries

CREATE TABLE countries (
  country_id      serial PRIMARY KEY,
  country         varchar(30) UNIQUE NOT NULL,
  population      int,
  capital         varchar(30),
  "area"          float
)

--INPUT DATA INTO THE TABLE countries

INSERT INTO countries(country, population, capital, "area") 
VALUES 
	   ('Russia' ,  143000000, 'Moscow' , 17100000.),
	   ('England',   55900000, 'London' ,   130279.),
	   ('France' ,   67500000, 'Paris'  ,   543940.),
	   ('Germany',   83100000, 'Berlin' ,   357588.),
	   ('China'  , 1412000000, 'Beijing',  9597000.)
	   
--CREATING THE FIRST RELATIONSHIP TABLE

CREATE TABLE languages_nations (
  language_id     integer NOT NULL,
  nation_id       integer NOT NULL,
  CONSTRAINT languages_nations_pk PRIMARY KEY (language_id, nation_id),
  CONSTRAINT FK_language FOREIGN KEY (language_id) REFERENCES languages (language_id),
  CONSTRAINT FK_nation   FOREIGN KEY (nation_id)   REFERENCES nations (nation_id)
)

--INPUT DATA INTO THE TABLE languages_nations

insert into languages_nations(language_id, nation_id)
values
	   (1, 1),
	   (1, 2),
	   (2, 1),
	   (2, 3),
	   (2, 5),
	   (3, 5)

--CREATING THE SECOND RELATIONSHIP TABLE

CREATE TABLE nations_countries (
  nation_id       integer NOT NULL,
  country_id      integer NOT NULL,
  CONSTRAINT nations_countries_pk PRIMARY KEY (nation_id, country_id),
  CONSTRAINT FK_nation   FOREIGN KEY (nation_id)   REFERENCES nations (nation_id),
  CONSTRAINT FK_country  FOREIGN KEY (country_id)  REFERENCES countries (country_id)
 )
 
--INPUT DATA INTO THE TABLE nations_countries

insert into nations_countries(nation_id, country_id)
values
	   (1,1),
	   (2,1),
	   (3,2),
	   (4,2),
	   (5,2),
	   (5,3),
	   (6,3)
	   
--======== ADDITIONAL PART ==============

--TASK №1 
--Create a new table film_new with the following fields:
--  film_name        - film name                - data type varchar(255) and constraint not null
--  film_year        - film release year        - integer data type, condition that the value must be greater than 0
--  film_rental_rate - film rental cost         - data type numeric(4,2), default value 0.99
--  film_duration    - film duration in minutes - integer data type, not null constraint and condition that the value must be greater than 0

CREATE TABLE film_new (
  film_name        varchar(255) not null,
  film_year        integer CHECK (film_year > 0),
  film_rental_rate numeric(4,2) DEFAULT(0.99),
  film_duration    integer not null check (film_duration > 0)
 )

--TASK №2 
--Fill the film_new table using an SQL query with this data:
--  film_name        - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--  film_year        - array[1994, 1999, 1985, 1994, 1993]
--  film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--  film_duration    - array[142, 189, 116, 142, 195]

insert into film_new
select unnest(array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']), 
       unnest(array[1994, 1999, 1985, 1994, 1993]),
       unnest(array[2.99, 0.99, 1.99, 2.99, 3.99]),
       unnest(array[142, 189, 116, 142, 195])

--TASK №3
--Update the film_rental_rate in the film_new table:
--cost of film_rental_rate has risen by 1.41

update film_new
set film_rental_rate = film_rental_rate + 1.41

--TASK №4
--The film called "Back to the Future" was taken out of the lease,
--delete the row with this movie from the film_new table

DELETE FROM film_new
WHERE film_name = 'Back to the Future'

--TASK №5
--Add an entry to the film_new table

insert into film_new(film_name, film_year, film_rental_rate, film_duration)
values ('The Matrix', 1999, 3.00, 136)

--TASK №6
--Write a SQL query that will display all columns from the film_new table,
--and a new calculated column "movie duration in hours", rounded to tenths

select *, round(film_duration::decimal/60., 1) as "movie duration in hours"
from film_new

--TASK №7 
--Delete table film_new

drop table film_new