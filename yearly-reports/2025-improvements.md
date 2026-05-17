# 2026 — Year in Review: Targeting Improvements & Impact

This year focused on operational maturity — cleaning up legacy logic, fixing production issues after a major data migration, improving cross-team communication, and building sustainable practices that make future work faster and more reliable.

---

## 1. SMB Manual Renewal Campaigns — Full Cleanup

### What I Did

Performed a comprehensive audit and cleanup of all SMB manual renewal campaigns. Each campaign was reviewed and adjusted across multiple dimensions:

- **Data availability:** Verified what data sources each campaign actually had access to and whether they were being used correctly
- **Query improvements:** Identified inefficiencies, outdated logic, and missed opportunities in existing targeting queries
- **Applied fixes:** Implemented improvements to increase audience reach where legitimate
- **Template-target sync:** Ensured email templates matched their targeting logic (correct product references, tier names, messaging alignment)

### Result

Increased send volumes across SMB manual renewal campaigns by reaching previously missed eligible users.

### Bonus: Summary Tracking Table

On top of the technical work, I created a summary table consolidating:

| Column | Purpose |
|--------|---------|
| Campaign name | Which campaign |
| Template name | Which email creative |
| Sendout tracking code | Links targeting to delivery |
| Targeting tracking code | Links targeting to measurement |
| Daily send volume | Operational monitoring |

This reference became a key communication tool between the business owner and the email operations team — reducing back-and-forth questions and giving everyone a single source of truth for campaign status.

### Skills Demonstrated
- Systematic audit across multiple production campaigns
- End-to-end ownership: data → logic → template → delivery alignment
- Creating operational tooling that improves team communication

---

## 2. One-Off Campaign Improvements

### What I Did

With every one-off campaign, I pushed to improve the targeting approach — not just deliver what was asked, but actively find ways to get a larger, more accurate audience while maintaining quality.

### Key Improvements Developed

**Checkpoint system for QA:**
- Developed a set of data checkpoints embedded in the targeting process
- These checkpoints compare current extraction stats against historical data, flag unexpected drops or spikes, and catch issues before send
- Proved invaluable for spotting problems invisible at the surface level (e.g., a segment unexpectedly dropping to zero)
- *Next step:* Need to build persistent history tracking so checkpoints can reference trends over time, not just point-in-time comparisons

**Bugs discovered and fixed:**
- SMB customers incorrectly classified as free-account users (affecting multiple campaigns)
- Bench products included in targeting where they shouldn't have been
- Errors in business-provided matrices (product/tier mapping tables) — caught through data validation and flagged back to business
- Each fix improved not just the immediate campaign but all future campaigns using similar logic

**Black Friday preparation:**
- Prepared a structured list of suggestions for how to improve targeting for the upcoming BF campaign — proactive recommendations based on patterns observed throughout the year

**Consultative approach:**
- Actively helping business stakeholders shape their campaign ideas into the most efficient targeting possible — not just executing requests but advising on what's achievable and optimal given the data

### Skills Demonstrated
- Continuous improvement mindset: each campaign is better than the last
- Proactive bug detection through systematic validation
- Upstream influence: fixing source data, not just working around it
- Consultative partnership with business teams

---

## 3. STO (Send Time Optimization) Fix

### Background

After a major data migration in December 2025, the tables powering Send Time Optimization broke. STO is critical for sendout planning — it determines when each user should receive their email based on their predicted optimal engagement time.

Initial fixes were attempted by the data engineering (ADS) and data operations (CDO) teams, but the STO table remained unreliable after their adjustments. I took ownership of the investigation.

### Investigation Findings

During deep-dive analysis, I discovered multiple underlying issues:

1. **Hashing bug in funnel table:** Records were being incorrectly hashed, causing join mismatches and data loss
2. **Case sensitivity inconsistency:** Email addresses were not unified for case sensitivity — `user@email.com` and `User@Email.com` were treated as different records in some tables
3. **Locale data gap:** Customers with unknown locale information were disproportionately assigned a specific default individual send time (13:51), which skewed any aggregate estimation that used predicted time

### Resolution

- Opened tickets for the hashing and case-sensitivity bugs → resulted in data-side fixes by engineering
- Designed a new STO estimation approach: **build predictions using only customers with known locale data**, filtering out the "unknown locale" population that was skewing results
- Updated the STO estimation table with the corrected logic
- Applied the same fix to one-off campaign queries that referenced STO predictions

### Impact
- STO became reliable again for sendout planning
- Upstream data quality improved (hashing + case sensitivity fixes benefit all downstream consumers)
- Documented the locale-assignment pattern as a known data characteristic for future reference

### Skills Demonstrated
- Taking ownership of a cross-team problem when initial fixes didn't work
- Root cause analysis across multiple data layers
- Finding bugs that others missed (hashing, case sensitivity)
- Designing a statistically sound workaround (locale filtering) while underlying issues are fixed
- Opening upstream tickets to fix problems at the source

---

## 4. Tracking Codes Sync & Cost Optimization

### Problem

The targeting team and the sendout team used different tracking codes for what were nominally the same campaigns. This disconnect caused confusion, made it hard to trace issues end-to-end, and masked problems like campaigns that had silently stopped running.

### What I Did

Created a comprehensive reconciliation spreadsheet that merged:
- All running campaigns on the targeting side
- Historical and current tracking codes from the sendout side
- Current status of each campaign (running vs. stopped)
- Last query update date for each campaign

### Results

**1. Cost reduction — stopped unnecessary automations (~$2,000/month saved):**
Performed a full reconciliation of running Airflow DAGs against active SFMC campaigns. Identified ~20 orphaned jobs that were consuming BigQuery compute daily for campaigns that had been stopped on the sendout side. Stopping these saved approximately $2,000 USD per month (~$24K annualized). See [full case study](../case-studies/10-airflow-sfmc-reconciliation.md).

**2. Identified broken campaigns requiring fixes:**
Discovered campaigns in a problematic state. Example: certain campaigns had zero targets for a period (due to data issues), which triggered SFMC's automatic shutoff. However, these campaigns' audiences were starting to grow again and should have been running. Both sendout and targeting teams applied fixes to restart them.

**3. Identified stale queries requiring updates:**
By tracking the last update date of each campaign's query, produced a prioritized list of outdated targeting logic. Reasons updates are needed:
- Product names have changed
- Manual renewal logic has been refined (improved distinguishing criteria)
- Trial product variables have been updated
- General data model evolution since the query was last touched

*This backlog of stale queries is the next priority for systematic cleanup.*

### Skills Demonstrated
- Cross-team reconciliation and alignment
- Cost optimization through eliminating waste
- Proactive identification of silent failures
- Building operational visibility tooling (the spreadsheet became a living reference)
- Creating a prioritized maintenance backlog from data-driven audit

---

## Summary: Themes of 2026

| Theme | Examples |
|-------|----------|
| **Operational cleanup** | SMB MR campaigns, tracking codes sync, stale query identification |
| **Data quality improvement** | STO bugs, hashing fixes, case sensitivity, matrix errors |
| **Process maturity** | Checkpoint system, summary tables, reconciliation tooling |
| **Cost consciousness** | Stopped unnecessary automations, reduced BigQuery spend |
| **Cross-team impact** | Upstream bug tickets, business consultation, team communication tools |

---

## What's Next

- Systematic update of stale campaign queries (identified via tracking codes audit)
- Build persistent checkpoint history for one-off QA comparisons
- Black Friday targeting optimization (suggestions prepared)
- Continue improving SMB campaign coverage
