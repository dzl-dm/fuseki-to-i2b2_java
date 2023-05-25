#!/bin/bash
## Run through array of tests
## Load: SQL -> i2b2
## Test: xml query/response of i2b2 ontology

## Please ensure i2b2-core is running with on normal ports with db exposed.
## Please start with fresh database volume and "i2b2_data_level=demo_empty_project"

df="[%Y-%m-%d %H:%M:%S]"

function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;  
            [Nn]*) return 1 ;;
        esac
    done
}

while getopts 'ut:d?' OPTION; do
    case "$OPTION" in
        u)
            echo "$(date +"$df") WARN: Running in UPDATE mode! Expected test results will be updated based on the output of these test runs"
            yes_or_no "Are you sure you want to run in update mode?" && UPDATE_MODE=1 || echo "Ok. Running in normal test mode..."
        ;;
        t)
            echo "$(date +"$df") INFO: Running for single test case provided"
            test_names=(${OPTARG})
        ;;
        d)
            echo "$(date +"$df") WARN: Running in DEBUG mode! Extra logging will be printed"
            DEBUG_MODE=1
        ;;
        ?)
            echo "script usage: $(basename $0) [-ut:d]" >&2
            echo "$(basename $0) -u = update mode. Test result will replace expected result" >&2
            echo "$(basename $0) -t test-name = individual test. Run the test provided" >&2
            echo "$(basename $0) -d = debug mode. More detailed logs" >&2
            exit 0
        ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "${test_names}" ]] ; then
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: test_names not passed"
    fi
    ## Space separated list of tests to run
    # test_names=(P-3_multi-notation-child-and-modifier-with-child)
    ## Safest to use globing instead of ls
    shopt -s nullglob
    cd src/test/resources/ontology/
    test_names=(*/)
    cd -
    shopt -u nullglob
fi
if [[ DEBUG_MODE -ne 0 ]]; then
    echo "$(date +"$df") DEBUG: Test names: ${test_names[@]}"
fi

## Ensure output dir is created
mkdir -p /tmp/metadata/i2b2-ont/

FAIL_TESTS=()
for tname in "${test_names[@]}"; do
    echo "*--------VvV--------*"
    echo "$(date +"$df") INFO: Running test '${tname}'"
    FAIL_FILES=()
    ## TODO: Clean database (pushing SQL only clears from the same source_cd)
    
    ## Load ontology to i2b2 database
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Loading ontology for '${tname}'..."
        ./load-ont.sh -t ${tname} -d
    else
        ./load-ont.sh -t ${tname}
    fi

    echo "$(date +"$df") INFO: Querying i2b2..."
    ## Run multiple query/response tests?
    ## Glob for all xml queries
    shopt -s nullglob
    cd src/test/resources/ontology/${tname}/xml/
    query_names=(query*.xml)
    cd -
    shopt -u nullglob
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Query names: ${query_names[@]}"
    fi
    for qname in "${query_names[@]}"; do
        rname="${qname/query/response}"
        if [[ DEBUG_MODE -ne 0 ]]; then
            echo "$(date +"$df") DEBUG: Running query '${qname}', expecting response '${rname}'..."
        fi

        curl -X POST -d @src/test/resources/ontology/${tname}/xml/${qname} http://localhost/webclient/index.php > /tmp/metadata/i2b2-ont/response_raw.xml
        ## Extract "response_header" and "message_body" from response
        xmlstarlet sel -t -c "/ns5:response/response_header" -n -c "/ns5:response/message_body" -n /tmp/metadata/i2b2-ont/response_raw.xml > /tmp/metadata/i2b2-ont/response.xml
        ## WIP: ... and strip attributes (which we don't need and seem to change?!)
        # xmlstarlet sel -t -c "/ns5:response/response_header" -n -c "/ns5:response/message_body" -n /tmp/metadata/i2b2-ont/response_raw.xml | xmlstarlet ed -d '//@xmlns:*' > /tmp/metadata/i2b2-ont/response.xml

        if [[ ${UPDATE_MODE} == 1 ]] ; then
            echo >&2 "$(date +"$df") INFO: Updating xml response file."
            cp /tmp/metadata/i2b2-ont/response.xml src/test/resources/ontology/${tname}/xml/${rname}
        else
            if [[ DEBUG_MODE -ne 0 ]]; then
                echo "$(date +"$df") DEBUG: Comparing actual response with expected..."
            fi
            diff src/test/resources/ontology/${tname}/xml/${rname} /tmp/metadata/i2b2-ont/response.xml
            [[ $? == 0 ]] || FAIL_FILES+=(${qname})
        fi
    done
    if [[ ${#FAIL_FILES[@]} -gt 0 ]] ; then
        FAILED_TEXT="${tname}[${FAIL_FILES[@]}]"
        if [[ DEBUG_MODE -ne 0 ]]; then
            echo >&2 "$(date +"$df") DEBUG: Failed text: ${FAILED_TEXT}"
        fi
        FAIL_TESTS+=("${FAILED_TEXT}")
    fi
    ## DEBUG
    # sleep 30

done

echo >&2 "$(date +"$df") INFO: All tests complete with '${#FAIL_TESTS[@]}' failures..."
for tfail in "${FAIL_TESTS[@]}"; do
    echo "${tfail}"
done
if [[ ${UPDATE_MODE} == 1 ]] ; then
    echo >&2 "$(date +"$df") INFO: Running in UPDATE MODE, reference files for expected output were updated with actual output..."
fi
echo -e "*--------^--------*\n"
