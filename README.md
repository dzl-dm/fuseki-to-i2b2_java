# fuseki-to-i2b2_java

Java tool to convert SPARQL hosted [CoMetaR](https://github.com/dzl-dm/cometar) RDF meta data into i2b2 database table format. A CoMetaR instance is not required, the TTL files defining the RDF data may be used directly.

## Installation
Use the following command to build from source, or download the .jar from this github repository.
```sh
mvn clean install
```
Outputs will be generated in the `target` directory.

For production use, compiling without tests is recommended:
```sh
mvn clean install -Dmaven.test.skip
```

### Dependencies
If building yourself (via the maven command above), libraries on which the program depends are available under `target/lib`.

## Usage
The program runs on most recent java versions (tested on java 17.0.7). Please test for your specific environment before deploying in a production environment.

The basic way to run the program is:
```sh
java -cp target/fuseki-to-i2b2-1.0.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter
```
We also provide some configurability via commandline parameters and a `.properties` file. By default, the program will try to use `properties.properties` in the current working directory.

### Parameters
You can view the help output of the program with:
```sh
java -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter --help

usage: SQLFileWriter [-h] [-v] [-e] [-t] [-d] [-p [PROPERTIES]] [-r [RULES]] [-i [INPUT]] [-s [SPARQL]] [--download_date [DOWNLOAD_DATE]] [--max_description_length [MAX_DESCRIPTION_LENGTH]]

Process RDF based metadata into i2b2's SQL format.

named arguments:
-h, --help             show this help message and exit
-v, --version          Show the application version and exit.
-e, --embedded         Use embedded fuseki server. Usually only for testing. (default: false)
-t, --test             Run in testing mode. Will require some additional variables either as arguments or set in the properties. (default: false)
-d, --debug            Increase logging verbosity. (default: false)
-p [PROPERTIES], --properties [PROPERTIES]
Path to properties file [Default is properties.properties].
-r [RULES], --rules [RULES]
Path to properties file [can be defined in properties].
-i [INPUT], --input [INPUT]
Directory containing input ttl files.
-s [SPARQL], --sparql [SPARQL]
SPARQL endpoint to fetch RDF data from.
--download_date [DOWNLOAD_DATE], --dldate [DOWNLOAD_DATE]
Set a specific download_date to use in the generated SQL.
--max_description_length [MAX_DESCRIPTION_LENGTH], --mdl [MAX_DESCRIPTION_LENGTH]
Set no of chars to trim description to.
```

We can also run the program with a log configuration file referenced as:
```sh
java -Dlog4j.configurationFile=config/log4j2.xml -cp target/fuseki-to-i2b2-1.0-SNAPSHOT.jar:target/lib/\* de.dzl.dwh.metadata.SQLFileWriter --help
```

### Config
There is a large overlap of variable between command line parameters and `.properties` parameters, however some are unique to each. Here we outline the `.properties` parameters available. Some experience of the i2b2 database and its structure is required to understand some parameters.
```properties
## The i2b2 database scheme names for meta and data parts of the metadata ontology
i2b2.meta_schema=i2b2metadata.
i2b2.data_schema=i2b2demodata.
## The i2b2 table name to use for metadata in the metaschema
i2b2.ontology.tablename=i2b2
## The prefix to apply to metadata's "path" in the i2b2 database
i2b2.ontology.path_prefix=\\i2b2
## The sourcesystem_cd to use for metadata from this source
i2b2.sourcesystem=test-auto
## The char limit applied to the database column for concept/modifier description
i2b2.max_description_length=900

## Where the output files (SQL) will be written to
generator.output_dir=target/test-output/
## These mappings are used to map concept code schemes to their shortened representation/prefix
generator.mappings=http://data.dzl.de/ont/dwh#;dzl:;http://purl.bioontology.org/ontology/SNOMEDCT/;S:;http://loinc.org/owl#;L:;http://sekmi.de/histream/dwh#snomed;S:;http://sekmi.de/histream/dwh#loinc;L:
## Whether to use the embedded fuseki server to load RDF data or not
generator.use_embedded_server=flase

## Where to query for RDF data (alternative to use embedded server)
source.remote.sparql_endpoint=
## Which directory to read RDF files from
source.local.ttl_file_directory=src/test/resources/demo/ttl/
## Some rules to ensure bi-directional links are made in the presented RDF data
source.local.ttl_rule_file=config/insertrules.ttl

## Used to allow consistent comparison of generated output and expected output
testing.constant_download_date=1970-01-01 00:00:00.0

```

### Output
The program generates SQL files which clean and re-insert the meta data into i2b2. One file is generated per schema, currently hard-coded as:
* `./output/` (configurable in `.properties` file: generator.output_dir)
    * `meta.sql`
    * `data.sql`

### Integration
The way this program is called and how the output is integrated into i2b2 is not enforced, but it lends itself to a similar structure to this:  

Once the metadata is updated, the translation and upload process should be triggered. This could be from a git hook or an alternative processing pipeline. A wrapper scipt or control program could be called to coordinate the following fundamental steps
1. Run this translation program to produce SQL files
1. Run the SQL contained in these files against the i2b2 database
1. Update the patient counts which are computed for each concept
    * The purpose of this step is primarily for i2b2 to optimize queries by selecting the smallest dataset to work with first when possible
    * It also allows i2b2 users to see, at a glance, the size of the dataset corresponding to a concept


## Testing

We include testing resources to validate the processing. It is comprised of input and output data files for testing different features. You will find these under `src/test/resources/`.

This is expected to be run over multiple stages:  
1. Processing the RDF data into SQL data for i2b2.
1. Uploading the SQL to the i2b2 database and confirming the XML responses from i2b2's wildfly server.
1. Ensuring the visible metadata queries the clinical data correctly.

Testing can be performed per stage (run all test cases) by running the scripts in this format from this directory where the scipts reside:
```sh
./run-test-stage1.sh
## Some options are supported:
# -t test-name = specify specific test name to run
# -d = additional debugging output
```

Further information is provided in README's as you naviage the test directory structure.
