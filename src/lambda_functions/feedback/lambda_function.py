import json
import os
import boto3
import paho.mqtt.client as mqtt

def lambda_handler(event, context):
    strategy_result = event.get("strategyResult", {})
    body_str = strategy_result.get("body", "{}")
    
    try:
        payload_dict = json.loads(body_str)
    except Exception:
        payload_dict = {}

    payload = json.dumps(payload_dict)

    feedback_type = os.environ.get('FEEDBACK_TYPE', 'INTERNAL').upper()
    topic = os.environ.get('FEEDBACK_TOPIC', 'default/topic')

    if feedback_type == "INTERNAL":
        iot_client = boto3.client('iot-data')
        try:
            iot_client.publish(topic=topic, qos=1, payload=payload)
        except Exception as e:
            raise e

    elif feedback_type == "EXTERNAL":
        broker_url = os.environ.get('BROKER_URL')
        broker_port = int(os.environ.get('BROKER_PORT', 1883))
        username = os.environ.get('BROKER_USERNAME')
        password = os.environ.get('BROKER_PASSWORD')
        
        client = mqtt.Client()
        if username and password:
            client.username_pw_set(username, password)
        if os.environ.get('USE_TLS', 'false').lower() == 'true':
            client.tls_set()
        try:
            client.connect(broker_url, broker_port, 60)
            client.loop_start()
            client.publish(topic, payload, qos=1)
            client.loop_stop()
            client.disconnect()
        except Exception as e:
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Feedback sent successfully')
    }
