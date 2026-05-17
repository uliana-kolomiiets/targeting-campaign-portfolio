# Targeting and Campaign Execution Portfolio

This repository highlights selected case studies from my work in lifecycle marketing targeting and campaign operations. The projects focus on audience selection, experiment setup, SQL-based targeting logic, QA, rollout support, and production investigations.

The examples are sanitized and simplified to protect internal systems and customer data while still showing how I approach campaign execution from business ask to implementation.

## About Me

Email Targeting Specialist with experience in lifecycle marketing at a major cybersecurity company. I work at the intersection of data engineering and marketing operations — translating business asks into audience logic, validating edge cases, supporting experiments, and troubleshooting production issues when data or delivery breaks.

**Core skills:** BigQuery SQL, audience segmentation, A/B/C testing design, Salesforce Marketing Cloud (SFMC), campaign QA, production investigation

## Case Studies

| # | Project | Type | Skills Demonstrated |
|---|---------|------|---------------------|
| 1 | [Spring Cleaning One-Off](case-studies/01-spring-cleaning-one-off.md) | Campaign Execution | Audience design, suppression logic, cohort targeting, QA |
| 2 | [Chequebook ABC Test](case-studies/02-chequebook-abc-test.md) | Experimentation | Test design, control/variant splits, exclusion logic |
| 3 | [Einstein STO Rollout](case-studies/03-einstein-sto-rollout.md) | Operationalization | Rollout planning, production checks, scaling a winning test |
| 4 | [SMB Winback & Investigation](case-studies/04-smb-winback-and-investigation.md) | Targeting + Debugging | Complex segmentation, data investigation, constraint handling |
| 5 | [DSR Spike Investigation](case-studies/05-dsr-spike-investigation.md) | Production Investigation | Root cause analysis, cross-system correlation, compliance |
| 6 | [Payment Failure Renewal](case-studies/06-payfail-renewal-targeting.md) | Automated Pipeline | Recurring targeting, lifecycle triggers, exit logic |
| 7 | [Engagement Program Update](case-studies/07-engagement-program-update.md) | Maintenance & Audit | Logic refresh, impact analysis, phased rollout |
| 8 | [Data Legitimacy Cross-Check](case-studies/08-data-legitimacy-cross-check.md) | Data Quality | Pipeline validation, source-of-truth reconciliation, quality gates |
| 9 | [One-Off Campaign Tracker](case-studies/09-one-off-campaign-tracker.md) | Operational Tooling | Multi-year tracking system, YoY comparison, planning reference |
| 10 | [Airflow vs. SFMC Reconciliation](case-studies/10-airflow-sfmc-reconciliation.md) | Cost Optimization | Cross-system audit, ~$2K/month saved by stopping orphaned jobs |
| 11 | [Offer Matrix Formula System](case-studies/11-offer-matrix-formula-system.md) | System Design | Combinatorial offer assignment for cross-sell/upsell, 32+ campaign variants |
| 12 | [Targeting Documentation Guide](case-studies/12-targeting-documentation-guide.md) | Knowledge Management | Full Confluence knowledge base for onboarding and team reference |
| 13 | [Business Consultation: SMB Targeting](case-studies/13-business-consultation-smb-targeting.md) | Stakeholder Consulting | Advising business owners on data possibilities, constraints, and improvements |

## Yearly Reports

Impact summaries highlighting key improvements and initiatives by year.

- [**2026** — Operational Maturity](yearly-reports/2026-improvements.md): SMB campaign cleanup, STO fix after data migration, one-off targeting improvements, tracking codes reconciliation & cost savings

## SQL Snippets

Sanitized examples of common targeting patterns I build:

- [`audience-selection.sql`](snippets/audience-selection.sql) — Cohort eligibility logic
- [`experiment-split.sql`](snippets/experiment-split.sql) — A/B/C test assignment
- [`suppression-logic.sql`](snippets/suppression-logic.sql) — Contact frequency and exclusion rules
- [`qa-validation.sql`](snippets/qa-validation.sql) — Pre-send validation checks

## How I Work

1. **Translate** business requirements into precise audience definitions
2. **Build** SQL-based targeting with proper suppressions and timing
3. **Validate** counts, overlaps, and edge cases before any send
4. **Support** experiments from design through rollout
5. **Investigate** when things break — data discrepancies, delivery issues, unexpected behavior
