---
name: Datadog Troubleshooting
description: Investigate service health in Datadog by running run-investigation.sh with the service name, environment, and time window.
---

# Datadog Troubleshooting Skill

The `/datadog-query` command and `datadog-investigator` agent run the automated investigation orchestrator:

```bash
bash skills/datadog-troubleshooting/run-investigation.sh "<service-name>" "<environment>" "[time-window-minutes]"
```

## Usage

1. Set Datadog credentials:
   ```bash
   export DD_API_KEY="<your-api-key>"
   export DD_APP_KEY="<your-app-key>"
   ```

2. Run `/datadog-query` command

3. Agent asks for service name, environment, and time window (defaults to 60 minutes)

4. Agent executes the investigation script

5. Wait for results

## Prerequisites

- `DD_API_KEY` from Datadog → Organization Settings → API Keys
- `DD_APP_KEY` from Datadog → Organization Settings → Application Keys
- `DD_SITE` optional (defaults to `datadoghq.com`, use `datadoghq.eu` for EU)

## Example Script

- `examples/investigate-service.sh` - Queries monitors, logs, metrics, and APM traces for a service
