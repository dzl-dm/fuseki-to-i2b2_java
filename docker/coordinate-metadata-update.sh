#!/bin/sh
## Run the translation, push data to i2b2 and update patient counts.
## echo useful data back to user
## error data to docker logs

df="[%Y-%m-%d %H:%M:%S]"

>&2 echo "$(date +"$df") INFO: Received endpoint GET request, processing metadata"
[[ -z i2b2_database_host ]] && >&2 echo "$(date +"$df") WARN: i2b2_database_host is not set!"
[[ -z i2b2_database_port ]] && >&2 echo "$(date +"$df") WARN: i2b2_database_port is not set!"
[[ -z i2b2_data_password ]] && >&2 echo "$(date +"$df") WARN: i2b2_data_password is not set!"
[[ -z i2b2_meta_password ]] && >&2 echo "$(date +"$df") WARN: i2b2_meta_password is not set!"

echo "$(date +"$df") Starting translation process. This can take some time depending on the size of your RDF metadata..."
java -Dlog4j.configurationFile=config/log4j2.xml -cp /usr/local/share/java/\* de.dzl.dwh.metadata.SQLFileWriter -p config/properties.properties
translate_return=$?
[ "$translate_return" = 0 ] || ( echo "$(date +"$df") ERROR: The translation program returned a non-zero exit code (${translate_return}). Aborting" | tee /dev/stderr && exit 1 )

echo "$(date +"$df") Starting upload process. This replaces the metadata on the server"
PGPASSWORD=${DS_CRC_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_CRC_IP} --port=${DS_CRC_PORT} --username=${DS_CRC_USER} --dbname=${I2B2DBNAME} -f "output/data.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed loading data schema data, see docker log and/or server log: log/postgres.log"
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi
PGPASSWORD=${DS_ONT_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_ONT_IP} --port=${DS_ONT_PORT} --username=${DS_ONT_USER} --dbname=${I2B2DBNAME} -f "output/meta.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed loading meta schema data, see docker log and/or server log: log/postgres.log"
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi

echo "$(date +"$df") Updating the patient counts in i2b2."
##TODO: Check the i2b2 built in patient count frunction/trigger - new in i2b2
PGPASSWORD=${DS_PATCOUNT_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_ONT_IP} --port=${DS_ONT_PORT} --username=${DS_PATCOUNT_USER} --dbname=${I2B2DBNAME} -f "patient_count.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command to update the patient count, see docker log and/or server log: log/postgres.log"
    echo "$(date +"$df") ERROR: Update processing incomplete. Data should be fully queryable, but pre-indicated patient counts may not be accurate."
    exit 1
fi
echo "$(date +"$df") Session complete."
