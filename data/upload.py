#!/usr/bin/python3

import psycopg2

PROCEDURE_SQL = """
	INSERT INTO procedures(code, description, requires_tooth_number, requires_surface_code, procedure_type, auto_add, cost, number_of_surfaces)
	VALUES ('{}', '{}', '{}', '{}', '{}', '{}', '{}', '{}')
	RETURNING id;
""".format

FIND_PROCEDURE = """
	SELECT id
	FROM procedures
	WHERE code = '{}'
""".format

FIND_TREATMENT_AREA = """
	SELECT id
	FROM treatment_areas
	WHERE name = '{}'
""".format

# This is a mapping table for treatment_areas and procedures
PROC_TA_SQL = """
	INSERT INTO procedure_treatment_area_mappings (procedure_id, treatment_area_id)
	VALUES ({}, {});
""".format

def get_treatment_areas(cur):
	cur.execute('SELECT * FROM treatment_areas;')
	treatment_areas = cur.fetchall()
	ret = {}
	for ta in treatment_areas:
		ret.update({ ta[1]: ta[0] })
	return ret

def get_procedure_id(cur, procedure):
	cur.execute("SELECT id FROM procedures WHERE code='{}';".format(procedure))
	return cur.fetchone()[0]

def add_procedure(cur, *args):
	cur.execute(PROCEDURE_SQL(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
	return cur.fetchone()[0]

def add_proc_ta_mapping(cur, proc_id, ta_id):
	cur.execute(PROC_TA_SQL(proc_id, ta_id))

def clean_record(rec):
	return [rec[0], rec[1], rec[3], rec[4], rec[5], rec[6], rec[2], rec[7] if type(rec[7]) == type(0) else 0]

#WITH HEADERS
#DATA_FILE = './procedures.csv.bk'

DATA_FILE = './procedures_new.csv'
DB_HOST = 'localhost'
DB_NAME = 'mom'
DB_USER = 'ubuntu'
DB_PW = ''

conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PW)
cur = conn.cursor()

ta_lookup = get_treatment_areas(cur)


with open(DATA_FILE, 'r') as fd:
	#headers = fd.readline().split(',')
	data = [l.split(',') for l in fd.readlines()]
	fd.close()


for ix,procedure in enumerate(data):
	if ix == 0:
		continue
	# If a procedure is specific to a treatment area, we add the id to the mapping table
	treatment_areas = []
	treatment_area_ids = []
	if len(procedure) > 9:
		treatment_areas = [procedure[-2].strip('"\n'), procedure[-1].strip('"\n')]
	elif len(procedure) > 8 and len(procedure[8]) > 1:
		treatment_areas = [procedure[8].strip('\n')]
	#treatment_area_id = treatment_areas[ta] if procedure[8].strip('\n') in treatment_areas else False
	for ta in treatment_areas:
		if ta in ta_lookup:
			treatment_area_ids.append(ta_lookup[ta])
	if len(treatment_area_ids) == 0:
		continue
	procedure_id = get_procedure_id(cur, procedure[0])
	for ta_id in treatment_area_ids:
		add_proc_ta_mapping(cur, procedure_id, ta_id)

conn.commit()
conn.close()
