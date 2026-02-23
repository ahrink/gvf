#!/bin/sh
# pni_v01net.sh example of PNI w/dynamic TUI and network
# ============================================================================
set -eu

D_TME="⧖" # \tmedlm, tme (Time Machine Efficiency)
ahr_stamp() { date +"%Y%m%d%H%M%S%N" | cut -c 1-23; }

D_KV="Ⓥ"  # key/value
D_TXT="Ⓣ" # \txtdlm,  txt, text
D_ROW="Ⓐ" # row delimiter usually an array
D_FLD="↔"  # field delimiter (uniprint-friendly)

PNI_IF=$(ls /sys/class/net)
SEL_PNI=""

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

  # the arr is stil delimited
  sel=$(echo "$arr" | grep -E "^${sel}${D_FLD}")
  SEL_PNI=$(echo "$sel" | D_DLM -d "$D_FLD" -f "2")
  [ "$SEL_PNI" = "Exit" ] && exit 0
  SEL_PNI=$(echo "$SEL_PNI")
}

dynamic_pni() {
  local raw_json=$(lshw -json -C network)
  local inTitle=""; local iPNI=""; local ct=1; local pni="";

  for pni in $PNI_IF; do
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
  iPNI=$(echo "$iPNI" | awk -v D_TXT="$D_TXT" '{gsub(/ /, D_TXT); print}')

  # [elsewhere] Display the dynamic menu for user interactive selection
  dyna_tui "$inTitle" "$iPNI" "$ct"
}

cfg_interface() {
    local iface="$1"

    # Initialize array keys with defaults
    iCIDR="192.168.1.0/24"
    sIP="192.168.1.100"
    mask="255.255.255.0"
    gate="192.168.1.1"
    iDNS="8.8.8.8, 1.1.1.1"
    done="no"

    while [ "$done" != "yes" ]; do
        clear
        echo "─────────────────────────────────────────────────"
        echo "  Configure: $iface"
        echo "  Warning: this script does not validate"
        echo "  the network layer user input."
        echo "─────────────────────────────────────────────────"
        echo ""
        echo "Current settings:"
        echo "  1. Network CIDR    : $iCIDR"
        echo "  2. Start IP        : $sIP"
        echo "  3. Subnet Mask     : $mask"
        echo "  4. Gateway         : $gate"
        echo "  5. DNS Servers     : $iDNS"
        echo ""
        echo "  6. Done - Review configuration"
        echo "  7. Cancel"
        echo ""
        printf "Select field to edit [1-7]: "
        read choice

        case "$choice" in
            1)
                printf "Enter network CIDR [current: $iCIDR]: "
                read newval
                [ -n "$newval" ] && iCIDR="$newval"
                # Auto-calculate mask from CIDR if desired
                # mask=$(cidr_to_mask "${iCIDR#*/}")
                ;;
            2)
                printf "Enter management IP [current: $sIP]: "
                read newval
                [ -n "$newval" ] && sIP="$newval"
                ;;
            3)
                printf "Enter subnet mask [current: $mask]: "
                read newval
                [ -n "$newval" ] && mask="$newval"
                ;;
            4)
                printf "Enter gateway [current: $gate]: "
                read newval
                [ -n "$newval" ] && gate="$newval"
                ;;
            5)
                printf "Enter DNS servers (comma-separated) [current: $iDNS]: "
                read newval
                [ -n "$newval" ] && iDNS="$newval"
                ;;
            6)
                done="yes"
                ;;
            7)
                echo "Cancelled."
                return 1
                ;;
            *)
                echo "Invalid choice. Press Enter to continue..."
                read dummy
                ;;
        esac
    done

    # Show summary for verification
    clear
    echo "─────────────────────────────────────────────────"
    echo "  Configuration Summary for $iface"
    echo "─────────────────────────────────────────────────"
    echo ""
    echo "  Network CIDR    : $iCIDR"
    echo "  Start IP        : $sIP"
    echo "  Subnet Mask     : $mask"
    echo "  Gateway         : $gate"
    echo "  DNS Servers     : $iDNS"
    echo ""
    echo "─────────────────────────────────────────────────"
    echo ""
    printf "Apply this configuration? (yes/no): "
    read confirm

    if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ]; then
        echo "Configuration saved for $iface"
        # Return the config as a delimited string for further processing
        echo "${iface}${D_FLD}${iCIDR}${D_FLD}${sIP}${D_FLD}${mask}${D_FLD}${gate}${D_FLD}${iDNS}"
        return 0
    else
        echo "Configuration cancelled."
        return 1
    fi
}

# --- Main execution ---
runtime() {
    dynamic_pni
    cfg_interface "${SEL_PNI}"
}

runtime
