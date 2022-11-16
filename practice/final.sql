SET search_path TO bookings;

--TASK 1 Which planes have more than 50 landing places?

select a.aircraft_code, a.model, count(s.seat_no) number_seats
from aircrafts a 
join seats s on a.aircraft_code = s.aircraft_code
group by a.aircraft_code 
having count(s.seat_no) > 50
order by count(s.seat_no) desc

--TASK 2 Which airports have flights where business class is cheaper than economy class?
--HINT: use CTE

with cte as (select flight_id, fare_conditions, 
                    case when fare_conditions = 'Economy' then MAX(amount) else MIN(amount) end class_amount
             from ticket_flights
             group by flight_id, fare_conditions)
select f.departure_airport, array_agg(cte1.flight_id) as flights--, cte1.class_amount economy_amount, cte2.class_amount business_amount
from cte cte1
join cte cte2 on cte1.flight_id = cte2.flight_id and cte1.fare_conditions = 'Economy'
                                                 and cte2.fare_conditions = 'Business'
join flights f on cte1.flight_id = f.flight_id
where cte1.class_amount > cte2.class_amount
group by f.departure_airport
                                                 
--TASK 3 Do planes exist without business-class?
--HINT: use array_agg

select array_agg(a.model)
from (select aircraft_code,
             COUNT(CASE WHEN fare_conditions = 'Economy'  THEN seat_no ELSE Null END) economy_seats,
             COUNT(CASE WHEN fare_conditions = 'Business' THEN seat_no ELSE Null END) business_seats
      from seats
      group by aircraft_code) s
join aircrafts a on s.aircraft_code = a.aircraft_code 
where business_seats = 0

--TASK 4 Find the number of occupied seats for each flight, 
--            percentage of the number occupied seats to the total number of seats in airplane, 
--            add a cumulative total passengers taken out at each airport on every day.
--HINT: use window function, subquery

select f.flight_id, f.flight_no, 
       os.seats_occupied, 
       round(os.seats_occupied::numeric / fc.seats_all * 100., 2) || '%' percent_occupied,
       f.departure_airport,
       sum(os.seats_occupied) over (partition by f.departure_airport, f.actual_departure::date order by f.actual_departure) total_passengers
from flights f 
join (select bp.flight_id, count(distinct bp.seat_no) seats_occupied
      from boarding_passes bp 
      group by flight_id) os on f.flight_id = os.flight_id
join (select s.aircraft_code, count(distinct s.seat_no) seats_all
      from seats s 
      group by s.aircraft_code) fc on f.aircraft_code = fc.aircraft_code
      
--TASK 5 Find the percentage of flights by routes from the total number of flights.
--       Output the names of the airports in the result and percentage.
--HINT: use Window function, ROUND operator
   
select a1.airport_name arrival_to, a2.airport_name departure_from, q.percent_of_flights
from (select distinct(f.departure_airport, f.arrival_airport) as route, 
             f.departure_airport,
             f.arrival_airport,
             round((count(f.flight_id) OVER (PARTITION BY f.departure_airport, f.arrival_airport))::numeric / count(f.flight_id) over (), 5) as percent_of_flights
             from flights f
             where f.departure_airport < f.arrival_airport) q 
join airports a1 on q.arrival_airport = a1.airport_code
join airports a2 on q.departure_airport = a2.airport_code 

--TASK 6 Print the number of passengers for each mobile operator code, given that the code
--       operator is three characters after +7
      
select SUBSTRING(contact_data->>'phone', 3, 3) mobile_code, count(passenger_id) as number_passengers
from tickets
where contact_data ? 'phone'
group by mobile_code
order by mobile_code
      
--TASK 7 Between which cities does not exist flights?
--HINT: use Cartesian product, EXCEPT statement

select a1.city, a2.city--, a1.airport_code, a1.airport_name, a2.airport_code, a2.airport_name
from airports a1 
cross join airports a2
where a1.airport_code <> a2.airport_code 
except
select departure_city, arrival_city--, departure_airport, departure_airport_name, arrival_airport, arrival_airport_name
from bookings.flights_v
except
select arrival_city, departure_city--, departure_airport, departure_airport_name, arrival_airport, arrival_airport_name
from bookings.flights_v

--TASK 8 Classify financial turnover (sum ticket prices) on routes:
--       low:    Up to 50 million
--       middle: From 50 million inclusive to 150 million
--       high:   From 150 million inclusive
--       Output the number of routes in each class.
--HINT: use CASE

select financial_turnover, count(sum_amount) as number_of_routes
from
(select f.departure_airport, f.arrival_airport, sum(amount) sum_amount,
       case when sum(tf.amount) < 50000000 then 'low'
            when sum(tf.amount) >= 50000000 and sum(tf.amount) < 150000000 then 'middle'
            else 'high' end as financial_turnover
from ticket_flights tf
join flights f on tf.flight_id = f.flight_id
group by f.departure_airport, f.arrival_airport
having f.departure_airport < f.arrival_airport) q
group by financial_turnover

--TASK 9 Output pairs of cities between which distance over 5000 km
--HINT: use RADIANS operator or sind/cosd

select *
from(select a1.airport_code, a1.airport_name, a2.airport_code, a2.airport_name,
            round(6371 * acos(sind(a1.latitude)*sind(a2.latitude)+ cosd(a1.latitude)*cosd(a2.latitude)*cosd(a1.longitude - a2.longitude))) distance_km
     from airports a1
     cross join airports a2
     where a1.airport_code < a2.airport_code) q
where q.distance_km > 5000