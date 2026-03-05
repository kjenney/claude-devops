---
name: datadog-query
description: Investigate Datadog service health using automated diagnostics.
argument-hint: "[optional: service name or investigation description]"
allowed-tools:
  - Agent
---

Launch the Datadog investigator agent to investigate service health.

The agent will ask for:
- **Service name** (e.g., payment-api, user-service)
- **Environment** (defaults to prod)
- **Time window in minutes** (defaults to 60)

Then run:
```bash
PLUGIN_DIR="$(dirname "$(find ~ -name ".claude-plugin" -type d 2>/dev/null | grep devops-claude-plugin)" 2>/dev/null)" && \
bash "$PLUGIN_DIR/skills/datadog-troubleshooting/run-investigation.sh" "<service-name>" "<environment>" "[time-window-minutes]"
```

Note: Requires DD_API_KEY and DD_APP_KEY environment variables set.
