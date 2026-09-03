CREATE TYPE "display_status" AS ENUM (
	'active',
	'deceased'
);

CREATE TABLE owner (
	owner_id SERIAL NOT NULL PRIMARY KEY,
	owner_name VARCHAR(100) NOT NULL,
	national_id CHAR(13) NOT NULL UNIQUE
);

CREATE TABLE pet (
	pet_id SERIAL PRIMARY KEY,
	owner_id INTEGER NOT NULL REFERENCES owner(owner_id) ON DELETE RESTRICT,
	pet_name VARCHAR(100) NOT NULL,
	species VARCHAR(50) NOT NULL,
	breed VARCHAR(50) NULL,
	dob DATE NOT NULL CHECK (dob <= CURRENT_DATE),
	display_status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (display_status IN ('active','deceased'))
);

CREATE TABLE vet (
	vet_id SERIAL PRIMARY KEY,
	vet_name VARCHAR(100) NOT NULL
);

CREATE TABLE visit (
	pet_id INTEGER NOT NULL REFERENCES pet (pet_id) ON DELETE RESTRICT,
	visit_no INTEGER NOT NULL CHECK (visit_no > 0),
	vet_id INTEGER NULL ,
	visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
	diagnosis TEXT NULL,
	total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
	receipt_printed BOOLEAN DEFAULT FALSE,

	PRIMARY KEY (pet_id,visit_no)
);
