# ic-projects

数字 IC 学习过程中的手写 RTL 与验证代码合集。目标方向：数字后端（PD / STA）。

## 环境

- 仿真：Icarus Verilog 10.2 + GTKWave（CentOS 7 虚拟机）
- 编译：`iverilog -o <sim> <rtl>.v tb_<rtl>.v`
- 运行：`vvp <sim>`
- 波形：`gtkwave <rtl>.vcd &`

## 已完成的模块

| 文件 | 内容 | 关键点 |
|---|---|---|
| `verilog/mux4.v` | 四选一选择器（assign 与或式 + always/case） | 组合逻辑两种建模方式 |
| `verilog/1mu4.v` | 四选一选择器（always + case 版本） | `always @(*)` 里不能用多驱动 |
| `verilog/dff.v` | 带异步复位的 D 触发器 | `posedge clk or negedge rst_n` |
| `verilog/reg8.v` | 8 位寄存器，带异步复位与使能 | 复位优先 / 使能采样 / 保持 |
| `verilog/cnt10.v` | 模 10 计数器 | 到顶归零的条件写法 |
| `verilog/tick_gen.v` | 参数化时钟使能脉冲发生器 | clock enable 优于分频时钟 |
| `verilog/edge_det.v` | 异步输入边沿检测 | 三级触发器 + 两级同步抗亚稳态 |
| `verilog/seq_det.v` | "101" 序列检测状态机 | 三段式写法 + 最长后缀匹配 |

## 验证思路

每个 RTL 都配 `tb_*.v`，激励变化点统一放在时钟沿之后 2~3ns，避免"贴着沿采样"导致的仿真结果不可靠（对应 STA 的 setup / hold 概念）。
