@echo off
rem Re-run synthesis on sync_fifo.v with Yosys (YoWASP build)
rem Use the exact python that has yowasp-yosys installed (bundled python 3.13)
set "PYEXE=C:\Users\AORUS\.workbuddy\binaries\python\versions\3.13.12\python.exe"
if not exist "%PYEXE%" set "PYEXE=python"
cd /d %~dp0verilog
"%PYEXE%" -c "from yowasp_yosys import run_yosys; import sys; sys.exit(run_yosys(['-l','synth.log','-s','syn.ys']))"
if errorlevel 1 (
  echo Synthesis FAILED - see verilog\synth.log for the error
) else (
  echo Synthesis OK. Report = verilog\synth.log, netlist = verilog\sync_fifo_netlist.v
  findstr /C:"cells" synth.log
)
pause
