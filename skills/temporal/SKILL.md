---
name: temporal
description: Temporal platform documentation and operational reference
---

# Temporal Platform Documentation

## Description

Comprehensive documentation for the [Temporal](https://temporal.io) workflow orchestration platform, covering architecture, SDK usage, deployment, configuration, monitoring, and operational best practices. This skill synthesizes knowledge from **official Temporal documentation** and **configuration analysis** to provide a unified reference.

**Supported SDKs:** Go, Java, Python, TypeScript, PHP, .NET, Ruby

### Source Summary

| Source Type            | Files | Confidence |
| ---------------------- | ----- | ---------- |
| Official Documentation | 266   | High       |
| Configuration Analysis | 6     | Medium     |

Both sources are in agreement on all covered topics. No conflicts detected.

---

## When to Use This Skill

Use this skill when you need to:

### Core Development

- **Define Workflows** - Understand Workflow Definitions, deterministic constraints, and Workflow Types across Go, Java, Python, TypeScript, PHP, and .NET
- **Implement Activities** - Learn Activity Definitions, execution patterns, timeouts, retries, and heartbeating
- **Handle Messages** - Work with Signals, Queries, and Updates for Workflow communication
- **Use Child Workflows** - Partition workloads, represent resources, or create separate services
- **Version Workflow Code** - Apply patching or Worker Versioning strategies for safe deployments

### Operations & Deployment

- **Deploy Temporal** - Self-host using Docker, Kubernetes (Helm), or binary deployment
- **Configure Clusters** - Set up `development.yaml` with persistence, TLS, metrics, and services
- **Monitor Performance** - Use Prometheus metrics (`service_requests`, `service_latency`, `poll_success`, etc.)
- **Manage Namespaces** - Follow naming conventions and organizational best practices
- **Set Up Archival** - Configure Event History and Visibility archival

### Temporal Cloud

- **Choose Regions** - Find AWS and GCP region codes, endpoints, and replication options
- **Configure Connectivity** - Set up PrivateLink (AWS) or Private Service Connect (GCP)
- **Manage Actions & Limits** - Understand per-Namespace and per-Workflow limits

### Troubleshooting

- **Debug Workflows** - Use Stack Trace Queries, Event History analysis, and the Web UI
- **Handle Errors** - Understand failure types, retry policies, and error handling patterns
- **Resolve Non-Determinism** - Diagnose and fix deterministic constraint violations

---

## Key Concepts

### Workflow Execution Model

Temporal Workflows are resilient. They can run for years, even if the underlying infrastructure fails. If the application crashes, Temporal automatically recreates its pre-failure state so it can continue where it left off.

**Three key terms:**

1. **Workflow Definition** - The code that defines your Workflow
2. **Workflow Type** - The name that maps to a Workflow Definition (an identifier)
3. **Workflow Execution** - A running instance of a Workflow Definition

### Deterministic Constraints

Workflow code must be deterministic - it must make the same API calls in the same sequence given the same input. The following operations produce **Commands** and must not be reordered without proper versioning:

- Starting/cancelling Timers
- Scheduling/cancelling Activity Executions
- Starting/cancelling Child Workflow Executions
- Signalling external Workflow Executions
- Scheduling/cancelling Nexus operations
- Ending the Workflow (completing, failing, cancelling, continue-as-new)
- `Patched`/`GetVersion` calls
- Upserting Search Attributes or Memos

**Safe changes** (no versioning needed):

- Changing input parameters, return values, or timeouts of Activities/Child Workflows
- Changing Timer durations (except to/from 0 in Java/Python/Go, or to/from -1 in .NET)
- Adding Signal handlers for unsent Signal types

### Message Passing

Temporal supports three types of messages to Workflow Executions:

| Message    | Direction                   | Synchronous | Mutates State  |
| ---------- | --------------------------- | ----------- | -------------- |
| **Signal** | Client/Workflow -> Workflow | No          | Yes            |
| **Query**  | Client -> Workflow          | Yes         | No (read-only) |
| **Update** | Client -> Workflow          | Yes         | Yes            |

**Signal-With-Start**: Lazily initialize a Workflow while sending a Signal. If the Workflow exists, it receives the Signal; otherwise, a new Workflow starts and immediately receives it.

**Update-With-Start**: Send an Update request, starting a Workflow if necessary. Great for lazy initialization and early-return patterns (e.g., shopping carts, payment validation).

### Continue-As-New

Continue-As-New allows you to checkpoint a Workflow's state and start a fresh Workflow Execution with a new Event History. Use it when:

- Event History is growing too large (approaching limits)
- Long-running Workflows need to move to newer code versions
- Building "Entity Workflows" that represent durable objects running indefinitely

### Child Workflows vs Activities

| Aspect           | Child Workflow                     | Activity                     |
| ---------------- | ---------------------------------- | ---------------------------- |
| API Access       | All Workflow APIs                  | No Workflow APIs             |
| Constraints      | Must be deterministic              | No deterministic constraints |
| On Parent Cancel | Configurable (Parent Close Policy) | Always cancelled             |
| State Tracking   | Full Event History                 | Input/output/retries only    |
| Best For         | Composite operations, partitioning | Single external operations   |

**Rule of thumb:** When in doubt, use an Activity.

---

## Quick Reference

### Workflow Definition Examples

_From official documentation - high confidence_

**Go:**

```go
func YourBasicWorkflow(ctx workflow.Context) error {
    // ...
    return nil
}
```

**Java:**

```java
@WorkflowInterface
public interface YourBasicWorkflow {
    @WorkflowMethod
    String workflowMethod(Arguments args);
}

// Implementation
public class YourBasicWorkflowImpl implements YourBasicWorkflow {
    // ...
}
```

**Python:**

```python
@workflow.defn
class YourWorkflow:
    @workflow.run
    async def YourBasicWorkflow(self, input: str) -> str:
        # ...
```

**TypeScript:**

```typescript
type BasicWorkflowArgs = {
  param: string;
};

export async function WorkflowExample(
  args: BasicWorkflowArgs,
): Promise<{ result: string }> {
  // ...
}
```

**C# / .NET:**

```csharp
[Workflow]
public class YourBasicWorkflow {
    [WorkflowRun]
    public async Task<string> workflowExample(string param) {
        // ...
    }
}
```

### Cluster Configuration (development.yaml)

_From official documentation - high confidence_

**Minimal global config with Prometheus metrics:**

```yaml
global:
  membership:
    broadcastAddress: "127.0.0.1"
  metrics:
    prometheus:
      framework: "tally"
      listenAddress: "127.0.0.1:8000"
```

**Persistence with Cassandra and Elasticsearch:**

```yaml
persistence:
  defaultStore: default
  visibilityStore: cass-visibility
  secondaryVisibilityStore: es-visibility
  numHistoryShards: 512
  datastores:
    default:
      cassandra:
        hosts: "127.0.0.1"
        keyspace: "temporal"
        user: "username"
        password: "password"
    cass-visibility:
      cassandra:
        hosts: "127.0.0.1"
        keyspace: "temporal_visibility"
    es-visibility:
      elasticsearch:
        version: "v7"
        logLevel: "error"
        url:
          scheme: "http"
          host: "127.0.0.1:9200"
        indices:
          visibility: temporal_visibility_v1_dev
        closeIdleConnectionsInterval: 15s
```

**Frontend TLS configuration:**

```yaml
global:
  tls:
    frontend:
      server:
        certFile: /path/to/cert/file
        keyFile: /path/to/key/file
      client:
        serverName: dnsSanInFrontendCertificate
```

### Docker Quick Start

_From official documentation - high confidence_

```bash
git clone https://github.com/temporalio/docker-compose.git
cd docker-compose
docker compose up
```

Connect at `127.0.0.1:7233` (gRPC) and `127.0.0.1:8080` (Web UI).

### Key Prometheus Metrics

_From official documentation - high confidence_

```promql
# Service requests by operation on Frontend
sum by (operation) (rate(service_requests{service_name="frontend"}[2m]))

# P95 service latency by operation
histogram_quantile(0.95, sum(rate(service_latency_bucket{service_name="frontend"}[5m])) by (operation, le))

# History task processing errors
sum(rate(task_errors{operation=~"TransferActive.*"}[1m]))

# Poll timeouts (no tasks available)
sum(rate(poll_timeouts{}[5m]))
```

### Archival Configuration

_From official documentation - high confidence_

```yaml
archival:
  history:
    state: "enabled"
    enableRead: true
    provider:
      filestore:
        fileMode: "0666"
        dirMode: "0766"
      gstorage:
        credentialsPath: "/tmp/gcloud/keyfile.json"
  visibility:
    state: "enabled"
    enableRead: true
    provider:
      filestore:
        fileMode: "0666"
        dirMode: "0766"

namespaceDefaults:
  archival:
    history:
      state: "enabled"
      URI: "file:///tmp/temporal_archival/development"
    visibility:
      state: "disabled"
      URI: "file:///tmp/temporal_vis_archival/development"
```

### Multi-Cluster Replication

_From official documentation - high confidence_

```yaml
clusterMetadata:
  enableGlobalNamespace: true
  failoverVersionIncrement: 10
  masterClusterName: "active"
  currentClusterName: "active"
  clusterInformation:
    active:
      enabled: true
      initialFailoverVersion: 0
      rpcAddress: "127.0.0.1:7233"
```

### Service Definition

_From official documentation - high confidence_

```yaml
services:
  frontend:
    rpc:
      grpcPort: 8233
      membershipPort: 8933
      bindOnIP: "0.0.0.0"
```

Four service roles: `frontend`, `matching`, `worker`, `history`. Each can be deployed independently (e.g., one per pod in Kubernetes).

---

## Working with This Skill

### For Beginners

1. **Start here:** Read `references/documentation/overview/getting-started.md` for SDK setup
2. **Understand Workflows:** Read `references/documentation/workflows/workflow-overview.md`
3. **Learn Activities:** Check `references/documentation/other/activity.md`
4. **Try Docker:** Use the Docker Quick Start above to run Temporal locally
5. **Explore the Web UI:** See `references/documentation/overview/web-ui.md`

### For Intermediate Users

1. **Message Passing:** Explore Signals, Queries, and Updates in `references/documentation/workflows/sending-messages.md`
2. **Child Workflows:** Learn partitioning patterns in `references/documentation/workflows/child-workflows.md`
3. **Versioning:** Understand patching in `references/documentation/workflows/patching.md`
4. **Schedules:** Automate Workflows with `references/documentation/features/schedules.md`
5. **Error Handling:** Review `references/documentation/api/errors.md` and `references/documentation/api/failures.md`

### For Advanced Users / Operators

1. **Cluster Configuration:** Deep dive into `references/documentation/api/configuration.md`
2. **Monitoring:** Set up dashboards using `references/documentation/api/cluster-metrics.md`
3. **Deployment:** Plan production deployment with `references/documentation/guides/deployment.md`
4. **Security:** Configure TLS and access control via `references/documentation/guides/security.md`
5. **Multi-Cluster:** Set up replication using `references/documentation/guides/multi-cluster-replication.md`
6. **Scaling:** Understand limits in `references/documentation/workflows/limits.md`

### Navigation Tips

- **By topic:** Use the category directories (`workflows/`, `features/`, `guides/`, `api/`, `overview/`)
- **By SDK:** Many documents contain language-specific tabs (Go, Java, Python, TypeScript, PHP, .NET)
- **By role:** Developers should focus on `workflows/` and `features/`; Operators on `guides/` and `api/`
- **Configuration:** Both `references/config_patterns/` and `references/documentation/api/configuration.md` cover configuration; the documentation source is more comprehensive

---

## Documentation Categories

### Overview (6 files)

`references/documentation/overview/`

Getting started guides, glossary, quickstarts, and Web UI documentation. Start here if you're new to Temporal.

### Workflows (17 files)

`references/documentation/workflows/`

Core Workflow concepts: definitions, executions, child workflows, signals/queries/updates, versioning, continue-as-new, cron jobs, schedules, timers, and limits.

### Features (17 files)

`references/documentation/features/`

Platform capabilities: schedules, debugging, observability, data encryption, failure detection, Temporal Nexus, testing suite, and cloud vs self-hosted comparison.

### Guides (14 files)

`references/documentation/guides/`

Operational guides: deployment, monitoring, security, namespaces, visibility, archival, multi-cluster replication, and server upgrades.

### API Reference (19 files)

`references/documentation/api/`

Technical reference: cluster configuration, metrics, commands, events, errors, failures, SDK metrics, server options, region endpoints, and dynamic configuration.

### Security (1 file)

`references/documentation/security/`

Security reference documentation.

### Other (192 files)

`references/documentation/other/`

Extensive reference material covering SDK-specific guides (Go, Java, Python, TypeScript, PHP, .NET), cloud operations, activity patterns, worker management, and 150+ additional reference documents.

---

## Configuration Patterns

_From C3.4 configuration analysis (medium confidence) and official documentation (high confidence)_

**Configuration Files Analyzed:** 6
**Total Settings:** 36

The configuration analysis identified 6 JSON configuration files used in the Temporal analysis pipeline. The official documentation provides comprehensive YAML configuration reference for the Temporal Cluster itself.

### Cluster Configuration Sections

| Section               | Required | Purpose                                                 |
| --------------------- | -------- | ------------------------------------------------------- |
| `global`              | Yes      | Process-wide config: membership, metrics, TLS, pprof    |
| `persistence`         | Yes      | Data store config: Cassandra, MySQL, PostgreSQL, SQLite |
| `log`                 | No       | Logging: stdout, level, output file                     |
| `clusterMetadata`     | Yes      | Cluster identity and multi-cluster replication          |
| `services`            | Yes      | Service roles: frontend, matching, worker, history      |
| `publicClient`        | Yes      | Worker-to-server connection for background maintenance  |
| `archival`            | No       | Event History and Visibility archival                   |
| `namespaceDefaults`   | No       | Default Namespace archival settings                     |
| `dcRedirectionPolicy` | No       | Cross-DC API forwarding policy                          |
| `dynamicConfigClient` | No       | File-based dynamic configuration                        |

### Supported Databases

| Database         | Persistence | Visibility | Notes                         |
| ---------------- | ----------- | ---------- | ----------------------------- |
| Apache Cassandra | Yes         | Yes        | Production-grade, distributed |
| MySQL            | Yes         | Yes        | SQL option                    |
| PostgreSQL       | Yes         | Yes        | SQL option                    |
| SQLite           | Yes         | Yes        | Development/embedded only     |

### Metrics Providers

| Provider   | Native Support  | Configuration Key           |
| ---------- | --------------- | --------------------------- |
| Prometheus | Yes             | `global.metrics.prometheus` |
| M3         | Yes             | `global.metrics.m3`         |
| StatsD     | No (not native) | `global.metrics.statsd`     |

_See `references/config_patterns/` for analysis pipeline configuration details_
_See `references/documentation/api/configuration.md` for complete cluster configuration reference_

---

## Available References

### Documentation (`references/documentation/`)

266 markdown files of official Temporal documentation organized by category. **High confidence** - sourced directly from Temporal's documentation site.

| Category     | Files | Key Topics                                              |
| ------------ | ----- | ------------------------------------------------------- |
| `overview/`  | 6     | Getting started, glossary, Web UI                       |
| `workflows/` | 17    | Workflow definitions, executions, messaging, versioning |
| `features/`  | 17    | Schedules, debugging, encryption, observability         |
| `guides/`    | 14    | Deployment, monitoring, security, namespaces            |
| `api/`       | 19    | Configuration, metrics, commands, events, errors        |
| `security/`  | 1     | Security reference                                      |
| `other/`     | 192   | SDK guides, cloud ops, activities, workers, and more    |

### Dependencies (`references/dependencies/`)

Dependency analysis in multiple formats. Note: the analyzed project had no external dependencies detected.

- `dependency_graph.json` - Graph data (JSON)
- `dependency_graph.dot` - GraphViz format
- `dependency_graph.mmd` - Mermaid diagram format
- `statistics.json` - Dependency statistics

### Configuration Patterns (`references/config_patterns/`)

Analysis of configuration files used in the documentation pipeline. **Medium confidence** - reflects analysis tooling configuration, not Temporal cluster configuration.

- `config_patterns.md` - Human-readable overview
- `config_patterns.json` - Detailed analysis (6 files, 36 settings)

---

## Temporal Cloud Quick Reference

### AWS Regions

| Region                   | API Code             | Endpoint                                |
| ------------------------ | -------------------- | --------------------------------------- |
| N. Virginia (us-east-1)  | `aws-us-east-1`      | `aws-us-east-1.region.tmprl.cloud`      |
| Ohio (us-east-2)         | `aws-us-east-2`      | `aws-us-east-2.region.tmprl.cloud`      |
| Oregon (us-west-2)       | `aws-us-west-2`      | `aws-us-west-2.region.tmprl.cloud`      |
| Ireland (eu-west-1)      | `aws-eu-west-1`      | `aws-eu-west-1.region.tmprl.cloud`      |
| Frankfurt (eu-central-1) | `aws-eu-central-1`   | `aws-eu-central-1.region.tmprl.cloud`   |
| Tokyo (ap-northeast-1)   | `aws-ap-northeast-1` | `aws-ap-northeast-1.region.tmprl.cloud` |
| Sydney (ap-southeast-2)  | `aws-ap-southeast-2` | `aws-ap-southeast-2.region.tmprl.cloud` |

_See `references/documentation/api/awsregions.md` for full list with PrivateLink endpoints and replication options_

### GCP Regions

_See `references/documentation/api/gcpregions.md` for full GCP region list with Private Service Connect details_
