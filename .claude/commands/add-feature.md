---
description: Guide for adding a new feature to Fizzy
---

I'll help you add a new feature to Fizzy. Let's follow the Rails conventions and Fizzy patterns.

Key steps for adding a feature:
1. **Identify the domain** - Is this for Cards, Boards, Users, etc.?
2. **Choose the pattern** - Controller, Model concern, Job, or Service?
3. **Add routes** - Follow RESTful conventions
4. **Create controller** - Nested under resource if applicable
5. **Add model logic** - Use concerns for shared behavior
6. **Create views** - Use Turbo Frames/Streams for interactivity
7. **Add Stimulus controller** - For client-side behavior if needed
8. **Track events** - Use `track_event` for audit trail
9. **Write tests** - Unit and system tests
10. **Check style** - Run `bundle exec rubocop`

What feature would you like to add? Please describe:
- The domain (Cards, Boards, etc.)
- What it should do
- Where in the UI it should appear
