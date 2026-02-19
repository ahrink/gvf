#!/bin/sh
# 02_CMN_the.sh (barebone strap) - is a cache type
# ============================================================================
set -eu
D_TME="⧖" # \tmedlm, tme (Time Machine Efficiency)
ahr_stamp() { date +"%Y%m%d%H%M%S%N" | cut -c 1-23; }

D_KV="Ⓥ"  # key/value
D_TXT="Ⓣ" # \txtdlm,  txt, text
D_ROW="Ⓐ" # row delimiter usually an array
D_FLD="↔"  # field delimiter (uniprint-friendly)
# ----------------------------------------------------------------------------
# Semiotic Utilities (by SanAnton.substack via AHR UniPrint)
# ----------------------------------------------------------------------------
D_fn() {
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

fn_serial() { echo $(basename "$1" | D_fn -d "$D_TME" -f "1"); }

# ----------------------------------------------------------------------------
# srcFS - search directory for pattern by file/dir type
# ----------------------------------------------------------------------------
srcFS() {
    local dir="$1"; local ptrn="$2"; local mod="$3"; local results="";

    [ "$mod" = "D" ] && results=$(ls -l "$dir" 2>/dev/null \
        | awk -v pattern="$ptrn" '$1 ~ /^d/ && $NF ~ pattern {print $NF}')

    [ "$mod" = "F" ] && results=$(ls -l "$dir" 2>/dev/null \
        | awk -v pattern="$ptrn" '$1 ~ /^-/ && $NF ~ pattern {print $NF}')

    echo "$results"
}

barebone_strap() {
  local patt="$1"
  local serial=$(fn_serial "$DIR_TMP")
  # expression cnt|k=v|description for both human AI interpretation
  local dlm_MEM=$(printf "%s" \
  "1${D_FLD}AHRtID=$(ahr_stamp)${D_TME}${patt}${D_FLD}a new stamp${D_ROW}" \
  "2${D_FLD}serial=${serial}${D_TME}${patt}${D_FLD}a serial assigned to a pattern${D_ROW}" \
  "3${D_FLD}DIR_TMP=${DIR_TMP}${D_FLD}a dir holding cache-type files${D_ROW}" \
  "4${D_FLD}iLOG=${iLOG}${D_FLD}a path to cache-type file${D_ROW}" \
  "5${D_FLD}iEOR=5${D_FLD}End Of Records${D_ROW}")
  dlm_MEM=$(echo "$dlm_MEM" \
  | awk -v D_TXT="$D_TXT" '{gsub(/ /, D_TXT); print}')

  echo "$dlm_MEM" >> "$iLOG"
}

ini_bootstrap() {
  local stamp=$(ahr_stamp)
  local base_dir="/tmp"
  local pattern="master"
  local INI_TMP="${base_dir}/${stamp}${D_TME}${pattern}"
  local probe=$(srcFS "$base_dir" "${D_TME}${pattern}" "D")
  [ -z "$probe" ] && sudo mkdir -p "$INI_TMP"

  DIR_TMP=$(srcFS "$base_dir" "${D_TME}${pattern}" "D")
  DIR_TMP="${base_dir}/$DIR_TMP"

  iLOG="${DIR_TMP}/master_log.dlm"
  local pblog=$(srcFS "$DIR_TMP" "${pattern}" "F")
  [ -z "$pblog" ] && sudo touch "$iLOG" && barebone_strap "master"
  # ...
  export iLOG="$iLOG"
}

# Test to strip rows for coherent human output
vali_date() {
  local log=$(cat "$iLOG"); local r="";
  local nx=""; local kv=""; local dsc="";
  for r in $(echo "$log" \
  | awk -v D_ROW="$D_ROW" '{gsub(/'"$D_ROW"'/, "\n"); print}'); do
    # Strip row for coherent human output
    nx=$(echo "$r" | D_fn -d "$D_FLD" -f "1")
    kv=$(echo "$r" | D_fn -d "$D_FLD" -f "2")
    dsc=$(echo "$r" | D_fn -d "$D_FLD" -f "3")
    dsc=$(echo "$dsc" \
    | awk -v D_TXT="$D_TXT" '{gsub(/'"$D_TXT"'/, " "); print}')
    echo "${nx}. ${kv} ${dsc}"
  done
}

keylog_desc() {
    local k="$1"
    awk -v D_ROW="$D_ROW" -v D_FLD="$D_FLD" -v D_TXT="$D_TXT" -v key="$k" '
    BEGIN { RS = D_ROW; found = 0 }
    {
        split($0, fields, D_FLD)
        if (length(fields) >= 3) {
            kv = fields[2]
            if (index(kv, key "=") == 1) {
                desc = fields[3]
                gsub(D_TXT, " ", desc)
                print desc
                found = 1
                exit
            }
        }
    }
    END { if (!found) exit 1 }' < "$iLOG"
}

read_bootstrap() {
  local cache=$(cat "$iLOG"); local i="";
  for i in $(echo "$cache" \
  | awk -v D_ROW="$D_ROW" '{gsub(/'"$D_ROW"'/, "\n"); print}'); do
    # Strip row for eval
    i=$(echo "$i" | D_fn -d "$D_FLD" -f "2")
    eval $(echo "$i")
  done
}

write_bootstrap() {
    local str="$1"
    [ -n "$str" ] && [ -f "$iLOG" ] || return 2
    # The immutable fingerprint of current state
    local dir=$(dirname "$iLOG")
    local serial=$(fn_serial "$dir")
    read_bootstrap
    [ "$iEOR" = "$serial" ] && return 2

    # Replace spaces with D_TXT
    str=$(echo "$str" | awk -v D_TXT="$D_TXT" '{gsub(/ /, D_TXT); print}')

    # Build complete record set in one temp file no reindex
    # stick with two field expression
    local tmp_file="${iLOG}.tmp"

    # Write old records (no iEOR) - STRIP the index field (field 1)
    awk -v D_ROW="$D_ROW" -v D_FLD="$D_FLD" '
    BEGIN { RS = D_ROW; ORS = D_ROW }
    {
        if (length($0) == 0) next
        split($0, fields, D_FLD)
        # Skip iEOR, print only fields 2 and 3 (k=v and description)
        if (fields[2] !~ /^iEOR=/) {
            if (length(fields) >= 3)
                print fields[2] D_FLD fields[3]
            else if (length(fields) >= 2)
                print fields[2]
        }
    }' < "$iLOG" > "$tmp_file"

    # Append new records
    printf "%s" "$str" >> "$tmp_file"

    # Get the two-field temp file content
    local xcat=$(cat "$tmp_file")
    local reindex=""
    local cnt=1
    local ix=""

    # Reindex all records
    for ix in $(echo "$xcat" | awk -v D_ROW="$D_ROW" '{gsub(/'"$D_ROW"'/, "\n"); print}'); do
        [ -z "$ix" ] && continue
        reindex="${reindex}${cnt}${D_FLD}${ix}${D_ROW}"
        cnt=$((cnt + 1))
    done

    # iEOR gets the PROVIDED SERIAL as its value (the immutable fingerprint)
    reindex="${reindex}${cnt}${D_FLD}iEOR=${serial}${D_FLD}End${D_TXT}Of${D_TXT}Records${D_ROW}"

    # Write to tmp_file and atomically move to iLOG
    echo "$reindex" > "$tmp_file"
    sync "$tmp_file" 2>/dev/null || true
    mv -f "$tmp_file" "$iLOG"
}

# ----------------------------------------------------------------------------
# runtime - Where functions are a form for functioning
# ----------------------------------------------------------------------------
runtime() {
  ini_bootstrap
  # DONE: barebone_strap "master"
  # DONE: keylog_desc
  # DONE: read_bootstrap needs a revision for eval
  # DONE: write_bootstrap is an append of ini
  vali_date
  echo ""
  desc=$(keylog_desc "AHRtID")
  echo "AHRtID reserved for $desc"
  echo ""
  # ...

  # These records are added for experimental reasons and are meant for
  # training rather than a final implementation.
  # Demonstrates locking a bootstrap by using AHRtID form.

  local patt="master"
  local DIR_BKP="/path/to/backup"
  local FLE_SRC="/path/to/file.source.txt"
  local add_MEM=$(printf "%s" \
  "one_stp=$(ahr_stamp)${D_TME}${patt}${D_FLD}one new stamp${D_ROW}" \
  "DIR_BKP=${DIR_BKP}${D_FLD}backup dir${D_ROW}" \
  "FLE_SRC=${FLE_SRC}${D_FLD}source file${D_ROW}")
  write_bootstrap "$add_MEM"
  echo ""
  vali_date
  echo ""
}

runtime
