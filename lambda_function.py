import json
import os


def lambda_handler(event, context):
    print("Alarm Payload:")
    print(json.dumps(event))

    instance_id = os.environ.get("INSTANCE_ID", "Unknown")
    print(f"High CPU detected on instance: {instance_id}")

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda processed the alarm event."),
    }
