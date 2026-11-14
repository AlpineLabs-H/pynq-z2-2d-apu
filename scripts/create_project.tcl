set root [file normalize [file join [file dirname [info script]] ..]]
set scripts_dir [file join $root scripts]
set project_dir [file join $root vivado]

proc read_filelist {filelist root} {
    set file_handle [open $filelist r]
    set files {}
    while {[gets $file_handle line] >= 0} {
        set line [string trim $line]
        if {$line eq "" || [string match "#*" $line]} { continue }
        lappend files [file normalize [file join $root $line]]
    }
    close $file_handle
    return $files
}

create_project -force VGA_GPU $project_dir -part xc7a35tcpg236-1
set rtl_files [read_filelist [file join $scripts_dir filelist_sv.f] $scripts_dir]
add_files -norecurse $rtl_files
set_property file_type SystemVerilog [get_files *.sv]
set_property top top_level_design [get_filesets sources_1]

set xdc_file [file join $root src constraints main.xdc]
if {[file exists $xdc_file]} {
    add_files -fileset constrs_1 -norecurse $xdc_file
}

update_compile_order -fileset sources_1
save_project
puts "Project created successfully: [file join $project_dir VGA_GPU.xpr]"
