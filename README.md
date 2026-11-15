# ic-projects

数字 IC 学习过程中的手写 RTL 与自验证代码合集。方向：数字后端（PD / STA）。

所有模块均用 Icarus Verilog 编译、GTKWave 看波形验证，配套 testbench 带自检比对。

## 快速开始

```bash
cd verilog

# 同步 FIFO
iverilog -o sync_sim sync_fifo.v tb_sync_fifo.v && vvp sync_sim
gtkwave sync_fifo.vcd &

# 异步 FIFO
iverilog -o async_sim async_fifo.v tb_async_fifo.v && vvp async_sim
gtkwave async_fifo.vcd &
```

## 目录结构

```
verilog/
  *.v             RTL 源码
  tb_*.v          testbench（每个 RTL 配一个）
```

## 模块清单

| 文件 | 内容 | 关键点 |
|---|---|---|
| `mux4.v` | 四选一选择器 | 单条 assign 与或式，避免多驱动 |
| `1mu4.v` | 四选一选择器 | `always @(*)` + `case` + `default` |
| `dff.v` | 带异步复位的 D 触发器 | `posedge clk or negedge rst_n` |
| `reg8.v` | 8 位寄存器 | 复位优先 / 使能采样 / 保持 |
| `cnt10.v` | 模 10 计数器 | 到顶归零的边界写法 |
| `tick_gen.v` | 参数化时钟使能脉冲 | clock enable 优于分频时钟 |
| `edge_det.v` | 异步输入边沿检测 | 三级触发器 + 两级同步抗亚稳态 |
| `seq_det.v` | "101" 序列检测 | 三段式状态机 + 最长后缀匹配 |
| `sync_fifo.v` | 同步 FIFO（参数化深度） | 多一位指针区分满/空 |
| `async_fifo.v` | 异步 FIFO（双时钟） | 格雷码指针 + 可配置级数同步器 |

## FIFO 设计

### 同步 FIFO

- 参数：`DW` 数据位宽、`AW` 地址位宽，深度 `2^AW`
- 指针 `AW+1` 位：最高位区分"指针相等"的空与"差整一圈"的满
- `dout` 寄存器输出，读命令后一拍有效
- 存储体不加复位，地址只取低 `AW` 位

验证：同一个 testbench 通过 `DEPTH = 1 << AW` 参数化，`AW=3`（深度 8）与 `AW=4`（深度 16）分别跑通，
写满时指针停在 `1010` / `10010`，读空后 `empty=1`，读出序列与写入完全一致。

### 异步 FIFO

写时钟 `wclk`、读时钟 `rclk` 频率与相位完全无关，两个域只靠格雷码指针通信。

设计要点：

1. **跨域只传格雷码**：相邻值只差 1 位，采样结果只能是旧值或新值，误差最大 1 格，不会撕裂成不存在的指针值
2. **同步器级数可配**（`SYNC` 参数，默认 2）：`generate` 展开成 N 级触发器串联，并标注 `ASYNC_REG` 防止综合优化与拆散
3. **各域独立判满/判空**：写域用 `wgray_next` 对比同步来的 `rgray`，读域用 `rgray_next` 对比同步来的 `wgray`
4. **full / empty 寄存器输出**：避免 `full -> wbin_next -> wgray_next -> full` 组合环
5. **判据**：格雷码下满 = 最高两位相反、其余相同；空 = 完全相等

验证结果（`DW=8`、`AW=3`、共搬 24 个数据、写 100MHz / 读 62.5MHz）：

| 同步级数 | 完成时刻 | full 拉高次数 | 数据比对 |
|---|---|---|---|
| 2 | 1192 ns | 12 | 24/24 全对 |
| 3 | 1208 ns | 13 | 24/24 全对 |
| 4 | 1224 ns | 14 | 24/24 全对 |

结论：同步级数只影响性能与有效容量，不影响正确性。指针跨域延迟造成的误差是单向的（只会更保守），
所以 full / empty 可能提前拉高，但绝不会晚报，因此不会溢出、不会读空。

## 验证方法

- 激励变化点统一放在时钟沿之后 2~3ns，避免"贴着沿采样"导致的仿真结果不可靠（对应 STA 的 setup / hold）
- 每个 testbench 都带期望值队列，读出时逐拍比对，结束时打印 `TEST PASS` / `TEST FAIL`
- 满/空等关键状态变化单独打印时间戳，便于与波形对照

## 环境

- 仿真：Icarus Verilog 10.2 + GTKWave（CentOS 7.6）
- 版本管理：Git / GitHub

## 后续

- 读后端流程（综合 → 布局布线 → STA），跑通一次完整 flow
- 集创赛项目
