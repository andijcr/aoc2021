package require Tcl 8.5

package require struct::list 1.8.4

set test_statuses [struct::list filter [split "00100
11110
10110
10111
10101
01111
00111
11100
10000
11001
00010
01010" \n] {string length} ]

set fl [open 03input]; set data [read $fl]; close $fl
set statuses [struct::list filter [split $data \n] {string length}]; unset data 
puts "statuses data in a list"

split [lindex $statuses 0] ""

proc make_report {report item} {
    set res {}
    foreach r $report i [split $item ""] {
        lappend res [incr r [ expr { ($i*2) -1 } ]]
    }
    return $res
}

set empty_report [struct::list repeat [string length [lindex $statuses 0]] 0]
set report [struct::list fold $statuses $empty_report make_report]

set gamma_report [string cat 0b [join [::struct::list mapfor d $report {expr { $d > 0 }}] "" ]]
set epsilon_report [string cat 0b [join [::struct::list mapfor d $report { expr { $d < 0 }}] "" ]] 

puts "gamma [expr { $gamma_report }] epsilon [ expr { $epsilon_report }]"
expr { $gamma_report * $epsilon_report }

package require lambda 1

proc is_1 { i item } {
    string index $item $i
}

proc is_0 { i item } {
    expr {![is_1 $i $item]}
}

proc count_bit_column { i } {
    lambda { i report item } {
        lassign $report zero_cnt one_cnt
        list [incr zero_cnt [is_0 $i $item]] [incr one_cnt [is_1 $i $item]]
    } $i
}

proc is_oxi { i report } {
    lassign $report 0_rep 1_rep

    if { $1_rep == 0 || $0_rep == 0} { return lambda {item} {expr 1} }
    
    if { $1_rep >= $0_rep } {
        list is_1 $i
    } else {
        list is_0 $i
    }
}

proc is_co2 { i report } {
    lassign $report 0_rep 1_rep
    if { $1_rep == 0 || $0_rep == 0} { return lambda {item} {expr 1} }
    
    if { $1_rep >= $0_rep } {
        list is_0 $i
    } else {
        list is_1 $i
    }
}


set oxi_statuses $statuses
for {set i 0; set max [string length [lindex $oxi_statuses 0]]} { $i < $max } {incr i } {
    if { [llength $oxi_statuses] == 1 } { break }
    set oxi_acc [struct::list fold $oxi_statuses [list 0 0] [count_bit_column $i]]
    set oxi_statuses [struct::list filter $oxi_statuses [is_oxi $i $oxi_acc]]
}
set oxi_rating [string cat 0b $oxi_statuses]
puts "oxi rating: $oxi_rating [expr {$oxi_rating}]"

set co2_statuses $statuses
for {set i 0; set max [string length [lindex $co2_statuses 0]]} { $i < $max } {incr i } {
    if { [llength $co2_statuses] == 1 } { break }
    set co2_acc [struct::list fold $co2_statuses [list 0 0] [count_bit_column $i]]
    set co2_statuses [struct::list filter $co2_statuses [is_co2 $i $co2_acc]]
}
set co2_rating [string cat 0b $co2_statuses]
puts "co2 rating: $co2_rating [expr {$co2_rating}]"

puts "life support rating: [expr {$oxi_rating * $co2_rating }]"
