#!/bin/sh

rSke=$(cd "$(dirname "$0")" && pwd)
nCFG="${rSke}/cfg/node.ahr"
defPath="/home/<USER>/xFLE/BKP" # relace user and path with your external bkup
# curl -O https://nodejs.org/dist/latest-v24.x/node-v24.14.0-linux-x64.tar.gz
# curl -O https://github.com/npm/cli/archive/refs/tags/v11.11.1.tar.gz
# rename v11.11.1.tar.gz to npm-v11.11.1.tar.gz

# refresh bashrc
ske_devs() {
    echo "Syncing Skeleton Devs to ~/.bashrc..."
    M_START="# [SKE-START] - ${rSke}"
    M_END="# [SKE-END]"

    # Backup original bashrc if not already done
    if [ ! -f "$HOME/.bashrc.bak" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
    fi

    # Remove old SKE block from backup
    awk -v start="$M_START" -v end="$M_END" '
        BEGIN { inBlock = 0 }
        $0 == start { inBlock = 1; next }
        $0 == end { inBlock = 0; next }
        !inBlock { print }
    ' "$HOME/.bashrc.bak" > "$HOME/.bashrc.tmp"

    mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"

    # Append new SKE block with the message
    {
        echo "$M_START"
        echo "$1"  # This is the actual config block
        echo "$M_END"
    } >> "$HOME/.bashrc"

    # Source the config block DIRECTLY (don't rely on .bashrc)
    eval "$1"

    # NOW verify (after PATH is updated in current shell)
    echo ""
    if command -v node > /dev/null 2>&1; then
        echo "✓ Node: $(node -v) at $(command -v node)"
    else
        echo "✗ Node not found in PATH"
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "✓ NPM: $(npm -v) at $(command -v npm)"
    else
        echo "✗ NPM not found in PATH"
    fi
}

extract_ver() {
    local vfle="$1"
    # Extract version from filenames like:
    # node-v24.14.0-linux-x64.tar.gz -> v24.14.0
    # npm-v11.11.1.tar.gz -> v11.11.1
    echo "$vfle" | awk -F'[-.]' '{
        for (i=1; i<=NF; i++) {
            if ($i ~ /^v?[0-9]+$/) {
                # Found start of version
                ver = $i
                for (j=i+1; j<=NF && $j ~ /^[0-9]+$/; j++) {
                    ver = ver "." $j
                }
                print ver
                exit
            }
        }
    }'
}

DO_cfg() {
    echo "Config ........................."
    cat "$nCFG"
    echo ""

    # Read versions from config file
    local vNOD=""
    local vNPM=""

    if [ -f "$nCFG" ]; then
        vNOD=$(grep "^vNOD=" "$nCFG" | cut -d'"' -f2)
        vNPM=$(grep "^vNPM=" "$nCFG" | cut -d'"' -f2)
    fi

    if [ -z "$vNOD" ] || [ -z "$vNPM" ]; then
        echo "✗ Error: Missing version info in $nCFG"
        return 1
    fi

    local NODE_BIN="${rSke}/njs/${vNOD}/bin"
    local NPM_BIN="${rSke}/npm/${vNPM}/bin"
    local NODE_MODULES="${rSke}/npm/${vNPM}/node_modules"

    echo "Configuring paths:"
    echo "  NODE_BIN: $NODE_BIN"
    echo "  NPM_BIN: $NPM_BIN"
    echo "  NODE_MODULES: $NODE_MODULES"
    echo ""

    # Build bashrc block with correct paths
    local msg=$(printf "%s\n" \
        "# SKE Environment Configuration (Node v${vNOD}, NPM v${vNPM})" \
        "export rSke=\"${rSke}\"" \
        "export vNOD=\"${vNOD}\"" \
        "export vNPM=\"${vNPM}\"" \
        "export NODE_HOME=\"${rSke}/njs/${vNOD}\"" \
        "export NPM_HOME=\"${rSke}/npm/${vNPM}\"" \
        "export NODE_PATH=\"${NODE_MODULES}\${NODE_PATH:+:\$NODE_PATH}\"" \
        "export PATH=\"${NODE_BIN}:${NPM_BIN}:\$PATH\"" \
        "export PROJECT_ROOT=\"${rSke}/PRJ\"" \
        "[ -f \"${rSke}/cfg/ahr/addendum.sh\" ] && . \"${rSke}/cfg/ahr/addendum.sh\"" \
        "alias node-env='echo \"Node: \$(node -v) at \$(which node)\" && echo \"npm: \$(npm -v)\"'" \
        "alias npm-globals='ls -la ${NPM_BIN}'")

    ske_devs "$msg"
}

# 3. NPM extraction
DO_npm() {
    local tNPM="$1"
    local tVer=$(extract_ver "$tNPM")
    local tDir="${rSke}/npm/${tVer}"

    if [ ! -d "$tDir" ]; then
        echo "Installing NPM ${tVer} to ${tDir} ..."
        mkdir -p "$tDir"
        if [ -f "${rSke}/bkp/$tNPM" ]; then
            cp "${rSke}/bkp/$tNPM" "$tDir/"
            (cd "$tDir" && tar -xf "$tNPM" --strip-components=1 && rm "$tNPM")
        else
            echo "✗ Tarball not found: ${rSke}/bkp/$tNPM"
            return 0
        fi
        echo "vNPM=\"$tVer\"" >> "$nCFG"
    else
        echo "✓ NPM ${tVer} already installed"
    fi
}

# 2. Node extraction
DO_node() {
    local unTar="$1"
    # local unVer=$(echo "$unTar" | sed -E 's/node-([v0-9.]+)-.*/\1/')
    local unVer=$(extract_ver "$unTar")
    local unDir="${rSke}/njs/${unVer}"

    if [ ! -d "$unDir" ]; then
        echo "Installing NodeJS ${unVer} to ${unDir} ..."
        mkdir -p "$unDir" && cd "$unDir"
        if [ -f "${rSke}/bkp/$unTar" ]; then
            cp "${rSke}/bkp/$unTar" "$unDir/"
            (tar -xf "$unTar" --strip-components=1 && rm "$unTar")
        else
            echo "✗ Tarball not found: ${rSke}/bkp/$unTar"
            return 0
        fi
        echo "vNOD=\"$unVer\"" >> "$nCFG"
    else
        echo "✓ NodeJS ${unVer} already installed"
    fi
}

# 1. Structural Logic
cre_ske() {
    local dr=""
    for dr in bkp cfg/ahr logs njs PRJ PRJ/AHRexe; do
        [ ! -d "${rSke}/$dr" ] && mkdir -p "${rSke}/$dr"
    done

    # populate ${rSke}/bkp if defPath exists
    if [ -d "$defPath" ]; then
        cp "${defPath}"/* "${rSke}"/bkp/ 2>/dev/null || true
    fi

    # copy cnf from bkp if they exist
    [ -f "${rSke}/bkp/addendum.cnf" ] && \
    cp "${rSke}/bkp/addendum.cnf" "${rSke}/cfg/ahr/addendum.sh"
    chmod +x "${rSke}/cfg/ahr/addendum.sh"
    [ ! -f "$nCFG" ] && touch "$nCFG"
}

# Simple reason:
# if node -v and npm -v are empty, run this script.
# So, the runtime() is skipped if -v, BUT:
# Only because .ahr eg [ ! -d "${rSke}/.ahr" ] && runtime
# pending implementation of the verdict()
runtime() {
    cre_ske
    # Install Node from tarball if available
    if ls "${rSke}/bkp/node-"* 1>/dev/null 2>&1; then
        NODE_TAR=$(ls "${rSke}/bkp/" | grep '^node-' | head -n 1)
        [ -n "$NODE_TAR" ] && DO_node "$NODE_TAR"
    fi

    # Install NPM from tarball if available
    if ls "${rSke}/bkp/npm-"* 1>/dev/null 2>&1; then
        NPM_TAR=$(ls "${rSke}/bkp/" | grep '^npm-' | head -n 1)
        [ -n "$NPM_TAR" ] && DO_npm "$NPM_TAR"
    fi

    DO_cfg
    # DO_verdict
    echo ""
}

[ ! -d "${rSke}/.ahr" ] && runtime
# (cd "${rSke}" && tree -d -L 5)
