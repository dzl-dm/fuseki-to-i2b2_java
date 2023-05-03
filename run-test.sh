#!/bin/bash
## Run through array of tests
## Load: ttl -> fuseki
## Run: translator
## Test: SQL output of translator

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

# test_names=(C-10_1parent-2notations-2children-2notations)
# test_names=($(ls -1 src/test/resources/))
## Safest to use globing instead of ls
shopt -s nullglob
cd src/test/resources/
test_names=(*/)
cd -
shopt -u nullglob
echo >&2 "$(date +"$df") DEBUG: Test names: ${test_names[@]}"

echo >&2 "$(date +"$df") INFO: Installing and testing metadata translation tool"

# mvn integration-test
mvn install

## Ensure output dir is created (defined in properties)
mkdir -p /tmp/metadata/i2b2-sql/

FAIL_COUNT=0
for tname in "${test_names[@]}"; do
    # java -jar target/fuseki-to-i2b2-1.0-SNAPSHOT.jar -X config/test.properties true Test-multi-notation
    echo >&2 "$(date +"$df") INFO: Running test '${tname}'"
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter config/test.properties true ${tname}
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/"
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/" --dldate "1970-01-01 00:00:00.1"
    java -Dlog4j.configurationFile=config/log4j2.xml -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/"
    # java -Dlog4j.configurationFile=config/log4j2-debug.xml -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/"
    if [[ ${UPDATE_MODE} == 1 ]] ; then
        echo >&2 "$(date +"$df") INFO: Updating sql files..."
        cp /tmp/metadata/i2b2-sql/data.sql src/test/resources/${tname}/sql/data.sql
        cp /tmp/metadata/i2b2-sql/meta.sql src/test/resources/${tname}/sql/meta.sql
    else
        diff --color src/test/resources/${tname}/sql/data.sql /tmp/metadata/i2b2-sql/data.sql
        [[ $? == 0 ]] || FAIL_COUNT=$((FAIL_COUNT+1))
        diff --color src/test/resources/${tname}/sql/meta.sql /tmp/metadata/i2b2-sql/meta.sql
        [[ $? == 0 ]] || FAIL_COUNT=$((FAIL_COUNT+1))
    fi
    ## DEBUG
    # sleep 30
done

## Diff with provided files
    ## Diff each csv file under the test name's directory
# diff src/test/resources/Test-multi-notation/sql/data.sql /tmp/cometar/i2b2-sql/data.sql
# diff src/test/resources/Test-multi-notation/sql/meta.sql /tmp/cometar/i2b2-sql/meta.sql
echo >&2 "$(date +"$df") INFO: All tests complete with '${FAIL_COUNT}' failures..."
