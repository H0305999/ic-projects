# ① 定义时钟：100MHz，挂在 clk 端口上
create_clock -name wclk -period 10 [get_ports wclk]
create_clock -name rclk -period 16 [get_ports rclk]

# ② 输入延迟 2ns：din 的 8 个位
set_input_delay 2 -clock wclk [get_ports wdata[*]]

# ③ 输出延迟 2ns：dout 的 8 个位
set_output_delay 2 -clock rclk [get_ports rdata[*]]

# ④ rst_n 是异步复位，不按同步路径检查
set_false_path -from [get_ports rrst_n]
set_false_path -from [get_ports wrst_n]

# rgray（读域的格雷码寄存器）→ rgray_s（写域的同步链）
set_false_path -from [get_cells rgray[*]] -to [get_cells rgray_s[*]]
# wgray（写域）→ wgray_s（读域的同步链）
set_false_path -from [get_cells wgray[*]] -to [get_cells wgray_s[*]]

