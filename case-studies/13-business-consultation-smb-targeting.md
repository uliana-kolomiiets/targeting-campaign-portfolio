# Business Consultation: SMB Campaign Targeting Expansion

## Context

As a targeting specialist, a significant part of my role goes beyond writing SQL — it involves **consulting with business owners** on what's technically possible, what data constraints exist, and how to improve campaign performance through better segmentation. Business owners have campaign goals and customer intuition; I have knowledge of the data landscape, its gaps, and its possibilities.

This is an ongoing, collaborative process — not a one-time handoff.

## Use Case: SMB Cross-Sell Volume Improvement

A business owner launched a new cross-sell campaign targeting SMB (small business) customers. After one week, volumes were lower than expected. They reached out asking what parameters could be adjusted to increase reach.

### The Request

> "New cross-sell campaign targeting SMB customers was launched a week ago. I see the numbers are not as high as I expected. Which parameters could we adjust to increase the volume?"

### My Approach

Rather than just tweaking a number in a WHERE clause, I took a structured investigative approach:

**1. Share existing research**
I had previously conducted an investigation of all possible SMB customers in our database. I shared this working analysis as context — not as a final answer, but as inspiration for the business owner to see the full landscape of what exists in the data.

**2. Identify specific improvement hypotheses**

Based on my experience maintaining SMB campaigns, I proposed concrete directions:

- **Product name coverage:** We had prior experience with manual renewal campaigns where the database contained a broader list of product names than what our targeting logic was filtering for. The same gap likely exists for SMB — we may be missing eligible customers simply because their product is named slightly differently in the source data.

- **Data source completeness:** Questioned whether ALL SMB data truly lives in the primary data warehouse (C360), or whether separate SMB-specific datasets exist that we're not querying. I had encountered separate SMB datasets before — if some customers only exist there, we're missing them entirely.

- **Recommended escalation:** Suggested involving data owners to confirm the canonical source of truth for SMB data, rather than guessing from our side.

**3. Provide full transparency on current data sources**

I shared the complete list of source tables our SMB targeting currently uses, categorized by purpose:

| Category | Tables | Purpose |
|----------|--------|---------|
| Core campaign tables | Order items, licenses, email funnel | Main SMB eligibility, suppressions, contact history |
| Account-level sources | Account events | SMB cohort identification, free account logic |
| BI helper tables | Connection history, ID mappings | Winback logic, identity resolution |

This gives the business owner (and any data team we involve) full visibility into where we're currently looking — making it easy to spot where we're NOT looking.

## What This Interaction Demonstrates

### The Consulting Skillset

| What business owners need | What I provide |
|---------------------------|---------------|
| "Make numbers bigger" | Structured analysis of WHY numbers are what they are |
| Quick fix | Root cause investigation + sustainable improvements |
| Assumptions about data | Reality check on what data exists and its limitations |
| One campaign view | Cross-campaign pattern recognition (e.g., product naming gaps seen before) |

### Key Principles I Follow

**1. Don't just execute — educate**
Instead of silently adjusting a filter and reporting "done, numbers are higher," I explain the reasoning. This helps business owners make better requests in the future and understand trade-offs.

**2. Distinguish between "we can change" vs. "needs escalation"**
Some improvements are within targeting's control (expand product name filters). Others require data engineering action (switching data sources, fixing upstream tables). I clearly separate these and recommend the right path for each.

**3. Share working context, not just polished outputs**
Sharing my investigation file — even if messy — gives the business owner raw material to think with. It builds trust and invites collaboration rather than creating a black-box dynamic.

**4. Connect patterns across campaigns**
The product naming gap I identified came from experience with a completely different campaign type (manual renewals). Cross-pollinating learnings across campaign families is something only possible when one person maintains broad awareness of the targeting landscape.

**5. Protect data integrity**
I don't recommend changes I'm not confident about. When unsure about data source completeness, I recommend involving data owners rather than guessing — protecting campaign quality over speed.

## Typical Consultation Scenarios

This SMB case is one example, but similar conversations happen regularly:

| Scenario | My Role |
|----------|---------|
| "Can we target users who did X?" | Assess whether that behavior is trackable in our data |
| "Why is the audience smaller than expected?" | Investigate suppressions, data gaps, logic constraints |
| "Can we split the audience by Y?" | Evaluate whether Y is available, reliable, and granular enough |
| "We want to exclude customers who..." | Determine if the exclusion is technically feasible with current data |
| "How do we avoid cannibalizing another campaign?" | Design suppression logic that respects cross-campaign boundaries |
| "What about targeting lapsed free users?" | Clarify what "lapsed" and "free" mean in the data vs. in business language |

## Outcome

For this specific case:
- Business owner gained understanding of data landscape and constraints
- Two actionable improvement paths identified (product name expansion + data source investigation)
- Data team was engaged to confirm SMB data architecture
- Campaign volumes improved after implementing the product name expansion
- Foundation laid for longer-term SMB data consolidation project

## What This Demonstrates

- **Technical consulting:** Translating data reality into business-understandable recommendations
- **Proactive pattern recognition:** Applying lessons from one campaign domain to another
- **Collaborative approach:** Sharing context and inviting dialogue rather than gatekeeping
- **System awareness:** Knowing not just what's in the queries, but what's in the underlying data landscape
- **Professional judgment:** Knowing when to act independently vs. when to escalate to data owners
- **Communication skills:** Explaining complex data constraints clearly to non-technical stakeholders
