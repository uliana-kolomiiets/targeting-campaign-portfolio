# Cross-Check Data Legitimacy

## Context

Before a major campaign send, a routine QA check revealed that certain audience counts looked anomalous — higher than expected for specific segments. Rather than proceeding with the send or simply trimming the numbers, the team needed to verify whether the underlying data was legitimate or whether a data pipeline issue had introduced phantom/duplicate/stale records into the targeting tables.

## Goal

Validate the legitimacy of records in the targeting pipeline by cross-referencing against authoritative source systems, identifying any records that shouldn't exist, and ensuring the campaign audience only contained real, active, contactable users.

## My Role

I designed and executed the cross-check investigation: building validation queries that compared targeting data against source-of-truth systems, quantifying the discrepancy, identifying root causes, and producing a clean audience after filtering out illegitimate records.

## Audience Logic

This was a data quality investigation layered on top of an existing audience:

- **Starting point:** Pre-built campaign audience that showed unexpected inflation
- **Validation sources:**
  - Master user registry (does this user_id actually exist?)
  - Email deliverability table (is this email address valid and not hard-bounced?)
  - License system (does this user actually hold the product/tier we think?)
  - Activity logs (has this user shown any sign of life in the past year?)
- **Classification:**
  - Legitimate: passes all cross-checks
  - Stale: user exists but hasn't been active and license state is outdated
  - Orphaned: user_id exists in targeting table but not in master registry
  - Duplicate: same user appearing multiple times due to join fanout

## Approach

1. Quantified the anomaly: which segments were inflated and by how much
2. Hypothesized causes: pipeline delay, join fanout, stale snapshot, source system migration
3. Built cross-reference queries against each authoritative source
4. Categorized every record in the inflated segment as legitimate, stale, orphaned, or duplicate
5. Traced orphaned records back to their origin — found a pipeline that hadn't been updated after a user migration
6. Produced a cleaned audience and documented the pipeline fix needed
7. Added a recurring validation check to catch similar issues proactively

## Sanitized SQL / Logic Example

```sql
-- Cross-reference targeting data against authoritative sources
WITH campaign_audience AS (
  SELECT
    user_id,
    email_address,
    product_family,
    license_status
  FROM targeting.final_audience
  WHERE campaign_id = @campaign_id
),

-- Check 1: Does user exist in master registry?
registry_check AS (
  SELECT
    a.user_id,
    CASE WHEN r.user_id IS NOT NULL THEN TRUE ELSE FALSE END AS exists_in_registry
  FROM campaign_audience a
  LEFT JOIN users.master_registry r ON a.user_id = r.user_id
),

-- Check 2: Is the email actually deliverable?
deliverability_check AS (
  SELECT
    a.user_id,
    a.email_address,
    CASE
      WHEN d.status = 'hard_bounce' THEN 'bounced'
      WHEN d.email_address IS NULL THEN 'unknown'
      ELSE 'deliverable'
    END AS email_status
  FROM campaign_audience a
  LEFT JOIN email.deliverability d ON a.email_address = d.email_address
),

-- Check 3: Does license state match source of truth?
license_check AS (
  SELECT
    a.user_id,
    a.license_status AS targeting_status,
    l.license_status AS source_status,
    CASE
      WHEN l.user_id IS NULL THEN 'no_license_found'
      WHEN a.license_status != l.license_status THEN 'status_mismatch'
      ELSE 'matches'
    END AS license_validity
  FROM campaign_audience a
  LEFT JOIN licenses.current_state l
    ON a.user_id = l.user_id
    AND a.product_family = l.product_family
),

-- Check 4: Any sign of life?
activity_check AS (
  SELECT
    a.user_id,
    MAX(act.event_date) AS last_activity,
    CASE
      WHEN MAX(act.event_date) IS NULL THEN 'no_activity_ever'
      WHEN MAX(act.event_date) < DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY) THEN 'inactive_1yr'
      ELSE 'active'
    END AS activity_status
  FROM campaign_audience a
  LEFT JOIN product.activity_log act ON a.user_id = act.user_id
  GROUP BY a.user_id
)

-- Summary of data quality issues
SELECT
  CASE
    WHEN rc.exists_in_registry = FALSE THEN 'orphaned_record'
    WHEN dc.email_status = 'bounced' THEN 'undeliverable'
    WHEN lc.license_validity = 'status_mismatch' THEN 'stale_license_state'
    WHEN ac.activity_status = 'no_activity_ever' THEN 'phantom_user'
    ELSE 'legitimate'
  END AS record_classification,
  COUNT(*) AS record_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_audience
FROM campaign_audience a
JOIN registry_check rc ON a.user_id = rc.user_id
JOIN deliverability_check dc ON a.user_id = dc.user_id
JOIN license_check lc ON a.user_id = lc.user_id
JOIN activity_check ac ON a.user_id = ac.user_id
GROUP BY 1
ORDER BY record_count DESC
```

## QA and Validation

- Verified that orphaned records traced to a specific pipeline that hadn't been updated post-migration
- Confirmed duplicate records were caused by a join fanout on multi-product users (1:many relationship not properly handled)
- Checked that "stale" records genuinely had outdated states vs. source system
- Validated the cleaned audience matched expected volumes after removing illegitimate records
- Tested the new recurring validation check against a known-good historical extraction

## Outcome

Investigation found that ~12% of the audience contained illegitimate records: 7% orphaned (pipeline issue), 3% duplicates (join fanout), 2% stale license states. The campaign was paused, audience cleaned, and sent with accurate targeting. The pipeline team fixed the root cause, and I implemented a recurring validation query that runs before every major send as a quality gate.

## What This Demonstrates

- Data quality instinct: questioning anomalous numbers rather than accepting them
- Systematic validation against multiple authoritative sources
- Root cause analysis: tracing bad data back to its origin in the pipeline
- Proactive prevention: turning a one-time investigation into a recurring quality check
- Protecting campaign integrity and sender reputation by refusing to send to bad data
