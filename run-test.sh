#!/bin/bash
## Run through array of tests

df="[%Y-%m-%d %H:%M:%S]"

# test_names=(A-1_concept-with-0-notations)
# test_names=($(ls -1 src/test/resources/))
## Safest to use globing instead of ls
shopt -s nullglob
cd src/test/resources/
test_names=(*/)
cd -
shopt -u nullglob
echo >&2 "$(date +"$df") DEBUG: Test names: ${test_names[@]}"

# exit 0


echo >&2 "$(date +"$df") INFO: Installing and testing metadata translation tool"
#
## test name from args
## Clean fuseki
## Load data
    ## Provide "download date" (matching result file)
    ## Load ttl file under the test name's directory
## Run function(s) to extract, process and output data

# mvn integration-test
mvn install

for tname in "${test_names[@]}"; do
    # java -jar target/fuseki-to-i2b2-1.0-SNAPSHOT.jar -X config/test.properties true Test-multi-notation
    echo >&2 "$(date +"$df") INFO: Running test '${tname}'"
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter config/test.properties true ${tname}
    java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/"
    # java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter -p config/test.properties -e -i "src/test/resources/${tname}/ttl/" --dldate "1970-01-01 00:00:00.1"
    diff --color src/test/resources/${tname}/sql/data.sql /tmp/cometar/i2b2-sql/data.sql
    diff --color src/test/resources/${tname}/sql/meta.sql /tmp/cometar/i2b2-sql/meta.sql
done

## Diff with provided files
    ## Diff each csv file under the test name's directory
# diff src/test/resources/Test-multi-notation/sql/data.sql /tmp/cometar/i2b2-sql/data.sql
# diff src/test/resources/Test-multi-notation/sql/meta.sql /tmp/cometar/i2b2-sql/meta.sql
echo >&2 "$(date +"$df") INFO: All tests complete"
