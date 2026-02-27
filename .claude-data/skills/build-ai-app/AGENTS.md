# AI Agents (Tool Calling)

Create AI agents that can call your backend endpoints as tools.

## Full Example

```javascript
const agent = Nxcode.ai.createAgent({
  instructions: 'You are a helpful email assistant.',
  tools: [
    {
      name: 'search_emails',
      description: 'Search emails by query',
      parameters: { query: 'string', limit: 'number' },
      endpoint: '/api/emails/search'
    },
    {
      name: 'send_email',
      description: 'Send an email to someone',
      parameters: { to: 'string', subject: 'string', body: 'string' },
      endpoint: '/api/emails/send'
    }
  ],
  model: 'fast',   // Optional, default: 'fast'
  maxSteps: 10     // Optional, max tool calls per run
});

// Run the agent
const result = await agent.run('Find emails from John and reply saying hello');
console.log(result.output);      // Final text response
console.log(result.toolCalls);   // Tools that were called
console.log(result.usage);       // Token usage

// Agent remembers conversation history
const result2 = await agent.run('Now forward that email to Sarah');

// Clear history to start fresh
agent.reset();
```

## How It Works

1. User input → Agent decides which tool to call
2. SDK POSTs to your endpoint with tool parameters
3. Your backend returns result → Agent continues
4. Repeat until agent has final answer

## Tool Endpoint Format

Your backend receives POST requests with the tool parameters plus `_context`:

```javascript
// Your backend endpoint: POST /api/emails/search
// Request body:
{
  "query": "from:john",           // Tool parameters
  "limit": 10,
  "_context": {                   // Auto-injected context
    "agentId": "...",
    "stepIndex": 2,
    "previousTools": [            // Results from earlier tools
      { "name": "...", "result": {...} }
    ]
  }
}
```
