using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer

out_test = joinpath(@__DIR__, "..", "exports", "test_sample_2s.mp4")

println("Testing 2-second video render (60 frames) with audio muxing...")
render_animation_video(
    out_test;
    data_dir = joinpath(@__DIR__, "..", "data"),
    audio_path = joinpath(@__DIR__, "..", "data", "HouseOfCards_DataSample.mp3"),
    start_frame = 1,
    end_frame = 60,
    framerate = 30,
    resolution = (1280, 720),
    colormap = :turbo,
    markersize = 3.5f0,
    min_intensity = 18.0f0,
    camera_mode = :subtle_orbit
)

println("Test export successful! Output file: $out_test")
