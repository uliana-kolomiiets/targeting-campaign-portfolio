
    /******************************************************************************
    AVG Spring Cleaning OO 2026

    https://confluence.corp.nortonlifelock.com/spaces/CNS/pages/921416884/2026_04_13+AVG+Spring+Cleaning+one-off+campaign+2026
    -------------------------------------------------------------------------------
    USAGE EXAMPLE
    --------------------
    select * from `tab.spring26_final`
    -------------------------------------------------------------------------------
    CHANGE HISTORY
    --------------------
    Version   Date                Author            Description
    --        ----                ------            -----------
    1.0       2026-04-22         uliana.kolomiiets    usual one-off, same as 2024
    ******************************************************************************/

-- +-------------------------------------------------------------------------+
-- | 1. SUPPRESSION FOR PAID USERS (ACTIVE, EXPIRED, TRIAL)
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_sup`;
CREATE TABLE `tab.spring26_sup` AS
with supression as (
-- suppression 45D after purchase
    SELECT DISTINCT customer_email
    FROM `tab.order_item`
    WHERE current_date <= order_date + INTERVAL 30 DAY
UNION ALL
-- suppression of paid customers in window 75 before expiration - 60 post expiration 
    SELECT DISTINCT customer_email
    from `tab.order_item`
    WHERE current_date >= expiration_date - INTERVAL 65 DAY
      AND current_date <= expiration_date + INTERVAL 60 DAY
UNION ALL
-- suppression of restricted GEOs
    SELECT DISTINCT customer_email
    FROM`tab.order_item`
    WHERE country_iso2 IN ('CU', 'IR', 'KP', 'SD', 'RU', 'UA', 'BY', 'SY')
UNION ALL    
-- suppression of active trial customers (preauth-trial)
    SELECT DISTINCT customer_email
    from `tab.order_item`
    WHERE product_trial_type = 'D'
    AND  current_date between order_date and date_add(order_date, INTERVAL product_trial_length day) 
-- suppression of ultimate AVG or avg bundles
UNION ALL
SELECT DISTINCT customer_email
FROM `tab.order_item`
WHERE (lower(product_family_group) LIKE '%privacy bundle%' OR lower(product_family_group) LIKE '%performance bundle%'
or lower(product_family_group) LIKE '%avg ultimate%')
  AND current_date <= expiration_date
--- suppression of Indian VPN
UNION ALL
select distinct customer_email
from `tab.order_item`
where business_source_name = 'VPN' and country_iso2 IN ('IN') 
 -- suppression for excluding the countries without spring seasong = southern hemisphere countries
UNION ALL
    SELECT DISTINCT customer_email
    FROM`tab.order_item`
    WHERE 
    --country_iso2 IN ('AE', 'BH', 'DZ', 'EG', 'IQ', 'JO', 'KW', 'LB', 'MA', 'MR', 'OM', 'PS', 'QA', 'SA', 'SD', 'TN', 'SA', 'YE', 'ID', 'ZA', 'AU', 'NZ', 'AR', 'BO', 'CL', 'CO', 'EC', 'PE', 'PY', 'BR')
  country_iso2 IN ('AR', 'BO', 'CL', 'CO', 'EC', 'PE', 'PY', 'BR')
  )


SELECT DISTINCT customer_email
FROM supression
--limit 1000
;

-- +-------------------------------------------------------------------------+
-- | 1. PAID ACTIVE PAAC
-- +-------------------------------------------------------------------------+
DROP TABLE IF EXISTS `tab.spring26_active`;
CREATE TABLE `tab.spring26_active` AS

WITH customers AS (
     SELECT    oi.customer_email,
               oi.order_date,
               oi.flag_return,
               l.flag_removed,
               oi.business_source_name,
               l.container_id,
               oi.locale,
               oi.country_iso2,
                CASE
                    WHEN business_source_name = 'Utilities'     THEN 'TUD'
                    WHEN business_source_name = 'DriverUpdater' THEN 'DUW'
                    WHEN business_source_name = 'AV'
                      OR business_source_name = 'AntiTrack' 
                      OR business_source_name = 'BreachGuard' 
                      OR business_source_name = 'VPN'          THEN 'OTHER'
                    ELSE NULL
                END AS SEGMENT,
                ROW_NUMBER() OVER (PARTITION BY oi.customer_email, oi.business_source_name ORDER BY oi.order_date DESC)    AS rn_bs  -- expired last business source

FROM `tab.order_item` AS oi
JOIN `tab.license` AS l ON oi.order_item_id=l.order_item_id AND l.distributor_id=oi.distributor_id AND l.dedup_rn_per_oi = 1

WHERE 1=1
AND current_date >= order_date + INTERVAL 30 DAY
AND current_date <= expiration_date
AND oi.business_source_group_name = 'Consumer'
AND oi.channel_group = 'Online'
AND oi.entity = 'AVG'
AND oi.product_family_group LIKE 'AVG%'
AND oi.business_source_name IN ('AV','Utilities', 'VPN', 'AntiTrack', 'DriverUpdater', 'BreachGuard')
AND oi.product_trial_type != 'D'
AND flag_return = FALSE
AND flag_removed = FALSE
)

,customers_out as (

       SELECT  *, ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY order_date DESC)                             AS rn_ord
       FROM customers
       WHERE 1=1
       AND rn_bs =1

)

SELECT a.customer_email,
      a.segment,
      b.country_iso2,
      b.container_id,
      b.locale

FROM customers_out as a

LEFT JOIN

(SELECT z.customer_email,
        z.locale,
        z.country_iso2,
        z.container_id
FROM customers_out z
WHERE rn_ord = 1) as b on a.customer_email=b.customer_email

WHERE a.customer_email IS NOT NULL

ORDER BY customer_email
--limit 1000
;

-- +-------------------------------------------------------------------------+
-- | 2. PAID ACTIVE USERS WITH OFFERS
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_active_offer`;
CREATE TABLE `tab.spring26_active_offer`  AS

SELECT DISTINCT getid.customer_email,
                loc.locale,
                loc.country_iso2,
                offer.offer AS SEGMENT,
                'PAAC' as query_param,
                'x-sell' as campaign_segment,
                loc.container_id

FROM -- napočítání SUMY aktivních produktů
  (SELECT a.customer_email , --11
          sum(CAST(seg.segment_id AS INT)) AS sum_segment_id
   FROM `tab.spring26_active` a
   JOIN `tabg.t_avg_matrix` seg ON a.segment = seg.segment ---keep the same matrix from 2024
   GROUP BY customer_email) getid

  -- převedení na offer
JOIN `tab.t_avg_matrix` offer ON getid.sum_segment_id = offer.offer_id
JOIN `tab.spring26_active` loc ON getid.customer_email = loc.customer_email 
where offer.offer!='NO OFFER'
ORDER BY customer_email
--limit 1000
;

-- +-------------------------------------------------------------------------+
-- | 3. WINBACK: PAID EXPIRED AND TRIAL EXPIRED CUSTOMERS:  PAEX and TREX
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_expired`;
CREATE TABLE `tab.spring26_expired` AS

WITH customers AS (
SELECT oi.customer_email,
       oi.order_date,
       oi.expiration_date,
       oi.flag_return,
       l.flag_removed,
       l.container_id,
       oi.locale,
       oi.country_iso2,
       oi.product_update_period,
                CASE
                    WHEN business_source_name = 'Utilities'     THEN 'TUD'
                    WHEN business_source_name = 'DriverUpdater' THEN 'DUW'
                    WHEN business_source_name = 'AV'
                      OR business_source_name = 'AntiTrack' 
                      OR business_source_name = 'BreachGuard' 
                      OR business_source_name = 'VPN'          THEN 'OTHER'
                    ELSE NULL
                END AS SEGMENT_EXP,

      CASE WHEN oi.product_trial_type = 'D' THEN 'TREX'
        ELSE 'PAEX'  
      END AS query_param,

      ROW_NUMBER() OVER (PARTITION BY oi.customer_email, oi.business_source_name ORDER BY oi.order_date DESC)    AS rn_bs  -- expired last business source

FROM `tab.order_item`  AS oi
JOIN `tab.license`  AS l ON oi.order_item_id=l.order_item_id AND l.distributor_id=oi.distributor_id AND l.dedup_rn_per_oi = 1

LEFT JOIN 
 (SELECT customer_email FROM `tab.order_item`
  WHERE current_date < expiration_date) as act on oi.customer_email=act.customer_email

WHERE 1=1
AND current_date BETWEEN expiration_date AND DATE_ADD(expiration_date, INTERVAL 720 DAY)
AND oi.business_source_group_name = 'Consumer'
AND oi.channel_group = 'Online'
AND oi.entity = 'AVG'
AND oi.product_family_group LIKE 'AVG%'
AND oi.business_source_name IN ('AV','Utilities', 'VPN', 'AntiTrack', 'DriverUpdater', 'BreachGuard')
AND act.customer_email is null
AND flag_return = FALSE 
AND flag_removed=FALSE
),

list as (
SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY expiration_date DESC) AS rn -- for calculation of the very last expired product 
FROM customers 
WHERE 1=1
AND rn_bs = 1           -- to have only 1 row for each BS 
AND container_id is not null)

SELECT *,
  CASE WHEN SEGMENT_EXP = 'OTHER' THEN 'upsell'
  ELSE 'winback'     
  END  AS campaign_segment,

   CASE 
      WHEN SEGMENT_EXP = 'OTHER' THEN 'TUD'
      ELSE SEGMENT_EXP 
  END as SEGMENT
from list
where rn = 1

--LIMIT 1000
;

-- +-------------------------------------------------------------------------+
-- | 4. UNION active and expired
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_paid_union`;
CREATE TABLE `tab.spring26_paid_union` AS

with 
union_all as (

SELECT    customer_email, 
          locale,
          country_iso2,
          SEGMENT,
          query_param,
          container_id,
          campaign_segment

FROM `tab.spring26_active_offer`
where SEGMENT!='NO OFFER'

UNION ALL

SELECT    customer_email, 
          locale,
          country_iso2,
          SEGMENT,
          query_param,
          container_id,
          campaign_segment

FROM `tab.spring26_expired`
)

select paid.*
from union_all as paid
LEFT JOIN `tab.spring26_sup` as sup on paid.customer_email=sup.customer_email
WHERE sup.customer_email is NULL

--limit 1000
;


-- +-------------------------------------------------------------------------+
-- | 5. FREE USERS: SUPPRESSION
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_free_supp`;
CREATE TABLE `tab.spring26_free_supp`  AS

with supression as (

--suppression A1 users

    SELECT cast(null as string) as email, uuid AS UUID
    FROM `tab.t_lifecycle_events` 
    WHERE uuid IS NOT NULL
    AND product_bi_id IN ('1_21', '84_6')     --- excluding Avast One OSX - Free and Avast One Free Windows

UNION ALL
---suppression for all nul uuid =  those who made registration, but do not have any product

    SELECT cast(null as string) as email, uuid AS UUID
    FROM `tabs.t_lifecycle_events`
    WHERE uuid IS NULL


UNION ALL

-- paid/trial users

   SELECT distinct customer_email as email, cast(null as string) as UUID
   FROM `tab.order_item`
   WHERE current_date BETWEEN order_date AND DATE_ADD(expiration_date, INTERVAL  720 DAY)

UNION ALL

-- deleted accounts

    SELECT p_email as email, UUID
    FROM `tab.v_avast_id_account_eventsv2`
    WHERE lower(event_type) = 'account_deleted'
    AND YEAR > EXTRACT(YEAR FROM date_sub(current_date, interval 3 year))

UNION ALL

SELECT distinct acc.p_email as email, acc.UUID
FROM `tab.v_avast_id_account_eventsv2` acc
JOIN `tab.t_uuid_mapping` map on acc.uuid=map.uuid
JOIN `tab.t_connection` conn on map.guid=conn.guid
JOIN `tab.license` lic on conn.container_id = lic.container_id
WHERE lic.container_schema_id like '%ultimate%'
and date(lic.container_furthest_expiration_date_time_utc) > current_date()
and (acc.year = 2025 or acc.year=2026)

    )

SELECT DISTINCT email, UUID
FROM supression

--limit 1000
;

--- +-------------------------------------------------------------------------+
-- | 6. FREE USERS: ACC
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.spring26_free`;
CREATE TABLE `tab.spring26_free`  AS

with accounts_all as (

SELECT DISTINCT a.p_email                                          AS customer_email, 
                upper(a.locale)                                    AS locale,
                upper(substring(a.locale, 4))                           AS country_iso2,
                'TUD'                                                   as SEGMENT,
                'ACC'                                                   AS query_param,
                'upsell'                                                AS campaign_segment,
                a.UUID                                                  AS account_uuid,
                cast(concat (a.year, '-', a.month, '-', a.day) as date) as change_date
FROM (
   SELECT * from `ppp-bie-bi-data-6e.bi_src_payload.v_avast_id_account_eventsv2` 
   where year>2021) a

LEFT JOIN `tab.spring26_free_supp` del_one ON del_one.uuid = a.uuid

LEFT JOIN `tab.spring26_free_supp` oi on a.p_email=oi.email -- email -- has to be a.p_email instead od del_one.email

LEFT JOIN `tab.spring26_paid_union` paac ON paac.customer_email = a.p_email

LEFT JOIN `tab.spring26_sup` ass ON ass.customer_email= a.p_email

WHERE   lower(a.brand) = 'avg'
  AND oi.email IS  NULL
  AND paac.customer_email IS NULL
  AND ass.customer_email IS NULL
  AND del_one.uuid IS NULL
  AND YEAR > EXTRACT(YEAR FROM date_sub(current_date, interval 3 year))
  AND verified = TRUE
  AND cast(concat (a.year, '-', a.month, '-', a.day) as date) > DATE_SUB(CURRENT_DATE,INTERVAL  720 DAY)
  AND lower(substring(a.locale, 4)) not in ('cu', 'ir', 'kp', 'sd', 'ru', 'ua', 'by', 'sy') 
  and upper(substring(a.locale, 4)) not in ('AR', 'BO', 'CL', 'CO', 'EC', 'PE', 'PY', 'BR')
  --('AE', 'BH', 'DZ', 'EG', 'IQ', 'JO', 'KW', 'LB', 'MA', 'MR', 'OM', 'PS', 'QA', 'SA', 'SD', 'TN', 'SA', 'YE', 'ID', 'ZA', 'AU', 'NZ', 'AR', 'BO', 'CL', 'CO', 'EC', 'PE', 'PY', 'BR')

  --LIMIT 1000
  ),


accounts_out as (

SELECT  *
        , ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY change_date DESC)      AS rn_ord -- customer_email is null for free acc, thus partitioned is not working
FROM accounts_all
)

SELECT DISTINCT customer_email,
                locale,
                segment,
                country_iso2,
                query_param,
                campaign_segment,
                account_uuid,
                'NULL' as days_to_expiration

FROM accounts_out
WHERE rn_ord = 1

--limit 1000
;

-- +--------------------------------------------------------------------------------------------------------------------------------------+
-- | 7. FINAL TABLE: PAAC, PAEX, TREX, ACC with offers, experiment and tracking
-- +--------------------------------------------------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS `tab.spring26_final`;
CREATE TABLE `tab.spring26_final` AS

with final_all as

( SELECT DISTINCT customer_email,
                  locale,
                  country_iso2,
                  SEGMENT,
                  query_param,
                  campaign_segment,
                  cast(NULL as string) as account_uuid,
                  container_id
  FROM `tab.spring26_paid_union`


  UNION ALL


  SELECT DISTINCT customer_email,
                  locale,
                  country_iso2,
                  SEGMENT,
                  query_param,
                  campaign_segment,
                  account_uuid,
                  cast(NULL as string) as container_id
  FROM `tab.spring26_free`),



tracking_fin as (  
    
    SELECT *,

    CONCAT(

       query_param,                 '_',  --1 Subscription Segment    
       'xs',                        '_',  --2 Campaign Category 1--Xsell     
       'sea',                       '_',  --3 Campaign Category 2 --Seasonal     
       segment,                     '_',  --4 Offer SKU
      'NULL',                        '_',   --5 Test Variant  

    CASE
     WHEN query_param = 'PAAC' THEN 'EC-ONEOFFEMAIL-NICE55'
     ELSE 'EC-ONEOFFEMAIL-NICE60' 
     END,                             '_',    --6 DiscountCode, 

    'EC-OO-SPRINGCLEAING2026-',             '_',  --7 Campaign Marker  

    CASE
                  WHEN query_param = 'PAAC'  THEN 'Paid-Active'
                  WHEN query_param = 'PAEX'  THEN 'Paid-Expired'
                  WHEN query_param = 'TREX'  THEN 'Trial-Expired'
                  WHEN query_param = 'ACC'   THEN 'Free (account)'
       ELSE ''
       END,                           '_',  --8 Campaign Segment  

       'NULL',                        '_',  --9 Time to Expiration              
       'NULL',                        '_',  --10 Ad hoc1 
       'NULL',                        '_',  --11 Ad hoc2
       'NULL',                        '_',  --12 Ad hoc3

       CASE 
         WHEN query_param ='ACC' THEN 'NULL'
         ELSE container_id 
         END
       )  AS tracking

       FROM final_all
       ),

suppression_smb as (
select distinct (customer_email) as customer_email
from tracking_fin as a
join `ppp-cdo-dw-6c.edw_ana_c360.c360_email_funnel` as b on a.customer_email=b.email_address
where lower(b.email_name) like '%smb%'
and b.from_name='AVG'
and a.query_param='ACC'
and b.email_campaign like '%_tr_%'
),

final as(

select a.*,
ROW_NUMBER() OVER (PARTITION BY a.customer_email) as rn
from tracking_fin as a
left join suppression_smb b on a.customer_email=b.customer_email
where b.customer_email is null
),

-- +---------------------------------------------------------------------------------------------------------------------------------
-- | preparing time_groups using sto table for WW (unknown individual time) and non-WW (known individual time) customers separately
-- +---------------------------------------------------------------------------------------------------------------------------------
  sample_non_ww as( 
    select f.*, 
      NTILE(12) OVER (ORDER BY sto.individual_time) as time_group
      from  final f 
  JOIN `ppp-dit-data-acq-d3.securedb.master_email` h
       ON lower(f.customer_email) = lower(h.hash_value)
  LEFT JOIN `ppp-mailops-dls-b0.email_adhoc.PS_time_analysis` sto
       ON LOWER(TRIM(sto.email_address)) = h.string_value 
  where country_iso2!='WW'
  and rn=1
     ),

sample_ww as( 
    select f.*, 
      NTILE(12) OVER (ORDER BY sto.individual_time) as time_group
      from  final f
  JOIN `ppp-dit-data-acq-d3.securedb.master_email` h
       ON lower(f.customer_email) = lower(h.hash_value)
  LEFT JOIN `ppp-mailops-dls-b0.email_adhoc.PS_time_analysis` sto
       ON LOWER(TRIM(sto.email_address)) = h.string_value 
  where country_iso2='WW'
  and rn=1
     ),

sto as(
select * from sample_non_ww
union all
select a.* from sample_ww as a
left join sample_non_ww as b on a.customer_email=b.customer_email
where b.customer_email is null)
-- +---------------------------------------------------------------------------------------------------------------------------------
-- | final table
-- +---------------------------------------------------------------------------------------------------------------------------------
select distinct customer_email,
                --locale,
                country_iso2 as country_iso,
                segment,
                campaign_segment as dynamic_field,
                query_param as userType,
                account_uuid as accountID,
                container_id as containerID,
                time_group,
                tracking
from sto 
--where flag_india_vpn='false'
;




/************************************************************************************************

Following queries necessary for OO (time-tables, analyses, splitting, exposure table)

-- +--------------------------------------------------------------------------------------------+
-- | TABLE FOR UPDATING TIME-GROUPS. CREATED BY PAVEL SHEDA. SHOULD BE UPDATED BEFORE EVERY OO
-- +--------------------------------------------------------------------------------------------+

CREATE OR REPLACE TABLE `ppp-mailops-dls-b0.spring_cleaning.PS_time_analysis_march2025` AS

with

cte_emails_base as (

SELECT
  email_address,
  sent_date_time,
  email_locale,
  container_id,
  TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',TIME(first_open_date_time)) as timestamp)),0.5) OVER (PARTITION BY email_address) as int64))) as avg_first_open_time,
  TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',TIME(first_click_date_time)) as timestamp)),0.5) OVER (PARTITION BY email_address) as int64))) as avg_first_click_time
FROM
  `ppp-cdo-dw-6c.edw_ana_c360.v_c360_email_funnel` 
),

cte_emails as (

SELECT
  email_address,
  avg_first_open_time,
  avg_first_click_time,
  split(max(concat(sent_date_time,'#',replace(email_locale,'_','-'))),'#')[1] as last_email_locale,
  split(max(if(container_id is null,null,concat(sent_date_time,'#',container_id))),'#')[1] as last_container_id
FROM
  cte_emails_base
group by 
  email_address,
  avg_first_open_time,
  avg_first_click_time
),

cte_order_base as (

select 
    customer_email,
    event_date_time,
    country_iso2,
  TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',TIME(event_date_time)) as timestamp)),0.5) OVER (PARTITION BY customer_email) as int64))) as avg_order_time
from 
    `tab.order_item`
where
    product_trial_type in ('D','(not set)') 
    and business_source_group_name = 'Consumer'
    and channel_group = 'Online'
    and lob_level_1 = 'Acquisition'
    and time(event_date_time) != '00:00:00'
),

cte_order as (

select 
    customer_email,
    avg_order_time,
    max(concat(event_date_time,'#',country_iso2)) as last_order_country
from 
    cte_order_base
group by 
  customer_email,
    avg_order_time
),

cte_connection as (

SELECT
  container_id,
  max(concat(ifnull(last_seen_datetime_utc,cast('1970-01-01 00:00:01' as datetime)),'#',last_country)) as last_container_country
FROM
  `ppp-bie-bi-data-6e.bi_core_tables.t_connection`
where 
  container_id is not null 
  and last_country is not null
group by 
  container_id
),

cte_account as (

SELECT  
  a.p_email,
  max(concat(ifnull(u.last_seen_datetime_utc,cast('1970-01-01 00:00:01' as datetime)),'#',u.last_country)) as last_account_country
FROM 
  `ppp-bie-bi-data-6e.bi_core_account.t_account` as a 
left join 
  `ppp-bie-bi-data-6e.bi_core_tables.t_uuid_mapping` as u 
  on a.uuid = u.uuid 
  and u.last_country is not null
  and u.uuid is not null
where 
  a.p_email is not null
  and a.uuid is not null
group by 
  a.p_email
),

cte_customer_base as (

select  
  email_address 
from
  cte_emails 
where 
  email_address is not null 

UNION DISTINCT

select distinct 
  customer_email as email_address
from
  `tab.order_item`
where 
  customer_email is not null 
),

cte_join as (

select 
  b.email_address,
  e.last_email_locale,
    IFNULL(o.avg_order_time, IFNULL(e.avg_first_click_time, e.avg_first_open_time)) AS optimal_time_base,
    if(REGEXP_CONTAINS(e.last_email_locale,'-') = true, split(e.last_email_locale,'-')[1],e.last_email_locale) as last_email_country,
  IF(
    SPLIT(GREATEST(IFNULL(o.last_order_country,'0#0'), IFNULL(c.last_container_country,'0#0'), IFNULL(a.last_account_country,'0#0')),'#')[SAFE_OFFSET(1)] in ('0','WW','N/A','EU','EN','ISO','YU','XW','(TBD)','AQ','TF','GS','HM','BV','JA','DA','CS','SP','IC'),
      IF(REGEXP_CONTAINS(e.last_email_locale,'-') = true, 
        SPLIT(e.last_email_locale,'-')[1],
        e.last_email_locale), 
      SPLIT(GREATEST(IFNULL(o.last_order_country,'0#0'), IFNULL(c.last_container_country,'0#0'),IFNULL(a.last_account_country,'0#0')),'#')[SAFE_OFFSET(1)]) AS optimal_country
from 
  cte_customer_base as b 
left join 
  cte_emails as e 
  on b.email_address = e.email_address
left join 
  cte_order as o 
  on b.email_address = o.customer_email
left join
  cte_connection as c 
  on e.last_container_id = c.container_id
left join 
  cte_account as a 
  on e.email_address = a.p_email 
)

select 
  j.email_address,
  j.last_email_locale,
  j.optimal_country,
  case
    when j.optimal_country = 'EU' then 'Europe' 
    when c.continent_name is null or c.continent_name in ('Antarctica','(not set)','(unknown)','(TBD)','Worldwide') then 'unknown' 
    else c.continent_name
  end as optimal_continent,
  ifnull(j.optimal_time_base,TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',j.optimal_time_base) as timestamp)),0.5) OVER (PARTITION BY if(j.optimal_country is null or j.optimal_country in ('(TBD)','N/A','WW','EU','ISO'),'unknown',j.optimal_country)) as int64)))) as individual_time,
  if(j.optimal_time_base is not null,1,0) as is_individual_data,
  TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',j.optimal_time_base) as timestamp)),0.5) OVER (PARTITION BY if(j.optimal_country is null or j.optimal_country in ('(TBD)','N/A','WW','EU','ISO'),'unknown',j.optimal_country)) as int64))) as country_time,
  TIME(TIMESTAMP_SECONDS(cast(PERCENTILE_CONT(UNIX_SECONDS(cast(concat('1970-01-01 ',j.optimal_time_base) as timestamp)),0.5) OVER (PARTITION BY case when j.optimal_country = 'EU' then 'Europe' when c.continent_name is null or c.continent_name in ('Antarctica','(not set)','(unknown)','(TBD)','Worldwide') then 'unknown' else c.continent_name end) as int64))) as continent_time
from 
  cte_join as j 
left join 
  `ppp-bie-bi-data-6e.bi_core_dm.v_dim_country` as c 
  on j.optimal_country = c.country;


-- +--------------------------------------------------------------------------------------------------------------------------------------+
-- | TABLE FOR CREATING TIME-GROUPS WITH MIN-MAX-MEDIAN NUMBER OF CUSTOMERS IN EACH GROUP. SHOULD BE SENT TO SENDOUT FOR SENDOUT PLANNING
-- +--------------------------------------------------------------------------------------------------------------------------------------+

with temporaryTable as (
SELECT 
        a.time_group, 
        b.individual_time, 
        a.customer_email
    FROM 
        `tab.spring26_final` a
        LEFT JOIN `ppp-mailops-dls-b0.spring_cleaning.PS_time_analysis_april2025`  as b on a.customer_email = b.email_address
),
medianTable AS (
    SELECT 
        time_group,
        APPROX_QUANTILES(individual_time, 2)[OFFSET(1)] AS median_time
    FROM 
        temporaryTable
    GROUP BY 
        time_group
)
SELECT 
    t.time_group,
    MIN(t.individual_time) AS min_time,
    MAX(t.individual_time) AS max_time,
    m.median_time,
    COUNT(DISTINCT t.customer_email) AS total_count
FROM 
    temporaryTable t
JOIN 
    medianTable m
ON 
    t.time_group = m.time_group
GROUP BY 
    t.time_group, m.median_time
ORDER BY 
    t.time_group;


-- +--------------------------------------------------------------------------------------------------------------------------------------+
-- | TABLE FOR MAIN STATISTICS, SHOULD BE SENT TO SENDOUT TO CHECK NUMBERS WITH OWNERS
-- +--------------------------------------------------------------------------------------------------------------------------------------+

select distinct(segment),
count(customer_email) as counts
from `tab.spring26_final`
group by segment
order by counts desc
;

select distinct(userType),
count(customer_email) as counts
from `tab.spring26_final`
group by userType
order by counts desc
;




-- +------------------------------------------------------------------------------------------------------------------------------------+
-- | TABLES FOR SPLITTING TO AIRFLOW. ADD COUNTS FOR HISTORY
-- +--------------------------------------------------------------------------------------------------------------------------------------+    TOTAL COUNT is 8 755 026

DROP TABLE IF EXISTS `tab.spring26_final_acc_en` ;
CREATE table `tab.spring26_final_acc_en` as
SELECT * FROM `tab.spring26_final` where userType = 'ACC' and lower(locale) like '%en%';       

DROP TABLE IF EXISTS `tab.spring26_final_acc_row` ;
CREATE table `tab.spring26_final_acc_row` as
SELECT * FROM `tab.spring26_final` where userType = 'ACC' and lower(locale) not like '%en%'; 

DROP TABLE IF EXISTS `tab.spring26_final_winback` ;                    
CREATE table `tab.spring26_final_winback` as
SELECT * FROM `tab.spring26_final` where userType = 'TREX' or userType = 'PAEX';                

DROP TABLE IF EXISTS `tab.spring26_final_paac` ;      
CREATE table `tab.spring26_final_paac` as
SELECT * FROM `tab.spring26_final` where userType = 'PAAC';   


with 
sample as (
select customer_email,
       'acc_ww' as dynamic_field
from  `tab.spring26_final_acc_ww`
UNION ALL 
select customer_email,
       'acc_not_ww' as dynamic_field
from  `tab.spring26_final_acc_not_ww`
UNION ALL
select customer_email,
        'winback' as dynamic_field  
from  `tab.spring26_final_winback`
UNION ALL       
select customer_email,
        'paac' as dynamic_field  
from  `tab.spring26_final_paac`   
UNION ALL
select customer_email,
       'total' as dynamic_field
from `tab.spring26_final` 
)

select distinct(dynamic_field), count(customer_email)
from sample
group by dynamic_field 
order by dynamic_field
;

------------
--statistics
------------
acc_en = 5,543,116
acc_row =1,803,310
paac = 2,862,515
winback= 407,274
total =14,281,688



-- +------------------------------------------------------------------------------------------------------------------------------------+
-- | Exposure Table
-- +--------------------------------------------------------------------------------------------------------------------------------------+    

insert into `tab.exposure_reporting`(
     experiment_id,
     variant_id,
     unit_type,
     unit_id
 )
 select
     experimentID as experiment_id,
     experimentVariantID as variant_id,
     'container_id' AS unit_type,
     containerID AS unit_id
 from `tab.spring26_final`
 WHERE ExperimentVariantID in ('a','b','c')
 and userType != 'ACC';

  insert into `tab.exposure_reporting`(
     experiment_id,
     variant_id,
     unit_type,
     unit_id
 )
 select
     experimentid as experiment_id,
     ExperimentVariantID as variant_id,
     'account_uuid' AS unit_type,
     accountid AS unit_id
 from `tab.spring26_final`
 WHERE ExperimentVariantID in ('a','b','c')
 and userType= 'ACC';