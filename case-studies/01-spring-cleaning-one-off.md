# Spring Cleaning One-Off Campaign

## Context

Each year, the company runs a seasonal "Spring Cleaning" promotion to re-engage lapsed users and drive renewals among free-tier customers approaching key lifecycle milestones. The campaign targets multiple product lines and requires careful coordination of audience cohorts, suppression rules, and send timing.

## Goal

Deliver a one-off promotional email blast to eligible users segmented into openers and non-openers from a prior campaign, with distinct messaging and timing for each cohort — while respecting all existing suppression and frequency rules.

## My Role

I owned the full targeting lifecycle: translating the campaign brief into audience logic, writing the SQL extraction, applying suppressions, validating counts, and handing off the final audience file for send.

## Audience Logic

- **Inclusion:** Users on free or expired plans, within specific product families, who had not converted in the prior 90 days
- **Segmentation:** Split into "prior openers" (engaged) vs. "non-openers" based on historical email interaction
- **Suppression:** Excluded users who:
  - Had received a campaign email in the past 7 days (frequency cap)
  - Were flagged as do-not-contact or had pending DSR requests
  - Had already converted since the campaign was planned
  - Were in active A/B test holdout groups for other experiments

## Approach

1. Reviewed the prior year's Spring Cleaning targeting to understand baseline logic
2. Identified what changed: new product tiers, updated suppression sources, different cohort definitions
3. Built the extraction query iteratively — starting with broad eligibility, then layering suppressions
4. Coordinated with the campaign manager on expected volumes and segment splits
5. Ran QA checks comparing my counts against historical baselines

## Sanitized SQL / Logic Example

```sql
WITH eligible_users AS (
  SELECT
    user_id,
    product_family,
    license_status,
    license_expiry_date
  FROM users.licenses
  WHERE license_status IN ('free', 'expired')
    AND product_family IN ('security', 'performance', 'privacy')
    AND license_expiry_date < DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
),

prior_engagement AS (
  SELECT
    user_id,
    CASE
      WHEN open_count > 0 THEN 'opener'
      ELSE 'non_opener'
    END AS engagement_segment
  FROM campaign_history.interactions
  WHERE campaign_name = 'spring_cleaning_prior_year'
),

suppressed AS (
  SELECT user_id
  FROM campaign_history.sends
  WHERE send_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  UNION DISTINCT
  SELECT user_id
  FROM users.suppression_list
  WHERE suppression_active = TRUE
)

SELECT
  e.user_id,
  e.product_family,
  p.engagement_segment
FROM eligible_users e
LEFT JOIN prior_engagement p ON e.user_id = p.user_id
WHERE e.user_id NOT IN (SELECT user_id FROM suppressed)
```

## QA and Validation

- Compared total eligible counts against prior year (~15% growth expected due to user base expansion)
- Verified suppression rates were within normal range (8-12% of eligible base)
- Cross-checked that no user appeared in both opener and non-opener segments
- Confirmed zero overlap with active experiment holdout populations
- Ran a sample check on 100 random users to verify suppression logic correctness

## Outcome

Campaign launched on schedule with ~200K targeted users split across two cohorts. The segmented approach (openers vs. non-openers) allowed different subject lines and CTAs, contributing to a higher overall open rate compared to the unsegmented prior year run.

## What This Demonstrates

- End-to-end campaign targeting ownership from brief to send
- Iterative SQL development with layered suppression logic
- QA discipline: baseline comparison, overlap checks, sample validation
- Cross-functional coordination with campaign management
