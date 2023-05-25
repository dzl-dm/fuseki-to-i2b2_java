#!/bin/bash
## Run through array of tests
## Load: CSV -> i2b2
## Test: xml query/response of i2b2 queries

## Please ensure i2b2-core is running with on normal ports with db exposed and metadata ontology already loaded
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

## DB passwords - should be default "demouser"? for testing
I2B2METAPW=demouser
I2B2DEMOPW=demouser

if [[ -z "${test_names}" ]] ; then
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: test_names not passed"
    fi
    ## Space separated list of tests to run
    # test_names=(P-3_multi-notation-child-and-modifier-with-child)
    ## Safest to use globing instead of ls
    shopt -s nullglob
    cd src/test/resources/query/
    test_names=(*/)
    cd -
    shopt -u nullglob
fi
if [[ DEBUG_MODE -ne 0 ]]; then
    echo "$(date +"$df") DEBUG: Test names: ${test_names[@]}"
fi

## Ensure output dir is created (defined in properties)
mkdir -p /tmp/metadata/i2b2-query/

FAIL_TESTS=()
for tname in "${test_names[@]}"; do
    echo "*--------VvV--------*"
    echo "$(date +"$df") INFO: Running test '${tname}'"
    FAIL_FILES=()
    ## TODO: Clean database (pushing SQL only clears from the same source_cd)
    
    ## Load ontology by referencing the applicable ontology test data
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Loading ontology metadata..."
    fi
    if [[ ! -f src/test/resources/query/${tname}/load-ont.sh && ! -f src/test/resources/query/${tname}/load-ont_1.sh ]]; then
        echo "$(date +"$df") WARN: Expected at least 'load-ont.sh' or 'load-ont_1.sh' to exist!"
        FAIL_FILES+=("ont*")
    fi
    if [[ -f src/test/resources/query/${tname}/load-ont.sh ]]; then
        ## This should give us an updated "oname", to load
        source ./src/test/resources/query/${tname}/load-ont.sh
        if [[ DEBUG_MODE -ne 0 ]]; then
            echo "$(date +"$df") DEBUG: Loading test default metadata..."
            ./load-ont.sh -t ${oname} -d
        else
            ./load-ont.sh -t ${oname}
        fi
    fi

    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Clearing existing demo data..."
    fi
    PGPASSWORD=$I2B2METAPW /usr/bin/psql -h localhost -U i2b2demodata -d i2b2 -c "DELETE FROM i2b2demodata.patient_dimension; DELETE FROM i2b2demodata.visit_dimension; DELETE FROM i2b2demodata.observation_fact;"
	if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed cleaning demodata, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with cleaning/loading data, then try again."
        exit 1
	fi
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Loading demo data..."
    fi
    cat src/test/resources/query/${tname}/csv/observation_facts.csv | PGPASSWORD=$I2B2METAPW /usr/bin/psql -h localhost -U i2b2demodata -d i2b2 -c "\COPY i2b2demodata.observation_fact FROM STDIN DELIMITER ',' CSV HEADER;"
    if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed loading demodata, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
        exit 1
    fi
    cat src/test/resources/query/${tname}/csv/patient_dimension.csv | PGPASSWORD=$I2B2METAPW /usr/bin/psql -h localhost -U i2b2demodata -d i2b2 -c "\COPY i2b2demodata.patient_dimension FROM STDIN DELIMITER ',' CSV HEADER;"
    if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed loading demodata, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
        exit 1
    fi
    cat src/test/resources/query/${tname}/csv/visit_dimension.csv | PGPASSWORD=$I2B2METAPW /usr/bin/psql -h localhost -U i2b2demodata -d i2b2 -c "\COPY i2b2demodata.visit_dimension FROM STDIN DELIMITER ',' CSV HEADER;"
    if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed loading demodata, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
        exit 1
    fi

    echo "$(date +"$df") INFO: Querying i2b2 data..."
    ## Run multiple query/response tests?
    ## Glob for all xml queries
    shopt -s nullglob
    cd src/test/resources/query/${tname}/xml/
    query_names=(query*.xml)
    cd -
    shopt -u nullglob
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: Query names: ${query_names[@]}"
    fi
    for qname in "${query_names[@]}"; do
        ## Check our ont-load files...
        olname_part1="${qname/query/load-ont}"
        olname="${oname_part1/.xml/.sh}"
        if [[ -f src/test/resources/query/${tname}/${olname} ]]; then
            ## This should give us an updated "oname", to load
            source ./src/test/resources/query/${tname}/${olname}
            if [[ DEBUG_MODE -ne 0 ]]; then
                echo "$(date +"$df") DEBUG: Loading query specific metadata '${oname}' specified in '${olname}' for this test..."
                ./load-ont.sh -t ${oname} -d
            else
                ./load-ont.sh -t ${oname}
            fi
        fi

        ## Convert query_#.xml to response_#.xml
        rname="${qname/query/response}"
        if [[ DEBUG_MODE -ne 0 ]]; then
            echo "$(date +"$df") DEBUG: Running query '${qname}', expecting response '${rname}'..."
        fi

        curl -X POST -d @src/test/resources/query/${tname}/xml/${qname} http://localhost/webclient/index.php > /tmp/metadata/i2b2-query/response_raw.xml
        ## Extract parts of the response for comparison
        xmlstarlet sel -t -c "/ns5:response/response_header" -n -c "/ns5:response/message_body/ns4:response/query_result_instance/query_result_type" -n -c "/ns5:response/message_body/ns4:response/query_result_instance/set_size" -n /tmp/metadata/i2b2-query/response_raw.xml > /tmp/metadata/i2b2-query/response.xml

        if [[ ${UPDATE_MODE} == 1 ]] ; then
            echo >&2 "$(date +"$df") INFO: Updating xml response file."
            cp /tmp/metadata/i2b2-query/response.xml src/test/resources/query/${tname}/xml/${rname}
        else
            if [[ DEBUG_MODE -ne 0 ]]; then
                echo "$(date +"$df") DEBUG: Comparing actual response with expected..."
            fi
            diff src/test/resources/query/${tname}/xml/${rname} /tmp/metadata/i2b2-query/response.xml
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

done

echo >&2 "$(date +"$df") INFO: All tests complete with '${#FAIL_TESTS[@]}' failures..."
for tfail in "${FAIL_TESTS[@]}"; do
    echo "${tfail}"
done
if [[ ${UPDATE_MODE} == 1 ]] ; then
    echo >&2 "$(date +"$df") INFO: Running in UPDATE MODE, reference files for expected output were updated with actual output..."
fi
echo -e "*--------^--------*\n"
