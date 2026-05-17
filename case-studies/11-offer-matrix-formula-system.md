# Formula-Based Offer Matrix for Cross-Sell & Upsell Campaigns

## Context

Cross-sell and upsell campaigns need to recommend the right product to each customer — but "right" depends on what the customer already owns. A user with a basic antivirus shouldn't be offered the same thing as someone who already has antivirus + VPN + password manager. The offer must be:

- Something they **don't** already have
- Something that makes sense given their current portfolio
- Prioritized when multiple offers are possible

With 6-7 product lines per brand and customers holding any combination of them, the number of possible portfolio states grows exponentially. Manually defining "if customer has X, Y but not Z → offer Z" for every combination is error-prone and doesn't scale.

## Goal

Create a systematic, formula-driven approach to generate offer assignments for every possible product combination — so that any one-off cross-sell or upsell campaign can quickly determine the correct offer for each customer based on their held products.

## My Role

I designed and built this offer matrix system from scratch. It's now used as the foundation for all cross-sell/upsell one-off campaigns across both brands and all regions.

## How It Works

### The Core Concept

Each product is assigned a positional segment ID (powers of 10):

| Product | Segment ID |
|---------|-----------|
| Product A | 1 |
| Product B | 10 |
| Product C | 100 |
| Product D | 1,000 |
| Product E | 10,000 |
| Product F | 100,000 |

A customer's full portfolio is encoded as the **sum** of their product IDs. For example:
- Holds A + C = segment `101`
- Holds B + D + E = segment `11,010`

This encoding uniquely identifies every possible product combination with a single number — making it easy to join, filter, and segment in SQL.

### The Offer Matrix

For each campaign, the matrix defines:

| Offer | Held Product 1 | Held Product 2 | Held Product 3 | ... |
|-------|---------------|---------------|---------------|-----|
| Product C | A | B | — | (offer C to users who have A+B but not C) |
| Product C | A | — | D | (offer C to users who have A+D but not C) |
| Product B | A | — | — | (offer B to users with only A) |

Every row is a valid combination of held products → resulting offer. The matrix exhaustively covers all combinations using a formula-based generation approach (not manual entry).

### Formula Logic

The formulas systematically generate every permutation where:
1. The customer holds at least one qualifying product (they're a customer, not free user)
2. The offered product is **not** in their current portfolio
3. Priority rules determine which offer wins when multiple are possible

### Scale

The system currently covers:

- **32 matrix variants** across different campaigns, brands, and regions
- **Campaigns:** Black Friday, Hobby, Valentine's, Spring Cleaning, Halloween, Holidays, product relaunches
- **Brands:** Avast (6 product lines), AVG (5 product lines)
- **Regions:** US vs. ROW (different product availability and pricing)
- **Customer states:** Active vs. expired (different offers for winback vs. cross-sell)

## Sanitized SQL / Logic Example

```sql
-- Using the segment_id approach in targeting queries
WITH customer_portfolio AS (
  SELECT
    user_id,
    -- Encode held products as sum of positional IDs
    SUM(
      CASE product_code
        WHEN 'PRD' THEN 1
        WHEN 'CLP' THEN 10
        WHEN 'SMP' THEN 100
        WHEN 'APW' THEN 1000
        WHEN 'BGW' THEN 10000
        WHEN 'DRW' THEN 100000
      END
    ) AS segment_id
  FROM licenses.active_products
  WHERE license_status = 'active'
  GROUP BY user_id
),

-- Join against the offer matrix to determine what to offer
offer_assignment AS (
  SELECT
    c.user_id,
    c.segment_id,
    m.offer_name,
    m.offer_priority
  FROM customer_portfolio c
  INNER JOIN campaign_config.offer_matrix m
    ON c.segment_id = m.segment_id
  WHERE m.campaign = @campaign_name
)

-- Deduplicate: one offer per user (highest priority wins)
SELECT
  user_id,
  segment_id,
  offer_name
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY offer_priority ASC) AS rn
  FROM offer_assignment
)
WHERE rn = 1
```

## How It's Used in Practice

1. **Business provides campaign brief:** "We want to cross-sell VPN to users who don't have it"
2. **I generate the matrix:** Using the formula approach, produce all valid combinations of held products where VPN is not present
3. **Matrix becomes the targeting config:** Each segment_id row maps to a specific offer and email creative
4. **Query uses the matrix:** The SQL joins customer portfolios against the matrix to assign offers
5. **Result:** Every customer gets exactly one relevant offer, no conflicts, no gaps

## Advantages Over Manual Approach

| Manual | Formula-Based |
|--------|--------------|
| Define each case one by one | Generate all permutations systematically |
| Easy to miss combinations | Exhaustive by construction |
| Hard to audit for completeness | Verifiable: 2^N - 1 possible states covered |
| Slow to adapt for new campaigns | Copy template, adjust product list, regenerate |
| Error-prone at scale | Consistent and reproducible |

## QA and Validation

- Verify total matrix rows = expected permutation count (2^N - 1 for N products, minus excluded states)
- Confirm no segment_id appears twice with different offers (uniqueness check)
- Validate that the offered product is never in the "held" columns for that row
- Cross-check against actual customer data: are all observed segment_ids covered by the matrix?
- Test edge cases: customer with all products (no valid offer), customer with one product (maximum offers available)

## Outcome

The matrix system reduced campaign setup time from days of manual logic building to hours of formula-driven generation. It eliminated offer-assignment bugs (wrong product shown to wrong customer) and made it trivial to spin up new cross-sell campaigns by reusing the template for different campaign contexts, regions, and seasonal events.

## What This Demonstrates

- Systems thinking: building a reusable framework, not one-off solutions
- Combinatorial problem-solving: encoding complex state into a scalable, queryable format
- Formula-based automation: eliminating manual errors and scaling to any product count
- Cross-campaign reusability: one system powers 32+ campaign variants
- End-to-end ownership: from mathematical concept to production SQL to campaign delivery
