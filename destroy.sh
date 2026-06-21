for twin in Battery PV; do
    cp -r ./DigitalTwinProfileSysMLv2/output/$twin/. ./digital-twin-manager/
    cp config_credentials.json ./digital-twin-manager/
    cd digital-twin-manager/src
    python main.py <<EOF
destroy
EOF
    cd ../..
done


cd CloudDeployerTestSimulator
pulumi destroy --yes
cd ..

cd output
terraform destroy -auto-approve
