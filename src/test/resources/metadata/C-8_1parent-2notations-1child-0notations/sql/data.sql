DELETE FROM i2b2demodata.concept_dimension WHERE sourcesystem_cd='test-auto';
DELETE FROM i2b2demodata.modifier_dimension WHERE sourcesystem_cd='test-auto';
INSERT INTO i2b2demodata.concept_dimension(concept_path,concept_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\i2b2\dzl:Concept\MULTI\0\','notation1','Concept',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test-auto');
INSERT INTO i2b2demodata.concept_dimension(concept_path,concept_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\i2b2\dzl:Concept\MULTI\1\','notation2','Concept',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test-auto');
