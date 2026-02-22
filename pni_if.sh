#!/bin/sh
# pni_if.sh
# ============================================================================
set -eu
D_TME="⧖" # \tmedlm, tme (Time Machine Efficiency)
ahr_stamp() { date +"%Y%m%d%H%M%S%N" | cut -c 1-23; }

D_KV="Ⓥ"  # key/value
D_TXT="Ⓣ" # \txtdlm,  txt, text
D_ROW="Ⓐ" # row delimiter usually an array
D_FLD="↔"  # field delimiter (uniprint-friendly)

# ...
pni_if=$(ls /sys/class/net)

# Capture once to a variable to avoid multiple sudo calls and for speed
# We use -json because it ensures fields are on predictable lines
raw_json=$(sudo lshw -json -C network)

for pni in $pni_if; do
    if [ "$pni" = "lo" ]; then
        echo "lo: Loopback (127.0.0.0/8) - Internal"
    else
        # Use awk to find the specific block where logicalname matches $pni
        # RS='}' treats every JSON object as one record
        # FS='"' uses double quotes as field delimiters for easy value extraction

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
                    printf "%s | %s | %s", vendor, product, desc
                }
            }
        ')

        if [ -n "$info" ]; then
            echo "$pni: $info"
        else
            # Handle virtual interfaces (docker, veth, etc) that lshw ignores
            echo "$pni: Virtual or Software Interface"
        fi
    fi
done
