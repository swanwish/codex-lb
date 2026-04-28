## Why

Account quota reset labels currently use the browser's default `en-US` hour cycle, which renders reset times with AM/PM in common environments. Operators scanning 5h and weekly reset windows prefer a consistent 24-hour clock to avoid ambiguity.

## What Changes

- Render dashboard quota reset labels with a 24-hour clock.
- Keep existing relative reset suffixes unchanged, such as `in 30m` and `in 6d 13h`.
- Preserve existing dashboard-wide configurable datetime preferences for non-reset timestamps.

## Impact

- Code: `frontend/src/utils/formatters.ts`
- Tests: `frontend/src/utils/formatters.test.ts`
- Specs: `openspec/specs/frontend-architecture/spec.md`
