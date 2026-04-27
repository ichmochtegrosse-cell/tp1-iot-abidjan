// R2 — Moyenne horaire sur 24h
from(bucket: "raw_7d")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "capteur")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> yield(name: "moyenne_horaire")
