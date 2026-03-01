# Datadog Log Query Syntax

## Core Attributes

| Attribute | Example | Description |
|-----------|---------|-------------|
| `service:` | `service:payment-api` | Filter by service name |
| `env:` | `env:prod` | Filter by environment |
| `status:` | `status:error` | Log level: error, warn, info, debug |
| `host:` | `host:ip-10-0-1-1` | Filter by host |
| `@http.status_code:` | `@http.status_code:500` | HTTP response code |
| `@http.method:` | `@http.method:POST` | HTTP method |
| `@http.url:` | `@http.url:*/checkout*` | URL pattern with wildcard |

## Boolean Operators

```
# AND (implicit, space between terms)
service:api env:prod status:error

# OR
service:api OR service:payment

# NOT
service:api NOT status:info

# Grouping
(service:api OR service:payment) env:prod status:error
```

## Wildcards

```
# Prefix wildcard
@http.url:*/api/v1/*

# Message contains
message:*timeout*
message:*connection refused*
message:*exception*
```

## Numeric Ranges

```
# Range
@http.status_code:[500 TO 599]
@duration:[1000 TO *]  # Greater than 1000ms

# Greater/less than
@http.response_time:>500
@http.response_time:[* TO 200]
```

## Common Investigation Queries

### All Errors for a Service
```
service:<name> env:prod status:error
```

### HTTP 5xx Errors
```
service:<name> env:prod @http.status_code:[500 TO 599]
```

### Slow Requests (>1000ms)
```
service:<name> env:prod @duration:>1000
```

### Specific Error Message
```
service:<name> env:prod "connection refused"
```

### Database Errors
```
service:<name> env:prod (status:error "db" OR "database" OR "sql" OR "redis")
```

### Authentication Failures
```
service:<name> env:prod (@http.status_code:401 OR @http.status_code:403)
```

### Timeout Errors
```
service:<name> env:prod (message:*timeout* OR message:*timed out* OR @error.message:*timeout*)
```

### Memory/OOM Issues
```
service:<name> env:prod (message:*out of memory* OR message:*OOM* OR message:*heap*)
```

## Facets for Aggregation

Common facets available in most services:
- `service` - Service name
- `env` - Environment
- `status` - Log level
- `host` - Host name
- `@http.status_code` - HTTP status
- `@http.url` - Request URL
- `@http.method` - HTTP method
- `@duration` - Request duration in ms
- `@error.type` - Error class/type
- `@error.message` - Error message
- `@dd.trace_id` - Trace ID for correlation with APM

## Correlating Logs with APM Traces

If logs include a trace ID, find correlated APM trace:

```bash
# Search logs with specific trace ID
QUERY="service:${SERVICE} @dd.trace_id:${TRACE_ID}"

# Or find trace ID in logs first, then look up the trace
# Log search for a correlation:
QUERY="service:${SERVICE} env:${ENV} status:error @dd.trace_id:*"
```
