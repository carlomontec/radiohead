# Quick render test for Makie
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer
using GLMakie

println("Testing GLMakie scene creation and saving a snapshot...")
pcd = DataLoader.load_frame(200; data_dir="data")

fig = Figure(size=(1000, 800), backgroundcolor=:black)
ax = Axis3(fig[1, 1], aspect=:data, perspectiveness=0.5, azimuth=1.25*pi, elevation=0.18*pi, backgroundcolor=RGBf(0.05, 0.05, 0.08))
scatter!(ax, pcd.points, color=pcd.intensities, colormap=:turbo, colorrange=(0, 255), markersize=3.0f0)

mkpath("exports")
save("exports/snapshot_frame_200.png", fig)
println("Snapshot successfully saved to exports/snapshot_frame_200.png!")
