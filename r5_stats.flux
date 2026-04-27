// R5 — Min / Max / Moyenne sur 24h
from(bucket: "raw_7d")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "capteur")
  |> group(columns: ["_field"])
  |> reduce(
      identity: {min: 9999.0, max: -9999.0, sum: 0.0, count: 0.0},
      fn: (r, accumulator) => ({
        min:   if r._value < accumulator.min then r._value else accumulator.min,
        max:   if r._value > accumulator.max then r._value else accumulator.max,
        sum:   accumulator.sum + r._value,
        count: accumulator.count + 1.0
      })
    )
  |> map(fn: (r) => ({r with moyenne: r.sum / r.count}))
  |> yield(name: "stats_24h")
