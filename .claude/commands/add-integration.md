---
description: Add external service integration to Fizzy
---

Add integration with an external service to Fizzy.

Integration patterns available:
1. **Webhooks (Outbound)** - Send events to external services
   - Already supports: Slack, Campfire, Basecamp, generic JSON
   - Events: card_created, card_assigned, card_closed, etc.

2. **API (Inbound)** - Receive data from external services
   - Create API controllers under `app/controllers/api/v1/`
   - Use token authentication
   - Return JSON responses

3. **Background Sync** - Periodic synchronization
   - Create job in `app/jobs/`
   - Add to `config/recurring.yml` for scheduling
   - Use Solid Queue

4. **Real-time** - WebSocket/SSE connections
   - Use Turbo Streams
   - Backed by Solid Cable

Which service would you like to integrate?
Examples:
- GitHub (issues sync)
- Slack (bot commands)
- Email (create cards from email)
- Zapier/Make.com (general webhooks)
- AI services (GPT, Claude, etc.)

Please describe the integration you want to add.
