vlib work
vlog display.v 
vsim  -L altera_mf_ver test
log -r {/*}
add wave {/*}
force {clock} 0 0ns, 1 10ns -r 20ns

force {KEY[1]} 1
force {KEY[0]} 0
run 20ns

force {SW[9:6]} 4'd0
force {KEY[1]} 0
force {KEY[0]} 1
run 20ns

force {SW[9:6]} 4'd0
force {KEY[1]} 1
force {KEY[0]} 1
run 8000ns