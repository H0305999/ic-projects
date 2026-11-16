@echo off
rem Gate-level simulation: re-synthesize, then simulate the NETLIST (not the RTL)
rem STEP 1: synthesize RTL -> gate netlist (yosys)
rem STEP 2: compile netlist + testbench (iverilog)
rem STEP 3: run the simulation (vvp)
call "C:\Users\AORUS\oss-cad-suite\environment.bat"
cd /d %~dp0verilog

echo ============================================================
echo  STEP 1/3  synthesize RTL -^> netlist
yosys -l synth.log -s syn.ys >nul 2>&1
if errorlevel 1 (
  echo Synthesis FAILED - see verilog\synth.log
  pause
  exit /b 1
)
echo  netlist regenerated: sync_fifo_netlist.v

echo.
echo  STEP 2/3  compile netlist + gate-level testbench
iverilog -o gl_sim sync_fifo_netlist.v tb_sync_fifo_gl.v
if errorlevel 1 (
  echo Compile FAILED
  pause
  exit /b 1
)

echo.
echo  STEP 3/3  run gate-level simulation
vvp gl_sim > gl.log 2>&1
echo ============================================================
echo  GATE-LEVEL SIM RESULT  (last lines of gl.log)
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "Get-Content -Encoding UTF8 -Tail 8 gl.log"
echo ============================================================
echo  Full log = verilog\gl.log    Waveform = verilog\sync_fifo_gl.vcd
pause
