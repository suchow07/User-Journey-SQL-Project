use user_journey_data;



select count(*) from front_interactions; -- 1625367 rows
select count(distinct event_name) from front_interactions; -- 2626 distinct event_name
select * from front_interactions
limit 5;
select count(distinct visitor_id) from front_interactions;-- 245562 

select count(*) from front_visitors; -- 3505 rows
select * from front_visitors
limit 5;
select count(distinct visitor_id) from front_visitors; -- 245562
select count(distinct user_id ) from front_visitors; -- 98207

select count(*) from student_purchases;
select * from student_purchases
limit 5;

select distinct purchase_type from student_purchases; -- 3 types: 0,1,2
--  the type of subscription purchased (0=monthly, 1=quarterly, 2=annual)
select count(distinct user_id) from student_purchases; -- 2590 distinct users purchase


select * from front_interactions limit 5;
select * from front_visitors limit 5;
select * from student_purchases limit 5;


-- We require distinct user_id and purchase_type for users whose first purchase
-- falls within Q1 2023.    
-- drop view vw_paid_users_info;
CREATE VIEW vw_paid_users_info AS
WITH paid_users AS (
   	SELECT
		user_id,
		MIN(date_purchased) as first_purchase,
		MIN(CASE
			WHEN purchase_type = 0 THEN 'Monthly'
            WHEN purchase_type = 1 THEN 'Quarterly'
			WHEN purchase_type = 2 THEN 'Annual'
			ELSE 'Other'
		END) as purchase_type,
		MIN(purchase_price) as price
	FROM 
		student_purchases
	GROUP BY user_id
	HAVING
		price > 0
		AND
		CAST(first_purchase as DATE) >= '2023-01-01'
		AND
		CAST(first_purchase as DATE) <= '2023-03-31'
), user_interactions AS (
 SELECT
		p.user_id,
        i.visitor_id,
        i.session_id,
		i.event_source_url, 
		i.event_destination_url,
        p.purchase_type
	FROM
		paid_users as p
        INNER JOIN
        front_visitors as v ON v.user_id = p.user_id
        INNER JOIN
        front_interactions as i ON i.visitor_id = v.visitor_id
	WHERE
		i.event_date < p.first_purchase)
SELECT user_id,
        session_id,
		purchase_type,
		CASE
			WHEN event_source_url = 'https://365datascience.com/' THEN 'Homepage'
			WHEN event_source_url LIKE 'https://365datascience.com/login/%' THEN 'Log in'
			WHEN event_source_url LIKE 'https://365datascience.com/signup/%' THEN 'Sign up'
			WHEN event_source_url LIKE 'https://365datascience.com/resources-center/%' THEN 'Resources center'
			WHEN event_source_url LIKE 'https://365datascience.com/courses/%' THEN 'Courses'
			WHEN event_source_url LIKE 'https://365datascience.com/career-tracks/%' THEN 'Career tracks'
			WHEN event_source_url LIKE 'https://365datascience.com/upcoming-courses/%' THEN 'Upcoming courses'
			WHEN event_source_url LIKE 'https://365datascience.com/career-track-certificate/%' THEN 'Career track certificate'
			WHEN event_source_url LIKE 'https://365datascience.com/course-certificate/%' THEN 'Course certificate'
			WHEN event_source_url LIKE 'https://365datascience.com/success-stories/%' THEN 'Success stories'
			WHEN event_source_url LIKE 'https://365datascience.com/blog/%' THEN 'Blog'
			WHEN event_source_url LIKE 'https://365datascience.com/pricing/%' THEN 'Pricing'
			WHEN event_source_url LIKE 'https://365datascience.com/about-us/%' THEN 'About us'
			WHEN event_source_url LIKE 'https://365datascience.com/instructors/%' THEN 'Instructors'
			WHEN event_source_url LIKE 'https://365datascience.com/checkout/%' AND event_source_url LIKE '%coupon%' THEN 'Coupon'
            WHEN event_source_url LIKE 'https://365datascience.com/checkout/%' AND event_source_url NOT LIKE '%coupon%' THEN 'Checkout'
			ELSE 'Other'
		END as event_source_alias,
		CASE
			WHEN event_destination_url = 'https://365datascience.com/' THEN 'Homepage'
			WHEN event_destination_url LIKE 'https://365datascience.com/login/%' THEN 'Log in'
			WHEN event_destination_url LIKE 'https://365datascience.com/signup/%' THEN 'Sign up'
			WHEN event_destination_url LIKE 'https://365datascience.com/resources-center/%' THEN 'Resources center'
			WHEN event_destination_url LIKE 'https://365datascience.com/courses/%' THEN 'Courses'
			WHEN event_destination_url LIKE 'https://365datascience.com/career-tracks/%' THEN 'Career tracks'
			WHEN event_destination_url LIKE 'https://365datascience.com/upcoming-courses/%' THEN 'Upcoming courses'
			WHEN event_destination_url LIKE 'https://365datascience.com/career-track-certificate/%' THEN 'Career track certificate'
			WHEN event_destination_url LIKE 'https://365datascience.com/course-certificate/%' THEN 'Course certificate'
			WHEN event_destination_url LIKE 'https://365datascience.com/success-stories/%' THEN 'Success stories'
			WHEN event_destination_url LIKE 'https://365datascience.com/blog/%' THEN 'Blog'
			WHEN event_destination_url LIKE 'https://365datascience.com/pricing/%' THEN 'Pricing'
			WHEN event_destination_url LIKE 'https://365datascience.com/about-us/%' THEN 'About us'
			WHEN event_destination_url LIKE 'https://365datascience.com/instructors/%' THEN 'Instructors'
			WHEN event_destination_url LIKE 'https://365datascience.com/checkout/%' AND event_destination_url LIKE '%coupon%' THEN 'Coupon'
            WHEN event_destination_url LIKE 'https://365datascience.com/checkout/%' AND event_destination_url NOT LIKE '%coupon%' THEN 'Checkout'
			ELSE 'Other'
		END as event_destination_alias
	FROM
		user_interactions;


select * from vw_paid_users_info;
WITH table_concatenated as -- 36831 rows
(
	SELECT 
		user_id,
        session_id,
		purchase_type,
		CONCAT(event_source_alias,
				'-',
				event_destination_alias) as source_destination
	FROM
		vw_paid_users_info
) 
	SELECT 
		user_id,
        session_id,
		purchase_type,
		GROUP_CONCAT(source_destination
			SEPARATOR '-') as user_journey
	FROM
		table_concatenated
	GROUP BY user_id, session_id, purchase_type;