# DSR Deletion Request Spike — Investigation

## Context

The compliance team flagged an unusual spike in Data Subject Requests (DSRs) — specifically "right to be deleted" requests — starting mid-March. The volume was significantly above the normal baseline and there was concern it could indicate a systemic issue: a broken unsubscribe flow, a misdirected link, a UX problem, or an external event driving mass opt-outs.

The targeting and email operations team was pulled in because the spike correlated with recent campaign sends, making email a prime suspect.

## Goal

Investigate the root cause of the DSR spike by analyzing the timing, user profiles, and campaign interaction patterns of affected users — and determine whether email operations needed to take corrective action (pause sends, fix a flow, update suppression logic).

## My Role

I led the data investigation from the email operations side: querying DSR request data, correlating it with campaign history and user behavior, and producing findings that either confirmed or ruled out email as the trigger.

## Audience Logic

This wasn't a traditional audience build — it was forensic analysis. But the logic followed a similar pattern:

- **Population:** All users who submitted deletion requests in the spike window
- **Correlation dimensions:**
  - Campaign sends received in the 7 days prior to request
  - Email link clicks (especially unsubscribe/preference center)
  - Product family and license status
  - Geography and language
  - Signup recency (were these new users?)
- **Comparison group:** DSR requestors from the same period in prior months (baseline)

## Approach

1. Pulled DSR request volumes by day to confirm the spike pattern and exact start date
2. Joined DSR requestors against campaign send history — did they all receive the same campaign?
3. Checked click-through data — were users clicking unsubscribe but landing on a deletion flow instead?
4. Segmented by geography and product — was it concentrated or diffuse?
5. Compared user profiles against baseline DSR requestors — any demographic shift?
6. Investigated whether a specific email template had a broken or misleading link
7. Shared findings with compliance and product teams

## Sanitized SQL / Logic Example

```sql
-- Identify the spike pattern
WITH daily_dsr AS (
  SELECT
    DATE(request_timestamp) AS request_date,
    request_type,
    COUNT(*) AS request_count
  FROM compliance.dsr_requests
  WHERE request_type = 'deletion'
    AND request_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY 1, 2
),

-- Correlate spike-period requestors with recent campaigns
spike_users AS (
  SELECT user_id, request_timestamp
  FROM compliance.dsr_requests
  WHERE request_type = 'deletion'
    AND DATE(request_timestamp) BETWEEN '2026-03-11' AND '2026-03-25'
),

campaign_correlation AS (
  SELECT
    s.user_id,
    c.campaign_id,
    c.campaign_name,
    c.send_date,
    DATE_DIFF(DATE(s.request_timestamp), c.send_date, DAY) AS days_between_send_and_dsr
  FROM spike_users s
  INNER JOIN campaign_history.sends c
    ON s.user_id = c.user_id
    AND c.send_date BETWEEN DATE_SUB(DATE(s.request_timestamp), INTERVAL 7 DAY)
                        AND DATE(s.request_timestamp)
)

-- Which campaigns are over-represented?
SELECT
  campaign_name,
  COUNT(DISTINCT user_id) AS dsr_users_who_received,
  AVG(days_between_send_and_dsr) AS avg_days_to_dsr
FROM campaign_correlation
GROUP BY campaign_name
ORDER BY dsr_users_who_received DESC
LIMIT 10
```

## QA and Validation

- Confirmed the spike was real (not a reporting artifact or duplicate submissions)
- Validated that campaign send dates preceded DSR requests (not the reverse)
- Cross-checked findings with the product team's own UX analytics on the preference center
- Verified that the baseline comparison period was representative (no holidays or other anomalies)

## Outcome

Investigation identified that the spike correlated strongly with a specific campaign that contained a preference center link whose landing page had been recently redesigned. The new design made the "delete my account" option more prominent than intended, leading users who wanted to unsubscribe from emails to inadvertently submit full deletion requests. Findings were shared with the product team, who reverted the UX change, and the compliance team, who paused processing of flagged requests pending user re-confirmation.

## What This Demonstrates

- Investigative data analysis under time pressure (compliance urgency)
- Ability to correlate across systems: email sends, user actions, compliance events
- Hypothesis-driven approach: systematically testing and ruling out causes
- Cross-functional collaboration: email ops, compliance, product/UX
- Translating data findings into actionable recommendations
