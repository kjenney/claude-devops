---
name: datadog-query
description: Interactively query Datadog for service logs, metrics, monitors, and APM traces. Asks for the service name, environment, time window, and query type, then fetches and analyzes data from the Datadog API.
argument-hint: "[optional: service name or investigation description]"
allowed-tools:
  - Agent
---

# Datadog Query

The user wants to investigate service health using Datadog with automated investigation.

Launch the Datadog investigator agent to handle the investigation. The agent will:
1. Verify Datadog API credentials
2. Ask for the service name and environment to investigate
3. Query monitors, logs, errors, and APM traces
4. Analyze service health and identify anomalies
5. Provide findings and recommendations

Use the Agent tool to launch the datadog-investigator agent with the user's service name or investigation request.

## How It Works

The agent will guide you through the investigation process using this script:

```bash
bash skills/datadog-troubleshooting/run-investigation.sh "<service-name>" "<environment>" "[time-window-minutes]"
```

**Parameters:**
- `service-name`: The `service` tag value in Datadog (e.g., `payment-api`, `user-service`)
- `environment`: The `env` tag value (e.g., `prod`, `staging`; defaults to `prod`)
- `time-window-minutes`: How many minutes back to investigate (defaults to `60`)

**What the script does:**
1. Verifies Datadog API credentials (DD_API_KEY and DD_APP_KEY)
2. Queries Datadog for service health using monitors, logs, metrics, and APM traces
3. Provides a comprehensive summary of:
   - Triggered monitors and alert status
   - Recent error logs with patterns
   - Error rate and latency metrics
   - Key performance indicators
   - Links to the Datadog UI for deeper investigation

**Required environment variables:**
- `DD_API_KEY`: Your Datadog API key (get from Organization Settings → API Keys)
- `DD_APP_KEY`: Your Datadog application key (get from Organization Settings → Application Keys)
- `DD_SITE`: Datadog site (optional; defaults to `datadoghq.com`, use `datadoghq.eu` for EU)

## Step 1: Verify Credentials

Check that Datadog credentials are set:

```bash
echo "DD_API_KEY is ${DD_API_KEY:+set}${DD_API_KEY:-NOT SET}"
echo "DD_APP_KEY is ${DD_APP_KEY:+set}${DD_APP_KEY:-NOT SET}"
```

If not set, ask the user:
- **DD_API_KEY**: Found in Datadog → Organization Settings → API Keys
- **DD_APP_KEY**: Found in Datadog → Organization Settings → Application Keys

Ask them to set in their shell: `export DD_API_KEY=... && export DD_APP_KEY=...`

Also set the Datadog site (default: `datadoghq.com`, EU customers use `datadoghq.eu`):
```bash
export DD_SITE="${DD_SITE:-datadoghq.com}"
```

## Step 2: Gather Query Parameters

Ask the user (all in one message):

1. **Service name**: The `service` tag value in Datadog (e.g., `payment-api`, `user-service`)
2. **Environment**: The `env` tag (e.g., `prod`, `staging`; default: `prod`)
3. **Time window**: How far back to look in minutes (default: last 60 minutes)

If the user provided an argument, use it as the service name.

## Step 3: Automatic Investigation

Once credentials and parameters are confirmed, run the automated investigation script which will:

1. Verify Datadog API access
2. Run the comprehensive service investigation
3. Query monitors, logs, errors, and APM traces
4. Provide health summary with relevant context

```bash
bash skills/datadog-troubleshooting/run-investigation.sh "<service-name>" "<environment>" "[time-window-minutes]"
```

This script automatically:
- Checks triggered monitors for the service
- Searches recent error logs
- Aggregates error counts by status
- Queries P95 latency from APM
- Provides Datadog UI link for full context

## Step 4: Additional Queries (If Needed)

If you need deeper analysis beyond the automated investigation, use the `datadog-troubleshooting` skill for detailed API call patterns and custom queries.

### For deeper Log Investigation:
- Search for specific error patterns: `service:${SERVICE} env:${ENV} "error text"`
- Aggregate by facets to group errors by source or type
- Search for specific exception types or stack traces

### For detailed Metrics:
- Query request rate, error rate, and latency percentiles (P50, P95, P99)
- Check infrastructure metrics if available
- Use v1 metrics query API or Metrics API documentation

### For deeper Monitor Analysis:
- Review recent monitor state changes and reasons
- Correlate multiple firing monitors to identify root cause
- Check composite monitor conditions

### For detailed APM Traces:
- Search for error traces filtered by service and environment
- Query slow traces (sorted by duration descending)
- Look for high error rates on specific endpoints or resources
- Correlate trace IDs with log entries

## Step 5: Analyze and Report

After gathering data:
1. **Summarize the health**: Is the service healthy? Error rate, latency trends
2. **Highlight anomalies**: Spike in errors, latency increase, monitors firing
3. **Show relevant log samples**: Most recent error messages
4. **Suggest follow-up**: Additional queries, correlated services to check, or remediation

## Tips

- Always check triggered monitors first — they're the fastest signal
- Log search with `status:error` is the quickest way to see recent failures
- Correlate log trace IDs with APM if the service has distributed tracing
- For intermittent issues, use a longer time window (24h) to find patterns
- The `datadog-troubleshooting` skill has the full API reference and log query syntax
