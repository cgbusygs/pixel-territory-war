# Pixel Territory War v216 WebGPU

WebGPU-first pixel territory simulation with a 120 Hz desktop simulation/render profile, active-only indirect projectile compute, GPU-rendered battlefield UI, and CPU/WebGL2 fallback paths.

## Run locally

1. Keep `index.html`, `run-v216-webgpu.bat`, and `vendor/` in the same directory.
2. Double-click `run-v216-webgpu.bat`.
3. The launcher opens the game through `localhost` in the default browser.

WebGPU requires a secure context. `localhost` satisfies that requirement; opening `index.html` directly through `file://` does not.

## Runtime profiles

- Desktop: 120 Hz simulation and 120 FPS render target.
- Mobile: 60 FPS safe profile.
- Territory renderer: WebGPU first, with WebGL2 and Canvas 2D fallback.
- GPU battle simulation: enabled by default.
- HQ video: local `vendor/mediabunny-renderer.mjs`, with MediaRecorder fallback when unavailable.

## Diagnostics

- `?perf=1`: performance counters and stress-test diagnostics.
- `?gpuBattle=0`: CPU battle simulation comparison path.
- `?territoryRenderer=cpu&gpuBattle=0`: complete CPU baseline.
- `?territoryRenderer=webgl2`: WebGL2 territory fallback.

Useful console helpers:

```js
__gpuBattleInfo()
__territoryRendererInfo()
__perfDebug()
```

## GPU scope

- Projectile integration and collision preparation
- Active projectile compaction and indirect dispatch
- Projectile/Orb spatial hashing and collision
- Base and shield collision
- Authoritative 1000 x 1000 territory state and capture
- Territory, projectile, Orb, base, and shield rendering

The CPU retains the left-side generator simulation, gameplay/business rules, DOM UI, charts, and low-frequency GPU status readback.

Mediabunny 1.52.3 is distributed under MPL-2.0; see `vendor/mediabunny-LICENSE.txt`.
