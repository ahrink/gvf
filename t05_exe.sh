#!/bin/sh
# t05_exe.sh - GVF Barebone SM v05 (LAB anchored)
# Focused reserved streams: a w x y z
# Adds a single example module stream as the pattern for future streams.

# Load common module (same directory as this script)
SELF_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1090
. "$SELF_DIR/t05_cmn.sh"

SM_runtime # not in the main loop yet

# --- a) System Information (reserved truth) ---
system_info() {

    read_pause

    clear_screen "$SYS_ID" "$SES_GEN"
    echo "${gC}── System Information (a: reserved truth) ─────────${nC}"
    echo "${cC}System ID:${nC}   ${yC}$SYS_ID${nC}"
    echo "${cC}Machine ID:${nC}  ${yC}$MCN_ID${nC}"
    echo "${cC}OS ID:${nC}       ${yC}$OS_ID${nC}"
    echo "${cC}LAB Mount:${nC}   ${yC}$LAB_MOUNT${nC}"
    echo "${cC}GVF Root:${nC}    ${yC}$GVF_ROOT${nC}"
    echo "${cC}CFG Path:${nC}    ${yC}$CFG_PTH${nC}"
    echo "${cC}Ledger D:${nC}    ${yC}$LGR_PTH${nC}"
    echo "${cC}Session:${nC}     ${yC}$SES_TME${nC}"
    echo "${cC}Gen:${nC}         ${yC}$SES_GEN${nC}"
    echo "${cC}Action:${nC}      ${yC}$SES_ACT${nC}"
    echo "${cC}Sub-ID:${nC}      ${yC}$SUB_ID${nC}"
    echo ""
    echo "SYS: $SYS_PTH"
    echo "JRN: $CFG_JRN"
    echo ""
#    read_pause
}

system_info
