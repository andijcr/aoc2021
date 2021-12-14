package require Tcl 8.5

package require struct::list
package require math::linearalgebra

set tmp [struct::list filter [split "NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C" \n] {string length} ]

proc make_transition_matrix { pattern rulelist outmatrix outvector outmapping } {
    lappend rulelist "[string index $pattern end]% -> %"
    set pattern $pattern%

    upvar $outmapping map
    set map {}
    set tmp_mat {}
    foreach r $rulelist {
        lassign [split $r {-> }] rule _ _ _ prod 
        lassign [split $rule {}] pre post
        set row {}
        foreach atom [list $rule $pre$prod $prod$post] {
            set idx [lsearch -exact $map $atom]
            if { $idx < 0 } { lappend map $atom; set idx [expr {[llength $map]-1}] }
            lappend row $idx
        }
        lappend tmp_mat $row
    }


    upvar $outvector vec
    set vec [make_input_vector $pattern $map]


    set tmp_mat [lsort -integer -index 0 $tmp_mat]
    set cardinality [llength $vec]
    upvar $outmatrix mat
    set mat [math::linearalgebra::mkMatrix $cardinality $cardinality 0]
    for { set i 0 } { $i < $cardinality } { incr i } {
        set pre_production [lsearch -exact -all -inline -index 1 $tmp_mat $i]
        set post_production [lsearch -exact -all -inline -index 2 $tmp_mat $i]
        foreach precursor [list {*}$pre_production {*}$post_production] {
            lassign $precursor col
            math::linearalgebra::setelem mat $i $col [expr {[math::linearalgebra::getelem $mat $i $col] +1}]
        }
    }
}

proc make_input_vector { pattern mapping } {
    set card [llength $mapping]
    set vec [lrepeat $card 0]
    for { set i 0 } { $i < ([string length $pattern] -1)} {incr i} {
        set pair [string range $pattern $i [expr {$i +1}]]
        set idx [lsearch -exact $mapping $pair]
        lset vec $idx [expr { [lindex $vec $idx] + 1}]
    }
    return $vec
}

proc letters_population { state_vec mapping } {
    set pop [dict create]
    set letters [split [join $mapping ""] {}]
    foreach l $letters {
        dict set pop $l 0
    }
    foreach s $state_vec m $mapping {
        lassign [split $m {}] l
        dict incr pop $l [expr {int($s)}]
    }

    set res_pop {}
    dict for {l s} $pop {
        if { $l == {%} } { continue }
        lappend res_pop [list $l $s]
    }

    lsort -integer -index 1 $res_pop
}

make_transition_matrix [lindex $tmp 0] [lrange $tmp 1 end] test_matrix test_pattern test_mapping
puts "$test_pattern \n\n[math::linearalgebra::show $test_matrix {%1.0f}]\n$test_mapping"

proc matpower { mat intpow } {
    if { $intpow <= 0 } { error "sorry only positive" }
    set res $mat
    for { set i 0 } { $i < $intpow } { incr i } {
        set res [::math::linearalgebra::matmul $mat $res]
    }
    return $res
}

set test_state [math::linearalgebra::matmul [matpower $test_matrix 9] $test_pattern]
set pop [letters_population $test_state $test_mapping]
set final_score [expr { [lindex $pop end 1] - [lindex $pop 0 1] }]
puts "$test_state\n$test_mapping\n$pop\n$final_score"

set fl [open 14input]
set input [struct::list filter [split [read $fl] \n] {string length} ]; close $fl

make_transition_matrix [lindex $input 0] [lrange $input 1 end] matrix pattern mapping
set state [math::linearalgebra::matmul [matpower $matrix 9] $pattern]
set pop [letters_population $state $mapping]
set final_score [expr { [lindex $pop end 1] - [lindex $pop 0 1] }]
puts "$state\n$pop\n$final_score"

set further_state [math::linearalgebra::matmul [matpower $matrix 29] $state]
set pop [letters_population $further_state $mapping]
set final_score [expr { [lindex $pop end 1] - [lindex $pop 0 1] }]
puts "$further_state\n$pop\n$final_score"


