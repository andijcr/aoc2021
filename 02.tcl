package require Tcl 8.5 

set fl [open 02input]; set data [read $fl]; close $fl
set commands [split $data \n]
puts "commands data in a list"
foreach cmd $commands {
    switch -glob $cmd {
        "forward *" { }
        "up *" { }
        "down *" { }
        "" {}
        default {error "unexpected input: [$cmd]"} 
    }
}

set x 0
set y 0
proc forward { d } { global x; incr x $d }
proc down { d } { global y; incr y $d }
proc up { d } { global y; incr y -$d }

# input should be sanitized before calling "eval"!
foreach cmd $commands {
    {*}$cmd
}
puts "pos $x $y, mult: [expr {$x*$y}]"
rename forward ""
rename down ""
rename up ""

set x 0
set aim 0
set y 0
proc forward { d } {
    global x y aim
    incr x $d
    incr y [expr {$d*$aim}]
}
proc down { d } { global aim; incr aim $d }
proc up { d } { global aim; incr aim -$d }

# input should be sanitized before calling "eval"!
foreach cmd $commands {
    {*}$cmd
}
puts "pos $x $y, mult: [expr {$x*$y}]"
rename forward ""
rename down ""
rename up ""
    


