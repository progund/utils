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

check_expr_in_file()
{
    local expr="$1"
    local file="$2"
    local excl_expr="$3"

    if [ "$excl_expr" != "" ]
    then
        grep "$expr" "$file" | grep -v "$excl_expr"
    else
        grep "$expr" "$file"
    fi
}

check_numeric_class_name() {
    check_expr_in_file 'class[ ]*[a-zA-Z]*' | egrep  '[0-9]'
}

check_bad_class_name() {
    local FILE_LIST="$1"
    local EXCLUDE_LIST="$2"

    if [ "$EXCLUDE_LIST" = "" ]
    then
        EXCLUDE_LIST="lskdfjlsdjflsdjflkjsdflksdjflksdjflkdjflskjdf"
    fi


    #
    # exprs
    # 
    for expr in  'class[ ]*[a-z][a-zA-Z0-9]*[ ]*{'
    do
        echo -n "Check expr $expr:   "
        echo "$FILE_LIST" | egrep -v "$EXCLUDE_LIST" | while read file
        do
            check_expr_in_file "'class[ ]*[a-z][a-zA-Z0-9]*[ ]*{'" $file 
        done | wc -l
    done

    #
    # expr with an additional expr
    # 
    echo -n "Check classes with 0-9:   "
    echo "$FILE_LIST" | egrep -v "$EXCLUDE_LIST" | while read file
    do
        check_expr_in_file 'class[ ]*[a-zA-Z]*' $file  '[0-9]'
    done  | wc -l

}


#file_types_stat java
FILES=$(file_types_stat java)
EXCLUDE_DIR="test/"
#count_expr static "$FILES" "$EXCLUDE_DIR"

check_bad_class_name "$FILES"  "$EXCLUDE_DIR"

#exit 0
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
