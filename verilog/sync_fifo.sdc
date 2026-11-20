# ① 定义时钟：100MHz，挂在 clk 端口上
create_clock -name clk -period 10 [get_ports clk]

# ② 输入延迟 2ns：din 的 8 个位
set_input_delay 2 -clock clk [get_ports din[*]]

# ③ 输出延迟 2ns：dout 的 8 个位
set_output_delay 2 -clock clk [get_ports dout[*]]

# ④ rst_n 是异步复位，不按同步路径检查
set_false_path -from [get_ports rst_n]

