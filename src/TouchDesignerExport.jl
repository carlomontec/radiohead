module TouchDesignerExport

using GeometryBasics
using ..DataLoader: PointCloudData

export export_ply, export_csv_td, export_sequence_ply

"""
    export_ply(filepath::String, pcd::PointCloudData; binary=true)

Exports a point cloud to PLY format (supported directly by TouchDesigner's Point File In TOP/SOP).
"""
function export_ply(filepath::String, pcd::PointCloudData; binary::Bool=true)
    mkpath(dirname(filepath))
    n = length(pcd.points)
    
    if binary
        open(filepath, "w") do io
            # PLY header
            write(io, "ply\n")
            write(io, "format binary_little_endian 1.0\n")
            write(io, "comment Generated for TouchDesigner from Radiohead House of Cards data\n")
            write(io, "element vertex $n\n")
            write(io, "property float x\n")
            write(io, "property float y\n")
            write(io, "property float z\n")
            write(io, "property float intensity\n")
            write(io, "end_header\n")
            
            # Binary payload: 4 x Float32 (16 bytes per vertex)
            buf = IOBuffer()
            @inbounds for i in 1:n
                pt = pcd.points[i]
                write(buf, Float32(pt[1]))
                write(buf, Float32(pt[2]))
                write(buf, Float32(pt[3]))
                write(buf, Float32(pcd.intensities[i]))
            end
            write(io, take!(buf))
        end
    else
        open(filepath, "w") do io
            # PLY ASCII header
            write(io, "ply\n")
            write(io, "format ascii 1.0\n")
            write(io, "comment Generated for TouchDesigner from Radiohead House of Cards data\n")
            write(io, "element vertex $n\n")
            write(io, "property float x\n")
            write(io, "property float y\n")
            write(io, "property float z\n")
            write(io, "property float intensity\n")
            write(io, "end_header\n")
            
            @inbounds for i in 1:n
                pt = pcd.points[i]
                write(io, "$(pt[1]) $(pt[2]) $(pt[3]) $(pcd.intensities[i])\n")
            end
        end
    end
    
    return filepath
end

"""
    export_csv_td(filepath::String, pcd::PointCloudData)

Exports point cloud as CSV formatted with TouchDesigner CHOP/DAT friendly headers:
`tx, ty, tz, intensity`
"""
function export_csv_td(filepath::String, pcd::PointCloudData)
    mkpath(dirname(filepath))
    n = length(pcd.points)
    
    open(filepath, "w") do io
        write(io, "tx,ty,tz,intensity\n")
        @inbounds for i in 1:n
            pt = pcd.points[i]
            write(io, "$(pt[1]),$(pt[2]),$(pt[3]),$(pcd.intensities[i])\n")
        end
    end
    return filepath
end

"""
    export_sequence_ply(out_dir::String, start_frame::Int, end_frame::Int; data_dir="data", binary=true)

Exports a sequence of frames to numbered PLY files for TouchDesigner timeline playback.
"""
function export_sequence_ply(out_dir::String, start_frame::Int, end_frame::Int; data_dir::String="data", binary::Bool=true)
    mkpath(out_dir)
    println("Exporting frames $start_frame to $end_frame to PLY in $out_dir ...")
    
    for f in start_frame:end_frame
        pcd = DataLoader.load_frame(f; data_dir=data_dir)
        target = joinpath(out_dir, "frame_$(lpad(f, 4, '0')).ply")
        export_ply(target, pcd; binary=binary)
    end
    println("Export completed: $(end_frame - start_frame + 1) files written to $out_dir.")
end

end # module
