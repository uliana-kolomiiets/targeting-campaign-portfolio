# One-Off Campaign Statistics Tracker

## Context

One-off (promotional) campaigns run throughout the year — seasonal events, product launches, special offers. Each campaign targets different audience segments across multiple product brands. Without centralized tracking, there was no easy way to:

- Compare this year's audience size to last year's for the same campaign
- Spot trends (growing or shrinking segments)
- Identify if a targeting change improved or reduced reach
- Have a quick reference for planning future campaigns

## Goal

Build and maintain a living statistics tracker that records audience composition for every one-off campaign, across years and brands — serving as both a QA reference and a planning tool.

## My Role

I created this tracker from scratch and maintain it with every campaign I target. It's become a core reference for campaign planning conversations with business stakeholders.

## What It Tracks

The tracker is organized by campaign type, with each campaign having its own sheet:

| Campaign | Frequency | Typical Scale |
|----------|-----------|---------------|
| Crazy Offer / Monster Sale | Seasonal | 10M+ users across brands |
| Spring Cleaning | Annual | 7-12M users |
| Big Saving | Periodic | Variable |
| Antiscam | Product-specific | Targeted segment |
| Cross-sell VPN | Always-on promo | Growing segment |
| Hobby campaigns | Seasonal/thematic | Variable |
| Halloween | Annual | Seasonal peak |
| Black Friday / Cyber Monday | Annual | Largest campaigns of the year |

## Structure Per Campaign

Each sheet records targeting results broken down by:

**Brand split:**
- Brand A audience (by dynamic field + by segment)
- Brand B audience (by dynamic field + by segment)

**Year-over-year comparison:**

| Segment | 2024 | 2025 | 2026 | YoY Change |
|---------|------|------|------|------------|
| Active accounts | 6.0M | 6.0M | 4.6M | -24% |
| Paid expired | 1.2M | 1.2M | 1.2M | -2% |
| Paid active | 1.1M | 1.1M | 1.0M | -2% |
| Trial expired | 358K | 358K | 381K | +7% |
| **Total** | **8.6M** | **8.6M** | **7.2M** | |

This structure immediately shows:
- Whether audience changes are expected (natural user base shifts) or unexpected (potential bug)
- Which segments are growing vs. shrinking
- Whether a targeting improvement actually increased reach

## How It's Used

### 1. QA checkpoint during campaign build
Before finalizing any one-off, I compare current counts against the tracker. If a segment dropped 30% but should be stable, that's a signal to investigate before send.

### 2. Planning conversations with business
When business asks "how big will the Black Friday audience be this year?", the tracker provides instant historical context and realistic expectations.

### 3. Improvement measurement
When I improve a query (fix a bug, expand eligibility), the tracker shows the concrete impact: "After fixing the SMB classification bug, the paid-active segment grew by 12%."

### 4. Year-over-year storytelling
Trends over 3 years tell a story about the user base, product changes, and targeting maturity — useful for roadmap and strategy discussions.

## Example: Spotting an Issue

From the Spring Cleaning tracker:

```
AVG Active Accounts:  2025: 6,025,081 → 2026: 4,588,537  (-24%)
Avast Active Accounts: 2025: 7,259,423 → 2026: 4,835,064  (-33%)
```

A -24% and -33% drop in the largest segment is a significant signal. This could mean:
- A genuine user base decline (confirm with product metrics)
- A data source change that reduced visibility
- A targeting logic change that was too aggressive
- A bug (e.g., users reclassified to a different segment)

Having this history *immediately* surfaces questions that would otherwise go unnoticed.

## What This Demonstrates

- Proactive tooling creation: built this without being asked because it solves a real problem
- Operational discipline: maintaining it consistently across every campaign
- Data storytelling: turning raw counts into actionable signals
- Cross-functional value: serves targeting, business planning, and QA simultaneously
- Long-term thinking: building institutional knowledge, not just one-time deliverables
