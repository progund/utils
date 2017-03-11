#!/bin/bash

mkdir -p /tmp/junedaywiki
declare -A PAGE_COUNTS

DOWNLOAD=true
if [ "$1" = "-nd" ]
then
    DOWNLOAD=false
    shift
fi

debug()
{
    if [ $DEBUG ]
    then
        echo $*
    fi
}

BOOK_CONF=$1
if [ ! -f $BOOK_CONF ] || [ "$BOOK_CONF" = "" ]
then
    if [ ! -f $BOOK_CONF ]
    then
        echo "missing: $BOOK_CONF"
        ls -al
        exit 1
    fi
    echo "Missing or faulty book configuration file ($BOOK_CONF)"
    exit 1
fi
. $BOOK_CONF


get_html()
{
#    echo get html
    if [ "$DOWNLOAD" = "true" ] || [ ! -f  ${page}.html ]
    then
        rm -f ${page}.html
        curl  "http://rameau.sandklef.com/mediawiki/index.php/${page}" -o ${page}.html
    fi
#    ls -al ${page}.html
}

get_pdf()
{
    PAGES="$1"
    for page in $PAGES
    do
        if [ "$DOWNLOAD" = "true" ] || [ ! -f  ${page}.pdf ]
        then
            rm -f ${page}.pdf
            curl -s "http://rameau.sandklef.com/mediawiki/index.php?title=${page}&action=pdfbook&format=single" -o ${page}.pdf 
        fi
        PDFS="$PDFS ${page}.pdf"
    done
}

check_pres_pdfs()
{
    PRES_PAGE_COUNT=0
#    echo "Presentation pdfs: $PRES_PDFS" 
    UNIQ_PDFS=$(echo "$PRES_PDFS" | uniq | tr '[\n]' '[ ]')

#    echo "pres pdfs: $UNIQ_PDFS  ($(echo $UNIQ_PDFS | wc -l))"; 
    
    for pdf_long in $UNIQ_PDFS
    do
        
        pdf=$(basename "$pdf_long")
        echo -n "$pdf: "
        PRES_PAGES=$(pdfinfo $pdf 2>/dev/null | grep Pages | awk ' { print $2}')
        PRES_PAGE_COUNT=$(( PRES_PAGE_COUNT + PRES_PAGES ))
        echo "$PRES_PAGES"
    done
    TOTAL_PRES_PAGE_COUNT=$(( TOTAL_PRES_PAGE_COUNT + PRES_PAGE_COUNT ))
    echo "Total presentation pdf: $PRES_PAGE_COUNT"
}

check_pdfs()
{
    
    PAGE_COUNT=0
    for pdf in $PDFS
    do
        echo -n "$pdf: "
        PAGES=$(pdfinfo $pdf | grep Pages | awk ' { print $2}')
        echo $PAGES
        PAGE_COUNT=$(( PAGE_COUNT + PAGES ))
    done
    TOTAL_PAGE_COUNT=$(( TOTAL_PAGE_COUNT + PAGE_COUNT ))
    echo "Total: $PAGE_COUNT"
}

get_presentations()
{
    HTML_PAGE="$1".html
    LOCAL_PRES_PDFS=$(grep "href=" "$HTML_PAGE" | grep pdf | sed 's, ,\n,g' | grep pdf | grep mediawiki | sed -e 's,href=,,g' -e 's,",,g')
    for page in $LOCAL_PRES_PDFS
    do
        short_page=$(basename ${page})
        if [ "$DOWNLOAD" = "true" ] || [ ! -f  ${short_page} ]
        then
            rm -f ${short_page}
            curl  "http://rameau.sandklef.com/$page" -o ${short_page}
        fi
        
#        echo  "pdf: $short_page"
        
        echo -n "$short_page: "
        PAGES=$(pdfinfo $short_page 2>/dev/null | grep Pages | awk ' { print $2}')
        echo $PAGES
    done
    PRES_PDFS="$PRES_PDFS $LOCAL_PRES_PDFS"
}


check_book()
{
    book=$1
    
    PAGES=${book}_PAGES
    TITLE_VAR=${book}_TITLE
    TITLE=${!TITLE_VAR}
    TITLE_NO_BLANKS=$(echo $TITLE | sed 's, ,_,g')

#    echo "PAGES: $PAGES / ${!PAGES}"
    
    debug " * $TITLE"
    
    printf "\n --== %s ==-- \n" "$TITLE"
    PDFS=""
    for page in ${!PAGES}
    do
        debug " ** $page"
        get_pdf "$page"
        get_html "$page"
        get_presentations "$page"
#        echo "PRES_PDF: $PRES_PDFS"
    done

    check_pdfs

  #  echo "Insert .... $book, ${PAGE_COUNT}"
    PAGE_COUNTS["${book}"]="${PAGE_COUNT}"
#    echo "Inserted .... $book:" ${PAGE_COUNTS["$book"]}
 #   echo "Inserted .... JAVA:" ${PAGE_COUNTS["JAVA"]}

    echo Skipping merge pdf
#    rm -f  "${TITLE_NO_BLANKS}.pdf"
 #   pdfmerge $PDFS "${TITLE_NO_BLANKS}.pdf"
}


main()
{
    debug "BOOKS: $BOOKS"
    PRES_PDFS=""

    for book in $BOOKS
    do
        debug "Handle book: $book"
        check_book $book
    done

    check_pres_pdfs

    printf "\n --== %s ==-- \n" "Books"
    for book in $BOOKS
    do
        TITLE_VAR=${book}_TITLE
        TITLE=${!TITLE_VAR}
        echo -n "${TITLE}: "
        echo ${PAGE_COUNTS[$book]}
    done
    echo "Total: $TOTAL_PAGE_COUNT"
    printf "\n --== %s ==-- \n" "Presentation pdfs"
    echo "$TOTAL_PRES_PAGE_COUNT"

}
        
cd  /tmp/junedaywiki
main



