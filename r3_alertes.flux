// R3 — Alertes températures > 32°C
from(bucket: "raw_7d")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "capteur" and r._field == "temperature")
  |> filter(fn: (r) => r._value > 32.0)
  |> yield(name: "alertes_temperature")
