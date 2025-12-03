---
description: Review recent code changes for quality and best practices
---

I'll review your recent code changes against Fizzy best practices.

Review checklist:
- **Style** - Follows STYLE.md guidelines
- **Security** - No vulnerabilities (XSS, SQL injection, etc.)
- **Multi-tenancy** - Queries properly scoped to account
- **Events** - Significant actions tracked via `track_event`
- **Tests** - Unit and system tests included
- **Performance** - No N+1 queries, proper indexing
- **Turbo** - Using Frames/Streams appropriately
- **Concerns** - Shared behavior extracted properly
- **Routes** - RESTful conventions followed
- **Background jobs** - Account context preserved

Which files or changes would you like me to review?
