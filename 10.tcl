package require Tcl 8.5

package require struct::list 1.8.4

set fl [open 10testinput]
set test_input [split [read $fl] \n]; close $fl

set fl [open 10input]
set input [struct::list filter [split [read $fl] \n] {string length}]; close $fl

proc tostr { input } { join $input \n } 

puts [tostr $test_input]


set closing [dict create \{ \} \[ \] ( ) < >]
set opening [dict keys $closing]

proc car { str } { string index $str 0 }
proc cdr { str } { string range $str 1 end }

proc parse { input } {
    global opening
    global closing
    
    # no input: ok
    if { $input == {} } { return {} }

    # first char must be an opening or CORRUPTED 
    set head [lsearch -exact -inline $opening [car $input]]
    if { $head == {} } { throw [list CORRUPTED_START [car $input]] {} }
    
    set rest [cdr $input]
    if { $rest == {} } { throw INCOMPLETE {} }
    # parse rest while it starts with an opening
    while { [lsearch -exact $opening [car $rest]] >= 0} {
        set rest [ parse $rest ]
        # no rest: INCOMPLETE (we still have to match our opening
        if { [string length $rest] == 0 } { throw INCOMPLETE {} }
    }
    
    #if the closing char is different from expected, CORRUPTED
    if {[dict get $closing $head] != [car $rest]} { throw [list CORRUPTED_END [car $rest]] {} }
    # return what's left to parse
    cdr $rest 
}

proc check_error { input type token} {
    upvar $type et
    upvar $token tok
    set et {}
    set tok {}
    if { [catch {parse $input} _ err] } {
        lassign [dict get $err -errorcode] et tok
        return 1
    }
    return 0
}
puts "opening $opening \nclosing $closing"
puts "[lsearch -exact -inline $opening \>]"

puts "[parse <{[][]<><{}[]>}>]todo ok"
if { [catch {parse <} res err] } {
    puts "cought $res [dict get $err -errorcode]"
}

check_error << type token

foreach line $test_input { 
    puts $line
    if { [check_error $line type token] } {
        puts "$type $token"
    }
}

set scoring [dict create ) 3 \] 57 } 1197 > 25137]

proc score { line } {
    global scoring
    if { [check_error $line type token] } {
        if { $type == {CORRUPTED_END} } {
            return [dict get $scoring $token]
        }
    }
    return 0
}

proc wrap_score {line} {
    puts "in: $line"
    set res [score $line]
    puts "out: -$res-"
    return $res
}

proc sum { a b } { expr {$a + $b } }

wrap_score [lindex $test_input 2]

puts "test_res: [struct::list fold [struct::list map $test_input score] 0 sum]"
puts "part one res: [struct::list fold [struct::list map $input score] 0 sum]"

# with INCOMPLETE we send up also the closing tag
proc parse { input } {
    global opening
    global closing
    
    set head [car $input]
    set rest [cdr $input]
    set tail [dict get $closing $head]
    
    #puts "[string repeat " " $lvl]$head"
    
    if { $rest == {} } { return [list INCOMPLETE [list $tail]] }
    # parse rest while it starts with an opening
    while { [lsearch -exact $opening [car $rest]] >= 0} {
        set tmp [ parse $rest ]
        lassign $tmp cmd payload

        if { $cmd == {INCOMPLETE} } { return [list INCOMPLETE [linsert $payload end $tail]] }
        if { $cmd == {CORRUPTED} } { return $tmp }

        if { $payload == {} } { return [list INCOMPLETE [list $tail]] }
        
        set rest $payload
    }

    #if the closing char is different from expected, CORRUPTED
    if { [car $rest] != $tail } { 
        return [list CORRUPTED [car $rest]] 
    }

    #puts "[string repeat " " $lvl]$tail"

    # return what's left to parse
    list CONT [cdr $rest]
}

proc parse_siblings { rest } {
    global opening
    while { [lsearch -exact $opening [car $rest]] >= 0} {
        set tmp [ parse $rest ]
        lassign $tmp cmd payload

        if { $cmd == {INCOMPLETE} || $cmd == {CORRUPTED} } { return $tmp }

        if { $payload == {} } { break }
        
        set rest $payload
    }
    return DONE {}
}
# puts "before: [parse [lindex $test_input 0]]"

# puts "after: [parse [string cat [lindex $test_input 0] {*}[lindex [parse [lindex $test_input 0]] 1]]]"


set inc_scoring [dict create ) 1 \] 2 \} 3 > 4]
proc step_score { prev now } { expr { $prev*5+$now } }
proc inc_score { list } {
    global inc_scoring
    struct::list fold [
        struct::list mapfor c $list { dict get $inc_scoring $c }
    ] 0 step_score
}

foreach t $test_input { puts $t; puts [parse_siblings $t] }

proc score_input { input } {
    set parse_res [struct::list map $input parse_siblings]
    set only_incomplete [struct::list filterfor res $parse_res { [lindex $res 0]=={INCOMPLETE} }]
    lsort -integer [struct::list mapfor inc_seq $only_incomplete { inc_score [lindex $inc_seq 1] }]
}

puts "test scores: [score_input $test_input]"
set scores [score_input $input]
puts "winner: [lindex $scores [expr {[llength $scores]/2}]]"
