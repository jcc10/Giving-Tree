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

COUNT=$2
if [ "$#" -ge 3 ]; then
    $FBINK -y "$COUNT" -pmh "$3"
    COUNT=$((COUNT + 1))
    $FBINK -y "$COUNT" -pmh " "
    COUNT=$((COUNT - 2))
    $FBINK -y "$COUNT" -pmh " "
fi

$FBINK -s