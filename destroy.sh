for twin in Battery PV; do
    cp -r ./DigitalTwinProfileSysMLv2/output/$twin/. ./digital-twin-manager/
    cp config_credentials.json ./digital-twin-manager/
    cd digital-twin-manager/src
    python main.py <<EOF
destroy
EOF
    cd ..
    cp ./digital-twin-manager/src/${twin}_federation_input.json ./input/strategyInputs
done


cd CloudDeployerTestSimulator
pulumi destroy --yes
cd ..

cd output
terraform destroy -auto-approve
