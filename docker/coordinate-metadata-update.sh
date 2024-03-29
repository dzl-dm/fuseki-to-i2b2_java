#!/bin/sh
## Run the translation, push data to i2b2 and update patient counts.
## echo useful data back to user
## error data to docker logs

df="[%Y-%m-%d %H:%M:%S]"

echo "$(date +"$df") INFO: Received endpoint GET request, processing metadata" | tee /proc/1/fd/1
[[ -z DS_CRC_IP ]] && echo "$(date +"$df") WARN: DS_CRC_IP is not set!" | tee /proc/1/fd/1
[[ -z DS_ONT_IP ]] && echo "$(date +"$df") WARN: DS_ONT_IP is not set!" | tee /proc/1/fd/1
[[ -z DS_CRC_PORT ]] && echo "$(date +"$df") WARN: DS_CRC_PORT is not set!" | tee /proc/1/fd/1
[[ -z DS_ONT_PORT ]] && echo "$(date +"$df") WARN: DS_ONT_PORT is not set!" | tee /proc/1/fd/1
[[ -z DS_CRC_PASS ]] && echo "$(date +"$df") WARN: DS_CRC_PASS is not set!" | tee /proc/1/fd/1
[[ -z DS_ONT_PASS ]] && echo "$(date +"$df") WARN: DS_ONT_PASS is not set!" | tee /proc/1/fd/1
[[ -z DS_PATCOUNT_PASS ]] && echo "$(date +"$df") WARN: DS_PATCOUNT_PASS is not set!" | tee /proc/1/fd/1

echo "$(date +"$df") Starting translation process. This can take some time depending on the size of your RDF metadata..."
java -Dlog4j.configurationFile=config/log4j2.xml -cp /usr/local/share/java/\* de.dzl.dwh.metadata.SQLFileWriter -p config/properties.properties >> /proc/1/fd/1
# translate_return=$?
# [ "$translate_return" = 0 ] || ( echo "$(date +"$df") ERROR: The translation program returned a non-zero exit code (${translate_return}). Aborting" | tee /proc/1/fd/1 && exit 1 )
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: The translation program returned a non-zero exit code. Aborting" | tee /proc/1/fd/1
    exit 1
fi

echo "$(date +"$df") Starting upload process. This replaces the metadata on the server" | tee /proc/1/fd/1
PGPASSWORD=${DS_CRC_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_CRC_IP} --port=${DS_CRC_PORT} --username=${DS_CRC_USER} --dbname=${I2B2DBNAME} -f "output/data.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed loading data schema data, see docker log and/or server log: log/postgres.log" | tee /proc/1/fd/1
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi
PGPASSWORD=${DS_ONT_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_ONT_IP} --port=${DS_ONT_PORT} --username=${DS_ONT_USER} --dbname=${I2B2DBNAME} -f "output/meta.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command failed loading meta schema data, see docker log and/or server log: log/postgres.log" | tee /proc/1/fd/1
    echo "$(date +"$df") ERROR: Cannot continue, please address issue with loading data, then try again."
    exit 1
fi

echo "$(date +"$df") Updating the patient counts in i2b2." | tee /proc/1/fd/1
##TODO: Check the i2b2 built in patient count frunction/trigger - new in i2b2
PGPASSWORD=${DS_PATCOUNT_PASS} psql -v ON_ERROR_STOP=1 -v statement_timeout=120000 -L "log/postgres.log" -q --host=${DS_ONT_IP} --port=${DS_ONT_PORT} --username=${DS_PATCOUNT_USER} --dbname=${I2B2DBNAME} -f "patient_count.sql"
if [ $? -ne 0 ]; then
    echo "$(date +"$df") ERROR: PostgreSQL command to update the patient count, see docker log and/or server log: log/postgres.log" | tee /proc/1/fd/1
    echo "$(date +"$df") ERROR: Update processing incomplete. Data should be fully queryable, but pre-indicated patient counts may not be accurate."
    exit 1
fi
echo "$(date +"$df") Session complete." | tee /proc/1/fd/1
