# ECProbe Sensor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ECProbe temperature, conductivity, and conductivity unit ingestion to the existing MQTT sensor telemetry configuration.

**Architecture:** Extend the existing `json_v2` configuration in `10-mqtt-sensors.conf` with one optional `ECProbe` object block and one optional top-level `ConductivityUnit` string field. Reuse the existing MQTT subscription, `telemetry_sensors` measurement, topic parsing tags, and bucket routing.

**Tech Stack:** Telegraf `inputs.mqtt_consumer`, Telegraf `json_v2`, MQTT sensor payloads, InfluxDB line protocol field naming.

## Global Constraints

- Modify only ECProbe telemetry ingestion behavior.
- Do not add new measurements.
- Do not change MQTT topic subscriptions.
- Do not change bucket routing.
- Preserve existing sensor ingestion behavior.
- Use normalized field names: `ecprobe_temperature_c`, `ecprobe_conductivity_us_cm`, and `conductivity_unit`.

---

### Task 1: Add ECProbe Sensor Fields

**Files:**
- Modify: `10-mqtt-sensors.conf`

**Interfaces:**
- Consumes: Existing `[[inputs.mqtt_consumer.json_v2]]` parser for measurement `telemetry_sensors`.
- Produces: Telegraf fields `ecprobe_temperature_c`, `ecprobe_conductivity_us_cm`, and `conductivity_unit` on `telemetry_sensors` metrics.

- [ ] **Step 1: Write the failing check**

Run:

```bash
rg 'ECProbe|ecprobe_temperature_c|ecprobe_conductivity_us_cm|ConductivityUnit|conductivity_unit' 10-mqtt-sensors.conf
```

Expected before implementation: no matches for `ECProbe`, `ecprobe_temperature_c`, `ecprobe_conductivity_us_cm`, `ConductivityUnit`, or `conductivity_unit`.

- [ ] **Step 2: Add the ECProbe object block**

Insert this block in `10-mqtt-sensors.conf` after the existing `SCD40` block and before top-level fields:

```toml
    # -------------------------
    # ECProbe
    # -------------------------
    [[inputs.mqtt_consumer.json_v2.object]]
      path = "ECProbe"
      optional = true
      disable_prepend_keys = true
      included_keys = ["Temperature","Conductivity"]
      [inputs.mqtt_consumer.json_v2.object.renames]
        Temperature  = "ecprobe_temperature_c"
        Conductivity = "ecprobe_conductivity_us_cm"
```

- [ ] **Step 3: Add the ConductivityUnit field**

Insert this top-level field after the existing `TempUnit` field:

```toml
    [[inputs.mqtt_consumer.json_v2.field]]
      path = "ConductivityUnit"
      rename = "conductivity_unit"
      type = "string"
      optional = true
```

- [ ] **Step 4: Run checks to verify the config contains the new fields**

Run:

```bash
rg 'ECProbe|ecprobe_temperature_c|ecprobe_conductivity_us_cm|ConductivityUnit|conductivity_unit' 10-mqtt-sensors.conf
```

Expected after implementation: matches for all five terms.

- [ ] **Step 5: Run Telegraf config validation if available**

Run:

```bash
telegraf --test --config-directory /Users/mpilone/atoom-telegraf
```

Expected if Telegraf is installed and required environment variables are configured: command exits successfully. If Telegraf or required environment variables are unavailable locally, record the exact failure.

- [ ] **Step 6: Commit**

Commit only if explicitly requested by the user:

```bash
git add 10-mqtt-sensors.conf docs/superpowers/specs/2026-07-18-ecprobe-sensor-design.md docs/superpowers/plans/2026-07-18-ecprobe-sensor.md
git commit -m "Add ECProbe sensor ingestion"
```

## Self-Review

- Spec coverage: The task adds the optional `ECProbe` object, maps temperature and conductivity field names, adds optional `ConductivityUnit`, and leaves topic subscriptions, measurements, and bucket routing unchanged.
- Placeholder scan: The plan contains no placeholders.
- Type consistency: Field names match the approved design: `ecprobe_temperature_c`, `ecprobe_conductivity_us_cm`, and `conductivity_unit`.
