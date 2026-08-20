# Test suite for RadioheadViewer
using Test

include("../src/RadioheadViewer.jl")
using .RadioheadViewer

@testset "DataLoader Tests" begin
    # Test frame count
    fc = DataLoader.get_frame_count("data")
    @info "Total face frames found: $fc"
    @test fc == 2101
    
    # Test loading frame 1
    pcd1 = DataLoader.load_frame(1; data_dir="data")
    @info "Frame 1 loaded: $(length(pcd1.points)) points"
    @test length(pcd1.points) > 10000
    @test length(pcd1.intensities) == length(pcd1.points)
    
    stats1 = DataLoader.compute_stats(pcd1)
    @info "Stats frame 1: $stats1"
    @test stats1["count"] == length(pcd1.points)
    @test stats1["intensity_min"] >= 0.0f0
    
    # Test loading culdesac lidar
    pcd_cul = DataLoader.load_lidar(:culdesac; data_dir="data/SceneViewer/data", downsample=10)
    @info "Culdesac (10x downsample) loaded: $(length(pcd_cul.points)) points"
    @test length(pcd_cul.points) > 50000
end

@testset "TouchDesigner Export Tests" begin
    pcd1 = DataLoader.load_frame(1; data_dir="data")
    test_out = "exports/test_frame_1.ply"
    TouchDesignerExport.export_ply(test_out, pcd1; binary=true)
    @test isfile(test_out)
    @test filesize(test_out) > 0
    @info "Exported binary PLY successfully ($(filesize(test_out)) bytes)"
    
    test_csv = "exports/test_frame_1_td.csv"
    TouchDesignerExport.export_csv_td(test_csv, pcd1)
    @test isfile(test_csv)
    @info "Exported TouchDesigner CSV successfully ($(filesize(test_csv)) bytes)"
end

println("\nAll tests passed successfully!")
