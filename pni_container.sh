#!/bin/sh
# pni_container.sh example of PNI dynamic TUI
# ============================================================================
set -eu
D_TME="⧖" # \tmedlm, tme (Time Machine Efficiency)
ahr_stamp() { date +"%Y%m%d%H%M%S%N" | cut -c 1-23; }

D_KV="Ⓥ"  # key/value
D_TXT="Ⓣ" # \txtdlm,  txt, text
D_ROW="Ⓐ" # row delimiter usually an array
D_FLD="↔"  # field delimiter (uniprint-friendly)

# ...
D_DLM() {
    d=""; f=""
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

    if [ $# -gt 0 ]; then
        printf '%s\n' "$1"
    else
        cat
    fi | awk -v d="$d" -v f="$f" '
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

dyna_tui() {
  local title="$1"; local arr="$2"; local cnt="$3";
  local sel=""
  arr=$(echo "$arr" | awk -v D_TXT="$D_TXT" '{gsub(/'"$D_TXT"'/, " "); print}')
  arr=$(echo "$arr" | awk -v D_ROW="$D_ROW" '{gsub(/'"$D_ROW"'/, "\n"); print}')
  clear
  echo ""
  echo "─────────── Select Physical Network Interface ───────────"
  echo "            $title            "
  echo ""
  echo "$arr" | awk -v D_FLD="$D_FLD" '{gsub(/'"$D_FLD"'/, " "); print}'
  echo ""
  printf "Select [1-${cnt}]: "
  read sel

  # the arr is still delimited
  sel=$(echo "$arr" | grep -E "^${sel}${D_FLD}")
  sel=$(echo "$sel" | D_DLM -d "$D_FLD" -f "2")
  [ "$sel" = "Exit" ] && exit 0
  echo "$sel"

}

pni_if=$(ls /sys/class/net)

dynamic_pni() {
  local raw_json=$(sudo lshw -json -C network)
  local inTitle=""; local iPNI=""; local ct=1; local pni="";

  for pni in $pni_if; do
    if [ "$pni" = "lo" ]; then
        inTitle="lo: Loopback (127.0.0.0/8) - Internal"
    else
        info=$(echo "$raw_json" | awk -v target="$pni" '
            BEGIN { RS="}"; FS="\"" }
            $0 ~ "\"logicalname\" : \""target"\"" {
                # Loop through the record to find our keys
                for (i=1; i<=NF; i++) {
                    if ($i == "vendor") vendor = $(i+2)
                    if ($i == "product") product = $(i+2)
                    if ($i == "description") desc = $(i+2)
                }
                if (product != "") {
                    printf "%s %s %s", vendor, product, desc
                }
            }
        ')

        if [ -n "$info" ]; then
            iPNI="${iPNI}${ct}${D_FLD}${pni}${D_FLD}$info${D_ROW}"
        else
            # Handle virtual interfaces (docker, veth, etc) that lshw ignores
            iPNI="${iPNI}${ct}${D_FLD}${pni}${D_FLD}Wired or Virtual Interface${D_ROW}"
        fi
        ct=$((ct + 1))
    fi
  done

  iPNI="${iPNI}${ct}${D_FLD}Exit${D_FLD}Network Setup${D_ROW}"
  # Replace spaces with D_TXT and create container
  # In this case, the results are intended to be used elsewhere,
  # similar with export one single string.
  container=$(echo "$iPNI" | awk -v D_TXT="$D_TXT" '{gsub(/ /, D_TXT); print}')

  # [elsewhere] Display the dynamic menu for user interactive selection
  dyna_tui "$inTitle" "$container" "$ct"
}

dynamic_pni
