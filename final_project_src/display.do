vlib work
vlog display.v image_process.v registers.v image_ram.v menu_ram.v 
vsim  -L altera_mf_ver display
log -r {/*}
add wave {/*}
force {clock} 0 0ns, 1 10ns -r 20ns

force {resetn} 0
force {KEY[1]} 1
force {SW[4:0]} 5'b00000
force {SW[9]} 1
run 20ns

force {resetn} 1
force {KEY[1]} 0
force {SW[4:0]} 5'b00000
force {SW[9]} 1
run 20ns

force {resetn} 1
force {KEY[1]} 1
force {SW[4:0]} 5'b00000
force {SW[9]} 1
run 1200ns