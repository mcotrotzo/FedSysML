import functools
import json
import os

_TWINS_DIR = os.path.join(os.environ.get("LAMBDA_TASK_ROOT", "."), "twins")


@functools.lru_cache(maxsize=None)
def twin_config(twin, file_name):
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

def hot_reader(twin):
    """Hot-reader coordinates of a twin: hot_reader_arn, workspace_id, region, entity_id."""
    info = dict(twin_config(twin, "hot_reader.json"))
    info["entity_id"] = twin_config(twin, "config_hierarchy.json")[0]["id"]
    return info


def component_of(twin, property_name):
    """Name of the component whose device carries the given property."""
    device = device_id(twin, property_name)
    for child in twin_config(twin, "config_hierarchy.json")[0].get("children", []):
        if child.get("iotDeviceId") == device:
            return child["name"]
    raise ValueError(f"Twin {twin} has no component for property {property_name}")


def const_value(twin, property_name):
    """Deployed initValue of a #constAttribute of the twin."""
    for device in twin_config(twin, "config_iot_devices.json"):
        for prop in device.get("properties", []):
            if prop.get("name") == property_name and "initValue" in prop:
                return prop["initValue"]
    raise ValueError(f"Twin {twin} has no constant {property_name}")