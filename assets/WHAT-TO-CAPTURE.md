# Screenshots & Assets Guide

Collect screenshots that show your work in action — but **always redact** sensitive data (customer emails, internal URLs, real tracking codes, Jira project keys) before committing.

## Recommended Screenshots

### From BigQuery / SQL
- [ ] Query results showing audience counts by segment (redact actual numbers if sensitive)
- [ ] A checkpoint validation output (counts comparison: expected vs. actual)
- [ ] The STO estimation table — before and after your fix
- [ ] An example of a one-off query with your checkpoint logic visible

### From SFMC / Sendout
- [ ] Journey builder canvas (shows automation structure)
- [ ] Data extension preview (column structure, not actual data)
- [ ] Send log showing campaign volumes over time

### From Jira / Project Work
- [ ] A ticket showing your investigation workflow (comments, status transitions)
- [ ] The tracking codes reconciliation spreadsheet (redact internal codes)
- [ ] The SMB campaigns summary table you created

### From Dashboards / Results
- [ ] Campaign performance comparison (before/after your improvements)
- [ ] STO distribution chart (sends spread across hours)
- [ ] Volume trends showing increased sends after SMB cleanup

## How to Redact

- Use your screenshot tool's blur/rectangle to cover sensitive text
- Replace real tracking codes with "XXXX-XXXX" or similar
- Crop out browser tabs, bookmarks, internal URLs
- Remove or blur any customer PII (emails, names, IDs)

## Naming Convention

Use descriptive names with the case study number prefix:

```
01-spring-cleaning-audience-counts.png
02-chequebook-test-split-results.png
03-sto-distribution-before-fix.png
03-sto-distribution-after-fix.png
04-smb-investigation-query.png
2026-smb-summary-table.png
2026-tracking-codes-excel.png
2026-sto-estimation-fixed.png
```

## Adding to Case Studies

Once you have screenshots, reference them in the markdown like this:

```md
![Audience counts by segment](../assets/01-spring-cleaning-audience-counts.png)
```
