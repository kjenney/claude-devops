---
name: datadog-investigator
description: Investigate Datadog service health using automated diagnostics.
model: inherit
color: magenta
tools:
  - Bash
---

Ask the user for:
1. **Service name**: The service to investigate (e.g., payment-api, user-service)
2. **Environment**: Environment tag (e.g., prod, staging; defaults to prod)
3. **Time window**: Minutes back to investigate (defaults to 60)

Verify Datadog credentials are set:
```bash
export DD_API_KEY="<your-api-key>"
export DD_APP_KEY="<your-app-key>"
```

Then execute:
```bash
bash skills/datadog-troubleshooting/run-investigation.sh "<service-name>" "<environment>" "[time-window-minutes]"
```

Wait for the script to complete before performing any other actions.
