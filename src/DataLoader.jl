module DataLoader

using GeometryBasics

export PointCloudData, load_frame, load_lidar, get_frame_count, compute_stats, clear_cache!

struct PointCloudData
    points::Vector{Point3f}
    intensities::Vector{Float32}
    bounds_min::Point3f
    bounds_max::Point3f
end

# In-memory frame cache to ensure silky-smooth 60+ FPS playback
const FRAME_CACHE = Dict{Int, PointCloudData}()

function clear_cache!()
    empty!(FRAME_CACHE)
end

"""
    load_frame(frame_num::Int; data_dir="data", use_cache=true) -> PointCloudData

Fast parser for Thom Yorke face frames (1.csv to 2101.csv) with memory caching.
"""
function load_frame(frame_num::Int; data_dir::String="data", use_cache::Bool=true)::PointCloudData
    if use_cache && haskey(FRAME_CACHE, frame_num)
        return FRAME_CACHE[frame_num]
    end
    
    filename = joinpath(data_dir, "$frame_num.csv")
    if !isfile(filename)
        error("Frame file not found: $filename")
    end
    
    pcd = parse_csv_points(filename; scale=1.0f0)
    if use_cache
        FRAME_CACHE[frame_num] = pcd
    end
    return pcd
end

"""
    load_lidar(name::Symbol; data_dir="data/SceneViewer/data", downsample::Int=1) -> PointCloudData

Loads LiDAR scene scans (:city or :culdesac) with optional downsampling step.
"""
function load_lidar(name::Symbol; data_dir::String="data/SceneViewer/data", downsample::Int=1)::PointCloudData
    filename = if name == :city
        joinpath(data_dir, "city.csv")
    elseif name == :culdesac
        joinpath(data_dir, "culdesac.csv")
    else
        error("Unknown lidar scene: $name. Available: :city, :culdesac")
    end
    
    if !isfile(filename)
        error("Lidar file not found: $filename")
    end
    
    # LiDAR data coordinates are in mm, scaled by 1/1000 to meters
    return parse_csv_points(filename; scale=0.001f0, downsample=downsample)
end

"""
    get_frame_count(data_dir="data") -> Int
"""
function get_frame_count(data_dir::String="data")::Int
    count = 0
    while isfile(joinpath(data_dir, "$(count + 1).csv"))
        count += 1
    end
    return count
end

"""
    parse_csv_points(filepath::String; scale=1.0f0, downsample=1) -> PointCloudData
"""
function parse_csv_points(filepath::String; scale::Float32=1.0f0, downsample::Int=1)::PointCloudData
    lines = readlines(filepath)
    n_total = length(lines)
    n = div(n_total, max(1, downsample))
    
    points = Vector{Point3f}(undef, n)
    intensities = Vector{Float32}(undef, n)
    
    min_x = Inf32; min_y = Inf32; min_z = Inf32
    max_x = -Inf32; max_y = -Inf32; max_z = -Inf32
    
    idx = 1
    @inbounds for i in 1:downsample:n_total
        idx > n && break
        line = lines[i]
        isempty(strip(line)) && continue
        
        parts = split(line, ',')
        if length(parts) >= 4
            x = parse(Float32, parts[1]) * scale
            y = parse(Float32, parts[2]) * scale
            z = parse(Float32, parts[3]) * scale
            intensity = parse(Float32, parts[4])
            
            points[idx] = Point3f(x, y, z)
            intensities[idx] = intensity
            
            min_x = min(min_x, x); min_y = min(min_y, y); min_z = min(min_z, z)
            max_x = max(max_x, x); max_y = max(max_y, y); max_z = max(max_z, z)
            idx += 1
        end
    end
    
    actual_count = idx - 1
    if actual_count < n
        resize!(points, actual_count)
        resize!(intensities, actual_count)
    end
    
    b_min = Point3f(min_x == Inf32 ? 0.0f0 : min_x, min_y == Inf32 ? 0.0f0 : min_y, min_z == Inf32 ? 0.0f0 : min_z)
    b_max = Point3f(max_x == -Inf32 ? 0.0f0 : max_x, max_y == -Inf32 ? 0.0f0 : max_y, max_z == -Inf32 ? 0.0f0 : max_z)
    
    return PointCloudData(points, intensities, b_min, b_max)
end

"""
    compute_stats(pcd::PointCloudData) -> Dict
"""
function compute_stats(pcd::PointCloudData)
    n = length(pcd.points)
    if n == 0
        return Dict("count" => 0)
    end
    
    min_i = isempty(pcd.intensities) ? 0.0f0 : minimum(pcd.intensities)
    max_i = isempty(pcd.intensities) ? 0.0f0 : maximum(pcd.intensities)
    avg_i = isempty(pcd.intensities) ? 0.0f0 : sum(pcd.intensities) / n
    
    dims = pcd.bounds_max .- pcd.bounds_min
    
    return Dict(
        "count" => n,
        "bounds_min" => pcd.bounds_min,
        "bounds_max" => pcd.bounds_max,
        "dimensions" => dims,
        "intensity_min" => min_i,
        "intensity_max" => max_i,
        "intensity_avg" => avg_i
    )
end

end # module
