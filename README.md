# Federated Twin Strategy Tool

This tool lets you combine ("federate") strategies from multiple deployed digital twins into a single new strategy. It generates one AWS Lambda pipeline per new strategy. The pipeline collects current input values, runs your custom strategy code, and publishes the result as feedback, either internally or to an external MQTT broker.

## Prerequisites

- Python 3.x
- Access to the `digital-twin-manager` (https://github.com/cloud-DTs/digital-twin-manager) and the twins you want to federate already deployed through it

## Setup

Create and activate a virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
.venv\Scripts\activate      # Windows
```

Install the dependencies:

```bash
python -m pip install -r requirements.txt
```

### Docker

Build the image and generate `output/main.tf`:

```bash
docker compose build
docker compose run --rm fed-sysml
```

Without arguments, `generate` uses the default inputs under `/pipeline/input`
(see [Command-line options](#command-line-options)). To pass the configs of the
deployed twins, call `generate` explicitly:

```bash
docker compose run --rm fed-sysml generate \
  --output /pipeline/output \
  --twin_config Battery=/pipeline/input/twinConfigs/Battery/config_iot_devices.json \
  --twin_config Battery=/pipeline/input/twinConfigs/Battery/config_hierarchy.json
```

Terraform commands run inside the same image and use the mounted `output`
directory:

```bash
docker compose run --rm fed-sysml terraform init
docker compose run --rm fed-sysml terraform apply
```

AWS credentials are read from the corresponding host environment variables,
including `AWS_SESSION_TOKEN` when temporary credentials are used.

## How it works

The tool packages three internal phases into one Lambda deployment:

```
Event checker -> Pipeline Lambda: collect -> strategy -> feedback
```

- **Collector phase**: gathers the current values of every twin/strategy you reference in `fedtwin.json`.
- **Your combined strategy**: your `lambda_function.py`, which receives all collected values as input and computes a new result.
- **Feedback phase**: takes the return value of your strategy and publishes it over MQTT, either to the internal broker or to an external one, depending on `feedback.type`.

The generated SSM registry entry contains the pipeline Lambda ARN with `type = "lambda"`. The `digital-twin-manager` event checker invokes it asynchronously.

If you already have a deployment based on the previous three-Lambda Step Functions workflow, follow the [migration guide](MIGRATION.md) before applying the newly generated Terraform.

To set up the tool, you need to provide the four things described below. Section 5 describes the optional twin configs that strategy code can read at runtime.

## 1. Federation input file

For every twin you want to federate, you first need its `<TwinName>_federation_input` file. You get this from the `digital-twin-manager` after deploying that twin — it's exported automatically as part of the deployment process.

Place each of these files in:

```
./input/strategyInputs
```

This is what tells the tool which strategies and attributes actually exist on each twin, so it can validate and wire up the `fedtwin.json` config below.

## 2. `fedtwin.json` — defining the federation

This file describes which strategies from which twins get combined into a new one, and what happens to the result.

```json
{
  "fedTwins": [
    {
      "name": "MicroGrid",
      "newStrategies": [
        {
          "name": "ConsumptionStrategy",
          "pathToCode": "sysml/testLambdaFunctions/fedTwinCombinedStrategy",
          "feedback": {
            "type": "INTERNAL",
            "topic": "Battery/iot-data"
          },
          "strategies": ["PV.production", "Battery.status"]
        }
      ]
    }
  ]
}
```

Field by field:

- **`fedTwins[].name`** — the name of the (virtual) federated twin this new strategy belongs to, e.g. `MicroGrid`.
- **`newStrategies[].name`** — the name of the new, combined strategy you're creating, e.g. `ConsumptionStrategy`.
- **`pathToCode`** — path to the folder containing your combined `lambda_function.py` (see section 4). Relative paths are resolved from the directory containing `fedtwin.json`.
- **`feedback.type`** — `INTERNAL` or `EXTERNAL`:
  - `INTERNAL`: the result is published over MQTT to the aws internal broker.
  - `EXTERNAL`: the result is published over MQTT to an outside broker. In this case you also need a `"brokerKey": "<a key in brokerConfig.json>"` here, pointing at one of the broker entries described in section 3.
- **`feedback.topic`** — the MQTT topic the result gets published to, e.g. `Battery/iot-data`.
- **`strategies`** — the list of input strategies being combined, written as `Twin.strategyName`, e.g. `PV.production` and `Battery.status`. These are the strategy inputs the collector phase will fetch and pass into your strategy code.

## 3. `brokerConfig.json` — only needed for external feedback

If any of your strategies use `"type": "EXTERNAL"` feedback, you also need a `brokerConfig.json` defining the broker(s) to publish to:

```json
{
  "brokers": {
    "default": {
      "broker_url": "broker.hivemq.com",
      "broker_port": 1883,
      "broker_username": "",
      "broker_password": ""
    },
    "eu_broker": {
      "broker_url": "cc673a1ab883421dbfcd225d0e26e925.s1.eu.hivemq.cloud",
      "broker_port": 8883,
      "broker_username": "Test12345678",
      "broker_password": "Test12345678",
      "use_tls": true
    }
  }
}
```

Each top-level key (`default`, `eu_broker`, ...) is a broker profile you can reference by name via `brokerKey` in `fedtwin.json`. `use_tls` is optional and only needed for brokers that require TLS (like the HiveMQ Cloud example above, which uses port `8883`).

## 4. `lambda_function.py` — your combined strategy logic

Your combined strategy must be a Python file named exactly `lambda_function.py`, with a `lambda_handler(event, context)` entry point — standard AWS Lambda signature.

```python
import json
from datetime import datetime, timezone

from twin_configs import device_id


BATTERY_CONSUMPTION_DEVICE_ID = device_id("Battery", "consumption")

def lambda_handler(event, context):
    kombi_data = event.get("ConsumptionStrategy", {})
    pv_data = kombi_data.get("production", {})
    battery_data = kombi_data.get("status", {})

    pv_power = pv_data.get("generatedPower", 0.0)
    charge_value = battery_data.get("chargeValue", 0.0)

    base_battery_consumption = float(charge_value) * 1.0
    effective_consumption = base_battery_consumption - float(pv_power)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "iotDeviceId": BATTERY_CONSUMPTION_DEVICE_ID,
            "time": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z',
            "consumption": effective_consumption,
        })
    }
```

### Accessing input values

The collector phase puts every input strategy's current values into `event`, keyed by your **new strategy's name** (not the source twin's name). From there, drill down by strategy name and attribute:

```
event["YourStrategyName"]["theSingleStrategyName"]["theAttribute"]
```

In the example above, the new strategy is called `ConsumptionStrategy`, so:

- `event["ConsumptionStrategy"]["production"]["generatedPower"]` — comes from `PV.production`
- `event["ConsumptionStrategy"]["status"]["chargeValue"]` — comes from `Battery.status`

If strategy code must not depend on its own strategy name (for example because a
caller renames strategies when merging federations), use
`strategy_values(event)` from `twin_configs`. It returns the same dictionary,
looked up by the name of the pipeline Lambda.

Note that only the strategy name (`production`, `status`) is used as the key inside `event["ConsumptionStrategy"]`, not the twin name (`PV`, `Battery`) — the twin name in `fedtwin.json`'s `strategies` list is only there to tell the collector phase _where_ to fetch the value from.

### Return value and feedback behavior

Whatever your `lambda_handler` returns is passed to the feedback phase, which handles it in one of two ways:

1. **If your return value has a `body` field** (as in the example above), the feedback phase takes the contents of `body` _only_ — without the surrounding `statusCode`/`body` wrapper — and publishes that to the configured topic.
2. **Otherwise**, it publishes the entire return value as-is.

So in the example, what actually gets published to `Battery/iot-data` is just:

```json
{
  "iotDeviceId": "SwiB9jTPm8kzDXz6chmo5T",
  "time": "2026-06-21T10:15:30.123Z",
  "consumption": 12.5
}
```


## 5. Twin configs — `--twin_config` and `twin_configs.py`

Strategy code often needs values that only exist after the twins are deployed:
the IoT device ID to publish feedback to, a constant from the model (e.g. a
battery capacity), or the hot reader of another twin. Instead of hard-coding these
values or injecting them after deployment, pass the configs of the deployed twins
to the tool:

```bash
python main.py \
  --twin_config Battery=../input/twinConfigs/Battery/config_iot_devices.json \
  --twin_config Battery=../input/twinConfigs/Battery/config_hierarchy.json \
  --twin_config PV=../input/twinConfigs/PV/config_iot_devices.json
```

Each entry is `twinName=path` and can be given multiple times. Use the configs the
twin was deployed with (the `digital-twin-manager` input: `config.json`,
`config_iot_devices.json`, `config_events.json`, `config_hierarchy.json`). Pass
the configs of every twin your strategy code reads, including twins that trigger
no strategy themselves.

For every new strategy, the generated deployment package then contains:

```text
twin_configs.py                      helper module, importable from strategy code
twins/<twinName>/<config file>       every --twin_config file of that twin
twins/<twinName>/hot_reader.json     hot_reader_arn, workspace_id, region
```

`hot_reader.json` is written for every twin with a federation input file (section 1).
The generated IAM role of every pipeline Lambda may invoke the hot readers of all
these twins, so no permissions have to be added after `terraform apply`.

Strategy code reads the values with the helpers of `twin_configs`:

| Function | Returns | Needs |
| --- | --- | --- |
| `device_id(twin, property)` | ID of the IoT device that has the property | `config_iot_devices.json` |
| `component_device_id(twin, component)` | ID of the device behind a named component | `config_hierarchy.json` |
| `component_of(twin, property)` | name of the component whose device has the property | both |
| `const_value(twin, property)` | deployed `initValue` of a constant attribute | `config_iot_devices.json` |
| `hot_reader(twin)` | `hot_reader_arn`, `workspace_id`, `region`, `entity_id` | `hot_reader.json`, `config_hierarchy.json` |
| `twin_config(twin, file)` | any shipped config file, parsed | that file |
| `strategy_values(event)` | collector values of the own strategy (section 4) | — |

Example:

```python
from twin_configs import const_value, device_id, hot_reader

BATTERY_CAPACITY = const_value("Battery", "totalCapacity")
BATTERY_STORAGE_DEVICE_ID = device_id("Battery", "charge")
GRID = hot_reader("Grid")
```

The helpers raise `ValueError` if a twin, property or component is missing, so a
wrong model fails when the Lambda starts instead of publishing to a wrong device.



## Command-line options

`main.py` (Docker: `generate`) accepts:

| Option | Default | Meaning |
| --- | --- | --- |
| `--output` | `../output/` | Folder for `main.tf` and the build folders |
| `--fed_twin_json` | `../input/fedtwin.json` | Federation definition (section 2) |
| `--broker_config_json` | `../input/brokerConfig.json` | Broker profiles (section 3) |
| `--deployer_federation_input_json` | `../input/strategyInputs/` | One or more federation input files or folders (section 1) |
| `--twin_config` | — | `twinName=path` of a deployed twin config (section 5), repeatable |
| `--code` | — | `pathToCode=folder`, replaces a `pathToCode` from `fedtwin.json`, repeatable |
