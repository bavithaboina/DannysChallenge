--DANNY'S DINNER
CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
 

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
 
 
-- 1.What is the total amount each customer spent at the restaurant?

USE dannys_diner;
SELECT
    customer_id,
    sum(price) as total_amount
FROM sales s
JOIN menu
    ON s.product_id=menu.product_id
GROUP BY customer_id
order by customer_id;

/* 
OUTPUT:
---------------------------------------------------------------
customer_id | total_amount
---------------------------------------------------------------
A           |   76
B           |   74
C           |   36
---------------------------------------------------------------
*/

--2. How many days has each customer visited the restaurant?

USE dannys_diner;
SELECT
    customer_id,
    COUNT(DISTINCT order_date) as number_of_days_customer_visited
FROM sales s
JOIN menu
    ON s.product_id=menu.product_id
GROUP BY customer_id
order by customer_id;

/* 
OUTPUT:
------------------------------------------------------------------
customer_id | number_of_days_customer_visited
------------------------------------------------------------------
A           |    4
B           |    6
C           |    2
-------------------------------------------------------------------
*/

--3 What was the first item from the menu purchased by each customer?

USE dannys_diner;
SELECT
customer_id,
    FIRST_VALUE(product_name) OVER(PARTITION BY customer_id ORDER BY order_date) first_item_purchased
FROM sales s
JOIN menu
    ON s.product_id=menu.product_id
GROUP BY customer_id;

/* 
OUTPUT:
-------------------------------------------------------------------------------------------------------
customer_id | first_item_purchased
-------------------------------------------------------------------------------------------------------
A           | sushi
B           | curry
C           | ramen
-------------------------------------------------------------------------------------------------------
*/

--4 What is the most purchased item on the menu and how many times was it purchased by all customers?

USE dannys_diner;
SELECT
    product_name,
    s.product_id,
    COUNT(*)  no_of_times_purchased
FROM sales s
JOIN menu
    ON s.product_id=menu.product_id
GROUP BY product_id
ORDER BY no_of_times_purchased DESC
LIMIT 1;

/* 
OUTPUT:
------------------------------------------------------------------------------------------------------
product_name | product_id | no_of_times_purchased
------------------------------------------------------------------------------------------------------
ramen        |  3         |   8
------------------------------------------------------------------------------------------------------
*/



--5 Which item was the most popular for each customer?

-- Here dense_rank is used for finding out the most popular for each customer

USE dannys_diner;
WITH cte1 AS(
    SELECT
        customer_id,
        product_name,
        s.product_id,
        count(*) no_of_times_purchased,
        dense_rank() over(partition by customer_id order by count(*) desc) rnk
    FROM sales s
    JOIN menu
        ON s.product_id=menu.product_id
    GROUP BY customer_id,product_id)
SELECT
    customer_id,
    group_concat(product_name order by product_name separator ', ' ) as popular_product_for_customer  
FROM cte1
WHERE rnk=1
GROUP BY customer_id
order by customer_id,rnk asc;

/* 
OUTPUT:
------------------------------------------------------------------------------
customer_id | popular_product_for_customer
------------------------------------------------------------------------------
A           |   ramen
B           |   curry, ramen, sushi
C           |   ramen
------------------------------------------------------------------------------
*/


--6 Which item was purchased first by the customer after they became a member?
USE dannys_diner;
WITH cte1 AS(
    SELECT
        s.* ,
        members.join_date,
        menu.product_name,
        menu.price,
        dense_rank() over(partition by customer_id order by order_date) as rnk
    FROM sales s
    LEFT JOIN members
        ON s.customer_id=members.customer_id
    JOIN menu
        ON s.product_id=menu.product_id
    WHERE order_date>=join_date)
SELECT
    customer_id,
    product_name as first_purchased_after_becoming_member
FROM cte1
WHERE rnk=1

/* OUTPUT
------------------------------------------------------------------------------
customer_id | first_purchased_after_becoming_member
------------------------------------------------------------------------------
A           |    curry
B           |    sushi
-------------------------------------------------------------------------------

*/


--7 Which item was purchased just before the customer became a member?
USE dannys_diner;
WITH cte1 AS(
    SELECT
        s.* ,
        members.join_date,
        menu.product_name,
        menu.price,
        dense_rank() over(partition by customer_id order by order_date DESC) as rnk
    FROM sales s
    JOIN members
        ON s.customer_id=members.customer_id
    JOIN menu
        ON s.product_id=menu.product_id
    WHERE order_date<join_date)
SELECT
    customer_id,
    group_concat(product_name ORDER BY product_name SEPARATOR ',') as purchased_before_becoming_member
FROM cte1
WHERE  rnk=1
GROUP BY customer_id

/*
OUTPUT : 
------------------------------------------------------------------------------
customer_id | purchased_before_becoming_member
------------------------------------------------------------------------------
A           |   curry,sushi
B           |   sushi
------------------------------------------------------------------------------
*/



--8 What is the total items and amount spent for each member before they became a member?

USE dannys_diner;
SELECT 
    s.customer_id,
    sum(price) as amount_spent_before_becoming_member
FROM sales s
JOIN members
    ON s.customer_id=members.customer_id
JOIN menu
    ON s.product_id=menu.product_id
WHERE order_date<join_date
GROUP BY customer_id
order by customer_id;

/*
------------------------------------------------------------------------------
customer_id | amount_spent_before_becoming_member
------------------------------------------------------------------------------
A           |   25
B           |   40
-----------------------------------------------------------------------------
*/


--9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier -
--how many points would each customer have?

USE dannys_diner;
SELECT
    customer_id,
    SUM(CASE WHEN product_name='SUSHI' THEN 20*price ELSE 10*price END) AS points
FROM sales s
JOIN menu
    ON s.product_id=menu.product_id
GROUP BY customer_id

/* 
OUTPUT:
------------------------------------------------------------------------------
customer_id | total_points
------------------------------------------------------------------------------
A           |   860
B           |   940
C           |   360
--------------------------------------------------------------------------------
*/

--10 In the first week after a customer joins the program (including their join date)
--they earn 2x points on all items, not just sushi -
--how many points do customer A and B have at the end of January?

USE dannys_diner;
SELECT
    s.customer_id,
    SUM(CASE WHEN order_date BETWEEN join_date and DATE_ADD(join_date,INTERVAL 6 DAY) THEN 20*price
             WHEN  product_name='SUSHI' THEN 20*price
             ELSE 10*price
        END) as points
FROM sales s
LEFT JOIN members
    ON s.customer_id=members.customer_id
JOIN menu
    ON s.product_id=menu.product_id
WHERE order_date<=DATE("2021-01-31")
GROUP BY customer_id
ORDER BY customer_id

/* 
OUTPUT:
------------------------------------------------------------------------------
customer_id | points
------------------------------------------------------------------------------
A           |   1370
B           |   820
C           |   360
------------------------------------------------------------------------------
*/

--Bonus Questions

--1.creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

--Recreate the following table output using the available data:

/*
----------------------------------------------------------------------------------
customer_id | order_date | product_name | price | member
----------------------------------------------------------------------------------
A           | 2021-01-01 | curry        |   15  | N
A           | 2021-01-01 | sushi        |   10  | N
A           | 2021-01-07 | curry        |   15  | Y
A           | 2021-01-10 | ramen        |   12  | Y
A           | 2021-01-11 | ramen        |   12  | Y
A           | 2021-01-11 | ramen        |   12  | Y
------------------------------------------------------------------------------------
*/

USE dannys_diner;
SELECT
    s.customer_id,
    s.order_date ,
    menu.product_name,
    menu.price,
    CASE WHEN s.order_date>=members.join_date THEN 'Y' ELSE 'N' END as member
FROM sales s
LEFT JOIN members
    ON s.customer_id=members.customer_id
JOIN menu
    ON s.product_id=menu.product_id

/* OUTPUT
----------------------------------------------------------------------------------------------------
customer_id order_date product_name price member
----------------------------------------------------------------------------------------------------
A 2021-01-01 sushi 10 N
A 2021-01-01 curry 15 N
A 2021-01-07 curry 15 Y
A 2021-01-10 ramen 12 Y
A 2021-01-11 ramen 12 Y
A 2021-01-11 ramen 12 Y
B 2021-01-01 curry 15 N
B 2021-01-02 curry 15 N
B 2021-01-04 sushi 10 N
B 2021-01-11 sushi 10 Y
B 2021-01-16 ramen 12 Y
B 2021-02-01 ramen 12 Y
C 2021-01-01 ramen 12 N
C 2021-01-01 ramen 12 N
C 2021-01-07 ramen 12 N
------------------------------------------------------------------------------------------------------
*/


--2. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

/*
-----------------------------------------------------------------------------------------------
customer_id order_date product_name price member ranking
-----------------------------------------------------------------------------------------------
A 2021-01-01 curry 15 N null
A 2021-01-01 sushi 10 N null
A 2021-01-07 curry 15 Y 1
A 2021-01-10 ramen 12 Y 2
A 2021-01-11 ramen 12 Y 3
A 2021-01-11 ramen 12 Y 3
------------------------------------------------------------------------------------------------
*/


USE dannys_diner;
WITH cte as (
    SELECT 
        s.* ,
        members.join_date,
        menu.product_name,
        menu.price,
        CASE WHEN s.order_date>=members.join_date THEN 'Y' ELSE 'N' END as member
    FROM sales s
    LEFT JOIN members
        ON s.customer_id=members.customer_id
    JOIN menu
        ON s.product_id=menu.product_id)
SELECT
    customer_id,
    order_date ,
    product_name,
    price,
    member,
    RANK()  over(PARTITION BY customer_id ORDER BY order_date ) as rnk
FROM cte
WHERE order_date>=join_date
UNION ALL
SELECT 
    customer_id,
    order_date ,
    product_name,
    price,
    member,
NULL AS rnk
FROM cte
WHERE order_date<join_date OR join_date is null
ORDER BY customer_id,order_date;

/*
OUTPUT:
----------------------------------------------------------------------------------------------------
customer_id order_date product_name price member rnk
----------------------------------------------------------------------------------------------------
A 2021-01-01 sushi 10 N
A 2021-01-01 curry 15 N
A 2021-01-07 curry 15 Y 1
A 2021-01-10 ramen 12 Y 2
A 2021-01-11 ramen 12 Y 3
A 2021-01-11 ramen 12 Y 3
B 2021-01-01 curry 15 N
B 2021-01-02 curry 15 N
B 2021-01-04 sushi 10 N
B 2021-01-11 sushi 10 Y 1
B 2021-01-16 ramen 12 Y 2
B 2021-02-01 ramen 12 Y 3
C 2021-01-01 ramen 12 N
C 2021-01-01 ramen 12 N
C 2021-01-07 ramen 12 N
*/