---
description: Debug an issue in Fizzy
---

Let's debug the issue you're experiencing.

To help debug effectively, I'll need to know:
1. **What's the issue?** - Error message, unexpected behavior, etc.
2. **Where does it occur?** - Which page/action/feature?
3. **What have you tried?** - Any troubleshooting steps?

Useful debugging approaches:
- Check logs: `tail -f log/development.log`
- Check browser console for JavaScript errors
- Check background jobs: http://fizzy.localhost:3006/admin/jobs
- Use Rails console to inspect data: `bin/rails console`
- Add breakpoints: `binding.break` in code
- Check account context: Is `Current.account` set correctly?
- Verify multi-tenancy: Are queries scoped properly?

Please describe the issue you're seeing.
