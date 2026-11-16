@echo off
rem Re-run synthesis on sync_fifo.v with Yosys (YoWASP build)
cd /d %~dp0verilog
python -c "from yowasp_yosys import run_yosys; import sys; sys.exit(run_yosys(['-l','synth.log','-s','syn.ys']))"
if errorlevel 1 (
  echo Synthesis FAILED - see verilog\synth.log
) else (
  echo Synthesis OK. Open verilog\synth.log and search for "Printing statistics".
  findstr /C:"cells" synth.log
)
pause
