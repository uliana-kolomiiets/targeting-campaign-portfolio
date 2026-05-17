# Einstein Send Time Optimization (STO) Rollout

## Context

After a successful pilot test, Einstein Send Time Optimization — which uses ML-predicted optimal send times per user instead of a fixed blast time — showed a statistically significant lift in open rates for a key email program. The decision was made to roll STO out to the full audience for that program.

## Goal

Operationalize the transition from a fixed send time to Einstein STO for the full-scale email program, ensuring targeting markers were correctly updated, downstream systems were aligned, and post-rollout metrics confirmed the expected behavior.

## My Role

I owned the targeting-side changes required for the rollout: updating the audience extraction logic to include STO-compatible markers, removing test-period split logic, coordinating the cutover with the email platform team, and monitoring post-launch data to confirm correct behavior.

## Audience Logic

- **Previous state:** Audience was split into STO-test and control groups via experiment assignment flags
- **Rollout change:** Remove the test/control split; apply STO to 100% of the eligible audience
- **Markers updated:**
  - STO eligibility flag set to TRUE for all qualifying users
  - Removed experiment group assignment column
  - Added fallback logic for users with insufficient engagement history (STO needs behavioral data to predict)
- **Maintained:** All existing suppressions, frequency caps, and eligibility filters unchanged

## Approach

1. Reviewed the test-period targeting code to understand what needed to change vs. stay
2. Identified the specific markers and flags that downstream systems used to trigger STO
3. Updated the extraction query: removed split logic, expanded STO flag to full population
4. Added fallback handling for "cold" users (new signups with no prior engagement data)
5. Ran parallel extractions (old logic vs. new) to verify the only difference was the STO expansion
6. Coordinated timing with the platform team for the cutover send
7. Monitored first sends to confirm STO was activating correctly

## Sanitized SQL / Logic Example

```sql
-- Previous: test-period split
-- CASE WHEN MOD(hash, 2) = 0 THEN 'sto_test' ELSE 'control' END

-- Rollout: full STO with fallback for cold users
WITH audience AS (
  SELECT
    user_id,
    email_address,
    engagement_score,
    last_open_date
  FROM targeting.eligible_base
  WHERE program = 'monthly_renewal_reminder'
    AND suppressed = FALSE
)

SELECT
  user_id,
  email_address,
  TRUE AS sto_enabled,
  CASE
    WHEN last_open_date IS NULL
      OR last_open_date < DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
    THEN 'fallback_default_time'
    ELSE 'sto_predicted'
  END AS send_time_method
FROM audience
```

## QA and Validation

- **Diff check:** Compared old extraction output (minus split columns) against new extraction — user sets matched exactly
- **Marker validation:** Confirmed all users now had `sto_enabled = TRUE` (previously ~50%)
- **Fallback coverage:** Verified fallback logic captured ~12% of audience (users with no recent engagement data)
- **Post-send monitoring:**
  - Confirmed STO was distributing sends across a 24-hour window (not concentrated at one time)
  - Checked delivery rates were consistent with pre-rollout baseline
  - Monitored open rate trajectory over first week to confirm lift was sustained at full scale

## Outcome

Rollout completed successfully. The full-scale STO deployment maintained the open rate lift observed during testing (~3-5% relative improvement). The fallback logic for cold users prevented delivery issues that could have occurred if STO tried to predict on insufficient data.

## What This Demonstrates

- Ability to operationalize experiment results into production workflows
- Careful transition management: understanding what changes vs. what stays
- Edge case handling (cold users without engagement history)
- Post-rollout validation and monitoring discipline
- Cross-team coordination for system-level changes
