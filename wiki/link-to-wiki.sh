#!/bin/bash

XSEL=$(xclip -o)

if [ "$(echo $XSEL | grep juneday | wc -l)" != "0" ]
then
    LINK=$(echo $XSEL | tr '/' '\n' | tail -1 )
    TITLE=$(echo $XSEL | tr '/' '\n' | tr '#' '\n' | tail -1 | tr '_' ' ')
    echo "[[$LINK|$TITLE]]" 
    echo "[[$LINK|$TITLE]]" | xclip -i -selection clipboard
    exit 0
fi

if [ "$(echo $XSEL | grep docs.google | wc -l)" != "0" ]
then
    LINK=$(echo $XSEL | sed 's/edit#slide=id.[a-z]//g')
    echo "$LINK/export/pdf" | xclip -i -selection clipboard
    exit 0
fi
