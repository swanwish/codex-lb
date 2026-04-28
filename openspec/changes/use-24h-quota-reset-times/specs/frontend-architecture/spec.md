## ADDED Requirements

### Requirement: Quota reset labels use a 24-hour clock
Dashboard quota reset labels for account usage windows MUST render absolute reset times with a 24-hour clock and MUST NOT include AM/PM markers. This requirement applies to both same-day reset labels and future-date reset labels. Relative reset text MUST remain unchanged.

#### Scenario: Same-day quota reset label uses 24-hour time
- **WHEN** an account quota reset occurs later on the current local day
- **THEN** the dashboard reset label renders the absolute time in `HH:mm`-style 24-hour form
- **AND** the label does not include `AM` or `PM`
- **AND** the relative suffix remains visible

#### Scenario: Future-date quota reset label uses 24-hour time
- **WHEN** an account quota reset occurs on a later local day
- **THEN** the dashboard reset label renders the future date with 24-hour time
- **AND** the label does not include `AM` or `PM`
