DELETE FROM i2b2demodata.concept_dimension WHERE sourcesystem_cd='test2';
DELETE FROM i2b2demodata.modifier_dimension WHERE sourcesystem_cd='test2';
INSERT INTO i2b2demodata.concept_dimension(concept_path,concept_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\i2b2\dzl:Concept\','notation','Concept',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2demodata.modifier_dimension(modifier_path,modifier_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\dzl:modifier2\MULTI\0\','MOD_1','Modifier2',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2demodata.modifier_dimension(modifier_path,modifier_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\dzl:modifier2\MULTI\1\','MOD_2','Modifier2',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
INSERT INTO i2b2demodata.modifier_dimension(modifier_path,modifier_cd,name_char,update_date,download_date,import_date,sourcesystem_cd)VALUES('\dzl:modifier1\','MOD','Modifier1',current_timestamp,'1970-01-01 00:00:00.0',current_timestamp,'test2');
