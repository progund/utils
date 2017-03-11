#!/bin/bash

INTRO=jd-intro.webm
OUTRO=jd-intro.webm

jd-webm() {
    mkvmerge -o jd- jd-intro.webm + $FILE + jd-outro.webm ;
}
