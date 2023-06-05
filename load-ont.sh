#!/bin/bash
## Load metadata ontology
## Expected to be called from another script

df="[%Y-%m-%d %H:%M:%S]"

while getopts 't:d' OPTION; do
    case "$OPTION" in
        t)
            tname=${OPTARG}
        ;;
        d)
            DEBUG_MODE=1
        ;;
        ?)
            echo "script usage: $(basename \$0) [-u]" >&2
            exit 0
        ;;
    esac
done
shift $((OPTIND-1))

## DB passwords - should be default "demouser"? for testing
I2B2METAPW=demouser
I2B2DEMOPW=demouser

echo "$(date +"$df") INFO: Loading metadata ontology data from '${tname}'..."

if [[ DEBUG_MODE -ne 0 ]]; then
    echo "$(date +"$df") DEBUG: Loading metadata ontology to meta schema..."
fi
## Run SQL against i2b2 database (Fixed as localhost:5432 postgres!) - use appropriate user for demo/meta data
PGPASSWORD=$I2B2METAPW /usr/bin/psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=localhost --username=i2b2metadata --dbname=i2b2 -f "src/test/resources/metadata/${tname}/sql/meta.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed loading meta, see log: log/postgres.log"
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi
if [[ DEBUG_MODE -ne 0 ]]; then
    echo "$(date +"$df") DEBUG: Loading metadata ontology to demo schema..."
fi
PGPASSWORD=$I2B2DEMOPW /usr/bin/psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=localhost --username=i2b2demodata --dbname=i2b2 -f "src/test/resources/metadata/${tname}/sql/data.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed data, see log: log/postgres.log"
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi
