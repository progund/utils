#!/bin/bash

JD_JAR_DIR=~/juneday
mkdir -p ${JD_JAR_DIR}

JAR_FILE=${JD_JAR_DIR}/google-java-format-1.4-all-deps.jar

if [ ! -f ${JAR_FILE} ]
then
    GJAR=google-java-format-1.4-all-deps.jar
    curl -LJO https://github.com/google/google-java-format/releases/download/google-java-format-1.4/$GJAR
    mv $GJAR ${JAR_FILE}
fi

format_java(){
echo    java -jar google-java-format-1.4-all-deps.jar -i  $*
}
    


format_dir(){
    DIR=$1
    FILES=$(find $DIR -name "*.java")

    if [ "$FORCE" != "true" ]
    then
        COUNT=$(echo $FILES | sed 's,\.java,\.java\n,g' | grep -c \.java)
        echo "$COUNT java files found"
        echo $FILES
        echo "Format them all? [y/n]"
        read ANSWER
        if [ "$ANSWER" = "y" ] || [ "$ANSWER" = "Y" ]
        then
            format_java $FILES
        fi
    else
            format_java $FILES
    fi        
}

if [ "$1" = "--force" ] 
then
    FORCE=true
    shift
fi
if [ "$1" != "" ] 
then
    if [ -f "$1" ]
    then
        format_java $1
    else
        format_dir $1
    fi
else
    format_dir .
fi
