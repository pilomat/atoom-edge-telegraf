# MQTT Discovery Ingestion Design

## Context

The Telegraf configuration currently ingests MQTT telemetry, state, LWT, actuator power, and control action events. Bucket routing already sends the `device_config` measurement to the `iot_meta` InfluxDB bucket.

Tasmota and ESP32 devices publish discovery metadata to these topic forms:

- `esp32/discovery/<serialnumber>/config`
- `tasmota/discovery/<serialnumber>/config`

The payload is JSON metadata describing the device, including network identity, display name, host name, MAC address, model, firmware, MQTT topic template, and capability flags.

## Goal

Ingest discovery messages into InfluxDB as device metadata using the existing `device_config` measurement and existing `iot_meta` bucket routing.

## Architecture

Add a dedicated Telegraf config file for discovery ingestion, separate from telemetry and state configs:

- Subscribe to `esp32/discovery/+/config` and `tasmota/discovery/+/config`.
- Parse the topic into stable tags: `platform` and `serialnumber`.
- Parse selected JSON payload fields into `device_config` fields.
- Rely on existing `90-bucket-routing.conf` routing, which already sends `device_config` to `iot_meta`.

## Measurement

Measurement name: `device_config`

Tags:

- `platform`: first topic segment, such as `esp32` or `tasmota`.
- `serialnumber`: third topic segment.

Fields:

- `ip`: device IP address.
- `display_name`: payload `dn`.
- `host_name`: payload `hn`.
- `mac`: payload `mac`.
- `model`: payload `md`.
- `firmware`: payload `sw`.
- `device_topic`: payload `t`.
- `full_topic`: payload `ft`.
- `offline_text`: payload `ofln`.
- `online_text`: payload `onln`.
- `type`: payload `ty`.
- `interface`: payload `if`.
- `camera`: payload `cam`.
- `battery`: payload `bat`.
- `deep_sleep`: payload `dslp`.
- `version`: payload `ver`.

Arrays such as `fn`, `state`, `tp`, `rl`, `swc`, `swn`, and `btn` are intentionally excluded from the first implementation to keep the metadata measurement compact and queryable.

## Data Flow

1. Device publishes discovery JSON to MQTT.
2. Telegraf MQTT consumer receives the message from either discovery topic pattern.
3. Topic parsing adds `platform` and `serialnumber` tags.
4. `json_v2` extracts selected fields into the `device_config` measurement.
5. Existing bucket routing tags the metric with `influx_bucket = iot_meta`.

## Error Handling

Telegraf will skip invalid JSON payloads according to normal `json_v2` parser behavior. Optional fields will not block ingestion when omitted. The two sample payloads differ in completeness, so non-essential fields must be marked optional.

## Testing

Validation should include:

- Telegraf config syntax validation if Telegraf is available locally.
- Manual inspection that the new config uses the same MQTT environment variables and TLS settings as existing inputs.
- Confirmation that `90-bucket-routing.conf` already includes `device_config` in the `iot_meta` route.

## Scope

This design only adds discovery metadata ingestion. It does not transform discovery arrays into separate catalog measurements and does not change bucket routing.
