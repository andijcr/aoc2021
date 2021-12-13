package require Tcl 8.5

package require struct::list 1.8.4
package require struct::matrix 2.0.4
package require generator

set fl [open 04input]; 
set data [struct::list filter [split [read $fl] \n] {string length}]; close $fl
set boards_tmp [lassign $data numbers]; unset data;

set numbers [split $numbers ,]
puts "numbers: $numbers"

set boards {}
foreach {0 1 2 3 4} [struct::list mapfor r $boards_tmp { struct::list filter [split $r " "] {string length} }] {
    set tmp [struct::matrix]
    $tmp deserialize [list 5 5 [list $0 $1 $2 $3 $4]]
    #puts "[$tmp format 2string]\n"
    lappend boards $tmp
}

proc print_grid {boards} {
    foreach {0 1 2 3 4 5 6 7 8 9} [struct::list mapfor bb $boards { $bb format 2string }] {
        foreach 0 [split $0 \n] 1 [split $1 \n] 2 [split $2 \n] 3 [split $3 \n] 4 [split $4 \n] 5 [split $5 \n] 6 [split $6 \n] 7 [split $7 \n] 8 [split $8 \n] 9 [split $9 \n] {
            puts "$0\t$1\t$2\t$3\t$4\t$5\t$6\t$7\t$8\t$9"
        }
        puts {}
    }
}

puts {}
print_grid $boards

set data [struct::list filter [split "7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1

22 13 17 11  0
 8  2 23  4 24
21  9 14 16  7
 6 10  3 18  5
 1 12 20 15 19

 3 15  0  2 22
 9 18 13 17  5
19  8  7 25 23
20 11 10 24  4
14 21 16 12  6

14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7" \n] {string length}]
set boards_tmp [lassign $data test_numbers]; unset data;

set test_numbers [split $test_numbers ,]

set test_boards {}
foreach {0 1 2 3 4} [struct::list mapfor r $boards_tmp { struct::list filter [split $r " "] {string length} }] {
    set tmp [struct::matrix]
    $tmp deserialize [list 5 5 [list $0 $1 $2 $3 $4]]
    lappend test_boards $tmp
}


puts "$test_numbers"
print_grid $test_boards

proc all { lst val } { expr {[lsearch -not $lst $val]==-1} } 

proc score { val board mark } {
        set sum 0
        foreach b [struct::list flatten [$board get rect 0 0 4 4]] m [struct::list flatten [$mark get rect 0 0 4 4]] {
            incr sum [expr {$b*$m}]
        }
        expr { $val* $sum }
    }
    
proc bingo_boards { boards } {
    set res {}
    foreach bb $boards {
        set mark [struct::matrix]
        set unit_r { 1 1 1 1 1 }
        $mark deserialize [list 5 5 [list $unit_r $unit_r $unit_r $unit_r $unit_r]]
        lappend res [list $bb $mark 0]
    }
    return $res
}

proc destroy_boards { boards } {
    foreach bb $boards {
        [lindex $bb 1] destroy
    }
}


generator define get_winning { numbers bingo } {
    set boards [bingo_boards $bingo]
    generator finally destroy_boards $boards
        
    foreach val $numbers {
        set winner {}
        foreach bm $boards {
            lassign $bm bb mm
            set pos [$bb search all $val]
            if { [llength $pos] > 0 } {
                lassign $pos pos
                lassign $pos col row
                $mm set cell $col $row 0
                if { [all [$mm get row $row] 0] || [all [$mm get column $col] 0] } {
                    lappend winner $bm
                }
            }
        }

        if { $winner != {} } {
            set true_win [lsearch -index 2 -all -inline -integer $winner 0]
            generator yield [list $val $true_win $winner]
            foreach tw $true_win {          
                set to_exclude [lsearch -exact $boards $tw]
                lset tw 2 1
                lset boards $to_exclude $tw
            }
        }
    }
}

set win [get_winning $numbers $boards]
generator next $win res
puts "first to win: $res"

proc print_bingo { val board } {
    if { $board == {} } { return "nada"  } 
    lassign $board bb mm removed
    list $removed [score $val $bb $mm] $bb
}

set cnt 1
generator foreach wn $win {
    lassign $wn val head_win brs
    puts -nonewline "$cnt: $val. winner:"
    foreach m $head_win {
        puts -nonewline "[print_bingo $val $m]\t"
    }
    puts -nonewline "other:"
    foreach m $brs {
        puts -nonewline "[print_bingo $val $m]\t"
    }
    puts -
    incr cnt
}

puts "\033\[46m 1 \033\[0m10\033\[0m"


