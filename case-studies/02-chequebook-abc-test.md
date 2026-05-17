# Chequebook ABC Test

## Context

New customers were receiving a high volume of onboarding and engagement emails in their first weeks after signup. There was concern that this "email overload" during early lifecycle was causing fatigue, leading to higher unsubscribe rates and lower long-term engagement. The team wanted to test whether reducing or delaying certain early-life emails would improve retention metrics.

## Goal

Design and implement an A/B/C test to measure the impact of different email cadence strategies on early-lifecycle engagement:
- **Group A (Control):** Existing email cadence — all scheduled touchpoints sent as normal
- **Group B (Reduced):** Remove one specific early-life email from the sequence
- **Group C (Delayed):** Keep all emails but delay the contested touchpoint by several days

## My Role

I owned the targeting and split logic: designing how users would be randomly assigned to test groups, ensuring clean separation between variants, building the exclusion rules, and validating that the split was statistically sound before launch.

## Audience Logic

- **Eligibility:** New signups within a defined product line, entering the onboarding flow in the test period
- **Assignment:** Deterministic hash-based split on user ID to ensure:
  - Even distribution across three groups
  - No user could drift between groups on re-query
  - Reproducible assignment without storing state
- **Exclusions:**
  - Users already mid-sequence from a prior cohort
  - Users in other active experiments (to avoid interaction effects)
  - Enterprise/B2B accounts (different lifecycle)

## Approach

1. Defined the test population window and eligibility criteria with the lifecycle team
2. Designed a hash-based split mechanism that would be stable across multiple query runs
3. Built the assignment query and verified distribution uniformity
4. Created suppression markers so downstream systems knew which group each user belonged to
5. Coordinated with the email platform team to wire variant logic into send flows

## Sanitized SQL / Logic Example

```sql
WITH test_eligible AS (
  SELECT
    user_id,
    signup_date,
    product_tier
  FROM users.registrations
  WHERE signup_date BETWEEN '2025-09-01' AND '2025-09-30'
    AND product_tier = 'consumer_standard'
    AND user_id NOT IN (
      SELECT user_id FROM experiments.active_assignments
      WHERE experiment_status = 'running'
    )
),

assigned AS (
  SELECT
    user_id,
    signup_date,
    CASE
      WHEN MOD(ABS(FARM_FINGERPRINT(CAST(user_id AS STRING))), 3) = 0 THEN 'control'
      WHEN MOD(ABS(FARM_FINGERPRINT(CAST(user_id AS STRING))), 3) = 1 THEN 'reduced'
      WHEN MOD(ABS(FARM_FINGERPRINT(CAST(user_id AS STRING))), 3) = 2 THEN 'delayed'
    END AS test_group
  FROM test_eligible
)

SELECT
  test_group,
  COUNT(*) AS user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM assigned
GROUP BY test_group
```

## QA and Validation

- Verified group sizes were within 0.5% of equal thirds (expected with hash-based assignment)
- Confirmed assignment stability: re-running the query on the same population produced identical results
- Checked that no user appeared in multiple groups
- Validated exclusion logic: zero overlap with other running experiments
- Ran a time-series check to ensure daily signup volume was evenly distributed across groups (no date bias)

## Outcome

Test launched cleanly with balanced groups. The experiment ran for its planned duration, providing statistically significant results that informed the team's decision on optimal early-life email cadence. The reduced-cadence variant showed improved 30-day retention, leading to a permanent change in the onboarding sequence.

## What This Demonstrates

- Experiment design: translating a hypothesis into a measurable A/B/C structure
- Deterministic assignment logic that ensures clean, reproducible splits
- Awareness of experiment interaction effects and proper isolation
- QA rigor on statistical properties of the test setup (balance, stability, exclusivity)
