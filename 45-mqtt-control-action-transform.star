def _s(v):
    if v == None:
        return ""
    return str(v)

def _lower(v):
    return _s(v).lower()

def _state_code_from_text(v):
    x = _lower(v)
    if x == "on":
        return 1
    if x == "off":
        return 0
    return -1

def _success_code(v):
    x = _lower(v)
    if x == "true":
        return 1
    if x == "false":
        return 0
    return -1

def _event_status_code(v):
    x = _s(v)
    if x == "control.action.sent":
        return 0
    if x == "control.action.acked":
        return 1
    if x == "control.action.failed":
        return 2
    return -1

def _mode_code(v):
    x = _lower(v)
    if x == "off":
        return 0
    if x == "heat":
        return 1
    if x == "cool":
        return 2
    if x == "dry":
        return 3
    if x == "fan":
        return 4
    if x == "auto":
        return 5
    if x == "eco":
        return 6
    return -1

def _fan_code(v):
    x = _lower(v)
    if x == "auto":
        return 0
    if x == "low":
        return 1
    if x == "medium":
        return 2
    if x == "high":
        return 3
    if x == "turbo":
        return 4
    if x == "quiet":
        return 5
    return -1

def apply(metric):
    event_type = metric.tags.get("event_type", "")

    desired_state = metric.tags.get("desired_state", "")
    desired_power = metric.tags.get("desired_power", "")
    actual_state = metric.tags.get("actual_state", "")
    actual_power = metric.tags.get("actual_power", "")

    desired_mode = metric.tags.get("desired_mode", "")
    actual_mode = metric.tags.get("actual_mode", "")
    desired_fan = metric.tags.get("desired_fan", "")
    actual_fan = metric.tags.get("actual_fan", "")

    success_raw = None
    if "success" in metric.fields:
        success_raw = metric.fields["success"]

    # Core numeric fields
    metric.fields["event_status_code"] = _event_status_code(event_type)
    metric.fields["success_code"] = _success_code(success_raw)

    # Requested side
    desired_state_num = _state_code_from_text(desired_state)
    if desired_state_num == -1:
        desired_state_num = _state_code_from_text(desired_power)

    metric.fields["desired_state_num"] = desired_state_num
    metric.fields["requested_power_num"] = desired_state_num
    metric.fields["desired_mode_code"] = _mode_code(desired_mode)
    metric.fields["desired_fan_code"] = _fan_code(desired_fan)

    # Confirmed side
    actual_state_num = _state_code_from_text(actual_state)
    if actual_state_num == -1:
        actual_state_num = _state_code_from_text(actual_power)

    metric.fields["actual_state_num"] = actual_state_num
    metric.fields["confirmed_power_num"] = actual_state_num
    metric.fields["actual_mode_code"] = _mode_code(actual_mode)
    metric.fields["actual_fan_code"] = _fan_code(actual_fan)

    # Best available power value
    if event_type == "control.action.acked":
        metric.fields["power_num"] = actual_state_num
    elif event_type == "control.action.sent":
        metric.fields["power_num"] = desired_state_num
    elif event_type == "control.action.failed":
        metric.fields["power_num"] = desired_state_num
    else:
        metric.fields["power_num"] = -1

    return metric
