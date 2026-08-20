using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer
using GLMakie

println("Loading Cul-de-sac LiDAR scan...")
pcd = DataLoader.load_lidar(:culdesac; data_dir="data/SceneViewer/data", downsample=4)

fig = Figure(size=(1400, 900), backgroundcolor=RGBf(0.02, 0.02, 0.04))
ax = Axis3(fig[1, 1], aspect=:data, perspectiveness=0.5, azimuth=0.8*pi, elevation=0.1*pi, backgroundcolor=RGBf(0.01, 0.01, 0.02))
scatter!(ax, pcd.points, color=pcd.intensities, colormap=:inferno, colorrange=(0, 255), markersize=1.5f0)

save("exports/culdesac_lidar.png", fig)
println("Saved Cul-de-sac LiDAR render to exports/culdesac_lidar.png")
