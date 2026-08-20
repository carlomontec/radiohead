![](https://github.com/dataarts/radiohead/blob/master/HoC_image_grid.png?raw=true)

# RADIOHEAD / HOUSE OF CARDS – 3D Point Cloud Studio

This repository contains tools and data for Radiohead's [House of Cards](https://www.youtube.com/watch?v=8nTFjVm9sTQ) (2008) music video, created without physical cameras using 3D structured-light optical scanning (Geometric Informatics) and 360-degree LiDAR rangefinders (Velodyne).

This modern fork introduces an interactive **Julia & GLMakie 3D Point Cloud Studio** and an export pipeline for **TouchDesigner**.

---

## AI-Assisted Development Note

The Julia 3D Studio, high-performance data loader, and TouchDesigner export pipeline in this fork were generated using **Gemini 3.7 Flash** (Google DeepMind) in pair-programming collaboration with Carlo Monjaraz. 

This project serves as an experimental case study in AI-assisted coding—demonstrating how modern reasoning models can inspect legacy creative coding archives (originally written in Processing 1.0 in 2008), modernize data structures, and build high-performance scientific/creative computing tools in Julia.

---

## Quickstart: Julia 3D Studio

### 1. Prerequisites
Install [Julia](https://julialang.org/downloads/) (v1.10+ recommended).

### 2. Download the Data
Download and extract the dataset releases into a `data/` directory:
* [HoC_AnimationData1_v1.0.zip](https://github.com/dataarts/radiohead/releases/download/v1.0.0/HoC_AnimationData1_v1.0.zip) (Thom Yorke singing, Part 1)
* [HoC_AnimationData2_v1.0.zip](https://github.com/dataarts/radiohead/releases/download/v1.0.0/HoC_AnimationData2_v1.0.zip) (Thom Yorke singing, Part 2)
* [HoC_DataApplications_v1.0.zip](https://github.com/dataarts/radiohead/releases/download/v1.0.0/HoC_DataApplications_v1.0.zip) (LiDAR scans & Processing code)

Extract all CSV frames (`1.csv` to `2101.csv`) directly into `data/`, and place `city.csv` and `culdesac.csv` in `data/SceneViewer/data/`.

### 3. Launch the Studio

```bash
# Instantiate dependencies and launch
julia --project=. run_viewer.jl
```

Or from the Julia REPL:
```julia
using Pkg; Pkg.activate(".")
using RadioheadViewer
launch_viewer()
```

---

## Studio Features

* **Real-time 3D Animation Playback**: Stream the 2,101 frames of Thom Yorke's performance at 30+ FPS.
* **Interactive 3D Navigation**: Left-click drag to rotate, right-click drag to pan, scroll wheel to zoom.
* **Timeline Scrubber & Speed**: Seek to any frame (1 - 2101) with instantaneous in-memory caching.
* **LiDAR Scans**: Switch seamlessly to explore the 1.36M point `city.csv` and 1.07M point `culdesac.csv` 3D captures.
* **Visual Shaders & Filters**: Live colormap selection (`turbo`, `viridis`, `plasma`, `inferno`, `coolwarm`, `ice`), point size scaling, and laser intensity noise thresholding.

---

## TouchDesigner Export Pipeline

Export point cloud frames directly for use in TouchDesigner:
1. In the studio sidebar, click **"Export Current Frame (.PLY)"** or **"Export Next 100 Frames (.PLY)"**.
2. In TouchDesigner:
   * Add a **Point File In SOP** or **Point File In TOP**.
   * Set the file path to `exports/touchdesigner/frame_1.ply`.
   * Directly drive particle systems, GPU feedback networks, and audio-reactive displace shaders.

---

## Repository Structure

```
RadioheadNew/
├── Project.toml              # Julia environment definition
├── Manifest.toml             # Pinned package versions
├── run_viewer.jl             # Studio entry point
├── src/
│   ├── DataLoader.jl         # High-speed CSV and LiDAR point cloud parser
│   ├── TouchDesignerExport.jl # PLY and CSV exporter for TouchDesigner
│   ├── ViewerApp.jl          # Interactive GLMakie OpenGL GUI studio
│   └── RadioheadViewer.jl    # Root Julia package module
├── test/
│   └── runtests.jl           # Automated integration test suite
└── LICENSE                   # Apache 2.0 License
```

---

## Legal & Licensing

#### Code
* Original 2008 Processing code: Copyright 2008 Aaron Koblin.
* Julia 3D Studio & Tools: Copyright 2026 Carlo Monjaraz & Contributors.
* Licensed under the **Apache License 2.0** (see [`LICENSE`](LICENSE)).

#### Data
* Data: Copyright 2008 Radiohead.
* Made available under the **Creative Commons Attribution-Noncommercial-Share Alike 3.0 License (CC BY-NC-SA 3.0)**.
