// R4 — Pivot température / humidité
from(bucket: "raw_7d")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "capteur")
  |> filter(fn: (r) => r._field == "temperature" or r._field == "humidite")
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> yield(name: "pivot_temp_hum")
