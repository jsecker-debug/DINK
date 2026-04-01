# DINK (PickleHub) Project

## Supabase

This project uses Supabase (project ref: `lqdlarbcrdkqpnsdkxcv`). When working with Supabase:

- **Always use the Supabase MCP tools** (configured in `.mcp.json`) for database operations, schema changes, migrations, edge functions, and querying data. Authenticate via `mcp__plugin_supabase_supabase__authenticate` if needed before using other Supabase MCP tools.
- **Always use the `/supabase-postgres-best-practices` skill** when writing, reviewing, or optimizing Postgres queries, schema designs, or database configurations.
