using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer
using GLMakie

println("Loading City LiDAR scan...")
pcd = DataLoader.load_lidar(:city; data_dir="data/SceneViewer/data", downsample=4)

fig = Figure(size=(1400, 900), backgroundcolor=RGBf(0.02, 0.02, 0.04))
ax = Axis3(fig[1, 1], aspect=:data, perspectiveness=0.5, azimuth=0.75*pi, elevation=0.12*pi, backgroundcolor=RGBf(0.01, 0.01, 0.02))
scatter!(ax, pcd.points, color=pcd.intensities, colormap=:coolwarm, colorrange=(0, 255), markersize=1.5f0)

save("exports/city_lidar.png", fig)
println("Saved City LiDAR render to exports/city_lidar.png")
