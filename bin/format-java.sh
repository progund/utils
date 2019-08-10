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
    java -jar ${JAR_FILE}  -i  $*
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

usage() {
    echo "format-java.sh OPTIONS [dir|file]"
    echo ""
    echo "OPTIONS"
    echo "  --help|-h   prints this help message"
    echo "  --force|-f  ask no questions"
    echo ""
    echo "If no dir or file specified: recursively find and format files in ."
    echo "If dir specified: recursively find and format files in dir"
    echo "If file specified: format file"
    echo ""
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
    usage
    exit 0
fi
if [ "$1" = "--force" ] || [ "$1" = "-f" ] 
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
