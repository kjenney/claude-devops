# Datadog API Reference

Base URL: `https://api.${DD_SITE}/api/v2`
Auth headers (add to every request):
```
-H "DD-API-KEY: ${DD_API_KEY}"
-H "DD-APPLICATION-KEY: ${DD_APP_KEY}"
```

## Logs API

### Search Logs (POST /logs/events/search)

```bash
curl -s -X POST "https://api.${DD_SITE}/api/v2/logs/events/search" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"filter\": {
      \"query\": \"service:${SERVICE} env:${ENV} status:error\",
      \"from\": \"${FROM_ISO}\",
      \"to\": \"${TO_ISO}\"
    },
    \"sort\": \"-timestamp\",
    \"page\": {
      \"limit\": 50
    }
  }" | jq '.data[].attributes | {timestamp: .timestamp, message: .message, status: .status}'
```

### Aggregate Logs (count errors by status)

```bash
curl -s -X POST "https://api.${DD_SITE}/api/v2/logs/analytics/aggregate" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"compute\": [{\"aggregation\": \"count\", \"type\": \"total\"}],
    \"filter\": {
      \"query\": \"service:${SERVICE} env:${ENV}\",
      \"from\": \"${FROM_ISO}\",
      \"to\": \"${TO_ISO}\"
    },
    \"group_by\": [{\"facet\": \"status\", \"total\": {\"type\": \"estimated_count\"}}]
  }" | jq '.data.buckets[] | {status: .by.status, count: .computes.c0}'
```

### Get Log by ID

```bash
curl -s "https://api.${DD_SITE}/api/v2/logs/events/${LOG_ID}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.'
```

## Metrics API

### Query Metrics (GET /query - v1 API)

```bash
# Note: metrics query uses v1 API
curl -s "https://api.${DD_SITE}/api/v1/query?from=${FROM}&to=${TO}&query=${METRIC_QUERY}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.series[].pointlist[-5:]'
```

Common metric queries:
```bash
# Request rate
METRIC_QUERY="sum:trace.web.request.hits{service:${SERVICE},env:${ENV}}.as_rate()"

# Error rate
METRIC_QUERY="sum:trace.web.request.errors{service:${SERVICE},env:${ENV}}.as_rate()"

# P95 latency
METRIC_QUERY="p95:trace.web.request.duration{service:${SERVICE},env:${ENV}}"

# CPU utilization
METRIC_QUERY="avg:system.cpu.user{service:${SERVICE},env:${ENV}}"

# Memory usage
METRIC_QUERY="avg:system.mem.used{service:${SERVICE},env:${ENV}}"
```

### List Metrics

```bash
curl -s "https://api.${DD_SITE}/api/v1/metrics?q=trace.${SERVICE}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.metrics[]'
```

## Monitors API

### Get All Triggered Monitors

```bash
curl -s "https://api.${DD_SITE}/api/v1/monitor?name=${SERVICE}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | \
  jq '.[] | select(.overall_state == "Alert" or .overall_state == "No Data") | {id: .id, name: .name, state: .overall_state, message: .message}'
```

### Get Monitor by ID

```bash
curl -s "https://api.${DD_SITE}/api/v1/monitor/${MONITOR_ID}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '{name: .name, state: .overall_state, query: .query, message: .message}'
```

### Search Monitors

```bash
curl -s "https://api.${DD_SITE}/api/v1/monitor/search?query=tag:service:${SERVICE}&monitor_tags=env:${ENV}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | \
  jq '.monitors[] | {id: .id, name: .name, status: .status}'
```

### Get Monitor Groups (for multi-alert monitors)

```bash
curl -s "https://api.${DD_SITE}/api/v1/monitor/${MONITOR_ID}/groups" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.groups[] | {group: .group, status: .status, last_triggered: .last_triggered_ts}'
```

## APM / Traces API

### List APM Services

```bash
curl -s "https://api.${DD_SITE}/api/v1/services" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.services[]'
```

### Get APM Service Stats (v2)

```bash
curl -s -X POST "https://api.${DD_SITE}/api/v2/apm/stats" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"attributes\": {
        \"query\": \"service:${SERVICE} env:${ENV}\",
        \"from\": ${FROM}000,
        \"to\": ${TO}000,
        \"group_by\": [\"resource_name\"],
        \"stats\": [\"hits\", \"errors\", \"duration\"]
      }
    }
  }" | jq '.'
```

### Search Traces

```bash
# Search for slow or errored traces
curl -s -X POST "https://api.${DD_SITE}/api/v2/apm/traces" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"filter\": {
      \"query\": \"service:${SERVICE} env:${ENV} status:error\",
      \"from\": \"${FROM_ISO}\",
      \"to\": \"${TO_ISO}\"
    },
    \"page\": {\"limit\": 20},
    \"sort\": \"-duration\"
  }" | jq '.data[] | {id: .id, duration: .attributes.duration, resource: .attributes.resource_name, error: .attributes.error}'
```

## Dashboards API

### List Dashboards

```bash
curl -s "https://api.${DD_SITE}/api/v1/dashboard" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.dashboards[] | {id: .id, title: .title, url: .url}'
```

### Get Dashboard

```bash
curl -s "https://api.${DD_SITE}/api/v1/dashboard/${DASHBOARD_ID}" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '{title: .title, url: .url}'
```

## Downtime API

### List Active Downtimes

```bash
curl -s "https://api.${DD_SITE}/api/v1/downtime?current_only=true" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.[] | {id: .id, scope: .scope, message: .message, start: .start, end: .end}'
```
