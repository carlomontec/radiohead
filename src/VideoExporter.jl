module VideoExporter

using GLMakie
using GeometryBasics
using Colors
using TOML
using ..DataLoader

export render_animation_video, load_render_config

"""
    load_render_config(toml_path::String="render_config.toml") -> Dict{String, Any}

Loads and parses a TOML video rendering configuration file.
"""
function load_render_config(toml_path::String="render_config.toml")
    if !isfile(toml_path)
        error("Configuration file not found: $toml_path")
    end
    return TOML.parsefile(toml_path)
end

"""
    render_animation_video(config_or_path; data_dir="data")

Renders the 3D point cloud sequence to MP4 at 30 FPS based on a TOML configuration.
"""
function render_animation_video(config_path::String; data_dir::String="data")
    if endswith(config_path, ".toml")
        cfg = load_render_config(config_path)
        return render_from_config_dict(cfg; data_dir=data_dir)
    else
        error("Please pass a TOML configuration path (.toml) or a parsed Dict.")
    end
end

function render_animation_video(cfg::Dict{String, Any}; data_dir::String="data")
    return render_from_config_dict(cfg; data_dir=data_dir)
end

function render_from_config_dict(cfg::Dict{String, Any}; data_dir::String="data")
    # Video Section
    v_sec = get(cfg, "video", Dict{String, Any}())
    res_vec = get(v_sec, "resolution", [1080, 1920])
    resolution = (Int(res_vec[1]), Int(res_vec[2]))
    framerate = get(v_sec, "framerate", 30)
    start_frame = get(v_sec, "start_frame", 1)
    end_frame = get(v_sec, "end_frame", 2101)
    output_mp4 = get(v_sec, "output_path", "exports/radiohead_house_of_cards_vertical.mp4")
    audio_path = get(v_sec, "audio_path", "data/HouseOfCards_DataSample.mp3")
    include_audio = get(v_sec, "include_audio", true)

    # Camera Section
    c_sec = get(cfg, "camera", Dict{String, Any}())
    cam_mode = Symbol(get(c_sec, "mode", "orbit"))
    base_azimuth = Float32(get(c_sec, "azimuth", 1.32)) * Float32(pi)
    base_elevation = Float32(get(c_sec, "elevation", -0.01)) * Float32(pi)
    perspectiveness = Float32(get(c_sec, "perspectiveness", 0.45))
    zoom_half_w = Float32(get(c_sec, "zoom_half_width", 72.0))
    drift_amp = Float32(get(c_sec, "drift_amplitude", 0.06))
    orbit_speed_sec = Float32(get(c_sec, "orbit_speed_seconds", 30.0))
    orbit_direction = get(c_sec, "orbit_direction", "counter_clockwise")
    dir_sign = orbit_direction == "clockwise" ? -1.0f0 : 1.0f0

    # Rendering Section
    r_sec = get(cfg, "rendering", Dict{String, Any}())
    cmap_sym = Symbol(get(r_sec, "colormap", "turbo"))
    crange_vec = get(r_sec, "colorrange", [20.0, 220.0])
    colorrange = (Float32(crange_vec[1]), Float32(crange_vec[2]))
    markersize = Float32(get(r_sec, "markersize", 7.0))
    min_intensity = Float32(get(r_sec, "min_intensity", 18.0))
    bg_vec = get(r_sec, "background_color", [0.012, 0.012, 0.020])
    bg_color = RGBf(bg_vec[1], bg_vec[2], bg_vec[3])

    # Title Section
    t_sec = get(cfg, "title", Dict{String, Any}())
    show_title = get(t_sec, "show", true)
    title_text = get(t_sec, "text", "RADIOHEAD // HOUSE OF CARDS (remake by @zurdo_visuals)")
    title_size = get(t_sec, "fontsize", 28)
    title_font_val = get(t_sec, "font", "Helvetica Bold")
    title_font = title_font_val == "bold" ? :bold : title_font_val
    t_col_vec = get(t_sec, "color", [0.85, 0.85, 0.95])
    title_color = RGBf(t_col_vec[1], t_col_vec[2], t_col_vec[3])

    total_render_frames = end_frame - start_frame + 1
    println("="^65)
    println("  Radiohead 3D Point Cloud Studio - Video Exporter")
    println("="^65)
    println("Output Video:    $output_mp4")
    println("Frame Range:     $start_frame to $end_frame ($total_render_frames frames)")
    println("Framerate:       $framerate FPS (~$(round(total_render_frames/framerate, digits=1))s)")
    println("Resolution:      $(resolution[1])x$(resolution[2])")
    println("Colormap:        $cmap_sym (Range: $colorrange)")
    println("Point Size:      $markersize px | Min Intensity: $min_intensity")
    println("Camera Mode:     $cam_mode (Start Azimuth: $(round(base_azimuth/pi, digits=2))pi, Elev: $(round(base_elevation/pi, digits=2))pi)")
    if cam_mode == :orbit
        println("Orbit Speed:     $orbit_speed_sec s / 360 deg ($orbit_direction)")
    end
    println("Audio Track:     $(include_audio && isfile(audio_path) ? audio_path : "None")")

    mkpath(dirname(output_mp4))
    temp_video = joinpath(dirname(output_mp4), "temp_silent_stream.mp4")

    # Initial frame data processing
    function process_frame(pcd)
        m = pcd.intensities .>= min_intensity
        raw_p = pcd.points[m]
        # Reorient: X, Z_depth, -Y_forehead (Upright orientation)
        upright = [Point3f(p[1], p[3], -p[2]) for p in raw_p]
        if !isempty(upright)
            c = Point3f(75.0f0, -75.0f0, -145.0f0)
            centered = [p - c for p in upright]
            return centered, pcd.intensities[m]
        else
            return Point3f[], Float32[]
        end
    end

    pcd_init = DataLoader.load_frame(start_frame; data_dir=data_dir)
    pts_init, ints_init = process_frame(pcd_init)
    pts_obs = Observable(pts_init)
    ints_obs = Observable(ints_init)

    azimuth_obs = Observable(base_azimuth)
    elevation_obs = Observable(base_elevation)

    # 3D Figure Setup
    fig = Figure(size=resolution, backgroundcolor=bg_color)
    
    title_arg = show_title ? title_text : ""
    ax = Axis3(
        fig[1, 1],
        aspect = :data,
        perspectiveness = perspectiveness,
        azimuth = azimuth_obs,
        elevation = elevation_obs,
        backgroundcolor = bg_color,
        title = title_arg,
        titlecolor = title_color,
        titlesize = title_size,
        titlefont = title_font,
        xlabel = "", ylabel = "", zlabel = "",
        xgridvisible = false, ygridvisible = false, zgridvisible = false,
        xticksvisible = false, yticksvisible = false, zticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false, zticklabelsvisible = false
    )

    scatter!(
        ax,
        pts_obs,
        color = ints_obs,
        colormap = cmap_sym,
        colorrange = colorrange,
        markersize = markersize,
        transparency = true
    )

    # Apply close-up zoom limits
    xlims!(ax, -zoom_half_w, zoom_half_w)
    ylims!(ax, -zoom_half_w, zoom_half_w)
    zlims!(ax, -zoom_half_w * 1.5, zoom_half_w * 1.5)

    println("Recording frames with GLMakie OpenGL engine...")
    
    # Offline deterministic render loop
    GLMakie.record(fig, temp_video, start_frame:end_frame; framerate=framerate) do f
        pcd = DataLoader.load_frame(f; data_dir=data_dir)
        pts, ints = process_frame(pcd)
        pts_obs[] = pts
        ints_obs[] = ints
        
        # Calculate current time in seconds
        elapsed_sec = (f - start_frame) / framerate
        
        if cam_mode == :orbit
            # Smooth 360 degree revolution around Thom
            rotation_progress = elapsed_sec / max(0.1f0, orbit_speed_sec)
            azimuth_obs[] = base_azimuth + dir_sign * rotation_progress * 2.0f0 * Float32(pi)
            elevation_obs[] = base_elevation
        elseif cam_mode == :portrait_3_4_drift
            # Subtle breathing drift
            progress = (f - start_frame) / max(1, total_render_frames)
            azimuth_obs[] = base_azimuth + drift_amp * sin(progress * 2 * pi)
            elevation_obs[] = base_elevation + (drift_amp * 0.4f0) * cos(progress * 2 * pi)
        else # :fixed
            azimuth_obs[] = base_azimuth
            elevation_obs[] = base_elevation
        end
        
        if (f - start_frame) % 150 == 0 || f == end_frame
            percent = round((f - start_frame + 1) / total_render_frames * 100, digits=1)
            print("\rRendering: frame $f / $end_frame ($percent%)")
            flush(stdout)
        end
    end
    println("\nVideo stream rendered.")

    # Mux audio with ffmpeg
    if include_audio && isfile(audio_path)
        println("Muxing audio track from $audio_path with ffmpeg...")
        cmd = `ffmpeg -y -i $temp_video -i $audio_path -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest $output_mp4`
        try
            run(pipeline(cmd, stdout=devnull, stderr=devnull))
            rm(temp_video, force=true)
            println("Finalized synchronized video saved to: $output_mp4 ($(round(filesize(output_mp4)/1024/1024, digits=2)) MB)")
        catch e
            @warn "ffmpeg mux failed, keeping raw stream as $output_mp4" exception=e
            mv(temp_video, output_mp4, force=true)
        end
    else
        mv(temp_video, output_mp4, force=true)
        println("Saved video to: $output_mp4")
    end

    return output_mp4
end

end # module
