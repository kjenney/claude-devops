---
name: Datadog Troubleshooting
description: This skill should be used when the user asks to "search Datadog logs", "query Datadog metrics", "check Datadog monitors", "investigate Datadog alerts", "find service errors in Datadog", "check APM traces", "look at Datadog dashboards", "query service latency in Datadog", "check triggered monitors", "analyze Datadog logs for errors", or mentions using Datadog to investigate service health, performance, or incidents. Provides workflows for querying Datadog logs, metrics, monitors, and APM traces via the Datadog API.
---

# Datadog Troubleshooting

A structured approach to investigating service health using the Datadog API. Covers log search and analysis, metrics queries, monitor/alert status, and APM traces. Uses the Datadog v2 API via curl with `DD_API_KEY` and `DD_APP_KEY` environment variables.

## Prerequisites

The following environment variables must be set before making API calls:

```bash
export DD_API_KEY="<your-datadog-api-key>"
export DD_APP_KEY="<your-datadog-app-key>"
export DD_SITE="datadoghq.com"  # or datadoghq.eu for EU customers
```

If these are not set, ask the user to provide them. Never hardcode credentials.

## Core Workflow

### 1. Gather Context

Collect before querying:
- **Service name**: The Datadog service tag value (e.g., `my-api`, `payment-service`)
- **Environment**: `env` tag value (e.g., `prod`, `staging`)
- **Time window**: How far back to look (default: last 1 hour)
- **Type of investigation**: Logs, metrics, monitors, or APM traces

### 2. Base API Call Pattern

All Datadog API calls follow this pattern:

```bash
curl -s -X GET "https://api.${DD_SITE}/api/v2/<endpoint>" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json"
```

For POST requests (log search, metrics query):
```bash
curl -s -X POST "https://api.${DD_SITE}/api/v2/<endpoint>" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"<key>": "<value>"}'
```

Use `| jq '.'` to pretty-print JSON responses. Install jq if not present: `brew install jq` (macOS) or `apt install jq` (Linux).

### 3. Investigate by Type

Use the patterns in `references/datadog-api.md` for:
- **Logs**: Search and filter log events
- **Metrics**: Query time-series metric data
- **Monitors**: Check alert and monitor states
- **APM**: Query trace data and service performance

### 4. Time Window Calculation

Datadog API uses Unix timestamps (seconds) for time ranges:

```bash
# Last 1 hour
FROM=$(date -u -d '1 hour ago' +%s 2>/dev/null || date -u -v-1H +%s)
TO=$(date -u +%s)

# Last 15 minutes
FROM=$(date -u -d '15 minutes ago' +%s 2>/dev/null || date -u -v-15M +%s)
TO=$(date -u +%s)

# Last 24 hours
FROM=$(date -u -d '24 hours ago' +%s 2>/dev/null || date -u -v-24H +%s)
TO=$(date -u +%s)
```

For ISO8601 format (logs API):
```bash
FROM_ISO=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)
TO_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

### 5. Interpret and Summarize

After querying:
1. Highlight error patterns, spikes, and anomalies
2. Correlate findings across logs, metrics, and monitors
3. State the likely root cause based on data
4. Suggest follow-up investigation steps or remediation

## Quick Reference: Common Investigations

### High Error Rate
1. Search logs for `status:error service:<name> env:prod`
2. Query `sum:trace.web.request.errors{service:<name>,env:prod}.as_count()`
3. Check monitors for `service:<name>` in ALERT state

### High Latency
1. Query `avg:trace.web.request.duration{service:<name>,env:prod}`
2. Check APM service page via API
3. Look for correlation with upstream dependency metrics

### Service Down / No Traffic
1. Check monitors for `service:<name>` in NO_DATA or ALERT
2. Search logs for any recent events from service
3. Query `sum:trace.web.request.hits{service:<name>}` - if 0, no traffic is reaching

## Additional Resources

### Reference Files

- **`references/datadog-api.md`** - Complete API call examples for logs, metrics, monitors, APM
- **`references/log-query-syntax.md`** - Datadog log search query syntax and examples

### Examples

- **`examples/investigate-service.sh`** - Full service health investigation script
