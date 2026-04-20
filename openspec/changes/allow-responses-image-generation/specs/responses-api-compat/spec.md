## ADDED Requirements

### Requirement: Allow image_generation tools on Responses routes

The service MUST accept Responses requests that include tools with type `image_generation` on `/backend-api/codex/responses`, `/v1/responses`, and websocket `response.create` payloads. The service MUST preserve the tool definition when forwarding upstream.

#### Scenario: v1 Responses accepts image_generation

- **WHEN** the client sends `/v1/responses` with `tools=[{"type":"image_generation"}]`
- **THEN** the service accepts the request and forwards the tool upstream

#### Scenario: Codex websocket response.create accepts image_generation

- **WHEN** a client sends websocket `response.create` with `tools=[{"type":"image_generation","output_format":"png"}]`
- **THEN** the service accepts the request and forwards the `image_generation` tool upstream unchanged
