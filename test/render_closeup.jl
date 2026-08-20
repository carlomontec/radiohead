using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "RadioheadViewer.jl"))
using .RadioheadViewer
using GLMakie

pcd = DataLoader.load_frame(200; data_dir="data")

# Filter points with intensity > 20
mask = pcd.intensities .> 20
pts = pcd.points[mask]
ints = pcd.intensities[mask]

fig = Figure(size=(1200, 900), backgroundcolor=RGBf(0.04, 0.04, 0.06))
ax = Axis3(fig[1, 1], aspect=:data, perspectiveness=0.5, azimuth=1.2*pi, elevation=0.15*pi, backgroundcolor=RGBf(0.02, 0.02, 0.03))
scatter!(ax, pts, color=ints, colormap=:turbo, colorrange=(20, 200), markersize=4.0f0)

save("exports/thom_face_frame200.png", fig)
println("Saved closeup to exports/thom_face_frame200.png")
