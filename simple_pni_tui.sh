#!/bin/sh
# simple_pni_tui.sh dynamic TUI for PNI user interactive selection
# ============================================================================

set -eu

# ...
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
            iPNI="${iPNI}${ct} ${pni}: $info\n"
        else
            # Handle virtual interfaces (docker, veth, etc) that lshw ignores
            iPNI="${iPNI}${ct} ${pni}: Virtual or Software Interface\n"
        fi
        ct=$((ct + 1))
    fi
  done

  iPNI="${iPNI}${ct} Exit: Network Setup\n"

  # Display the dynamic menu for user interactive selection
  clear
  echo ""
  echo "─────────── Select Physical Network Interface ───────────"
  echo "            $inTitle            "
  echo ""
  echo "$iPNI"
  printf "Select [1-${ct}]: "
  read sel_PNI

  sel_PNI=$(echo "$iPNI" | grep -E "^${sel_PNI}")
  sel_PNI=$(echo "$sel_PNI" | cut -d':' -f1)
  sel_PNI=$(echo "$sel_PNI" | cut -d' ' -f2)
  [ "$sel_PNI" = "Exit" ] && exit 0
  echo "$sel_PNI"

}

dynamic_pni
