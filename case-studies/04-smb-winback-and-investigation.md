# SMB Winback Campaign & Subscription Investigation

## Context

A segment of small business (SMB) customers had licenses that showed as expired in the system, but the circumstances were unusual: some had been manually cancelled by internal support operations, others had subscription states that didn't match expected lifecycle patterns. Before building a winback campaign for this segment, I needed to investigate the data to understand who was legitimately targetable vs. who had data integrity issues.

## Goal

1. **Investigate** the expired-license population to separate genuinely lapsed SMB customers from those with anomalous subscription states
2. **Build targeting** for a winback campaign addressing the legitimately lapsed segment
3. **Document** the data constraints and edge cases found during investigation for the team

## My Role

I owned both the investigation and the targeting build. This meant acting as both analyst (understanding what happened to these subscriptions) and targeting specialist (building a clean, defensible audience from a messy data situation).

## Audience Logic

- **Initial population:** SMB customers with expired licenses in specific product families
- **Investigation findings:**
  - ~15% had licenses cancelled via internal tools (support/ops intervention) — not natural churn
  - ~5% had conflicting states: expired in one system, active in another (sync issues)
  - Remaining ~80% were genuinely lapsed through natural expiry
- **Final targeting:**
  - Include: Naturally expired SMB licenses, 30-180 days past expiry
  - Exclude: Manually cancelled (different re-engagement path needed)
  - Exclude: Conflicting-state users (flagged for ops team to resolve first)
  - Exclude: Users who had already re-purchased on a different license key
  - Standard suppressions: frequency caps, do-not-contact, active experiments

## Approach

1. Started with the broad expired-SMB population — immediately noticed count was higher than expected
2. Investigated: joined license events table to understand *why* each license expired
3. Discovered the manual-cancellation pattern — these users had `cancellation_source = 'internal_tool'`
4. Found the sync discrepancy by cross-referencing two systems' subscription states
5. Documented findings for the ops and product teams (separate from targeting work)
6. Built the final targeting query using only the "clean" naturally-expired segment
7. Applied additional time windows and re-purchase checks to ensure relevance

## Sanitized SQL / Logic Example

```sql
-- Investigation: understanding expiry reasons
WITH expired_smb AS (
  SELECT
    user_id,
    license_id,
    product_family,
    expiry_date,
    cancellation_source,
    cancellation_reason
  FROM licenses.smb_subscriptions
  WHERE license_status = 'expired'
    AND segment = 'smb'
    AND expiry_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
),

-- Check for state conflicts between systems
state_conflicts AS (
  SELECT e.user_id
  FROM expired_smb e
  INNER JOIN billing.active_subscriptions b
    ON e.user_id = b.user_id
    AND e.product_family = b.product_family
  WHERE b.status = 'active'
),

-- Check for re-purchases on different license keys
repurchased AS (
  SELECT DISTINCT user_id
  FROM licenses.smb_subscriptions
  WHERE license_status = 'active'
    AND purchase_date > expiry_date
)

-- Final winback audience
SELECT
  e.user_id,
  e.product_family,
  e.expiry_date,
  DATE_DIFF(CURRENT_DATE(), e.expiry_date, DAY) AS days_since_expiry
FROM expired_smb e
WHERE e.cancellation_source = 'natural_expiry'
  AND e.user_id NOT IN (SELECT user_id FROM state_conflicts)
  AND e.user_id NOT IN (SELECT user_id FROM repurchased)
  AND DATE_DIFF(CURRENT_DATE(), e.expiry_date, DAY) BETWEEN 30 AND 180
```

## QA and Validation

- Verified the cancellation_source breakdown matched expectations from ops team knowledge
- Confirmed state-conflict users were flagged and routed to ops (not silently dropped)
- Checked that re-purchase detection worked across license key changes (not just same-key renewals)
- Validated final audience size against business team's estimate of addressable SMB churn
- Ensured no overlap with existing SMB retention programs

## Outcome

The investigation surfaced a data quality issue that affected ~20% of the initial population — preventing a campaign that would have reached users inappropriately (manually cancelled or in conflicting states). The ops team used the findings to initiate a state-reconciliation project. The clean winback campaign targeted the remaining 80% and launched successfully.

## What This Demonstrates

- Data investigation skills: not just building what's asked, but questioning whether the data supports it
- Ability to work with messy, real-world data and carve out a defensible audience
- Translating ambiguity into clear inclusion/exclusion rules
- Cross-functional impact: investigation findings informed ops and product decisions beyond just the campaign
- Balancing speed (campaign had a deadline) with rigor (don't target the wrong people)
