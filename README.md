# modelsim_test1
UART_TX_RX modelsim
top_module.v / module_mul :bit 4  multiply
top_module.v / uart_tx :uart_tx   bauds = 921600bps
top_module.v / uart_rx :uart_tx   bauds = 921600bps

top_module_tb.v:  create some input data
compail.do  :modelsim file 

follow flow:

open modelsim

cd .*****/

do compail.do

watch wave
