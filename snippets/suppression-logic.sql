   /******************************************************************************
    Black Friday OO 2025
    https://confluence-act.corp.nortonlifelock.com/pages/viewpage.action?pageId=416237710&spaceKey=CNS&title=2025_10_23%2BAvast%2BBlackFriday-CyberMonday%2BEmail%2BCampaign
    -------------------------------------------------------------------------------
    USAGE EXAMPLE
    --------------------
    select * from `ppp-mailops-dls-b0.black_friday.avast_bf2025_final`
    -------------------------------------------------------------------------------
    CHANGE HISTORY
    --------------------
    Version   Date                Author            Description
    --        ----                ------            -----------
    1.0       2025-11-06         uliana.kolomiiets  New initiative
    ******************************************************************************/




-- +-------------------------------------------------------------------------+
-- | 1. SUPPRESSION FOR PAID USERS (ACTIVE, EXPIRED, TRIAL)
-- +-------------------------------------------------------------------------+
DROP TABLE IF EXISTS `tab.bf2025_sup`;

CREATE TABLE `tab.bf2025_sup` AS

with supression as (
--suppression 30D after purchase
    SELECT DISTINCT customer_email
    FROM `tab.order_item`
    WHERE current_date <= order_date + INTERVAL 30 DAY
UNION ALL
-- suppression of paid customers 
    SELECT DISTINCT customer_email
    from `tab.order_item`
    WHERE current_date >= expiration_date - INTERVAL 75 DAY --75 days before expiration
      AND current_date <= expiration_date + INTERVAL 5 DAY --5 days post expiration
UNION ALL
-- suppression of restricted GEOs
    SELECT DISTINCT customer_email
    FROM`tab.order_item`
    WHERE substring(locale, 4) IN ('CU', 'IR', 'KP', 'SD', 'RU', 'UA', 'BY', 'SY')
UNION ALL    
-- suppression of active trial customers (preauth-trial)
    SELECT DISTINCT customer_email
    from `tab.order_item`
    WHERE product_trial_type = 'D'
    AND  current_date between order_date and date_add(order_date, INTERVAL product_trial_length day) 
-- suppression of ultimate Avast (A1 customers for AVAST) --
UNION ALL
SELECT DISTINCT customer_email
FROM `tab.order_item`
WHERE (
    --lower(product_family_group) like ('avast ultimate%') or 
    business_source_name = 'Avast One' 
    or lower(product_family_group) like ('avast%bundle%')
      )
  AND current_date <= expiration_date
  -- suppression of active A1F
UNION ALL
SELECT DISTINCT customer_email
from `tab.order_item`
WHERE flag_avast_one_modular = TRUE
  AND current_date <= expiration_date
  --- suppression of Indian VPN
UNION ALL
select distinct customer_email
from `tab.order_item`
where business_source_name = 'VPN' and substring(locale, 4) IN ('IN') 
)

SELECT DISTINCT customer_email
FROM supression
;


