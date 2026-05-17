# Airflow vs. SFMC Reconciliation — Cost Optimization

## Context

Targeting queries for email campaigns run as scheduled jobs in Airflow (orchestrating BigQuery extractions). Once a campaign is stopped or paused on the sendout side (Salesforce Marketing Cloud), there's no automatic mechanism to stop the corresponding Airflow job. Over time, this disconnect accumulates: Airflow jobs keep running daily — consuming BigQuery compute — for campaigns that no longer send emails.

Nobody was actively monitoring this gap.

## Goal

Audit all running Airflow jobs against active SFMC campaigns, identify orphaned jobs (running on Airflow but not sending in SFMC), and stop them to reduce unnecessary BigQuery costs.

## My Role

I initiated and executed this audit end-to-end: extracted the list of running Airflow DAGs, cross-referenced against active SFMC sends, identified the discrepancies, validated which jobs were safe to stop, coordinated the shutdowns, and quantified the cost savings.

## Approach

1. Pulled a list of all currently scheduled/running Airflow DAGs related to email targeting
2. Pulled a list of all active campaign sends in SFMC (campaigns that actually delivered emails in the past 30 days)
3. Matched them by campaign identifier / tracking code
4. Categorized each Airflow job:
   - **Active:** has a matching running SFMC campaign → keep
   - **Orphaned:** no matching SFMC send in 30+ days → candidate for shutdown
   - **Unclear:** needs investigation (e.g., feeds multiple campaigns, pre-scheduled for future launch)
5. Validated orphaned jobs with campaign owners to confirm they're truly no longer needed
6. Stopped confirmed orphaned jobs
7. Documented results and calculated cost savings

## Sanitized Logic Example

```sql
-- Cross-reference: which Airflow jobs have no corresponding SFMC activity?
WITH airflow_jobs AS (
  SELECT
    dag_id,
    campaign_identifier,
    schedule_interval,
    last_run_date,
    status
  FROM orchestration.airflow_dags
  WHERE dag_category = 'email_targeting'
    AND status = 'active'
),

sfmc_active_sends AS (
  SELECT DISTINCT
    campaign_identifier,
    MAX(send_date) AS last_send_date
  FROM sendout.campaign_sends
  WHERE send_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND send_status = 'delivered'
  GROUP BY campaign_identifier
)

SELECT
  a.dag_id,
  a.campaign_identifier,
  a.schedule_interval,
  a.last_run_date,
  s.last_send_date,
  CASE
    WHEN s.campaign_identifier IS NULL THEN 'ORPHANED - no SFMC send in 30+ days'
    ELSE 'ACTIVE - still sending'
  END AS status_recommendation
FROM airflow_jobs a
LEFT JOIN sfmc_active_sends s
  ON a.campaign_identifier = s.campaign_identifier
ORDER BY s.last_send_date NULLS FIRST
```

## QA and Validation

- Verified each "orphaned" job against SFMC campaign status (confirmed stopped/paused, not just a temporary gap)
- Checked with campaign owners for edge cases: seasonal campaigns paused but planned to restart, campaigns in testing phase
- Confirmed no job was a dependency for other active pipelines (some DAGs feed shared tables)
- Calculated per-job BigQuery cost from Airflow logs and billing data

## Outcome

| Metric | Value |
|--------|-------|
| Total Airflow jobs audited | ~50+ |
| Orphaned jobs identified | ~20+ |
| Jobs safely stopped | ~20 |
| **Monthly cost savings** | **~$2,000 USD** |
| Annual projected savings | ~$24,000 USD |

The reconciliation spreadsheet was shared with the team and became a reference for ongoing maintenance — preventing future cost drift as campaigns are stopped.

## What This Demonstrates

- Initiative: identified a cost leak nobody was monitoring and fixed it
- Cross-system thinking: connecting orchestration (Airflow) with delivery (SFMC) to find gaps
- Quantifiable business impact: $2,000/month in direct cost savings
- Operational hygiene: preventing resource waste through systematic reconciliation
- Documentation: results shared and trackable for ongoing governance
