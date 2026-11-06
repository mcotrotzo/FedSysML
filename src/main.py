import os

from domain.twin import FederationConfig
from domain.terraform import TerraformConfig
import json
import argparse

INPUT_FOLDER = '../input/strategyInputs/'
FED_TWIN_JSON = '../input/fedtwin.json'
BROKER_CONFIG_JSON = '../input/brokerConfig.json'
OUTPUT_FOLDER = '../output/'

def collect_input_json(paths):
    res = []
    for path in paths:
        if os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                res += [os.path.join(root, f) for f in files if f.endswith('.json')]
        else:
            res.append(path)
    return res

def main():
    parser = argparse.ArgumentParser(description='Generate Terraform configuration')
    parser.add_argument('--output', help='Output folder',default=OUTPUT_FOLDER)
    parser.add_argument('--fed_twin_json', help='Fed twin json',default=FED_TWIN_JSON)
    parser.add_argument('--deployer_federation_input_json', nargs='+', help='Federation input files',default=[INPUT_FOLDER])
    parser.add_argument('--broker_config_json', help='Broker config json',default=BROKER_CONFIG_JSON)
    parser.add_argument('--code', action='append', default=[], help='Mapping pathToCode=folder for strategy code, can be given multiple times')
    args = parser.parse_args()
    inputs = collect_input_json(args.deployer_federation_input_json)
    config = FederationConfig.load(inputs, args.fed_twin_json, args.broker_config_json)

    code_map = dict(entry.split('=', 1) for entry in args.code)
    for fed_twin in config.fedTwinConfig.fedTwins:
        for strategy in fed_twin.newStrategies:
            strategy.pathToCode = code_map.get(strategy.pathToCode, strategy.pathToCode)
    terraform_config = TerraformConfig(config)
    terraform_config.generate(output_path=os.path.join(args.output, "main.tf"))

if __name__ == '__main__':
    main()