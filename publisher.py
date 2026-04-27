import paho.mqtt.client as mqtt
import time, random

BROKER = "broker.hivemq.com"
TOPIC  = "iot/CI/abidjan/cocody/env"

def on_connect(client, userdata, flags, reason_code, properties):
    print(f"Connecté à {BROKER}" if reason_code == 0 else f"Erreur: {reason_code}")

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.on_connect = on_connect
client.connect(BROKER, 1883, 60)
client.loop_start()
time.sleep(2)

try:
    while True:
        payload = f"capteur,location=abidjan temperature={round(random.uniform(24.0,35.0),2)},humidite={round(random.uniform(60.0,90.0),2)}"
        client.publish(TOPIC, payload)
        print(f"Publié : {payload}")
        time.sleep(10)
except KeyboardInterrupt:
    client.loop_stop()
    client.disconnect()
