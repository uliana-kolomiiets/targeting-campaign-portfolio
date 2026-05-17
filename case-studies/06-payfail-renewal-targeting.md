# Payment Failure Renewal Targeting

## Context

A subset of customers with auto-renewal enabled were failing to renew — not because they chose to cancel, but because their payment method failed (expired card, insufficient funds, bank decline). These users still had active intent to stay subscribed but were at high risk of churning if not re-engaged quickly with a clear path to update their payment details.

## Goal

Build and maintain an automated targeting pipeline that identifies users experiencing payment failures and routes them into a dedicated email journey designed to recover the subscription before the grace period expires.

## My Role

I owned the targeting logic for the payfail renewal program: defining eligibility, building the extraction query that ran on a recurring schedule, ensuring proper suppressions, and maintaining the logic as business rules evolved over time.

## Audience Logic

- **Inclusion:** Users whose most recent renewal attempt failed, within the grace period window (typically 7-14 days after first failure)
- **Payment failure types:** Expired card, insufficient funds, generic bank decline (each routed to slightly different messaging)
- **Timing:** User enters the journey on the day after first failed attempt; exits if payment succeeds or grace period expires
- **Suppressions:**
  - Users who already updated their payment method (resolved)
  - Users who explicitly cancelled during the grace period
  - Users in active support tickets about billing issues
  - Standard frequency caps and global suppressions
- **Segmentation:** By failure reason (drives different email copy and CTA)

## Approach

1. Mapped the payment lifecycle: attempt → failure → retry schedule → grace period → expiry
2. Identified the right entry trigger: first failure event, not retry failures
3. Built logic to detect resolution (payment updated or retry succeeded) for journey exit
4. Handled edge cases: multiple products failing simultaneously, partial payment on bundled licenses
5. Set up the query to run daily, producing a delta of new entrants and exits
6. Coordinated with the SFMC journey team on entry/exit data extension format

## Sanitized SQL / Logic Example

```sql
WITH payment_failures AS (
  SELECT
    user_id,
    license_id,
    product_family,
    failure_date,
    failure_reason,
    grace_period_end,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, license_id
      ORDER BY failure_date ASC
    ) AS failure_sequence
  FROM billing.payment_events
  WHERE event_type = 'renewal_failure'
    AND failure_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
),

-- Only take the first failure per license (entry trigger)
first_failures AS (
  SELECT *
  FROM payment_failures
  WHERE failure_sequence = 1
    AND grace_period_end >= CURRENT_DATE()
),

-- Exclude resolved: payment updated or retry succeeded
resolved AS (
  SELECT DISTINCT user_id, license_id
  FROM billing.payment_events
  WHERE event_type IN ('payment_method_updated', 'renewal_success')
    AND event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
),

-- Exclude explicit cancellations during grace period
cancelled AS (
  SELECT DISTINCT user_id, license_id
  FROM licenses.cancellations
  WHERE cancellation_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
    AND cancellation_source = 'user_initiated'
)

SELECT
  f.user_id,
  f.license_id,
  f.product_family,
  f.failure_date,
  f.failure_reason,
  f.grace_period_end,
  DATE_DIFF(f.grace_period_end, CURRENT_DATE(), DAY) AS days_remaining
FROM first_failures f
LEFT JOIN resolved r ON f.user_id = r.user_id AND f.license_id = r.license_id
LEFT JOIN cancelled c ON f.user_id = c.user_id AND f.license_id = c.license_id
WHERE r.user_id IS NULL
  AND c.user_id IS NULL
ORDER BY f.grace_period_end ASC
```

## QA and Validation

- Verified entry logic: confirmed only first-failure events triggered entry (not subsequent retries)
- Checked exit logic: users who updated payment disappeared from next day's extraction
- Validated no overlap with cancelled users (explicit cancellation = different journey)
- Monitored daily volumes for consistency — sudden spikes could indicate a payment processor outage vs. normal churn
- Cross-checked a sample of 50 users against billing support tickets to confirm targeting accuracy

## Outcome

The payfail renewal program recovered ~18% of at-risk subscriptions that would have otherwise lapsed silently. The automated daily targeting pipeline ran reliably with minimal maintenance. Segmentation by failure reason (expired card vs. insufficient funds) enabled more relevant messaging, with expired-card users showing the highest recovery rate.

## What This Demonstrates

- Building automated, recurring targeting pipelines (not just one-off extractions)
- Understanding payment and subscription lifecycle events
- Designing entry/exit logic for triggered journeys
- Edge case handling: multiple products, concurrent failures, resolution detection
- Production reliability: daily pipeline that runs unattended with built-in monitoring
