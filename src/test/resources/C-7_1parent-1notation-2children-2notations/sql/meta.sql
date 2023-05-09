DELETE FROM i2b2metadata.table_access WHERE c_table_cd LIKE 'i2b2_%';
DELETE FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='test2';
INSERT INTO i2b2metadata.table_access(c_table_cd,c_table_name,c_protected_access,c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_facttablecolumn,c_dimtablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip)VALUES('i2b2_80f5eadf','i2b2','N',1,'\i2b2\dzl:Concept\','Concept','N','FA','concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\','Concept');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(2,'\i2b2\dzl:Concept\','Concept','N','FA','notation',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\','Concept','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(3,'\i2b2\dzl:Concept\dzl:Concept2\','Child concept','N','MA',NULL,NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept2\','Child concept','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(4,'\i2b2\dzl:Concept\dzl:Concept2\MULTI\','MULTI','N','MH','',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept2\MULTI\','Child concept','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(5,'\i2b2\dzl:Concept\dzl:Concept2\MULTI\0\','Child concept','N','LH','child-notation2',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept2\MULTI\0\','Child concept','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(5,'\i2b2\dzl:Concept\dzl:Concept2\MULTI\1\','Child concept','N','LH','child-notation1',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept2\MULTI\1\','Child concept','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(3,'\i2b2\dzl:Concept\dzl:Concept3\','Child conceptb','N','MA',NULL,NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept3\','Child conceptb','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(4,'\i2b2\dzl:Concept\dzl:Concept3\MULTI\','MULTI','N','MH','',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept3\MULTI\','Child conceptb','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(5,'\i2b2\dzl:Concept\dzl:Concept3\MULTI\0\','Child conceptb','N','LH','childb-notation1',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept3\MULTI\0\','Child conceptb','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2metadata.i2b2(c_hlevel,c_fullname,c_name,c_synonym_cd,c_visualattributes,c_basecode,c_metadataxml,c_facttablecolumn,c_tablename,c_columnname,c_columndatatype,c_operator,c_dimcode,c_tooltip,m_applied_path,update_date,download_date,import_date,sourcesystem_cd)VALUES(5,'\i2b2\dzl:Concept\dzl:Concept3\MULTI\1\','Child conceptb','N','LH','childb-notation2',NULL,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\dzl:Concept\dzl:Concept3\MULTI\1\','Child conceptb','@',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
