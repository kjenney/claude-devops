---
name: datadog-query
description: Interactively query Datadog for service logs, metrics, monitors, and APM traces. Asks for the service name, environment, time window, and query type, then fetches and analyzes data from the Datadog API.
argument-hint: "[optional: service name or investigation description]"
allowed-tools:
  - Bash
  - Read
---

# Datadog Query

The user wants to investigate service health using Datadog. Query the Datadog API for logs, metrics, monitors, and/or APM traces.

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
DD_SITE="${DD_SITE:-datadoghq.com}"
```

## Step 2: Gather Query Parameters

Ask the user (all in one message):

1. **Service name**: The `service` tag value in Datadog (e.g., `payment-api`, `user-service`)
2. **Environment**: The `env` tag (e.g., `prod`, `staging`)
3. **Time window**: How far back to look (default: last 60 minutes)
4. **What to investigate**: Logs, metrics, monitors, APM traces, or all?

If the user provided an argument, use it as the service name or investigation context.

## Step 3: Set Variables

```bash
export SERVICE=<service-name>
export ENV=<environment>
export DD_SITE="${DD_SITE:-datadoghq.com}"
BASE_URL="https://api.${DD_SITE}"

# Calculate time window (adjust MINUTES as needed)
MINUTES=60
FROM=$(date -u -d "${MINUTES} minutes ago" +%s 2>/dev/null || date -u -v-${MINUTES}M +%s)
TO=$(date -u +%s)
FROM_ISO=$(date -u -d "${MINUTES} minutes ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${MINUTES}M +%Y-%m-%dT%H:%M:%SZ)
TO_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

AUTH=(-H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" -H "Content-Type: application/json")
```

## Step 4: Query Datadog

Run the appropriate queries based on the investigation type. Use the `datadog-troubleshooting` skill for detailed API call patterns.

### For Log Investigation:
- Search for error logs: `service:${SERVICE} env:${ENV} status:error`
- Aggregate log counts by status
- Search for specific error patterns (timeout, connection, exception)

### For Metrics:
- Query request rate, error rate, P95 latency
- Check CPU/memory if service-level infra metrics exist
- Use v1 metrics query API

### For Monitor Status:
- Search monitors tagged with `service:${SERVICE}`
- Filter for monitors in Alert or No Data state
- Show monitor name, state, and triggering query

### For APM Traces:
- Search for error traces
- Query slow traces (sorted by duration descending)
- Look for high error rates on specific endpoints/resources

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
