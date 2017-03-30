#!/bin/bash

count_expr()
{
    local EXPR="$1"
    local FILE_LIST="$2"
    local EXCLUDE_LIST="$3"

    if [ "$EXCLUDE_LIST" = "" ]
    then
        EXCLUDE_LIST="lskdfjlsdjflsdjflkjsdflksdjflksdjflkdjflskjdf"
    fi
    
    printf "%-20s " "$EXPR:"
    COUNT=$(echo "$FILE_LIST" | egrep -v "$EXCLUDE_LIST" | while read file
    do
#        echo "test: $file \"$EXPR\" [$EXCLUDE_LIST]"
        egrep -e "$EXPR" "$file" 
 #       echo "-------------"
               done | wc -l)
    printf "%4s\n" "$COUNT"
}


file_types_stat()
{
    SUFFIX=""
    for option in $*
    do
        if [ "$SUFFIX" != "" ]
        then
            SUFFIX="$SUFFIX -o "
        fi
        SUFFIX="$SUFFIX -name \"*.$option\""
        shift
    done
    
    eval find $DIR -type f $SUFFIX
}

count_keyword() {
    KEYWORD="$1"
    count_expr "$KEYWORD" "$FILES" "$EXCLUDE_DIR"
}

#file_types_stat java
FILES=$(file_types_stat java)
EXCLUDE_DIR="test/"
#count_expr static "$FILES" "$EXCLUDE_DIR"

#for word in static 'if \(' implements interface extends 
for word in 'if[ ]*\(' '->' static implements interface extends 
do
    count_keyword "$word"
done

exit 0


	@echo -n "Counting if or else: "
	@egrep -r "if |else " se | egrep -v "[ \t]*\*" | grep -v Test | wc -l
	@echo -n "Counting static (excl imports): "
	@egrep -r "static" se | egrep -v "[ \t]*\*" | grep -v Test | grep -v import | wc -l
	@echo -n "Counting interface: "
	@egrep -r "interface" se | egrep -v "[ \t]*\*" | grep -v Test | wc -l
	@echo -n "Counting implements: "
	@egrep -r "implements" se | egrep -v "[ \t]*\*" | grep -v Test | wc -l
	@echo -n "Counting lambda: "
	@egrep -r "\->" se | egrep -v "[ \t]*\*" | grep -v Test | wc -l
	@echo -n "Counting inheritance: "
	@egrep -r "extends" se | egrep -v "[ \t]*\*" | grep -v Test | wc -l
	@echo -n "Counting static imports: "
	@egrep -r "static" se | egrep -v "[ \t]*\*" | grep -v Test | grep import | wc -l
