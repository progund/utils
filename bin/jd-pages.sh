#!/bin/bash

BASE_DIR=/tmp/jd-books
DATE="$(date '+%Y%m%d')"
BASE_URL="http://wiki.juneday.se/mediawiki/index.php"
JD_BOOKS_CONF="$(dirname $0)/../../utils-private/etc/juneday-books.conf"


if [ ! -d $BASE_DIR ]
then
    mkdir -p $BASE_DIR
fi

get_books()
{
    BOOKS_INDENT="  "
    . ${JD_BOOKS_CONF}
    BOOKS_PAGE_COUNT=0
    for book in $BOOKS
    do
        get_book "$book"
        BOOKS_PAGE_COUNT=$(( BOOKS_PAGE_COUNT + BOOK_COUNT ))
    done
    echo "Total: $BOOKS_PAGE_COUNT"
}

get_book()
{
    BOOK=$1
    BOOK_INDENT="  "
    . ${JD_BOOKS_CONF}
    PAGES=${BOOK}_PAGES

    TITLE_VAR=${BOOK}_TITLE
    TITLE=${!TITLE_VAR}
    echo "  $TITLE"
    BOOK_COUNT=0
    for page in ${!PAGES}
    do
        get_pages "$page"
        BOOK_COUNT=$(( BOOK_COUNT + PAGE_COUNT ))
        echo "  $BOOKS_INDENT$page:  $PAGE_COUNT"
    done
    echo "    Total:  $BOOK_COUNT"
    
}

get_pages()
{
    LOCAL_PAGE_URL=$1
    TMP_PDF="$BASE_DIR/$LOCAL_PAGE_URL.pdf"
    if [ "$FORCED" = "true" ]
    then
        rm -f "$TMP_PDF"
    fi
    if [ ! -f "$TMP_PDF" ]
    then
           htmldoc --quiet --size A4 "$BASE_URL/$LOCAL_PAGE_URL" --outfile "$TMP_PDF" 
    fi
    PAGE_COUNT=$(pdfinfo "$TMP_PDF" 2>&1 | grep Pages | awk '{print $2}')
    PAGE_COUNT=$(( PAGE_COUNT - 3 ))
}

#PAGE_URL=$1
#FIRST_DATE=$2

while [ "$1" != "" ]
do
    case "$1" in
        "--page")
            PAGE_URL="$2"
            ;;
        "--book")
            BOOK="$2"
            ;;
        "--force")
            FORCED="true"
            ;;
        *)
            FIRST_DATE="$1"
            ;;
    esac
    shift
done
    
if [ "$BOOK" != "" ]
then
    echo "Single book"
    get_book $BOOK
elif [ "$PAGE_URL" != "" ]
then
    echo "Single page"
    get_pages $PAGE_URL
else
    echo "All books"
    get_books
fi
