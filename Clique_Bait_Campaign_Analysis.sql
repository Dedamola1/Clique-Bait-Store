USE clique_bait;

-- Campaign Analysis
-- Output table for campaign
DROP TABLE IF EXISTS campaign_tab;

CREATE TABLE IF NOT EXISTS campaign_tab (
user_id INT,
visit_id VARCHAR(20),
visit_start_time DATETIME(3),
page_views INT,
cart_adds INT,
purchases INT,
impressions INT, 
clicks INT, 
campaign VARCHAR(200),
cart_products VARCHAR(200)
);

INSERT INTO campaign_tab (user_id, visit_id, visit_start_time, page_views, cart_adds, purchases, impressions, clicks, campaign, cart_products)
WITH Campaign_CTE AS ( 
	SELECT DISTINCT visit_id, 
					user_id,
                    MIN(e.event_time) as visit_start_time,
					COUNT(e.page_id) AS page_views,
                    COUNT(CASE WHEN e.event_type = 2 THEN 1 END) AS cart_adds,
                    COUNT(CASE WHEN e.event_type = 3 THEN 1 END) AS purchases,
                    CASE WHEN MIN(e.event_time) > '2020-01-01 00:00:00' AND MIN(e.event_time) < '2020-01-14 00:00:00' 
							THEN 'BOGOF - Fishing For Compliments'
						 WHEN MIN(e.event_time) > '2020-01-15 00:00:00' AND MIN(e.event_time) < '2020-01-28 00:00:00'
							THEN '25% Off - Living The Lux Life'
						 WHEN MIN(e.event_time) > '2020-02-01 00:00:00' AND MIN(e.event_time) < '2020-03-31 00:00:00' 
							THEN 'Half Off - Treat Your Shellf(ish)'
                    END AS campaign,
                    COUNT(CASE WHEN e.event_type = 4 THEN 1 END) AS impressions,
                    COUNT(CASE WHEN e.event_type = 5 THEN 1 END) AS clicks,
                    GROUP_CONCAT(' ', CASE WHEN product_id IS NOT NULL AND e.event_type = 2
												THEN ph.page_name 
										END) AS cart_products
	FROM events e 
	JOIN event_identifier ei 
			ON e.event_type = ei.event_type 
	JOIN users u
			ON e.cookie_id = u.cookie_id
	JOIN page_hierarchy ph
			ON e.page_id = ph.page_id
    GROUP BY visit_id, user_id         
)
SELECT user_id, visit_id, visit_start_time, page_views, cart_adds, purchases, impressions, clicks, campaign, cart_products
FROM Campaign_CTE;


SELECT *
FROM campaign_tab
ORDER BY user_id;

-- Users who have received impressions during each campaign period vs users without impressions
SELECT campaign,
		COUNT(DISTINCT CASE WHEN impressions !=0 THEN user_id END) AS users_with_impressions,
		COUNT(DISTINCT CASE WHEN user_id NOT IN (SELECT DISTINCT(user_id) AS users
										FROM campaign_tab
										WHERE impressions != 0 
										ORDER BY user_id) THEN user_id END) AS users_without_impressions
FROM campaign_tab
WHERE campaign IS NOT NULL
GROUP BY campaign;


-- Does clicking on an impression lead to higher purchase rates
WITH ImpressionPurchaseCTE AS (
    SELECT 
        COUNT(CASE WHEN impressions !=0 THEN 1 END) AS total_impressions,
        COUNT(CASE WHEN impressions!=0 AND purchases !=0 THEN 1 END) AS total_purchases_from_impressions
    FROM campaign_tab 
)
SELECT total_impressions,
		total_purchases_from_impressions,
		ROUND((total_purchases_from_impressions * 100.0 / total_impressions),2) AS impression_to_purchase_percentage
FROM ImpressionPurchaseCTE;


-- Uplift in purchase rate with users who click on campaign impressions vs users who don't click 
WITH Impression_Clicks_PurchaseCTE AS (
    SELECT 
        COUNT(CASE WHEN impressions!=0 AND clicks=1 AND purchases=1 THEN 1 END) AS impressions_from_clicks,
        COUNT(CASE WHEN impressions!=0 AND clicks=0 AND purchases=1 THEN 1 END) AS impressions_without_clicks
    FROM campaign_tab 
    WHERE campaign IS NOT NULL
)
SELECT 
		impressions_from_clicks,
		impressions_without_clicks,
		ROUND((impressions_without_clicks * 100.0 / impressions_from_clicks),2) AS uplift_in_purchase_rate
FROM Impression_Clicks_PurchaseCTE
;