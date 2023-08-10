#!/bin/bash
## Run through array of tests
## Load: ttl -> fuseki
## Run: translator
## Test: SQL output of translator

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

if [[ -z "${test_names}" ]] ; then
    if [[ DEBUG_MODE -ne 0 ]]; then
        echo "$(date +"$df") DEBUG: test_names not passed"
    fi
    ## Space separated list of tests to run
    # test_names=(P-3_multi-notation-child-and-modifier-with-child)
    # test_names=($(ls -1 src/test/resources/metadata/))
    ## Safest to use globing instead of ls
    shopt -s nullglob
    cd src/test/resources/metadata/
    test_names=(*/)
    cd -
    shopt -u nullglob
fi
if [[ DEBUG_MODE -ne 0 ]]; then
    echo "$(date +"$df") DEBUG: Test names: ${test_names[@]}"
fi

echo >&2 "$(date +"$df") INFO: Installing and testing metadata translation tool"

# mvn integration-test
mvn clean install

## Ensure output dir is created (defined in properties)
program_output_dir=target/test-output/
mkdir -p "${program_output_dir}"

FAIL_TESTS=()
for tname in "${test_names[@]}"; do
    # java -jar target/fuseki-to-i2b2-1.0-SNAPSHOT.jar -X config/test.properties true Test-multi-notation
    echo >&2 "$(date +"$df") INFO: Running test '${tname}'"
    FAIL_FILES=()
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter config/test.properties true ${tname}
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/metadata/${tname}/ttl/"
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/metadata/${tname}/ttl/" --dldate "1970-01-01 00:00:00.1"
    java -Dlog4j.configurationFile=src/test/resources/config/log4j2.xml -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p src/test/resources/config/test.properties -e -t -i "src/test/resources/metadata/${tname}/ttl/"
    # java -Dlog4j.configurationFile=config/log4j2-debug.xml -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/metadata/${tname}/ttl/"
    if [[ ${UPDATE_MODE} == 1 ]] ; then
        echo >&2 "$(date +"$df") INFO: Updating sql files..."
        cp ${program_output_dir}data.sql src/test/resources/metadata/${tname}/sql/data.sql
        cp ${program_output_dir}meta.sql src/test/resources/metadata/${tname}/sql/meta.sql
    else
        echo >&2 "$(date +"$df") INFO: Comparing 'data.sql' files..."
        diff --color src/test/resources/metadata/${tname}/sql/data.sql ${program_output_dir}data.sql
        [[ $? == 0 ]] || FAIL_FILES+=("data")
        echo >&2 "$(date +"$df") INFO: Comparing 'meta.sql' files..."
        diff --color src/test/resources/metadata/${tname}/sql/meta.sql ${program_output_dir}meta.sql
        [[ $? == 0 ]] || FAIL_FILES+=("meta")
        if [[ DEBUG_MODE -ne 0 ]]; then
            echo >&2 "$(date +"$df") DEBUG: Failed files (${#FAIL_FILES[@]}): ${FAIL_FILES[@]}"
        fi
        if [[ ${#FAIL_FILES[@]} -gt 0 ]] ; then
            FAILED_TEXT="${tname}[${FAIL_FILES[@]}]"
            if [[ DEBUG_MODE -ne 0 ]]; then
                echo >&2 "$(date +"$df") DEBUG: Failed text: ${FAILED_TEXT}"
            fi
            FAIL_TESTS+=("${FAILED_TEXT}")
        fi
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
