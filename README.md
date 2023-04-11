# fuseki-to-i2b2_java
Java tool to convert SPARQL hosted RDF meta data into i2b2 database table format


## Testing
We include testing resources to validate the processing. It is comprised of input and output data files for testing different features. You will find these under `test/resources/`.

This is expected to be run over 2 stages:  
1. Processing the RDF data into SQL data for i2b2  
1. Uploading the SQL to the i2b2 database and confirming the XML responses from i2b2's wildfly server  

This actually means multiple output files for each input file given we use a separate SQL file for each table, and make changes to 4 tables so i2b2 can display and query based on the metadata.

