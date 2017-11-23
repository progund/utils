#!/bin/bash

DEST_DIR_BASE=/var/www/html/systembolaget
DATE=$(date '+%Y%m%d')
DEST_DIR=${DEST_DIR_BASE}/${DATE}/

URL_BASE=https://www.systembolaget.se/api/assortment

PRODS_NAME=products.xml
PRODS=${URL_BASE}/products/xml

STORES_NAME=stores.xml
STORES=${URL_BASE}/assortment/stores/xml

STOCK_NAME=stock.xml
STOCK=${URL_BASE}/assortment/stock/xml

get_xml()
{
    FILE=$1
    URL=$2

    curl -s --output "$FILE" $URL
}

#
#
# set up dir
#
#
mkdir -p ${DEST_DIR} && cd   ${DEST_DIR} 
if [ $? -ne 0 ]
then
    echo "Could not create or enter: ${DEST_DIR}"
    exit 1
fi

get_xml $PRODS_NAME $PRODS
get_xml $STORES_NAME $STORES
get_xml $STOCK_NAME $STOCK
