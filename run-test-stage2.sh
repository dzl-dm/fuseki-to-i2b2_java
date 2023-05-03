#!/bin/bash
## Run through array of tests
## Load: SQL -> i2b2
## Test: xml query/response

## Please ensure i2b2-core is running with on normal ports with db exposed.
## Please start with fresh database volume and "i2b2_data_level=demo_empty_project"

df="[%Y-%m-%d %H:%M:%S]"

while getopts 'u' OPTION; do
    case "$OPTION" in
        u)
            echo "$(date +"$df") WARN: Running in UPDATE mode! Expected test results will be updated based on the output of these test runs"
            UPDATE_MODE=1
        ;;
        ?)
            echo "script usage: $(basename \$0) [-u]" >&2
            exit 1
        ;;
    esac
done

## DB passwords - should be default "demouser"? for testing
I2B2METAPW=demouser
I2B2DEMOPW=demouser

# test_names=(C-10_1parent-2notations-2children-2notations)
# test_names=(A-1_0-toplevel-nodes)
test_names=(A-2_1-toplevel-node)
## Safest to use globing instead of ls
shopt -s nullglob
cd src/test/resources/
# test_names=(*/)
cd -
shopt -u nullglob
echo "$(date +"$df") DEBUG: Test names: ${test_names[@]}"

## Ensure output dir is created (defined in properties)
mkdir -p /tmp/metadata/i2b2-sql/

FAIL_COUNT=0
for tname in "${test_names[@]}"; do
    echo "$(date +"$df") INFO: Running test '${tname}'"
    ## TODO: Clean database
    
    if [[ ${UPDATE_MODE} == 1 ]] ; then
        echo >&2 "$(date +"$df") WARN: One off - create structure."
        # mkdir -p src/test/resources/${tname}/{sql,ttl,xml}
        # touch src/test/resources/${tname}/xml/{query,response}.xml
        if [[ ${tname} != "A-1_0-toplevel-nodes" ]] ; then
            echo >&2 "$(date +"$df") WARN: Setting default query."
            cp src/test/resources/A-1_0-toplevel-nodes/xml/query.xml src/test/resources/${tname}/xml/query.xml
        fi
    fi

    ## Run SQL against i2b2 database (must be localhost postgres!) - use appropriate user for demo/meta data
    echo "$(date +"$df") DEBUG: Loading meta data..."
    PGPASSWORD=$I2B2METAPW /usr/bin/psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=localhost --username=i2b2metadata --dbname=i2b2 -f "src/test/resources/${tname}/sql/meta.sql"
	if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed loading meta, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
        exit 1
	fi
    echo "$(date +"$df") DEBUG: Loading demo data..."
    PGPASSWORD=$I2B2DEMOPW /usr/bin/psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=localhost --username=i2b2demodata --dbname=i2b2 -f "src/test/resources/${tname}/sql/data.sql"
	if [ $? -ne 0 ]; then
        echo "$(date +"$df") ERROR: PostgreSQL command failed data, see log: log/postgres.log"
        echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
        exit 1
	fi
    ## DEBUG
    # sleep 30

    echo "$(date +"$df") DEBUG: Querying i2b2..."
    curl -X POST -d @src/test/resources/${tname}/xml/query.xml http://localhost/webclient/index.php > /tmp/metadata/i2b2-sql/response_raw.xml
    ## Extract "response_header" and "message_body" from response
    xmlstarlet sel -t -c "/ns5:response/response_header" -n -c "/ns5:response/message_body" -n /tmp/metadata/i2b2-sql/response_raw.xml > /tmp/metadata/i2b2-sql/response.xml
    if [[ ${UPDATE_MODE} == 1 ]] ; then
        echo >&2 "$(date +"$df") INFO: Updating xml response file."
        cp /tmp/metadata/i2b2-sql/response.xml src/test/resources/${tname}/xml/response.xml
    else
        echo "$(date +"$df") DEBUG: Comparing actual response with expected..."
        diff src/test/resources/${tname}/xml/response.xml /tmp/metadata/i2b2-sql/response.xml
        [[ $? == 0 ]] || FAIL_COUNT=$((FAIL_COUNT+1))
    fi

done

echo "$(date +"$df") INFO: All tests complete with '${FAIL_COUNT}' failures..."
