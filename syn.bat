@echo off
rem Re-run synthesis on sync_fifo.v with native Yosys (OSS CAD Suite)
call "C:\Users\AORUS\oss-cad-suite\environment.bat"
cd /d %~dp0verilog
yosys -l synth.log -s syn.ys >nul 2>&1
if errorlevel 1 (
  echo Synthesis FAILED - see verilog\synth.log for the error
) else (
  echo ============================================================
  echo  Synthesis OK.  ==== CELL COUNT SUMMARY ====
  powershell -NoProfile -Command "Get-Content -Tail 26 synth.log"
  echo ============================================================
  echo  Full report = verilog\synth.log    Netlist = verilog\sync_fifo_netlist.v
)
pause
