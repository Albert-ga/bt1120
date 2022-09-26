vlib work
vmap work work


vlog top_module.v
vlog top_module_TB.v

vsim -voptargs=+acc work.top_module_TB
vsim -debugdb top_module.v

view *

add wave -position insertpoint sim:/top_module_TB/top_module_uut/uart_tx_uut/*
add wave -position insertpoint sim:/top_module_TB/top_module_uut/uart_rx_uut/*

log -r /*

run 5ms






