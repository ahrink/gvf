#!/bin/sh
# semiotics_for.sh RE: filter in, filter out w/semiotics
aT="Ⓣ"
aA="Ⓐ"

MY_VAR=$(printf "%s" \
"This is the first line.$aA" \
"This is the second line.$aA" \
"And this is the last line.$aA")

echo "$MY_VAR"
echo ""

# Replace spaces with the Unicode character stored in aT
MY_VAR=$(echo "$MY_VAR" | awk -v aT="$aT" '{gsub(/ /, aT); print}')
echo "$MY_VAR"

# Split the lines using aA and process each one
for line in $(echo "$MY_VAR" | awk -v aA="$aA" '{gsub(/'"$aA"'/, "\n"); print}'); do
    # Restore spaces from the Unicode character stored in aT
    line=$(echo "$line" | awk -v aT="$aT" '{gsub(/'"$aT"'/, " "); print}')
    echo "-- $line"
done
