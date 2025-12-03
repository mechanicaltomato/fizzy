---
description: Add AI/LLM features to Fizzy
---

Add AI/LLM integration to Fizzy. The codebase already has AI groundwork via `Card::Promptable`.

Suggested AI features:
1. **Card Summarization** - Generate summaries from card descriptions
2. **Smart Tagging** - Auto-suggest tags based on content
3. **Task Breakdown** - Generate checklist steps from descriptions
4. **Comment Analysis** - Extract action items from comments
5. **Priority Suggestions** - Recommend card priorities
6. **Similar Cards** - Find related cards using embeddings

The `card.to_prompt` method already formats cards for LLM consumption:
```ruby
card.to_prompt  # Returns formatted card with all context
```

Which AI feature would you like to implement?

I'll help you:
1. Create the necessary controller/service
2. Add background job for async processing
3. Create Stimulus controller for UI
4. Add routes and views
5. Integrate with your LLM API (OpenAI, Claude, etc.)
