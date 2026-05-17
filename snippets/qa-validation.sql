-- QA Validation: Pre-Send Checks
-- Standard validation queries run before any campaign handoff

-- 1. Total count and segment breakdown
SELECT
  'total_audience' AS check_type,
  COUNT(DISTINCT user_id) AS count
FROM targeting.final_audience
WHERE campaign_id = @campaign_id

UNION ALL

SELECT
  CONCAT('segment_', segment_name) AS check_type,
  COUNT(DISTINCT user_id) AS count
FROM targeting.final_audience
WHERE campaign_id = @campaign_id
GROUP BY segment_name;


-- 2. Duplicate check: no user should appear more than once
SELECT
  user_id,
  COUNT(*) AS occurrences
FROM targeting.final_audience
WHERE campaign_id = @campaign_id
GROUP BY user_id
HAVING COUNT(*) > 1;


-- 3. Overlap check against recent sends (catch suppression failures)
SELECT
  COUNT(DISTINCT a.user_id) AS overlap_count,
  ROUND(COUNT(DISTINCT a.user_id) * 100.0 / (
    SELECT COUNT(DISTINCT user_id)
    FROM targeting.final_audience
    WHERE campaign_id = @campaign_id
  ), 2) AS overlap_pct
FROM targeting.final_audience a
INNER JOIN campaign_history.sends s
  ON a.user_id = s.user_id
WHERE a.campaign_id = @campaign_id
  AND s.send_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY);


-- 4. Comparison to baseline: does this count make sense?
SELECT
  @campaign_id AS current_campaign,
  curr.total AS current_count,
  hist.avg_count AS historical_avg,
  ROUND((curr.total - hist.avg_count) / hist.avg_count * 100, 1) AS pct_deviation
FROM (
  SELECT COUNT(DISTINCT user_id) AS total
  FROM targeting.final_audience
  WHERE campaign_id = @campaign_id
) curr
CROSS JOIN (
  SELECT AVG(audience_size) AS avg_count
  FROM campaign_history.campaign_metadata
  WHERE program = @campaign_program
    AND send_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
) hist;


-- 5. Null/invalid email check
SELECT
  COUNT(*) AS invalid_records,
  SUM(CASE WHEN email_address IS NULL THEN 1 ELSE 0 END) AS null_email,
  SUM(CASE WHEN NOT REGEXP_CONTAINS(email_address, r'^[^@]+@[^@]+\.[^@]+$') THEN 1 ELSE 0 END) AS malformed_email
FROM targeting.final_audience
WHERE campaign_id = @campaign_id;
