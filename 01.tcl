package require Tcl 8.5 

set fl [open 01input]; set data [read $fl]; close $fl
set sonar [split $data \n]
puts "sonar data in a list"

set incr_count 0
for {set x 1} {$x< [llength $sonar]} {incr x} {
    if { [lindex $sonar $x-1] < [lindex $sonar $x] } {
        incr incr_count
    }
}
puts "sonar data increased $incr_count times"

proc wson {lst i} {
    expr {[lindex $lst $i] + [lindex $lst $i+1] + [lindex $lst $i+2]}
}
puts "lindex call: [lindex $sonar 1+2], window sum: [wson $sonar 0]"

set incr_win_count 0
for {set x 0} {$x < ([llength $sonar]-4)} {incr x} {
    set xn [expr {$x+1}]
    if { [wson $sonar $x] < [wson $sonar $xn] } {
        incr incr_win_count
    }
}
puts "sonar data increased $incr_win_count times in sliding window"
