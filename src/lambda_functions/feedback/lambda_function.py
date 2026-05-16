import json
import os
import boto3
import paho.mqtt.client as mqtt

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    feedback_type = os.environ.get('FEEDBACK_TYPE', 'INTERNAL').upper()
    topic = os.environ.get('FEEDBACK_TOPIC', 'default/topic')
    event["processed_by"] = "Feedback_Lambda"
    payload = json.dumps(event)

    if feedback_type == "INTERNAL":
        print(f"Publishing to Internal AWS IoT Topic: {topic}")
        iot_client = boto3.client('iot-data')
        
        try:
            iot_client.publish(
                topic=topic,
                qos=1,
                payload=payload
            )
        except Exception as e:
            print(f"Error publishing to Internal IoT: {e}")
            raise e

    elif feedback_type == "EXTERNAL":
        broker_url = os.environ.get('BROKER_URL')
        broker_port = int(os.environ.get('BROKER_PORT', 1883))
        username = os.environ.get('BROKER_USERNAME')
        password = os.environ.get('BROKER_PASSWORD')

        print(f"Publishing to External Broker: {broker_url} on topic {topic}")
        
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
            print(f"Error publishing to External Broker: {e}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Feedback sent successfully')
    }