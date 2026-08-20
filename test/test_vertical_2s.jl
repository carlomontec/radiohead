using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer

out_test = joinpath(@__DIR__, "..", "exports", "test_portrait_3_4_2s.mp4")

println("Rendering 2-second 3/4 portrait video test (1080x1920, 60 frames)...")
render_animation_video(
    out_test;
    data_dir = joinpath(@__DIR__, "..", "data"),
    audio_path = joinpath(@__DIR__, "..", "data", "HouseOfCards_DataSample.mp3"),
    start_frame = 1,
    end_frame = 60,
    framerate = 30,
    resolution = (1080, 1920),
    colormap = :turbo,
    markersize = 5.5f0,
    min_intensity = 18.0f0,
    camera_mode = :portrait_3_4
)

println("3/4 Portrait test render complete! File: $out_test")
