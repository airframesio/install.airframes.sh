#!/usr/bin/env bash
# Checks that build_run_command passes the station ident to every decoder.
# Run: bash tests/build_run_command_test.sh   (needs bash 4+)
set -u
here=$(cd "$(dirname "$0")" && pwd)
warn() { echo "WARN: $*"; }
get_frequencies() { echo "131.550 130.025"; }
declare -A DECODER_FEED_PORT=([acarsdec]=5550 [dumpvdl2]=5552 [dumphfdl]=5556 [vdlm2dec]=5555)
AIRFRAMES_FEED_HOST=feed.airframes.io
source <(sed -n '/^build_run_command()/,/^}/p' "$here/../installer")

fail=0
has()    { if [[ "$2" == *"$3"* ]]; then echo "ok   $1"; else echo "FAIL $1: $2"; fail=1; fi; }
hasnt()  { if [[ "$2" != *"$3"* ]]; then echo "ok   $1"; else echo "FAIL $1: $2"; fail=1; fi; }

STATION_IDENT=KE-KJFK-ACARS
has acarsdec "$(build_run_command acarsdec)" "acarsdec -v -i KE-KJFK-ACARS -o 4"
has vdlm2dec "$(build_run_command vdlm2dec)" "vdlm2dec -v -i KE-KJFK-ACARS -r 0"
for SELECTED_SDR in rtlsdr airspy sdrplay; do
  has "dumpvdl2/$SELECTED_SDR" "$(build_run_command dumpvdl2)" "dumpvdl2 --station-id KE-KJFK-ACARS "
  has "dumphfdl/$SELECTED_SDR" "$(build_run_command dumphfdl)" "dumphfdl --station-id KE-KJFK-ACARS "
done
unset SELECTED_SDR

STATION_IDENT=""
hasnt "no ident: acarsdec" "$(build_run_command acarsdec)" " -i "
hasnt "no ident: dumpvdl2" "$(build_run_command dumpvdl2)" "--station-id"

STATION_IDENT="bad ident;rm"
hasnt "unsafe ident left out" "$(build_run_command acarsdec 2>/dev/null)" "bad ident"
has "unsafe ident warns on stderr" "$(build_run_command acarsdec 2>&1 >/dev/null)" "WARN"

exit $fail
