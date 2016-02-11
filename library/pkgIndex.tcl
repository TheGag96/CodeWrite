if {[catch {package require Tcl 8.4}]} return
set script ""
if {![info exists ::env(TEXTPLUS_LIBRARY)]
    && [file exists [file join $dir textplus.tcl]]} {
    append script "set ::textplus_library \"$dir\"\n"
}
append script "load \"[file join $dir TkTextPlus01.dll]\" TkTextPlus"
package ifneeded TkTextPlus 0.1 $script
