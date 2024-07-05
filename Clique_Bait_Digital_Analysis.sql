USE clique_bait;

-- Total Number of Users
SELECT COUNT(DISTINCT(user_id)) AS total_users
FROM users;

-- Number of cookies per user on average
SELECT ROUND(SUM(total_cookies)/COUNT(users),1) AS average_cookies
FROM (SELECT user_id AS users, 
				COUNT(DISTINCT(cookie_id)) AS total_cookies
		FROM users
		GROUP BY user_id
) AS Agg_table;

-- Unique number of visits by all Users per month
SELECT MONTH(event_time) AS Month_Number, 
		MONTHNAME(event_time) AS Months, 
		COUNT(DISTINCT(visit_id)) AS Visits
FROM events
GROUP BY MONTH(event_time), 
			MONTHNAME(event_time)
ORDER BY MONTH(event_time);

-- Number of events for each event type
SELECT e.event_type,
		ei.event_name, 
		COUNT(*) AS events
FROM events e
JOIN event_identifier ei
	ON ei.event_type = e.event_type 
GROUP BY e.event_type, ei.event_name;

-- Percentage of visits with a purchase event
SELECT ROUND(COUNT(distinct visit_id)*100.0/(SELECT COUNT(distinct visit_id) from events e ) ,2) AS purchase_prcnt
FROM events e 
JOIN event_identifier ei
		ON e.event_type = ei.event_type
WHERE event_name = 'Purchase';
   
-- Percentage of visits which view the checkout but do not have a purchase event
WITH prct_visits AS (
   SELECT DISTINCT(visit_id),
   SUM(CASE WHEN event_name!='Purchase'AND page_id=12 THEN 1 ELSE 0 END) AS checkouts,
   SUM(CASE WHEN event_name='Purchase' THEN 1 ELSE 0 END) AS purchases
   FROM events e 
		JOIN event_identifier ei
			ON e.event_type=ei.event_type
   GROUP BY visit_id
   )
   SELECT SUM(checkouts) as total_checkouts,
			SUM(purchases) as total_purchases,
			100-ROUND(SUM(purchases)*100.0/SUM(checkouts),2) as prcnt
   FROM prct_visits;

-- Top 3 pages by number of views
SELECT ph.page_name, 
		COUNT(visit_id) AS visits
FROM page_hierarchy ph
JOIN events e 
		ON e.page_id = ph.page_id
GROUP BY ph.page_name
ORDER BY visits DESC 
LIMIT 3;

-- Number of views and cart adds for each product category
SELECT ph.product_category,
		COUNT(CASE WHEN e.event_type = 1 THEN 1 END) AS views, 
		COUNT(CASE WHEN e.event_type = 2 THEN 2 END) AS cart_adds
FROM page_hierarchy ph
JOIN events e 
		ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT null
GROUP BY ph.product_category
;

-- Top 3 products by purchases
SELECT ph.page_name, 
		COUNT(CASE WHEN e.event_type = 2 AND visit_id IN (SELECT DISTINCT visit_id AS purchase_id 
															FROM events 
                                                            WHERE event_type = 3 ) 
					THEN 1 END) AS purchases
FROM page_hierarchy ph
JOIN events e 
		ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT null
GROUP BY ph.page_name
ORDER BY purchases DESC
LIMIT 3;



