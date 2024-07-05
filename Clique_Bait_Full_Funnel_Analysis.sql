USE clique_bait;

-- Funnel Analysis
-- Output table for product
DROP TABLE IF EXISTS product_tab;

CREATE TABLE IF NOT EXISTS product_tab (
    page_name VARCHAR(50),
    page_views INT,
    cart_adds INT,
    cart_add_not_purchased INT,
    purchased INT
);

INSERT INTO product_tab (page_name, page_views, cart_adds, cart_add_not_purchased, purchased)
WITH product_CTE AS (
	SELECT DISTINCT(ph.page_name), 
			COUNT(CASE WHEN e.event_type = 1 THEN 1 END) AS page_views,
			COUNT(CASE WHEN e.event_type = 2 THEN 2 END) AS cart_adds,
			COUNT(CASE WHEN e.event_type = 2 AND visit_id NOT IN (SELECT DISTINCT visit_id AS purchase_id 
																	FROM events 
                                                                    WHERE event_type = 3 
																	AND visit_id IS NOT NULL) 
						THEN 1 END) AS cart_add_not_purchased,
			COUNT(CASE WHEN e.event_type = 2 AND visit_id IN (SELECT DISTINCT visit_id AS purchase_id 
																FROM events 
                                                                WHERE event_type = 3 
                                                                AND visit_id IS NOT NULL) 
						THEN 1 END) AS purchased
	FROM events e
	JOIN page_hierarchy ph
			ON e.page_id = ph.page_id
	JOIN event_identifier ei 
			ON e.event_type = ei.event_type 
	WHERE product_category IS NOT null
	GROUP BY ph.page_name
)
SELECT page_name, page_views, cart_adds, cart_add_not_purchased, purchased
FROM product_CTE;

SELECT * FROM product_tab;


-- Output table for product category
DROP TABLE IF EXISTS product_category_tab;

CREATE TABLE IF NOT EXISTS product_category_tab (
    product_category VARCHAR(50),
    page_views INT,
    cart_adds INT,
    cart_add_not_purchased INT,
    purchased INT
);

INSERT INTO product_category_tab (product_category, page_views, cart_adds, cart_add_not_purchased, purchased)
WITH product_category_CTE AS (
	SELECT DISTINCT(ph.product_category), 
			COUNT(CASE WHEN e.event_type = 1 THEN 1 END) AS page_views,
			COUNT(CASE WHEN e.event_type = 2 THEN 2 END) AS cart_adds,
			COUNT(CASE WHEN e.event_type = 2 AND visit_id NOT IN (SELECT DISTINCT visit_id AS purchase_id 
																	FROM events 
                                                                    WHERE event_type = 3 
                                                                    AND visit_id IS NOT NULL) 
						THEN 1 END) AS cart_add_not_purchased,
			COUNT(CASE WHEN e.event_type = 2 AND visit_id IN (SELECT DISTINCT visit_id AS purchase_id 
																FROM events 
                                                                WHERE event_type = 3 
                                                                AND visit_id IS NOT NULL) 
						THEN 1 END) AS purchased
	FROM events e
	JOIN page_hierarchy ph
			ON e.page_id = ph.page_id
	WHERE product_category IS NOT null
	GROUP BY ph.product_category
)
SELECT product_category, page_views, cart_adds, cart_add_not_purchased, purchased
FROM product_category_CTE;

SELECT * FROM product_category_tab;


-- Product with the most views, cart adds and purchases
SELECT page_name AS most_viewed
FROM product_tab
ORDER BY page_views DESC
LIMIT 1;

SELECT page_name AS most_cart_adds
FROM product_tab
ORDER BY cart_adds DESC
LIMIT 1;

SELECT page_name AS most_purchases
FROM product_tab
ORDER BY purchased DESC
LIMIT 1;


-- Product most likely to be abandoned
SELECT page_name AS most_abandoned
FROM product_tab
ORDER BY cart_add_not_purchased DESC
LIMIT 1;


-- Product with the highest view to purchase percentage
SELECT page_name AS product, 
		ROUND(purchased/page_views * 100,2) AS view_purchase_prcnt
FROM product_tab
ORDER BY view_purchase_prcnt DESC;


-- Average conversion rate from views to cart_adds
SELECT ROUND(AVG(cart_adds/page_views * 100),2) AS avg_conv_rate_views_to_cart
FROM product_tab;


-- Average conversion rate from cart_adds to purchases
SELECT ROUND(AVG(purchased/cart_adds * 100),2) AS avg_conv_rate_cart_to_purchase
FROM product_tab;