#!/bin/sh
FBINK="/mnt/us/koreader/fbink"
[ ! -f "$FBINK" ] && FBINK="/usr/bin/fbink"

# Clear the line
$FBINK -c

COUNT="1"
while IFS= read -r line; do
    echo "In Loop N:$COUNT L:$line"
    $FBINK -y "$COUNT" -pmqb "$line"
    COUNT=$((COUNT + 1))
done < "$1"

COUNT=$(($2 - 1))
if [ "$#" -ge 3 ]; then
    $FBINK -y "$COUNT" -pmhqb " "
    COUNT=$((COUNT + 1))
    $FBINK -y "$COUNT" -pmhqb "$3"
    COUNT=$((COUNT + 1))
    if [ "$#" -ge 4 ]; then
        $FBINK -y "$COUNT" -pmhqb "$4"
        COUNT=$((COUNT + 1))
    fi
    if [ "$#" -ge 5 ]; then
        $FBINK -y "$COUNT" -pmhqb "$5"
        COUNT=$((COUNT + 1))
    fi
    if [ "$#" -ge 6 ]; then
        $FBINK -y "$COUNT" -pmhqb "$6"
        COUNT=$((COUNT + 1))
    fi
    $FBINK -y "$COUNT" -pmhqb " "
fi

$FBINK -qs