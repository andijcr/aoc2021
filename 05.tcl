package require Tcl 8.5

package require struct::list 1.8.4

set test_input_txt "0,9 -> 5,9
8,0 -> 0,8
9,4 -> 3,4
2,2 -> 2,1
7,0 -> 7,4
6,4 -> 2,0
0,9 -> 2,9
3,4 -> 1,4
0,0 -> 8,8
5,5 -> 8,2"
set test_input [struct::list mapfor line [struct::list filter [split $test_input_txt "\n"] {string length} ] { struct::list filter [split $line "-> ,"] {string length} }]

set fl [open 05input]
set input [struct::list mapfor line [struct::list filter [split [read $fl] "\n"] {string length} ] { struct::list filter [split $line "-> ,"] {string length} }]
close $fl

proc vertical_normalize { lst } {
    lassign $lst x0 y0 x1 y1
    if { $y0 > $y1 } { return [list $x1 $y1 $x0 $y0 ] }
    return $lst
}
proc horizontal_normalize { lst } {
    lassign $lst x0 y0 x1 y1
    if { $x0 > $x1 } { return [list $x1 $y1 $x0 $y0 ] }
    return $lst
}

proc is_vertical { lst } { expr { [lindex $lst 0] == [lindex $lst 2] } }
proc is_horizontal { lst } { expr { [lindex $lst 1] == [lindex $lst 3] } }
proc is_axis_oriented { lst } { expr { [is_vertical $lst] || [is_horizontal $lst] } }
proc vertical_points { lst } { 
    lassign $lst x0 y0 x1 y1
    set points {}
    for { set i $y0 } { $i <= $y1 } { incr i } { lappend points [list $x0 $i] }
    return $points
}
proc horizontal_points { lst } { 
    lassign $lst x0 y0 x1 y1
    set points {}
    for { set i $x0 } { $i <= $x1 } { incr i } { lappend points [list $i $y0] }
    return $points
}

proc diagonal_points { lst } { 
    lassign $lst x0 y0 x1 y1
    set vdir 1
    if { $y0 > $y1 } { set vdir -1 }
    set points {}
    for { set x $x0; set y $y0 } { $x <= $x1 } { incr x; incr y $vdir } { lappend points [list $x $y] }
    return $points
}

proc to_points { lst } {
    if { [is_vertical $lst] } {
        vertical_points [vertical_normalize $lst]
    } elseif { [is_horizontal $lst] } {
        horizontal_points [horizontal_normalize $lst] 
    } else {
        diagonal_points [horizontal_normalize $lst]
    }
}

set map {}
foreach line [struct::list filter $input is_axis_oriented] {
    foreach p [to_points $line ] {
        set cnt 1
        if {[dict exists $map $p]} {
            lassign [dict get $map $p] cnt
            incr cnt
        }
        dict set map $p $cnt
    }
}

set tot_cnt 0
dict for {p cnt} $map {
    if { $cnt > 1 } {
        incr tot_cnt
        # puts "[list $p $cnt]"
    }
}
puts "tot $tot_cnt"

set map {}
foreach line $input {
    foreach p [to_points $line ] {
        set cnt 1
        if {[dict exists $map $p]} {
            lassign [dict get $map $p] cnt
            incr cnt
        }
        dict set map $p $cnt
    }
}

set tot_cnt 0
dict for {p cnt} $map {
    if { $cnt > 1 } {
        incr tot_cnt
        # puts "[list $p $cnt]"
    }
}
puts "tot $tot_cnt"
