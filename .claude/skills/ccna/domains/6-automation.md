# Domain 6: Automation & Programmability (10%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 6.1 Explain how automation impacts network management

**Exam focus:**
- **Traditional**: per-device CLI, manual changes, configuration drift, slow.
- **Automated**: declarative intent, version-controlled configs, consistent at scale, auditable.
- Faster changes, fewer human errors, repeatable deployments.
- Tradeoff: requires up-front investment in tooling and skills.

---

## 6.2 Compare traditional networks with controller-based networking

**Exam focus:**

**Traditional (distributed control plane):**
- Each router/switch runs its own routing protocols, makes its own forwarding decisions.
- Configuration is per-device.
- Topology changes propagate via routing protocols (OSPF, EIGRP, etc.).

**Controller-based (centralized control plane):**
- Controller computes the topology and pushes flows/configs to devices.
- Devices retain data plane (still forward traffic) but lose some control-plane autonomy.
- Examples: Cisco DNA Center, OpenDaylight, ONOS.
- Faster policy deployment; single pane of glass.

---

## 6.3 Describe controller-based, software-defined architecture (overlay, underlay, fabric)

**Exam focus:**
- **Underlay**: physical IP network (routers, switches, links). Provides reachability between fabric edges. Typically OSPF or IS-IS in spine-leaf.
- **Overlay**: virtual logical network on top of underlay. Encapsulates user traffic in tunnels (VXLAN, GRE, MPLS).
- **Fabric**: combination of underlay + overlay + control plane. Cisco SD-Access fabric uses LISP (control), VXLAN (data), Cisco TrustSec (policy).

**Separation of planes:**
- **Data plane**: forwarding (per-packet)
- **Control plane**: routing decisions, neighbor maintenance
- **Management plane**: SSH, SNMP, NETCONF, syslog
- SDN moves control plane to a centralized controller, leaving devices with just data plane.

---

## 6.4 Compare traditional campus device management with Cisco DNA Center enabled device management

**Exam focus:**
- **Traditional**: SSH/CLI, per-device, scripts, sometimes Cisco Prime.
- **DNA Center**:
  - GUI-driven, intent-based networking.
  - Plug-and-Play onboarding.
  - Software image management at scale.
  - Assurance / analytics.
  - Path Trace, Network Time Travel.
  - REST API for everything the GUI can do.

---

## 6.5 Describe characteristics of REST-based APIs (CRUD, HTTP verbs, data encoding)

**Exam focus:**
- **REST** = Representational State Transfer. Stateless. Uses HTTP.
- **CRUD → HTTP verbs:**
  - Create → **POST**
  - Read → **GET**
  - Update → **PUT** (full replace) or **PATCH** (partial)
  - Delete → **DELETE**
- **Status codes:**
  - 2xx success (200 OK, 201 Created, 204 No Content)
  - 3xx redirect (301, 302)
  - 4xx client error (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found)
  - 5xx server error (500 Internal Server Error, 503 Service Unavailable)
- **Data encoding**: JSON (most common), XML, YAML.
- **Headers**: `Content-Type: application/json`, `Authorization: Bearer <token>`.

**Example curl:**
```
curl -X GET https://dnac.example.com/dna/intent/api/v1/network-device \
  -H "X-Auth-Token: <token>" \
  -H "Content-Type: application/json"
```

---

## 6.6 Recognize the capabilities of configuration management mechanisms (Puppet, Chef, Ansible)

**Exam focus:**

| Tool | Language | Architecture | Push/Pull | Agent? |
|---|---|---|---|---|
| **Ansible** | YAML (playbooks) | Agentless | Push (over SSH) | No |
| **Puppet** | Puppet DSL (Ruby-based) | Master + agent | Pull (agent polls master every 30 min) | Yes |
| **Chef** | Ruby (recipes/cookbooks) | Server + workstation + nodes | Pull (chef-client polls) | Yes |
| **SaltStack** | YAML + Jinja2 | Master + minion | Push or pull | Yes |

**Why Ansible is popular for networking:**
- Agentless (no software on switches)
- SSH or NETCONF transport
- YAML is human-readable
- Idempotent modules (running twice = same result)

**Ansible terminology:**
- **Playbook**: YAML file describing tasks to run.
- **Inventory**: list of managed hosts.
- **Module**: a unit of work (e.g., `ios_config`).
- **Role**: bundled tasks + variables + templates.

---

## 6.7 Interpret JSON encoded data

**Exam focus:**

```json
{
  "device": {
    "hostname": "R1",
    "interfaces": [
      {"name": "GigabitEthernet0/0", "ip": "192.168.1.1", "up": true},
      {"name": "GigabitEthernet0/1", "ip": null, "up": false}
    ],
    "ospf_enabled": true
  }
}
```

**Rules:**
- Curly braces `{}` = object (key-value pairs)
- Square brackets `[]` = array (ordered list)
- Strings in **double quotes** (single quotes are invalid)
- Numbers without quotes
- Booleans: `true` / `false` (lowercase)
- Null: `null` (lowercase, no quotes)
- Keys must be quoted strings
- Comma between items, no trailing comma
- Comments are NOT allowed in standard JSON

**Reading paths:**
- `device.hostname` → "R1"
- `device.interfaces[0].ip` → "192.168.1.1"
- `device.interfaces[1].up` → false

---

## YAML (also commonly tested)

```yaml
device:
  hostname: R1
  interfaces:
    - name: GigabitEthernet0/0
      ip: 192.168.1.1
      up: true
    - name: GigabitEthernet0/1
      ip: null
      up: false
  ospf_enabled: true
```

**Rules:**
- Indentation (spaces, not tabs) defines structure
- `-` prefix = list item
- `key: value` for mappings
- Strings usually unquoted; quote if value contains special characters
- Comments start with `#`
- Boolean: `true`/`false` (also `yes`/`no`, `on`/`off` — but stick to true/false on exam)
- Used by: Ansible playbooks, Kubernetes, Cisco device configs in NSO

---

## XML

```xml
<device>
  <hostname>R1</hostname>
  <interfaces>
    <interface>
      <name>GigabitEthernet0/0</name>
      <ip>192.168.1.1</ip>
    </interface>
  </interfaces>
</device>
```

- Used by NETCONF.
- More verbose than JSON.
- Self-closing tags: `<empty/>`.

---

## NETCONF / RESTCONF (concept-only on CCNA)

- **NETCONF** (RFC 6241): SSH-based (port 830), XML payload, runs configurations on candidate datastore + commits.
- **RESTCONF** (RFC 8040): HTTP/HTTPS, JSON or XML, REST-style URLs over YANG models.
- **YANG**: data-modeling language describing what config and state data exists on a device.

---

## Common exam traps

- **POST = Create, GET = Read, PUT = Update (full), PATCH = Update (partial), DELETE = Delete.**
- **404 = client asked for something that doesn't exist; 401 = not authenticated; 403 = authenticated but not authorized.**
- **JSON requires double quotes** — single quotes are invalid.
- **JSON does NOT allow comments**, YAML and Python do.
- **YAML uses spaces, never tabs** — using a tab is a parse error.
- **Ansible is agentless and push-based**; Puppet/Chef are agent-based and pull-based.
- **Ansible playbooks are YAML files**.
- **Underlay = physical, Overlay = logical** — both exist simultaneously in a fabric.
- **Cisco DNA Center is the controller for SD-Access**; has REST API.
- **NETCONF uses SSH (port 830)**, RESTCONF uses HTTP/HTTPS.
- **Stateless** is a property of REST: the server doesn't keep client session state between requests; each request must contain all needed info (typically a token in the header).
- **Imperative** ("do this command") vs **declarative** ("be in this state") — Puppet/Ansible/Chef are declarative.
