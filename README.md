# fuseki-to-i2b2_java

Java tool to convert SPARQL hosted [CoMetaR](https://github.com/dzl-dm/cometar) RDF meta data into i2b2 database table format. A CoMetaR instance is not required, the TTL files defining the RDF data may be used directly.


## Testing

We include testing resources to validate the processing. It is comprised of input and output data files for testing different features. You will find these under `src/test/resources/`.

This is expected to be run over multiple stages:  
1. Processing the RDF data into SQL data for i2b2.
1. Uploading the SQL to the i2b2 database and confirming the XML responses from i2b2's wildfly server.
1. Ensuring the visible metadata queries the clinical data correctly.

Testing can be performed per stage (run all tests) by running the scripts in this format from this directory where the scipts reside:
```sh
./run-test-stage1.sh
## Some options are supported:
# -t test-name = specify specific test name to run
# -d = additional debugging output
# -u = Update the expected output (interactive confirmation required at run-time)
```

Further information is provided in README's as you naviage the directory structure.
