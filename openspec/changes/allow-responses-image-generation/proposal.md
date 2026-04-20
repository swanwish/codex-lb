## Why

Codex IDE now sends the built-in `image_generation` tool on Responses-style websocket `response.create` requests. `codex-lb` still rejects that tool during shared request validation, so the IDE extension fails locally with `invalid_request_error` and `param: "tools"` before any upstream call is attempted.

## What Changes

- Allow `image_generation` tool definitions on Responses-family request validation, including `/backend-api/codex/responses`, `/v1/responses`, and websocket `response.create`.
- Preserve the `image_generation` tool payload when forwarding upstream instead of rejecting it locally.
- Keep Chat Completions tool policy unchanged for now so this change stays scoped to the Codex/Responses path that currently fails.

## Capabilities

### Modified Capabilities

- `responses-api-compat`

## Impact

- Code: `app/core/openai/requests.py`, `app/core/openai/v1_requests.py`
- Tests: `tests/unit/test_openai_requests.py`, `tests/unit/test_proxy_utils.py`, `tests/integration/test_openai_compat_features.py`, `tests/integration/test_proxy_responses.py`
