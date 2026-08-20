#!/usr/bin/env julia

# High-Definition 3D Video Exporter with Synchronized Audio
# Usage: julia --project=. export_video.jl [custom_config.toml]

using Pkg
Pkg.activate(@__DIR__)

include("src/RadioheadViewer.jl")
using .RadioheadViewer

config_file = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "render_config.toml")

if !isfile(config_file)
    println(stderr, "Error: Configuration file not found: $config_file")
    exit(1)
end

println("Using configuration: $config_file")
render_animation_video(config_file; data_dir=joinpath(@__DIR__, "data"))
