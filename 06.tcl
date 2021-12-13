package require Tcl 8.6

package require struct::list 1
package require generator

set test_input [split "3,4,3,1,2" ,]

set fl [open 06input]
set input [struct::list filter [split [read $fl] ,] {string length}]; close $fl

generator define population { lst } {
    while { 1 } {
        set new 0
        set pop [struct::list mapfor f $lst {
            if { $f==0 } { incr new; set f 7}
            incr f -1
        }]
        set lst [struct::list flatten [list $pop [struct::list repeat $new 8]]]
        generator yield $lst
    }
}

set getpop [population $test_input]
for { set i 1} { $i < 80 } { incr i } {
    generator next $getpop pop
    #puts "$i: len [llength $pop] pop $pop"
}
generator next $getpop pop
puts "80: len [llength $pop] pop $pop"   

set getpop [population $input]
for { set i 1} { $i < 80 } { incr i } {
    generator next $getpop pop
    #puts "$i: len [llength $pop] pop $pop"
}
generator next $getpop pop
puts "len [llength $pop]"   

# this is a classic population problem that can be modeled with a matrix multiplication, that describes how a population evolves over time
# population with countdown 1 will go to  population that with countdown 0
# cnt 2 -> cnt 1
# 3 -> 2
# 4 -> 3
# 5 -> 4
# 6 -> 5
# 7 + 0 -> 6 - we get a reset of countdown and the younger pop coming from
# 8 -> 7 
# 0 -> 8 - here pop 0 generates a new fish
set step_matrix { 
    { 0 1 0 0 0 0 0 0 0 } 
    { 0 0 1 0 0 0 0 0 0 } 
    { 0 0 0 1 0 0 0 0 0 } 
    { 0 0 0 0 1 0 0 0 0 } 
    { 0 0 0 0 0 1 0 0 0 } 
    { 0 0 0 0 0 0 1 0 0 } 
    { 1 0 0 0 0 0 0 1 0 } 
    { 0 0 0 0 0 0 0 0 1 } 
    { 1 0 0 0 0 0 0 0 0 } 
}
puts $step_matrix

proc to_pop_vector { poplst } {
    set vec { 0 0 0 0 0 0 0 0 0 }
    foreach p $poplst {
        lset vec $p [expr {[lindex $vec $p] + 1 }]
    }
    list $vec
}

puts [to_pop_vector $test_input]

package require math::linearalgebra 1.1.5

proc matpower { mat intpow } {
    if { $intpow <= 0 } { error "sorry only positive" }
    set res $mat
    for { set i 0 } { $i < $intpow } { incr i } {
        set res [::math::linearalgebra::matmul $mat $res]
    }
    return $res
}

matpower [math::linearalgebra::mkIdentity 9] 80
puts [math::linearalgebra::show [matpower $step_matrix 80] %4.0f ]

# a check
set test_pop_80 [math::linearalgebra::matmul [matpower $step_matrix 79] [math::linearalgebra::transpose [ to_pop_vector $test_input ]]]
proc + {a b} {expr {$a + $b}}
puts "test tot: [struct::list fold $test_pop_80 0 +]"

set res_pop_256 [math::linearalgebra::matmul [matpower $step_matrix 255] [math::linearalgebra::transpose [ to_pop_vector $input ]]]
proc + {a b} {expr {$a + $b}}
puts "test tot: [struct::list fold $res_pop_256 0 +]"
