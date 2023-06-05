# Testing resources
These testing resources allow us to check that RDF metadata (in ttl formatted files and loaded into fuseki) is correctly represented in i2b2 and accurately queries clinical data.

The testing is currently separated into 3 stages which all follow a similar technical format of loading data, performing an action and checking the result where the data, query and expected result are all file based so they can easily be compared. Each stage will (by default) cycle through all test directories and run each test. Some tests are made up of multiple query/response comparisons to ensure the data is accurately tested.

## Stage 1 (Metadata ontology)

__Goal:__ Ensure RDF formatted metadata written for CoMetaR is correctly translated to i2b2's SQL metadata format.

__Processing overview:__
1. Run translation algorithm with testing configuration/parameters.
    1. Run embedded fuseki server.
    1. Load TTL file data.
    1. Query data via SPARQL.
    1. Process into SQL - SQL file is built up, and written to, throughout the processing.
1. Compare (diff) generated SQL with provided, expected SQL file.

## Stage 2 (Metadata ontology)

__Goal:__ Ensure the generated SQL is correctly interpreted and displayed in i2b2's metadata tree.

__Processing overview:__
_Pre-requisite:_ I2b2 must be running on localhost with default ports and default passwords (eg under docker using [i2b2-core](https://github.com/dzl-dm/i2b2-core)).
1. Load SQL metadata into i2b2.
    * Connect to postgres database with psql.
1. Query the i2b2 XML-RDF web service for elements of the metadata tree.
1. Process response to use only relevant elements which do not depend on the time the query is run.
1. Compare (diff) returned XML response with provided, expected XML file.

## Stage 3 (Query clinical data)

__Goal:__ Ensure that a query made using the metadata includes/excludes the correct clinical data.

__Processing overview:__
_Pre-requisite:_ I2b2 must be running on localhost with default ports and default passwords (eg under docker using [i2b2-core](https://github.com/dzl-dm/i2b2-core)).
1. Clear existing clinical data. (NOTE: This will DELETE all clinical data in the specified database - ensure you're using a test system!)
1. Load clinical data for the test.
1. Load SQL metadata for the test (`load-ont.env`).
1. Load SQL metadata for the individual query if specified (`load-ont#.env`).
1. Query the i2b2 XML-RDF web service to run a query on the clinical data.
1. Process response to use only the set_size field representing patient count.
1. Compare (diff) returned XML response with provided, expected XML file. (Essentially 1 number, but we leave the xml tag in place)

_NOTE:_ The scipt `load-ont#.env` simply contains a reference to a metadata stage test. It is sourced by the stage 3 test script so it knows which metadata ontology to load for the given test.
