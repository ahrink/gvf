#!/bin/sh
# t05_cmn.sh - GVF Barebone SM v06
# LAB-anchored state (Live + Persistent) via Ext4 label "LAB".
# Reserved streams: a w x y z
# Non-reserved letters remain placeholders (motif preserved).

# --- Colors (optional; safe in sh) ---
rC='\033[1;31m'; gC='\033[1;32m'; yC='\033[1;33m'
bC='\033[1;34m'; mC='\033[1;35m'; cC='\033[1;36m'
wC='\033[1;37m'; nC='\033[0m'

# --- AHR Semiotics ---
SYM_TME="⧖" # \tmedlm, tme (Time Machine Efficiency)
SYM_JRN="⇥" # \jrndlm,  jrn (Journal and Journey)
SYM_DC="𝄋"  # \dcdlm,  DC (Da Capo)
SYM_txt="Ⓣ" # \txtdlm,  txt, text
SYM_arr="Ⓐ" # \arrdlm,  arr, array
SYM_var="Ⓥ" # \vardlm,  var, variable (k=v)
SYM_dir="Ⓓ" # \dirdlm,  dir, directory full path
SYM_fle="Ⓕ" # \fledlm,  fle, file full path
SYM_err="Ⓔ" # \errdlm,  err, error 0/1 logical
SYM_lib="Ⓛ" # \libdlm,  lib, library
SYM_sci="Ⓢ" # \scidlm,  sci, scientific block
SYM_ns="⒩"  # \nandlm,  nan, nano unit

# --- AHR Timestamp (23 digits) ---
ahr_stamp() { date +"%Y%m%d%H%M%S%N" | cut -c 1-23; }

show_prompt() { printf "${cC}$1 ${nC}"; }
read_pause() { echo ""; show_prompt "Press Enter..."; read dummy; }

# --- Display helpers/Header ---
clear_screen() {
    clear
    local sys="$1"; local sGEN="$2"
    echo "${bC}═══════════════════════════════════════════${nC}"
    echo "${bC}   GVF Barebone SM v06 (LAB Anchored)      ${nC}"
    echo "${bC}   System: $sys | Gen: $sGEN${nC}"
    echo "${bC}═══════════════════════════════════════════${nC}"
    echo ""
}

# --- Semiotic Utilities ---
semiotic_delimiter() {
    local d=""; local f="";
    while [ $# -gt 0 ]; do
        case "$1" in
            -d) d="$2"; shift 2 ;;
            -f) f="$2"; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    [ -n "$d" ] || { echo "ERR: -d delimiter required" >&2; return 2; }
    [ -n "$f" ] || { echo "ERR: -f fields required" >&2; return 2; }

    if [ $# -gt 0 ]; then printf '%s\n' "$1"; else cat; fi | awk -v d="$d" -v f="$f" '
        BEGIN { n = split(f, want, ",") }
        {
            c = split($0, a, d)
            out = ""
            for (i = 1; i <= n; i++) {
                k = want[i] + 0
                if (k >= 1 && k <= c) out = out (out=="" ? "" : OFS) a[k]
            }
            print out
        }'
}

# --- System Detection ---
detect_machine_id() {
    if [ -f /etc/machine-id ]; then
        tr -d '\n' < /etc/machine-id | cut -c 1-8
    elif command -v hostid >/dev/null 2>&1; then
        hostid 2>/dev/null | cut -c 1-8
    else
        (uname -n; grep -m1 "model name" /proc/cpuinfo 2>/dev/null || echo "unknown") \
            | sha256sum | cut -d' ' -f1 | cut -c 1-8
    fi
}

detect_os_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release 2>/dev/null
        echo "${ID:-unknown}_${VERSION_ID:-0}" | tr -cd '[:alnum:]._-' | cut -c 1-24
    elif command -v lsb_release >/dev/null 2>&1; then
        echo "$(lsb_release -is 2>/dev/null)_$(lsb_release -rs 2>/dev/null)" \
            | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]._-' | cut -c 1-24
    else
        uname -s | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]._-' | cut -c 1-10
    fi
}

# --- LAB Detection ---
print_lsblk() {
    echo ""
    echo "Detected block devices (lsblk):"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -o NAME,LABEL,FSTYPE,SIZE,MOUNTPOINT 2>/dev/null || lsblk 2>/dev/null
    else
        echo "lsblk not found. Install util-linux or provide mount path manually."
    fi
    echo ""
}

resolve_lab_mount() {
    # Optional override for testing:
    #   GVF_LAB_MOUNT=/path/to/LAB
    if [ -n "${GVF_LAB_MOUNT:-}" ] && [ -d "$GVF_LAB_MOUNT" ]; then
        LAB_MOUNT="$GVF_LAB_MOUNT"
        return 0
    fi

    # 1) common mount locations (live + persistent)
    for p in /mnt/LAB /media/*/LAB /run/media/*/LAB; do
        if [ -d "$p" ]; then
            LAB_MOUNT="$p"
            return 0
        fi
    done

    # 2) ask lsblk for mountpoint by label
    if command -v lsblk >/dev/null 2>&1; then
        mp="$(lsblk -o LABEL,MOUNTPOINT -nr 2>/dev/null \
        | awk -v L="$LAB_LABEL" '$1==L {print $2; exit}')"
        if [ -n "$mp" ] && [ -d "$mp" ]; then
            LAB_MOUNT="$mp"
            return 0
        fi
    fi

    # 3) if label exists but not mounted, attempt mount (root only)
    if [ -e "/dev/disk/by-label/$LAB_LABEL" ]; then
        if [ "$(id -u 2>/dev/null)" = "0" ]; then
            mkdir -p /mnt/LAB 2>/dev/null || true
            if mount "/dev/disk/by-label/$LAB_LABEL" /mnt/LAB 2>/dev/null; then
                LAB_MOUNT="/mnt/LAB"
                return 0
            fi
        fi
    fi

    # 4) interactive fallback
    echo "ERR: Required disk label '$LAB_LABEL' is not mounted."
    print_lsblk
    echo "Enter the mount path for LAB (example: /media/kubuntu/LAB or /mnt/LAB)."
    printf "LAB mount path: "
    read ans
    if [ -n "$ans" ] && [ -d "$ans" ]; then
        LAB_MOUNT="$ans"
        return 0
    fi

    echo "FATAL: Cannot continue without LAB mounted."
    return 1
}

# --- Generation Management ---
get_next_gen() {
    current_gen="$1"
    if [ -z "$current_gen" ] || [ "$current_gen" = "GEN000" ]; then
        echo "GEN001"
        return
    fi
    numeric_part=$(echo "$current_gen" | sed "s/^${SYM_GEN}//" | tr -cd '0-9')
    [ -n "$numeric_part" ] || numeric_part=0
    gen_cnt=$((numeric_part + 1))
    printf "${SYM_GEN}%03d" "$gen_cnt"
}

# --- Sub-session allocator: letter + hex4 (0000..ffff) ---
alpha_hex() {
    local syl="$1"
    local alp=$(echo "$syl" | cut -c 1-1)
    local hex=$(echo "$syl" | cut -c 2-5)
    local dec=$(printf '%d\n' "0x$hex") # Convert Hex to Decimal
    dec=$((dec + 1)) # Increment Decimal
    hex=$(printf "%04x" "$dec") # new +1 hextet
    SUB_ID="$alp$hex" # alpha-hextet by AHR
    echo "$SUB_ID"
}

dataset_mem() {
    local act="$1"; local hextet="$2"; local cf="$3"
    local dir="$CFG_PTH" local gen=$(get_next_gen "GEN000")

    SES_GEN="${gen}" # Override Default
    SES_TME=$(ahr_stamp) # Override Default
    SYS_PTH="${dir}/${SES_TME}${SYM_TME}${act}"

    SUB_ID=$(alpha_hex "$hextet")
    CFG_JRN="${SYS_PTH}/${SES_TME}${SYM_TME}${SUB_ID}${SYM_JRN}${cf}"

    SYS_MEM=$(printf "%s" \
    "SYS_ID=$SYS_ID${SYM_var}System ID${SYM_arr}" \
    "MCN_ID=$MCN_ID${SYM_var}Machine ID${SYM_arr}" \
    "OS_ID=$OS_ID${SYM_var}Operating System ID${SYM_arr}" \
    "LAB_MOUNT=$LAB_MOUNT${SYM_var}LAB Disk Path${SYM_arr}" \
    "GVF_ROOT=$GVF_ROOT${SYM_var}Structure Root Path${SYM_arr}" \
    "CFG_PTH=$CFG_PTH${SYM_var}Configuration Directory${SYM_arr}" \
    "LGR_PTH=$LGR_PTH${SYM_var}Session Ledger Directory${SYM_arr}" \
    "SES_TME=$SES_TME${SYM_var}Session ID${SYM_arr}" \
    "SES_GEN=$SES_GEN${SYM_var}Session Generation${SYM_arr}" \
    "SES_ACT=$SES_ACT${SYM_var}Session Action${SYM_arr}" \
    "SUB_ID=$SUB_ID${SYM_var}Sub-Session Hextet${SYM_arr}" \
    "SYS_PTH=$SYS_PTH${SYM_var}System Full Path${SYM_arr}" \
    "CFG_JRN=$CFG_JRN${SYM_var}Configuration Full Path${SYM_arr}")
    SYS_MEM=$(echo "$SYS_MEM" \
    | awk -v SYM_txt="$SYM_txt" '{gsub(/ /, SYM_txt); print}')
}
# ................................................
SMCF_write() {
    # Writer Placeholder
    # writes the default configuration journal CFG_JRN
    # may require encryption of /tmp directory-name
    local line=""
    echo "Config Writer ..."
    for line in $(echo "$SYS_MEM" \
    | awk -v SYM_arr="$SYM_arr" '{gsub(/'"$SYM_arr"'/, "\n"); print}'); do
        line=$(echo "$line" | awk -v SYM_txt="$SYM_txt" '{gsub(/'"$SYM_txt"'/, " "); print}')
        echo "-- $line"
    done
}

SMCF_read() {
    # Reader Placeholder mod()
    # may require decryption of /tmp directory-name
    # requires validation process of OLD-JRN
    local sys="$1"
    echo "$sys"
}

# SEARCH(motif) dir → pattern → mod(d/f)
srcFS() {
    local dir="$1"; local ptrn="$2"; local mod="$3";
    local results=""

    [ "$mod" = "D" ] && results=$(ls -l "$dir" \
    | awk -v pattern="$ptrn" '$1 ~ /^d/ && $NF ~ pattern {print $NF}')

    [ "$mod" = "F" ] && results=$(ls -l "$dir" \
    | awk -v pattern="$ptrn" '$1 ~ /^-/ && $NF ~ pattern {print $NF}')

    echo "$results"
}

SM_runtime() {
    MCN_ID=$(detect_machine_id)
    OS_ID=$(detect_os_id)
    SYS_ID="${MCN_ID}${SYM_JRN}${OS_ID}"

    # --- LAB Disk Resolution ---
    LAB_LABEL="LAB"
    LAB_MOUNT=""

    resolve_lab_mount || exit 2

    # --- Session State ---
    GVF_ROOT="$LAB_MOUNT/gvf"
    CFG_PTH="${GVF_ROOT}/CF"
    LGR_PTH="${GVF_ROOT}/SM"
    SES_TME=""
    SES_GEN="GEN000"
    SES_ACT="INI"     # INI | OLD | ANOM
    SUB_ID="a0000"     # current sub-session id
    SYS_PTH=""
    CFG_JRN="jrn.ahr"
    SYS_MEM="dataset"
    # attention: if dataset is complete, create the actual to /tmp …
    # culminate to integrity chained reaction.
    dataset_mem "$SYS_ID" "$SUB_ID" "$CFG_JRN"
    # echo "$dataset"

    # SYS_MEM probe to decision making
    local probe=$(srcFS "$CFG_PTH" "$SYS_ID" "D")
    if [ -z "$probe" ]; then
        # case 1, no FC deploy system
        [ ! -d "$CFG_PTH" ] && mkdir -p "$CFG_PTH"
        # case 2, FC exists
        SMCF_write
    else
        # search for old records
        SMCF_read "$SYS_MEM"
    fi
}
