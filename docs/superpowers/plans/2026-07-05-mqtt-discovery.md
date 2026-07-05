# MQTT Discovery Ingestion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ingest Tasmota and ESP32 discovery MQTT payloads into Telegraf as `device_config` metrics routed to `iot_meta`.

**Architecture:** Add one focused Telegraf MQTT consumer config that subscribes to the discovery topic forms, parses `platform` and `serialnumber` from the topic, and maps only the stable scalar payload fields into `device_config`. Keep the existing bucket routing unchanged because `device_config` already routes to `iot_meta`.

**Tech Stack:** Telegraf `inputs.mqtt_consumer`, `json_v2`, InfluxDB line protocol, MQTT/TLS environment variables.

## Global Constraints

- Discovery messages must land in the existing `device_config` measurement.
- `device_config` must continue to route to `iot_meta` via `90-bucket-routing.conf`.
- Reuse the existing MQTT/TLS environment variables already used by the other Telegraf inputs.
- Exclude discovery arrays (`fn`, `state`, `tp`, `rl`, `swc`, `swn`, `btn`) from the first implementation.

---

### Task 1: Add discovery MQTT ingestion

**Files:**
- Create: `50-mqtt-discovery.conf`

**Interfaces:**
- Consumes: `${MQTT_URL}`, `${MQTT_USERNAME}`, `${MQTT_PASSWORD}`, `${MQTT_TLS_CA}`, `${MQTT_TLS_CERT}`, `${MQTT_TLS_KEY}`
- Produces: `device_config` metrics with `platform` and `serialnumber` tags

- [ ] **Step 1: Write the new Telegraf consumer config**

Create `50-mqtt-discovery.conf` with one `[[inputs.mqtt_consumer]]` block that mirrors the TLS/auth setup used by the other MQTT inputs and subscribes to both discovery patterns:

```toml
[[inputs.mqtt_consumer]]
  servers  = ["${MQTT_URL}"]
  username = "${MQTT_USERNAME}"
  password = "${MQTT_PASSWORD}"

  tls_ca   = "${MQTT_TLS_CA}"
  tls_cert = "${MQTT_TLS_CERT}"
  tls_key  = "${MQTT_TLS_KEY}"
  insecure_skip_verify = false

  topics = ["esp32/discovery/+/config", "tasmota/discovery/+/config"]
  qos = 0
  client_id = "telegraf_mqtt_discovery"
  persistent_session = true
  data_format = "json_v2"

  [[inputs.mqtt_consumer.topic_parsing]]
    topic = "esp32/discovery/+/config"
    tags  = "platform/_/serialnumber/_"

  [[inputs.mqtt_consumer.topic_parsing]]
    topic = "tasmota/discovery/+/config"
    tags  = "platform/_/serialnumber/_"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "device_config"

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ip"
      rename = "ip"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "dn"
      rename = "display_name"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "hn"
      rename = "host_name"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "mac"
      rename = "mac"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "md"
      rename = "model"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "sw"
      rename = "firmware"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "t"
      rename = "device_topic"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ft"
      rename = "full_topic"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ofln"
      rename = "offline_text"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "onln"
      rename = "online_text"
      type = "string"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ty"
      rename = "type"
      type = "int"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "if"
      rename = "interface"
      type = "int"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "cam"
      rename = "camera"
      type = "int"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "bat"
      rename = "battery"
      type = "int"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "dslp"
      rename = "deep_sleep"
      type = "int"
      optional = true

    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ver"
      rename = "version"
      type = "int"
      optional = true
```

Keep the arrays and any high-cardinality discovery structures out of this file.

- [ ] **Step 2: Validate the config parses cleanly**

Run:

```bash
telegraf --test --config-directory /Users/mpilone/atoom-telegraf
```

Expected: Telegraf loads the new discovery config without TOML or plugin parse errors.

- [ ] **Step 3: Confirm bucket routing remains unchanged**

Inspect `90-bucket-routing.conf` and confirm `device_config` is still routed to `iot_meta` without editing the routing file.

Expected: No routing changes are needed because the existing `namepass` already includes `device_config` and the bucket assignment already maps it to `iot_meta`.
