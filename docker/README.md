# Integrate the translator tool into your infrastructure with docker
There are many options for how to build the infrastructure, using containers can simplify and streamline the process meaning fewer variables to go wrong. So here we outline how to deploy the translator tool as a docker container which includes the steps of loading data into i2b2's database and updating patient counts which should be done to reflect any changes in the concept structure.

## What are these extra features?
The translator tool's java code reads RDF data in CoMetaR format from a SPARQL endpoint or RDF files, then translates that into i2b2 specific SQL.
To complete the link, we also want to:
* Load this SQL into the i2b2 database
* Update the patient counts (so that i2b2 can display them and better optimize some queries)

## Building the image
You do not need to do this, we provide it as a resource/package in this repository too.
```sh
## cd to the root of the repo (not inside the "docker" directory)
## Ensure the application and dependent jar's are built and available under target/
mvn clean install
## Build the docker image
docker build -t i2b2-metadata-translator:vX.Y.Z -f docker/Dockerfile .
```

Now its available in your local docker cache, you can also export it and re-load it elsewhere:
```sh
docker images ## See it in your local cache
docker save i2b2-metadata-translator:vX.Y.Z | gzip > i2b2-metadata-translator.tgz # Save it
docker load < i2b2-metadata-translator.tgz # Load it
```

## Deploying the image
There are many deployment tools available, we'll demonstrate how to use `docker compose` using the example `docker-compose.yml` file provided in this repository.

### Configs
We use two types of config:
* environment
* mounted config files

Both are important, you can use the examples we provide as a starting point and make adjustments to suit your environment.

Important to ensure the paths are correct for mounting the config files; the left side is to change the location on your system, the right side is within the docker container and should not be changed.

The most likely variable you will want to change is `source.remote.sparql_endpoint` within the `example.properties` file. In the same file, variables `i2b2.max_description_length` and `i2b2.sourcesystem` are also useful.

### Code
The deployment code, once all configurations are completed, is as simple as:
```sh
docker compose up -d
```