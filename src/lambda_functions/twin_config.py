"""Access to the configs of the deployed twins for strategy code.

The fedtool ships this module and the twin configs in every strategy package.
Strategy code only uses device_id / component_device_id; where the configs are
stored is decided here, so changing the storage only changes this module.
"""
import functools
import json
import os

_TWINS_DIR = os.path.join(os.environ.get("LAMBDA_TASK_ROOT", "."), "twins")


@functools.lru_cache(maxsize=None)
def twin_config(twin, file_name):
    """Parsed config file of a twin, e.g. twin_config("dtcBattery", "config_iot_devices.json")."""
    with open(os.path.join(_TWINS_DIR, twin, file_name), encoding="utf-8") as f:
        return json.load(f)


def device_id(twin, property_name):
    """Id of the device of the twin that has the given property."""
    for device in twin_config(twin, "config_iot_devices.json"):
        if any(p.get("name") == property_name for p in device.get("properties", [])):
            return device["id"]
    raise ValueError(f"Twin {twin} has no device with property {property_name}")


def component_device_id(twin, component_name):
    """Id of the device behind the named component, for components with identical properties."""
    def search(nodes):
        for node in nodes:
            if node.get("type") == "component" and node.get("name") == component_name:
                return node.get("iotDeviceId")
            found = search(node.get("children", []))
            if found:
                return found
        return None

    found = search(twin_config(twin, "config_hierarchy.json"))
    if not found:
        raise ValueError(f"Twin {twin} has no component {component_name}")
    return found