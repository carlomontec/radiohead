module ViewerApp

using GLMakie
using GeometryBasics
using Colors
using ..DataLoader
using ..TouchDesignerExport

export launch_viewer

function launch_viewer(; data_dir::String="data", start_frame::Int=1)
    GLMakie.activate!(title="Radiohead 'House of Cards' 3D Studio", focus_on_show=true)
    
    total_frames = DataLoader.get_frame_count(data_dir)
    println("Found $total_frames face animation frames in $data_dir.")
    
    # -------------------------------------------------------------
    # 1. Observables (Reactive State)
    # -------------------------------------------------------------
    current_frame = Observable(clamp(start_frame, 1, max(1, total_frames)))
    is_playing = Observable(false)
    fps_val = Observable(30)
    
    selected_mode = Observable("Face Animation")
    selected_colormap = Observable(:turbo)
    marker_size = Observable(3.5f0)
    intensity_min = Observable(0.0f0)
    intensity_max = Observable(255.0f0)
    
    # 3D geometry observables
    raw_pcd = Observable(DataLoader.load_frame(current_frame[]; data_dir=data_dir))
    filtered_points = Observable(Point3f[])
    filtered_intensities = Observable(Float32[])
    
    stats_text = Observable("Loading stats...")
    status_message = Observable("Ready.")
    
    # Helper to apply intensity filter and update geometry
    function update_filtered_geometry!()
        pcd = raw_pcd[]
        min_i = intensity_min[]
        max_i = intensity_max[]
        
        pts = Point3f[]
        ints = Float32[]
        
        @inbounds for i in eachindex(pcd.points)
            val = pcd.intensities[i]
            if min_i <= val <= max_i
                push!(pts, pcd.points[i])
                push!(ints, val)
            end
        end
        
        filtered_points[] = pts
        filtered_intensities[] = ints
        
        # Update stats text
        stats = DataLoader.compute_stats(pcd)
        dim_str = if haskey(stats, "dimensions")
            d = stats["dimensions"]
            "$(round(d[1], digits=1)) x $(round(d[2], digits=1)) x $(round(d[3], digits=1)) mm"
        else
            "N/A"
        end
        
        stats_text[] = string(
            "Mode: $(selected_mode[])\n",
            "Frame: $(current_frame[]) / $total_frames\n",
            "Points: $(length(pts)) / $(length(pcd.points))\n",
            "Dimensions: $dim_str\n",
            "Intensity Range: [$(round(stats["intensity_min"], digits=1)), $(round(stats["intensity_max"], digits=1))]"
        )
    end
    
    # Initial load
    update_filtered_geometry!()
    
    # When frame changes in face mode
    on(current_frame) do f
        if selected_mode[] == "Face Animation"
            raw_pcd[] = DataLoader.load_frame(f; data_dir=data_dir)
            update_filtered_geometry!()
        end
    end
    
    # When intensity filter changes
    on(intensity_min) do _ update_filtered_geometry!() end
    on(intensity_max) do _ update_filtered_geometry!() end
    
    # -------------------------------------------------------------
    # 2. Main GUI Layout
    # -------------------------------------------------------------
    fig = Figure(
        size = (1500, 950),
        backgroundcolor = RGBf(0.07, 0.07, 0.10)
    )
    
    # 3D Viewport
    ax3d = Axis3(
        fig[1:2, 1],
        aspect = :data,
        perspectiveness = 0.5,
        azimuth = 1.25 * pi,
        elevation = 0.18 * pi,
        backgroundcolor = RGBf(0.03, 0.03, 0.05),
        title = "Radiohead 'House of Cards' - 3D Point Cloud Studio",
        titlecolor = :white,
        titlesize = 18,
        xlabel = "X", ylabel = "Y", zlabel = "Z",
        xlabelcolor = :gray70, ylabelcolor = :gray70, zlabelcolor = :gray70,
        xgridcolor = RGBAf(1, 1, 1, 0.08),
        ygridcolor = RGBAf(1, 1, 1, 0.08),
        zgridcolor = RGBAf(1, 1, 1, 0.08)
    )
    
    # Scatter plot on the 3D axis
    scatter_plot = scatter!(
        ax3d,
        filtered_points,
        color = filtered_intensities,
        colormap = selected_colormap,
        colorrange = (0.0f0, 255.0f0),
        markersize = marker_size,
        transparency = true
    )
    
    # Colorbar on bottom of 3D view
    Colorbar(
        fig[3, 1],
        scatter_plot,
        label = "Laser Intensity / Reflectance (0 - 255)",
        labelcolor = :white,
        ticklabelcolor = :gray80,
        vertical = false,
        height = 14,
        flipaxis = false
    )
    
    # -------------------------------------------------------------
    # 3. Control Sidebar
    # -------------------------------------------------------------
    sidebar = GridLayout(fig[1:3, 2], tellheight = false, width = 360)
    
    row = 1
    
    # Section: Mode Selection
    Label(sidebar[row, 1:2], "1. DATASET MODE", font = :bold, color = RGBf(0.4, 0.8, 1.0), justification = :left, halign = :left)
    row += 1
    
    mode_menu = Menu(
        sidebar[row, 1:2],
        options = ["Face Animation", "City LiDAR (1.3M)", "Culdesac LiDAR (1.0M)"],
        default = "Face Animation"
    )
    row += 1
    
    on(mode_menu.selection) do mode_str
        selected_mode[] = mode_str
        is_playing[] = false
        if mode_str == "Face Animation"
            status_message[] = "Loaded Face Animation sequence."
            raw_pcd[] = DataLoader.load_frame(current_frame[]; data_dir=data_dir)
            update_filtered_geometry!()
            autolimits!(ax3d)
        elseif mode_str == "City LiDAR (1.3M)"
            status_message[] = "Loading City LiDAR scan (1.36M points)..."
            raw_pcd[] = DataLoader.load_lidar(:city; downsample=2)
            update_filtered_geometry!()
            autolimits!(ax3d)
            status_message[] = "City LiDAR loaded (2x downsampled for smooth interaction)."
        elseif mode_str == "Culdesac LiDAR (1.0M)"
            status_message[] = "Loading Cul-de-sac LiDAR scan (1.07M points)..."
            raw_pcd[] = DataLoader.load_lidar(:culdesac; downsample=2)
            update_filtered_geometry!()
            autolimits!(ax3d)
            status_message[] = "Culdesac LiDAR loaded (2x downsampled for smooth interaction)."
        end
    end
    
    # Section: Playback Controls
    row += 1
    Label(sidebar[row, 1:2], "2. ANIMATION PLAYBACK", font = :bold, color = RGBf(0.4, 0.8, 1.0), justification = :left, halign = :left)
    row += 1
    
    play_btn = Button(sidebar[row, 1], label = @lift($(is_playing) ? "Pause" : "Play"))
    reset_btn = Button(sidebar[row, 2], label = "Reset (F1)")
    row += 1
    
    prev_btn = Button(sidebar[row, 1], label = "<< -10 Frames")
    next_btn = Button(sidebar[row, 2], label = "+10 Frames >>")
    row += 1
    
    on(play_btn.clicks) do _
        if selected_mode[] == "Face Animation"
            is_playing[] = !is_playing[]
        end
    end
    
    on(reset_btn.clicks) do _
        is_playing[] = false
        current_frame[] = 1
        autolimits!(ax3d)
    end
    
    on(prev_btn.clicks) do _
        current_frame[] = max(1, current_frame[] - 10)
    end
    
    on(next_btn.clicks) do _
        current_frame[] = min(total_frames, current_frame[] + 10)
    end
    
    # Frame scrubber slider
    Label(sidebar[row, 1:2], @lift("Timeline Frame: $($(current_frame)) / $total_frames"), color = :white, justification = :left, halign = :left)
    row += 1
    
    frame_slider = Slider(sidebar[row, 1:2], range = 1:max(1, total_frames), startvalue = current_frame[])
    row += 1
    
    # Sync slider <-> current_frame observable without infinite recursion
    updating_from_slider = Ref(false)
    on(frame_slider.value) do val
        if !updating_from_slider[] && current_frame[] != val
            updating_from_slider[] = true
            current_frame[] = val
            updating_from_slider[] = false
        end
    end
    on(current_frame) do val
        if !updating_from_slider[]
            updating_from_slider[] = true
            set_close_to!(frame_slider, val)
            updating_from_slider[] = false
        end
    end
    
    # FPS Slider
    Label(sidebar[row, 1:2], @lift("Playback Speed: $($(fps_val)) FPS"), color = :white, justification = :left, halign = :left)
    row += 1
    fps_slider = Slider(sidebar[row, 1:2], range = 1:60, startvalue = fps_val[])
    row += 1
    on(fps_slider.value) do val
        fps_val[] = val
    end
    
    # Section: Styling & Shading
    row += 1
    Label(sidebar[row, 1:2], "3. VISUAL STYLING", font = :bold, color = RGBf(0.4, 0.8, 1.0), justification = :left, halign = :left)
    row += 1
    
    Label(sidebar[row, 1], "Colormap:", color = :white, halign = :left)
    cmap_menu = Menu(
        sidebar[row, 2],
        options = ["turbo", "viridis", "plasma", "inferno", "coolwarm", "ice", "hot", "magma", "prism"],
        default = "turbo"
    )
    row += 1
    on(cmap_menu.selection) do cm
        selected_colormap[] = Symbol(cm)
    end
    
    Label(sidebar[row, 1:2], @lift("Point Size: $(round($(marker_size), digits=1)) px"), color = :white, halign = :left)
    row += 1
    size_slider = Slider(sidebar[row, 1:2], range = 0.5:0.5:15.0, startvalue = marker_size[])
    row += 1
    on(size_slider.value) do sz
        marker_size[] = Float32(sz)
    end
    
    Label(sidebar[row, 1:2], @lift("Min Intensity Filter: $(round($(intensity_min), digits=0))"), color = :white, halign = :left)
    row += 1
    imin_slider = Slider(sidebar[row, 1:2], range = 0.0:5.0:200.0, startvalue = intensity_min[])
    row += 1
    on(imin_slider.value) do val
        intensity_min[] = Float32(val)
    end
    
    # Section: TouchDesigner Pipeline Exporter
    row += 1
    Label(sidebar[row, 1:2], "4. TOUCHDESIGNER EXPORT", font = :bold, color = RGBf(0.4, 0.8, 1.0), justification = :left, halign = :left)
    row += 1
    
    exp_frame_btn = Button(sidebar[row, 1:2], label = "Export Current Frame (.PLY)")
    row += 1
    exp_seq_btn = Button(sidebar[row, 1:2], label = "Export Next 100 Frames (.PLY)")
    row += 1
    
    on(exp_frame_btn.clicks) do _
        out_dir = joinpath("exports", "touchdesigner")
        mkpath(out_dir)
        filename = joinpath(out_dir, "frame_$(current_frame[]).ply")
        TouchDesignerExport.export_ply(filename, raw_pcd[]; binary=true)
        status_message[] = "Saved: $filename (Ready for Point File In)"
        println("Exported current frame to $filename")
    end
    
    on(exp_seq_btn.clicks) do _
        out_dir = joinpath("exports", "touchdesigner_seq")
        mkpath(out_dir)
        sf = current_frame[]
        ef = min(total_frames, sf + 99)
        status_message[] = "Exporting frames $sf to $ef..."
        @async begin
            TouchDesignerExport.export_sequence_ply(out_dir, sf, ef; data_dir=data_dir, binary=true)
            status_message[] = "Sequence exported: $sf to $ef in $out_dir"
        end
    end
    
    # Section: Info & Stats Box
    row += 1
    Label(sidebar[row, 1:2], "5. STATS & INFO", font = :bold, color = RGBf(0.4, 0.8, 1.0), justification = :left, halign = :left)
    row += 1
    Label(sidebar[row, 1:2], stats_text, color = :gray85, fontsize = 12, justification = :left, halign = :left)
    row += 1
    Label(sidebar[row, 1:2], status_message, color = RGBf(0.2, 1.0, 0.6), fontsize = 12, justification = :left, halign = :left)
    
    # -------------------------------------------------------------
    # 4. Reactive Playback Task
    # -------------------------------------------------------------
    playback_task = Ref{Union{Task, Nothing}}(nothing)
    
    on(is_playing) do playing
        if playing && selected_mode[] == "Face Animation"
            if playback_task[] === nothing || istaskdone(playback_task[])
                playback_task[] = @async begin
                    try
                        while is_playing[] && selected_mode[] == "Face Animation"
                            next_f = current_frame[] + 1
                            if next_f > total_frames
                                next_f = 1
                            end
                            current_frame[] = next_f
                            sleep(1.0 / max(1, fps_val[]))
                        end
                    catch e
                        @error "Playback loop error:" exception=(e, catch_backtrace())
                    end
                end
            end
        end
    end
    
    # Display the interactive window
    display(fig)
    return fig
end

end # module
