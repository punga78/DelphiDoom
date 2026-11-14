#!/bin/sh
# Makes the golden of the test DelphiDoom.Tests.Qvm.Parity.
#   golden.sh <folder of build.sh> <folder written by the test with QVM_DUMP> [program] > Tests/Data/Qvm/parity.golden.txt
# The second folder has scenarios.txt and one .qvm (and .map) for each scenario, written by
#   set QVM_DUMP=<folder>
#   bin\Win32\Release\Tests\DelphiDoom.Tests.Qvm.exe
# The third argument is the driver to run (qvmrun.exe; qvmrun_x87.exe to compare the two float units).
set -e
RUN=$(cd "$1" && pwd)
cd "$2"
"$RUN/${3:-qvmrun.exe}" run scenarios.txt
