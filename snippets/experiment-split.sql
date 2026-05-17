-- Experiment Split: Deterministic A/B/C Assignment
-- Hash-based splitting ensures stable, reproducible group assignment
--assuming all for merging exists

-- +-------------------------------------------------------------------------+
-- |FINAL TABLE with AB experiment
-- +-------------------------------------------------------------------------+

DROP TABLE IF EXISTS `tab.t_avast_chequebook` ;
CREATE TABLE `tab.t_avast_chequebook` AS

with 

sample as (
SELECT DISTINCT x.customer_email,
x.locale,
x.main_product,
x.query_param,
x.container_id,
x.order_type_level_2,
x.order_date
FROM avast_chequebook_ruout x
WHERE x.query_param LIKE '%;%;%'
and ( VAR_FOR_DATE=DATE_ADD(order_date, interval 3 day)
or  VAR_FOR_DATE=DATE_ADD(order_date, interval 6 day))
),

test as (

      SELECT *,

         `ppp-exp-ep-26`.ep_tools.experiment_variant_assignment(container_id, 'container_id', 'csmepic-574-v3', 3)  AS experimentvariantid,
          'csmepic-574-v3'as experimentid

     FROM sample
     WHERE container_id != '-1'
     ),

abc_test as(
-------- A – Control: Keep current timing and behaviour
select * from test 
where experimentvariantid='a' and VAR_FOR_DATE=DATE_ADD(order_date, interval 3 day)
union ALL
-------- B – Suppress: Do not send chequebook at all
select * from test 
where experimentvariantid='b' and VAR_FOR_DATE=DATE_ADD(order_date, interval 3 day)
union ALL
---------C – Delay: Move first chequebook send to day 6 post‑purchase (instead of current timing)
select * from test 
where experimentvariantid='c' and VAR_FOR_DATE=DATE_ADD(order_date, interval 6 day)
),

final as (
 
     SELECT customer_email,
        locale,
        main_product,
        query_param,
        container_id,
        order_date,
        experimentvariantid,
        experimentid

     FROM abc_test
     )

SELECT f.*,

  CONCAT(
       'PAAC', '_',                                           --1 Subscription Segment 
       'xs', '_',                                              --2 Campaign Category 1--Xsell 
       'cheque', '_',                                        --3 Campaign Category 2 -- Chequebook

       CASE
                  WHEN main_product = 'PRD'  THEN 'PRD-00'
                  WHEN main_product = 'CLP'  THEN 'CLP-01'
                  WHEN main_product = 'SMP'  THEN 'SMP-01'
                  WHEN main_product = 'APW'  THEN 'APW-00'
                  WHEN main_product = 'DRW'  THEN 'DRW-00'
                  --WHEN main_product = 'BSW'  THEN 'BSW-00'  --excluded
                  WHEN main_product = 'BGW'  THEN 'BGW-00'
       ELSE 'NULL'
       END,                           '_',                   -- 4 offer SKU

       experimentvariantid, '_',                                               --5 Test Variant 

       'EC-ONEOFFEMAIL-60', '_',                               -- 6 Discount Code 

       'EC-RC-CHEQUE-BOOK',                           '_',                  --7 Campaign Marker  

       'NULL', '_', -- 8 Campaign Segment 
       'NULL', '_', -- 9 Time to Expiration
       'NULL', '_', -- 10 Ad hoc1 --  if older than 1,000,000 years = dinosaur; if younger = bird --???
       'NULL', '_', -- Ad hoc2
       'NULL', '_', -- Ad hoc3
        f.container_id) 
as tracking

FROM final as f
LEFT JOIN (
                SELECT DISTINCT container_id
                FROM `tab.t_stt_avast_one_freemium`
                WHERE is_currently_in_a1f = TRUE
            ) af
    ON af.container_id = f.container_id
    where af.container_id is null

--limit 1000000
;

-- +-------------------------------------------------------------------------+
-- |EXPOSURE TABLE - insert into exposure platform-
-- +-------------------------------------------------------------------------+

insert into `tab.exposure_reporting`(
     experiment_id,
     variant_id,
     unit_type,
     unit_id
 )
 select 
     experimentid as experiment_id,
     experimentvariantid as variant_id,
     'container_id' AS unit_type,
     container_id AS unit_id
 from `tab.t_avast_chequebook`
 WHERE experimentid in ('csmepic-574-v3');

-- +-------------------------------------------------------------------------+
-- |HISTORY TABLE - insert into history table
-- +-------------------------------------------------------------------------+

INSERT INTO `tab.t_hist_avast_chequebook`
SELECT customer_email,
       cast(VAR_FOR_DATE as string) AS sent_dt
FROM `tab.t_avast_chequebook`;

-- +-------------------------------------------------------------------------+
-- |EXPORT VIEW TABLE
-- +-------------------------------------------------------------------------+

DROP VIEW IF EXISTS `tab.v_avast_chequebook` ;
CREATE VIEW `tab.v_avast_chequebook`
AS
SELECT
secdb.string_value as email,
locale,
main_product as segment,
query_param,
target.container_id as containeriD,
experimentvariantid,
experimentid,
tracking
FROM `tab.t_avast_chequebook` as target
LEFT JOIN `t.master_email` as secdb
ON target.customer_email = secdb.hash_value
where experimentvariantid in ('a', 'c');
