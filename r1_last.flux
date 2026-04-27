// R1 — Dernière valeur reçue par capteur
from(bucket: "raw_7d")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "capteur")
  |> last()
