import os

from domain.twin import FederationConfig
from domain.terraform import TerraformConfig
import json

INPUT_FOLDER = '/home/marcocotrotzo/PycharmProjects/SymlCOnv/input/strategyInputs/'
FED_TWIN_JSON = '/home/marcocotrotzo/PycharmProjects/SymlCOnv/input/fedtwin.json'
BROKER_CONFIG_JSON = '/home/marcocotrotzo/PycharmProjects/SymlCOnv/input/brokerConfig.json'
OUTPUT_FOLDER = '/home/marcocotrotzo/PycharmProjects/SymlCOnv/output/'
def collect_input_json():
    res = []
    for root, dirs, files in os.walk(INPUT_FOLDER):
        for file in files:
            if file.endswith('.json'):
                res.append(os.path.join(root, file))
    return res

config = FederationConfig.load(collect_input_json(), FED_TWIN_JSON, BROKER_CONFIG_JSON)
terraform_config = TerraformConfig(config)
terraform_config.generate(output_path=os.path.join(OUTPUT_FOLDER, "main.tf"))