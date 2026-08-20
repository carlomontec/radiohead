# Radiohead "House of Cards" – Technical Guide & Manual

This manual provides comprehensive instructions for running the Julia 3D Studio, customizing and rendering high-definition MP4 videos, configuring TOML parameters, and exporting point clouds to TouchDesigner.

---

## Table of Contents
1. [Dataset Setup](#1-dataset-setup)
2. [Interactive 3D Studio](#2-interactive-3d-studio)
3. [Video Exporter & TOML Reference](#3-video-exporter--toml-reference)
4. [TouchDesigner Integration](#4-touchdesigner-integration)
5. [Architecture & Codebase Overview](#5-architecture--codebase-overview)
6. [Legal & Licensing](#6-legal--licensing)

---

## 1. Dataset Setup

The 3D point cloud dataset was captured during the production of Radiohead's *House of Cards* music video (2008) directed by James Frost, with technical direction by Aaron Koblin.

### Download Releases
Download the three zip archives from the repository release page into a local `data/` directory:
1. `HoC_AnimationData1_v1.0.zip` (Frames 1 to 1200, Thom Yorke singing)
2. `HoC_AnimationData2_v1.0.zip` (Frames 1201 to 2101, Thom Yorke singing)
3. `HoC_DataApplications_v1.0.zip` (LiDAR scans and audio sample)

### Directory Structure
Extract all frame CSV files directly into `data/`, and place LiDAR files into `data/SceneViewer/data/`:

```
RadioheadNew/
├── data/
│   ├── 1.csv ... 2101.csv              # Facial animation frames
│   ├── HouseOfCards_DataSample.mp3    # Master audio track (67.13s / ~70s)
│   └── SceneViewer/
│       └── data/
│           ├── city.csv                # 1.36M points 360-degree LiDAR scan
│           └── culdesac.csv            # 1.07M points LiDAR scan
```

### Data Format Specification
* **Face CSVs (`1.csv` to `2101.csv`)**: Each file contains ~12,300 lines of `x,y,z,intensity`. Coordinates are in millimeters centered around the facial core. Laser reflectance intensity ranges from `0` to `255` (`intensity >= 18` represents the clean facial surface, while lower values are scanner background noise).
* **LiDAR CSVs (`city.csv`, `culdesac.csv`)**: 360-degree environmental scans containing over 1 million points each.

---

## 2. Interactive 3D Studio

The interactive studio is built in Julia using `GLMakie` (OpenGL backend).

### Launching the Studio
```bash
julia --project=. run_viewer.jl
```

Or from the Julia REPL:
```julia
using Pkg; Pkg.activate(".")
using RadioheadViewer
launch_viewer()
```

### Controls & Navigation
* **3D Orbit**: Left-click and drag to rotate the camera around the 3D scene.
* **Pan**: Right-click and drag to translate the camera.
* **Zoom**: Scroll wheel to zoom in and out.
* **Animation Playback**: Click `Play` / `Pause` or adjust the `Playback Speed` slider (1 - 60 FPS).
* **Timeline Scrubber**: Drag the slider to seek to any frame between 1 and 2101 with instant in-memory caching.
* **Dataset Switcher**: Toggle between Thom Yorke's facial animation, the City LiDAR scan (1.36M points), and the Cul-de-sac LiDAR scan (1.07M points).
* **Colormaps**: Select from built-in shaders (`turbo`, `viridis`, `plasma`, `inferno`, `coolwarm`, `ice`, `hot`, `magma`, `prism`).
* **Noise Filter**: Adjust the `Min Intensity Filter` slider to clean background sensor noise.

---

## 3. Video Exporter & TOML Reference

The video export engine produces deterministic, frame-accurate 30 FPS MP4 videos with synchronized stereo audio muxed via FFmpeg.

### Rendering a Video
Run the exporter from the command line:
```bash
# Uses default render_config.toml
julia --project=. export_video.jl

# Or specify a custom configuration file
julia --project=. export_video.jl custom_config.toml
```

### TOML Configuration Reference (`render_config.toml`)

```toml
[video]
resolution = [1080, 1920]          # [Width, Height] - e.g. [1080, 1920] for vertical (9:16)
framerate = 30                     # Target FPS (30 FPS matches the 70.03s audio sample)
start_frame = 1                    # First frame to render
end_frame = 2101                   # Last frame to render (2101 for full song)
output_path = "exports/radiohead_house_of_cards_vertical.mp4"
audio_path = "data/HouseOfCards_DataSample.mp3"
include_audio = true               # Automatically mux audio track with FFmpeg

[camera]
mode = "orbit"                     # Camera mode: "orbit", "portrait_3_4_drift", or "fixed"
azimuth = 1.32                     # Starting horizontal angle (multiplied by pi)
elevation = -0.01                  # Vertical eye-level pitch (multiplied by pi)
perspectiveness = 1.0              # Optical 3D depth (0.0 = isometric, 1.0 = full perspective)
zoom_half_width = 72.0             # Framing zoom (smaller value = tighter close-up)
orbit_speed_seconds = 60.0         # Seconds per full 360-degree rotation (e.g. 60.0s = 1 min)
orbit_direction = "counter_clockwise" # "counter_clockwise" or "clockwise"
drift_amplitude = 0.06             # Subtle breathing motion if mode is "portrait_3_4_drift"

[rendering]
colormap = "turbo"                 # Colormap name (turbo, viridis, plasma, ice, coolwarm)
colorrange = [20.0, 220.0]         # Min/Max intensity color map range
markersize = 7.0                   # Point marker size in pixels
min_intensity = 18.0               # Noise threshold filter
background_color = [0.012, 0.012, 0.020] # Background RGB [0.0 to 1.0]

[title]
show = true                        # Set to false for clean video without title text
text = "RADIOHEAD // HOUSE OF CARDS (remake by @zurdo_visuals)"
font = "Helvetica Bold"            # Font family or style (:bold, "Helvetica", "Arial")
fontsize = 28                      # Font size
color = [0.85, 0.85, 0.95]         # Title RGB color [0.0 to 1.0]
```

---

## 4. TouchDesigner Integration

The project includes built-in exporters to convert raw CSV frames into standard 3D formats compatible with TouchDesigner.

### Exporting Files
* In the interactive studio sidebar, click **"Frame (.PLY)"** to export the current frame, or **"Next 100 (.PLY)"** to export a sequence.
* Programmatically from Julia:
  ```julia
  using RadioheadViewer
  
  # Export single frame
  pcd = load_frame(1)
  export_ply("exports/touchdesigner/frame_1.ply", pcd; binary=true)
  
  # Export full sequence (1 to 2101)
  export_sequence_ply("exports/touchdesigner_seq", 1, 2101; binary=true)
  ```

### TouchDesigner Setup Guide
1. **Importing Geometry**:
   * Add a **Point File In SOP** or **Point File In TOP**.
   * Set the file path expression to load the sequence dynamically:
     ```python
     f"exports/touchdesigner_seq/frame_{int(me.time.frame):04d}.ply"
     ```
2. **Audio Sync**:
   * Add an **Audio File In CHOP** pointing to `data/HouseOfCards_DataSample.mp3`.
   * Frame 1 corresponds to `0.00` seconds of the audio sample (Thom's first vocal line).
3. **Creative Workflows**:
   * Feed points into a **Point SOP** or **Particles GPU COMP**.
   * Connect to **Feedback TOP** and **Displace TOP** networks driven by audio FFT spectrum analysis.

---

## 5. Architecture & Codebase Overview

```
RadioheadNew/
├── Project.toml              # Julia environment definition
├── Manifest.toml             # Pinned package versions
├── render_config.toml        # Declarative video rendering configuration
├── run_viewer.jl             # Interactive GUI studio entry point
├── export_video.jl           # 30 FPS video export script with audio muxing
├── src/
│   ├── DataLoader.jl         # CSV and LiDAR parser with in-memory caching
│   ├── TouchDesignerExport.jl # Binary/ASCII PLY and CSV exporter
│   ├── VideoExporter.jl      # GLMakie OpenGL video renderer & FFmpeg muxer
│   ├── ViewerApp.jl          # Interactive GLMakie OpenGL GUI application
│   └── RadioheadViewer.jl    # Root package aggregator
├── test/
│   ├── runtests.jl           # Automated integration test suite
│   └── test_video_export.jl  # Video export test
├── docs/
│   ├── GUIDE.md              # Technical manual (this file)
│   └── images/               # Preview stills and documentation screenshots
└── LICENSE                   # Apache 2.0 License
```

---

## 6. Legal & Licensing

### Original Project & Data
* **Music Video**: Radiohead – *House of Cards* (2008), directed by James Frost.
* **Technical Direction**: Aaron Koblin.
* **Original Archive**: [dataarts/radiohead on GitHub](https://github.com/dataarts/radiohead).
* **Data Copyright**: Copyright 2008 Radiohead.
* **Data License**: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License ([CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/)).

### Software
* **Original Processing Sketches**: Copyright 2008 Aaron Koblin.
* **Julia 3D Studio & Video Exporter**: Copyright 2026 Carlo Monjaraz & Contributors.
* **Software License**: Licensed under the Apache License 2.0 (see `LICENSE`).
