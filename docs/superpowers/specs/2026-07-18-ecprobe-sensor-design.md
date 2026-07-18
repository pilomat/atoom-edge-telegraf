# ECProbe Sensor Ingestion Design

## Context

The Telegraf configuration ingests MQTT `SENSOR` payloads into the `telemetry_sensors` measurement using `json_v2` object blocks in `10-mqtt-sensors.conf`. Existing sensors map device-specific JSON keys to normalized field names, and `90-bucket-routing.conf` already routes `telemetry_sensors` to the `iot_telemetry` bucket.

The new payload includes an `ECProbe` object:

```json
{"Time":"2026-07-18T18:08:37","ECProbe":{"Temperature":24.2,"Conductivity":582},"TempUnit":"C","ConductivityUnit":"uS/cm"}
```

## Goal

Ingest EC probe temperature and conductivity readings from existing MQTT sensor messages without changing topic subscriptions, measurement names, or bucket routing.

## Architecture

Add an optional `json_v2.object` block to `10-mqtt-sensors.conf` for the `ECProbe` JSON object. The block follows the existing sensor pattern:

- `path = "ECProbe"`
- `optional = true`
- `disable_prepend_keys = true`
- `included_keys = ["Temperature","Conductivity"]`
- field renames for normalized InfluxDB field names

Add a top-level optional `json_v2.field` for `ConductivityUnit`, matching the existing `TempUnit` handling.

## Measurement

Measurement name: `telemetry_sensors`

Fields:

- `ECProbe.Temperature` -> `ecprobe_temperature_c`
- `ECProbe.Conductivity` -> `ecprobe_conductivity_us_cm`
- `ConductivityUnit` -> `conductivity_unit`

Existing `TempUnit` ingestion remains unchanged as `temp_unit`.

## Data Flow

1. Device publishes the EC probe `SENSOR` JSON payload to the existing MQTT topic pattern.
2. Telegraf receives the message through the existing `inputs.mqtt_consumer` in `10-mqtt-sensors.conf`.
3. `topic_parsing` applies the existing tenant, facility, zone, module, and device tags.
4. `json_v2` extracts EC probe fields into `telemetry_sensors`.
5. Existing bucket routing tags the metric with `influx_bucket = iot_telemetry`.

## Error Handling

The `ECProbe` object and `ConductivityUnit` field are optional, so existing sensor payloads without EC probe data continue to ingest normally. Invalid JSON remains subject to Telegraf's standard `json_v2` parser behavior.

## Testing

Validation should include:

- Confirm the config parses with Telegraf if Telegraf is available locally.
- Confirm the `ECProbe` block follows the existing `json_v2.object` sensor pattern.
- Confirm the sample payload maps to `ecprobe_temperature_c`, `ecprobe_conductivity_us_cm`, and `conductivity_unit`.

## Scope

This change only adds EC probe telemetry ingestion. It does not add new measurements, change bucket routing, or introduce generic conductivity sensor handling.
