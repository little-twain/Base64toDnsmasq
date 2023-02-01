#!/bin/sh

clean_and_exit(){
    rm -rf $TMP_DIR
    exit $1
}

get_args(){
    DNS_IP=''
    DNS_PORT=''
    IPSET_NAME=''
    EXTRA_DOMAIN_FILE=''
    BASE_URL='https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt'
    IPV4_PATTERN='^((2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)\.){3}(2[0-4][0-9]|25[0-5]|[01]?[0-9][0-9]?)$'
    IPV6_PATTERN='^((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])){3}))|:)))(%.+)?$'

    while [ ${#} -gt 0 ]; do
        case "${1}" in
            -d)
                DNS_IP="$2"
                shift
                ;;
            -p)
                DNS_PORT="$2"
                shift
                ;;
            -s)
                IPSET_NAME="$2"
                shift
                ;;
            -o)
                OUT_FILE="$2"
                shift
                ;;
            -l)
                EXTRA_DOMAIN_FILE="$2"
                shift
                ;;
            -url)
                BASE_URL="$2"
                shift
                ;;
        esac
        shift 1
    done
}

process(){
    # Set Global Var
    TMP_DIR=`mktemp -d /tmp/gfwlist2dnsmasq.XXXXXX`
    BASE64_FILE="$TMP_DIR/base64.txt"
    GFWLIST_FILE="$TMP_DIR/gfwlist.txt"
    DOMAIN_TEMP_FILE="$TMP_DIR/gfwlist2domain.tmp"
    DOMAIN_FILE="$TMP_DIR/gfwlist2domain.txt"
    CONF_TMP_FILE="$TMP_DIR/gfwlist.conf.tmp"
    OUT_TMP_FILE="$TMP_DIR/gfwlist.out.tmp"
    BASE64_DECODE='base64 -d'
    SED_ERES='sed -r'

    # Fetch GfwList and decode it into plain text
    aria2c -s16 -x16 -d $TMP_DIR -o base64.txt $BASE_URL >/dev/null 2>&1
    if [ $? != 0 ]; then
        clean_and_exit 2
    fi
    $BASE64_DECODE $BASE64_FILE > $GFWLIST_FILE

    # Convert
    IGNORE_PATTERN='^\!|\[|^@@|(https?://){0,1}[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
    HEAD_FILTER_PATTERN='s#^(\|\|?)?(https?://)?##g'
    TAIL_FILTER_PATTERN='s#/.*$|%2F.*$##g'
    DOMAIN_PATTERN='([a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+)'
    HANDLE_WILDCARD_PATTERN='s#^(([a-zA-Z0-9]*\*[-a-zA-Z0-9]*)?(\.))?([a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+)(\*[a-zA-Z0-9]*)?#\4#g'

    grep -vE $IGNORE_PATTERN $GFWLIST_FILE | $SED_ERES $HEAD_FILTER_PATTERN | $SED_ERES $TAIL_FILTER_PATTERN | grep -E $DOMAIN_PATTERN | $SED_ERES $HANDLE_WILDCARD_PATTERN > $DOMAIN_TEMP_FILE

    cat $DOMAIN_TEMP_FILE > $DOMAIN_FILE

    if [ ! -z $EXTRA_DOMAIN_FILE ]; then
        cat $EXTRA_DOMAIN_FILE >> $DOMAIN_FILE
    fi

    sort -u $DOMAIN_FILE | $SED_ERES 's#(.+)#server=/\1/'$DNS_IP'\#'$DNS_PORT'\nipset=/\1/'$IPSET_NAME'#g' > $CONF_TMP_FILE

    # Generate output file
    echo '# dnsmasq rules generated by gfwlist' > $OUT_TMP_FILE
    echo "# Last Updated on $(date "+%Y-%m-%d %H:%M:%S")" >> $OUT_TMP_FILE
    echo '# ' >> $OUT_TMP_FILE
    cat $CONF_TMP_FILE >> $OUT_TMP_FILE
    cp $OUT_TMP_FILE $OUT_FILE

    # Clean up
    clean_and_exit 0
}

main() {
    get_args "$@"
    process
}

main "$@"
