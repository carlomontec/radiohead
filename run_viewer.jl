#!/usr/bin/env julia

# Radiohead Point Cloud 3D Studio Runner
using Pkg
Pkg.activate(@__DIR__)

include("src/RadioheadViewer.jl")
using .RadioheadViewer

println("="^60)
println("  Radiohead 'House of Cards' 3D Point Cloud Studio (Julia)")
println("="^60)
println("Starting interactive GLMakie viewer...")

fig = launch_viewer(data_dir="data", start_frame=1)

# Keep the Julia process alive if launched from CLI until window is closed
if !isinteractive()
    println("Interactive window open. Close the window to exit.")
    wait(fig.scene)
end
