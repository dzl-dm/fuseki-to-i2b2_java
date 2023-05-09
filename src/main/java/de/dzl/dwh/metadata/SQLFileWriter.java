package de.dzl.dwh.metadata;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.io.Writer;
import java.net.URI;
import java.util.HashMap;
import java.util.Properties;

import org.apache.jena.atlas.logging.LogCtl;
import org.apache.jena.fuseki.Fuseki;
import org.apache.jena.fuseki.embedded.FusekiServer;
import org.apache.jena.query.Dataset;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.sparql.modify.UsingList;
import org.apache.jena.update.UpdateAction;
import org.apache.log4j.Level;
import org.apache.logging.log4j.core.config.Configurator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.sourceforge.argparse4j.ArgumentParsers;
import net.sourceforge.argparse4j.impl.Arguments;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.ArgumentParserException;
import net.sourceforge.argparse4j.inf.Namespace;

public class SQLFileWriter extends SQLGenerator {

    private static final Logger logger = LoggerFactory.getLogger(SQLFileWriter.class);

	private Writer writer_meta;
	private Writer writer_data;

	public static void main(String[] args) throws ArgumentParserException, IOException {
        ArgumentParser parser = ArgumentParsers.newFor("SQLFileWriter").build()
                .defaultHelp(true)
                .version("0.0.1")
                .description("Process RDF based metadata into i2b2's SQL format.");
        parser.addArgument("-v", "--version")
		        .action(Arguments.version())
		        .help("Show the application version and exit.");
        parser.addArgument("-e", "--embedded")
                .action(Arguments.storeTrue())
                .help("Use embedded fuseki server. Usually only for testing.");
        parser.addArgument("-t", "--test")
                .action(Arguments.storeTrue())
                .help("Run in testing mode. Will require some additional variables either as arguments or set in the properties.");
        parser.addArgument("-d", "--debug")
                .action(Arguments.storeTrue())
                .help("Increase logging verbosity.");
        parser.addArgument("-p", "--properties")
		        .nargs("?")
		        .help("Path to properties file [Default is properties.properties].");
        parser.addArgument("-r", "--rules")
		        .nargs("?")
		        .help("Path to properties file [can be defined in properties].");
        parser.addArgument("-i", "--input")
		        .nargs("?")
		        .help("Directory containing input ttl files.");
        parser.addArgument("--download_date", "--dldate")
		        .nargs("?")
		        .help("set a specific download_date to use in the generated SQL.");
        Namespace ns = null;
        try {
            ns = parser.parseArgs(args);
        } catch (ArgumentParserException e) {
            parser.handleError(e);
//            System.out.printf("%s\n", "Bad use of arguments, use --help for more information");
            logger.error("Bad use of arguments, use --help for more information");
            System.exit(1);
        }
        if (ns.getString("debug").equals("true")) {
        	// Attempt to override the log level to debug
//            System.out.printf("DEBUGGING mode. High levels of logging!\n");
//            System.out.printf("Effective Log level (root): " + org.apache.log4j.Logger.getRootLogger().getEffectiveLevel() + "\n");
//            System.out.printf("Log level (root): " + org.apache.log4j.Logger.getRootLogger().getLevel() + "\n");
//            System.out.printf("Effective Log level (): " + org.apache.log4j.Logger.getLogger(SQLFileWriter.class).getEffectiveLevel() + "\n");
//            System.out.printf("Log level (): " + org.apache.log4j.Logger.getLogger(SQLFileWriter.class).getLevel() + "\n");
//        	org.apache.log4j.Logger logger4j = org.apache.log4j.Logger.getLogger(SQLFileWriter.class);
        	org.apache.log4j.Logger logger4j = org.apache.log4j.Logger.getRootLogger();
        	logger4j.setLevel(org.apache.log4j.Level.toLevel("debug"));
//        	Configurator.setAllLevels(Logger.ROOT_LOGGER_NAME, "DEBUG");
//        	logger.ROOT_LOGGER_NAME;
//            logger.debug("Debug logging successfully activated...");
        }
//        logger.debug("Arg namespace: {}", ns);
//        logger.debug(ns.getString("input")); // If nargs("?")
//        logger.debug("input: {}", ns.getList("input").get(0)); // If nargs("*")
       logger.trace("Test trace message");
       logger.debug("Test debug message");
       logger.info("Test log message");
       logger.warn("Test log message '{}'", "WARN");
       logger.error("Test error message");

        // Continue...
		SQLFileWriter sqlFileWriter = new SQLFileWriter();
		FusekiServer server = null;

		Properties prop = new Properties();
		String properties_path = "";
		properties_path = ns.getString("properties") != null ? ns.getString("properties") : "properties.properties";
		prop.load(new FileInputStream(properties_path));
		boolean use_embedded_server = ns.getString("properties").equals("true") ? true : prop.getProperty("test.use_embedded_server").equals("true");
		sqlFileWriter.meta_schema = prop.getProperty("i2b2.meta_schema");
		sqlFileWriter.data_schema = prop.getProperty("i2b2.data_schema");
		sqlFileWriter.ontology_tablename = prop.getProperty("i2b2.ontology.tablename");
		sqlFileWriter.i2b2_path_prefix = prop.getProperty("i2b2.ontology.path_prefix");
		sqlFileWriter.sourcesystem = prop.getProperty("i2b2.sourcesystem");
		sqlFileWriter.outputDir = prop.getProperty("generator.output_dir");
		String ttl_file_directory = ns.getString("input") != null ? ns.getString("input") : prop.getProperty("test.ttl_file_directory");
		String ttl_rule_file = ns.getString("rules") != null ? ns.getString("rules") : prop.getProperty("test.ttl_rule_file");
		String download_date = ns.getString("download_date") != null ? ns.getString("download_date") : prop.getProperty("test.download_date");
		String[] mappingsArray = prop.getProperty("generator.mappings").split(";");
		sqlFileWriter.mappings = new HashMap<String, String>();
		for (int i = 0; i < mappingsArray.length; i+=2)
		{
			sqlFileWriter.mappings.put(mappingsArray[i], mappingsArray[i+1]);
		}

		logger.debug("ttl_file_directory: {}", ttl_file_directory);
		logger.debug("ttl_rule_file: {}", ttl_rule_file);
		if (use_embedded_server)
		{
			server = startEmbeddedServer(ttl_file_directory,ttl_rule_file);
	    	URI uri = server.server.getURI();
	    	sqlFileWriter.sparqlEndpoint = "http://"+uri.getHost()+":3330/ds/query";
			logger.debug("sparqlEndpoint: http://{}:3330/ds/query", uri.getHost());
		}
		else
		{
			
			if (!prop.containsKey("generator.sparql_endpoint"))
			{
				throw new IllegalArgumentException("Missing SPARQL endpoint property.");
			}
			sqlFileWriter.sparqlEndpoint = prop.getProperty("generator.sparql_endpoint");
		}

		try {
			if (server != null) server.start();
	    	System.out.println("download_date (main): "+download_date);
			sqlFileWriter.generateSQLStatements(download_date);
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(1);
		} finally {
			if (server != null) server.stop();
		}
	}

	private static FusekiServer startEmbeddedServer(String ttl_folder_path, String ttl_rule_file_path) {
    	FusekiServer server = null;
		Dataset ds = DatasetFactory.createTxnMem() ;

		File folder = new File(ttl_folder_path);
		File rulesFile = new File(ttl_rule_file_path);
		File[] listOfFiles = folder.listFiles();
		System.out.println("No. of files: " + listOfFiles.length);
		for (File file : listOfFiles) {
			System.out.println("file: " + file.getAbsolutePath());
		    if (file.isFile()) {
		        RDFDataMgr.read(ds,file.getAbsolutePath()) ;
		    }
		}
		UpdateAction.parseExecute(new UsingList(), ds.asDatasetGraph(), rulesFile.getAbsolutePath()) ;

    	server = FusekiServer.create()
    			  .add("/ds", ds)
    			  .build() ;
    	LogCtl.setJavaLogging();
    	LogCtl.setLevel(Fuseki.serverLogName,  "WARN");
    	LogCtl.setLevel(Fuseki.actionLogName,  "WARN");
    	LogCtl.setLevel(Fuseki.requestLogName, "WARN");
    	LogCtl.setLevel(Fuseki.adminLogName,   "WARN");
    	LogCtl.setLevel("org.eclipse.jetty",   "WARN");
    	return server;
	}

	@Override
	protected void writeDataSql(String statement) throws IOException {
		writer_data.write(statement);
	}

	@Override
	protected void writeMetaSql(String statement) throws IOException {
		writer_meta.write(statement);
	}

	@Override
	protected void initializeWriters() throws UnsupportedEncodingException, FileNotFoundException {
		writer_meta = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputDir+"meta.sql"), "utf-8"));
		writer_data = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outputDir+"data.sql"), "utf-8"));
	}

	@Override
	protected void closeWriters() throws IOException {
		if (writer_meta != null) writer_meta.close();
		if (writer_data != null) writer_data.close();
	}
}
