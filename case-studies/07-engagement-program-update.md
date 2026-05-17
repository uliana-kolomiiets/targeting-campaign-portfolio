# Engagement Program Update

## Context

An existing always-on engagement email program had been running for over a year without significant updates to its targeting logic. During that time, the product had introduced new tiers, the user base composition had shifted, and several new suppression sources had come online. The program's audience definition was becoming stale — it was over-including some users and missing others who should qualify.

## Goal

Audit and update the engagement program's targeting logic to reflect current product structure, user base reality, and suppression requirements — without disrupting the live program or causing a jarring volume spike/drop for recipients.

## My Role

I owned the targeting refresh: auditing the existing logic, identifying gaps and over-inclusions, proposing changes, implementing the updated query, and managing a phased rollout to avoid abrupt volume changes.

## Audience Logic

**Issues identified in audit:**
- Old tier names still referenced (product had renamed/restructured tiers)
- Missing exclusion for a new "paused" subscription state introduced 6 months prior
- Engagement scoring used a 60-day window; team had agreed to move to 90 days
- No exclusion for users in a newly launched onboarding journey (double-messaging risk)
- Geographic expansion had added new markets not yet reflected in eligibility

**Updated logic:**
- Refreshed product tier mapping to current nomenclature
- Added "paused" state to exclusion list
- Extended engagement window to 90 days
- Added exclusion for users in first 30 days of onboarding journey
- Expanded geo eligibility to include new markets
- Maintained all existing frequency caps and global suppressions

## Approach

1. Pulled the existing production query and documented its current logic line by line
2. Identified discrepancies by comparing against current product data (tiers, states)
3. Estimated volume impact of each proposed change independently
4. Shared a summary with the program owner: "here's what changes and the net audience effect"
5. Implemented changes in a staging query for parallel comparison
6. Ran both old and new queries for one week to measure divergence
7. Cut over to new logic with monitoring for unexpected volume shifts

## Sanitized SQL / Logic Example

```sql
-- Audit comparison: old vs. new logic side by side
WITH old_logic_audience AS (
  SELECT user_id
  FROM targeting.engagement_program_v1
  WHERE extraction_date = CURRENT_DATE()
),

new_logic_audience AS (
  SELECT
    u.user_id
  FROM users.licenses u
  WHERE u.license_status IN ('active', 'trial')  -- added: was missing 'trial'
    AND u.product_tier IN ('standard', 'plus', 'premium')  -- updated tier names
    AND u.subscription_state != 'paused'  -- NEW: exclude paused
    AND u.country_code IN (
      SELECT country_code FROM config.eligible_markets
      WHERE program = 'engagement'
    )
    -- Extended engagement window: 90 days (was 60)
    AND u.user_id IN (
      SELECT user_id
      FROM campaign_history.interactions
      WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    )
    -- NEW: exclude users in onboarding journey
    AND u.user_id NOT IN (
      SELECT user_id
      FROM journeys.active_members
      WHERE journey_name = 'new_user_onboarding'
        AND entry_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    )
)

-- Impact analysis
SELECT
  'only_in_old' AS segment,
  COUNT(*) AS users
FROM old_logic_audience
WHERE user_id NOT IN (SELECT user_id FROM new_logic_audience)

UNION ALL

SELECT
  'only_in_new' AS segment,
  COUNT(*) AS users
FROM new_logic_audience
WHERE user_id NOT IN (SELECT user_id FROM old_logic_audience)

UNION ALL

SELECT
  'in_both' AS segment,
  COUNT(*) AS users
FROM old_logic_audience
WHERE user_id IN (SELECT user_id FROM new_logic_audience)
```

## QA and Validation

- Ran parallel extractions for 7 days to measure audience drift
- Confirmed net volume change was within acceptable range (+5% from geo expansion, -3% from new exclusions = ~+2% net)
- Verified no user was double-messaged from both engagement program and onboarding journey
- Checked that updated tier names correctly mapped to the same user population (no accidental drops)
- Monitored post-cutover metrics for 2 weeks: open rate, unsubscribe rate, complaint rate

## Outcome

Updated targeting logic went live without disruption. The refresh corrected ~8% of the audience (users who should have been excluded but weren't, and users who should have been included but were missed). Post-update metrics showed a slight improvement in engagement rates, consistent with a cleaner, more relevant audience.

## What This Demonstrates

- Proactive maintenance of production targeting systems
- Systematic audit approach: document existing state, identify gaps, estimate impact
- Risk management: parallel runs and phased cutover vs. big-bang changes
- Attention to downstream effects (double-messaging, volume stability)
- Communication with stakeholders on change impact before implementation
