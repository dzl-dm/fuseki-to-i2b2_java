DELETE FROM i2b2metadata.table_access WHERE c_table_cd LIKE 'i2b2_test-auto_%';
DELETE FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='test-auto';
