# Targeting Documentation — Confluence Knowledge Base

## Context

The email targeting function had no centralized documentation. Knowledge lived in individual team members' heads, scattered Jira tickets, and code comments. This created problems:

- New team members had no onboarding reference — ramp-up took weeks of shadowing and asking questions
- Handoffs between team members required extensive verbal explanations
- Tribal knowledge was at risk when people moved roles or left
- Repeated questions from business stakeholders about how targeting works

## Goal

Create a comprehensive, structured Confluence page that serves as both:
1. **Onboarding guide** for newcomers joining the targeting team
2. **Living documentation** of how email targeting works end-to-end

## My Role

I authored the entire documentation from scratch — structuring the content, writing all sections, and maintaining it as processes evolve.

## What It Covers

The documentation serves as a complete reference for the email targeting function:

### For Newcomers
- How the targeting system works end-to-end (data sources → query → extraction → handoff → send)
- Key tools and access: BigQuery, Airflow, SFMC, Git repositories, Jira boards
- Common terminology and abbreviations
- Step-by-step guides for common tasks (building a one-off, updating an automated campaign, running QA)

### For Day-to-Day Reference
- Campaign types and their targeting patterns (manual renewal, one-off, triggered, automated)
- Suppression logic documentation (what's suppressed, why, where it's implemented)
- Data sources: which tables contain what, freshness expectations, known quirks
- Query templates and patterns for common targeting scenarios
- QA checklist and validation steps before any handoff

### For Cross-Team Communication
- How targeting interacts with sendout (handoff format, timing, tracking codes)
- How to request a new campaign or changes to existing targeting
- Escalation paths for data issues, delivery problems, urgent requests

## Structure

```
Email Targeting Guide
├── Overview & Architecture
│   ├── System diagram (data flow)
│   ├── Tools and access
│   └── Team roles and responsibilities
├── Campaign Types
│   ├── Manual renewal campaigns
│   ├── One-off / promotional campaigns
│   ├── Triggered journeys
│   └── Always-on automated campaigns
├── How To
│   ├── Build a new one-off campaign
│   ├── Update existing automated targeting
│   ├── Run QA validation
│   ├── Handle suppression edge cases
│   └── Troubleshoot common issues
├── Data Reference
│   ├── Key tables and their purpose
│   ├── Product/tier mapping
│   ├── Suppression sources
│   └── Known data quirks and workarounds
└── Processes
    ├── Handoff to sendout team
    ├── Tracking code conventions
    ├── Change request workflow
    └── Incident response
```

## How It's Used

- **Onboarding:** New team members start here on day one — reduces ramp-up time significantly
- **Self-service:** Business stakeholders can answer basic questions without pinging the team
- **Consistency:** Everyone follows the same process because it's documented in one place
- **Maintenance reference:** When updating a campaign, the guide reminds you of steps you might forget

## Outcome

The documentation became the go-to reference for the targeting function. It reduced repetitive questions, shortened onboarding time for new team members, and created a single source of truth that the entire email operations team could rely on.

## What This Demonstrates

- Technical writing: translating complex systems into clear, structured documentation
- Knowledge management: capturing tribal knowledge before it's lost
- Proactive initiative: nobody assigned this — I built it because it was needed
- Team-first thinking: investing time in something that helps others, not just my own productivity
- Systems perspective: understanding the full end-to-end process well enough to document it comprehensively
