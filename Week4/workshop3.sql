
DROP TABLE IF EXISTS "owner" CASCADE;
DROP TABLE IF EXISTS "owner_phone" CASCADE;
DROP TABLE IF EXISTS "animal" CASCADE;
DROP TABLE IF EXISTS "vet" CASCADE;
DROP TABLE IF EXISTS "vet_specialty" CASCADE;
DROP TABLE IF EXISTS "visit" CASCADE;
DROP TABLE IF EXISTS "medicine" CASCADE;
DROP TABLE IF EXISTS "visit_medicine" CASCADE;
DROP TABLE IF EXISTS "receipt" CASCADE;

--เจ้าของสัตว์
CREATE TABLE "owner" (
	"owner_id" SERIAL NOT NULL ,
	"firsrt_name" VARCHAR(100) NOT NULL,
	"last_name" VARCHAR(100) NOT NULL,
	"address" TEXT NOT NULL,
	PRIMARY KEY("owner_id")
);

--เบอร์โทร
CREATE TABLE "owner_phone" (
	"owner_id" INTEGER NOT NULL,
	"phone_no" VARCHAR(20) NOT NULL,
	"is_primary" BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY("owner_id","phone_no"),
	CONSTRAINT "fk_owner_phone_owner"
	--เจ้าของ 1 คนสามารถมีเบอร์โทรได้หลายเบอร์
		FOREIGN KEY ("owner_id") REFERENCES "owner"("owner_id")
		ON DELETE CASCADE
);

CREATE INDEX "owner_phone_index_0"
ON "owner_phone" ("owner_id", "phone_no","is_primary");

--แต่เจ้าของ 1 คน สามารถมีเบอร์หลักได้เบอร์เดียว
CREATE UNIQUE INDEX IF NOT EXISTS "idx_unique_primary_phone_per_owner"
ON "owner_phone" ("owner_id")
WHERE "is_primary" = TRUE;

--สัตว์เลี้ยง
CREATE TABLE "animal" (
	"animal_id" SERIAL NOT NULL,
	"owner_id" INTEGER NOT NULL,
	"name" VARCHAR(100) NOT NULL,
	"species" VARCHAR(100),
	"sex" VARCHAR(10),
	"color" VARCHAR(30),
	"birth_date" DATE,
	PRIMARY KEY("animal_id"),
	--เจ้าของ 1 คนพาสัตว์เลี้ยงมารักษาหรือลงทะเบียนไว้ได้หลายตัว
	--และสัตว์เลี้ยงแต่ละตัวมีเจ้าของที่รับผิดชอบได้เพียง1คน
	--(เจ้าของสมัครสมาชิกทิ้งไว้โดยยังไม่พามารักษาได้เหมือนกัน)
	CONSTRAINT "fk_animal_owner"
		FOREIGN KEY ("owner_id") REFERENCES "owner"("owner_id")
);

--สัตวแพทย์
CREATE TABLE "vet" (
	"vet_id" SERIAL NOT NULL,
	"license_no" INTEGER NOT NULL UNIQUE,
	"name" VARCHAR(100) NOT NULL,
	"start_date" DATE NOT NULL,
	PRIMARY KEY("vet_id")
);

--ความเชี่ยวชาญ
CREATE TABLE "vet_specialty" (
	"vet_id" INTEGER NOT NULL,
	-- ความเชี่ยวชาญ มีได้หลายด้าน
	"specialty" VARCHAR(255) NOT NULL,
	PRIMARY KEY("vet_id","specialty"),
	--หมอ 1 คนมีความเชี่ยวชาญได้หลายด้าน
	--ทุกความเชี่ยวชาญที่ระบุต้องผูกกับหมอที่มีอยู่จริง
	CONSTRAINT "fk_vet_specialty_vet"
		FOREIGN KEY ("vet_id") REFERENCES "vet"("vet_id")
		ON DELETE CASCADE
);

CREATE INDEX "vet_specialty_index_0"
ON "vet_specialty" ("vet_id", "specialty");

--การเข้ารับบริการ
CREATE TABLE "visit" (
	"animal_id" INTEGER NOT NULL,
	"visit_no" INTEGER NOT NULL,
	"visit_date" TIMESTAMP NOT NULL,
	"weight" DECIMAL(5,2),
	"temperature" DECIMAL(4,1),
	--อาการ
	"symptom" TEXT,
	-- ตรวจระบุโรค
	"diagnosis" TEXT,
	"vet_id" INTEGER NOT NULL,
	PRIMARY KEY("animal_id","visit_no"),
	--สัตว์ 1 ตัวสามารถมาเข้ารับบริการได้หลายครั้ง นับครั้งแบบ ครั้งที่ 1,2,3,4...
	--แยกประวัติรักษาตามสัตว์ตัวนั้นๆ
	--ประวัติการรักษาจะไม่มีถ้าไม่มีสัตว์อยู่ในระบบ
	CONSTRAINT "fk_visit_animal"
		FOREIGN KEY ("animal_id") REFERENCES "animal"("animal_id")
		ON DELETE CASCADE,
	--หมอ 1 คนสามารถลงตรวจรักษาได้หลายครั้ง
	--แต่ละการรักษาต้องระบุหมอที่ลงตรวจอย่างน้อย 1 คนเสมอ
	CONSTRAINT "fk_visit_vet"
		FOREIGN KEY ("vet_id") REFERENCES "vet"("vet_id")
); 

CREATE INDEX "visit_index_0"
ON "visit" ("animal_id", "visit_no");

--ยา
CREATE TABLE "medicine" (
	"medicine_id" SERIAL NOT NULL,
	"name" VARCHAR(255) NOT NULL,
	"unit" VARCHAR(50) NOT NULL,
	-- ราคายา อาจเปลี่ยนได้
	"unit_price" DECIMAL(10,2) NOT NULL,
	PRIMARY KEY("medicine_id")
);

--การจ่ายยา
CREATE TABLE "visit_medicine" (
	"animal_id" INTEGER NOT NULL,
	"visit_no" INTEGER NOT NULL,
	"medicine_id" INTEGER NOT NULL,
	-- จำนวนที่สั่ง
	"dosage" VARCHAR(100) NOT NULL,
	-- จำนวนวันไม่ใช่วันที่
	"days" INTEGER NOT NULL,
	PRIMARY KEY("animal_id","visit_no","medicine_id"),
	--การรักษา 1 ครั้งสามารถรับยากลับไปได้หลายรายการหรือไม่มีก็ได้
	--ยาชนิดเดียวกันสามารถถูกจ่ายให้เคสอื่นๆได้เหมือนกัน
	--การรักษาครั้งนั้นได้ยาอะไรไปบ้างและให้ไปทานกี่วัน
	CONSTRAINT "fk_visit_medicine_visit"
		FOREIGN KEY ("animal_id","visit_no") REFERENCES "visit"("animal_id","visit_no")
		ON DELETE CASCADE,
	CONSTRAINT "fk_visit_medicine_medicine"
		FOREIGN KEY ("medicine_id") REFERENCES "medicine"("medicine_id")
);

CREATE INDEX "visit_medicine_index_0"
ON "visit_medicine" ("animal_id", "visit_no", "medicine_id");

--ใบเสร็จ
CREATE TABLE "receipt" (
	"receipt_id" SERIAL NOT NULL,
	"animal_id" INTEGER NOT NULL,
	"visit_no" INTEGER NOT NULL,
	--จ่ายเมื่อ
	"paid_at" TIMESTAMP NOT NULL,
	"total_amount" DECIMAL(10,2) NOT NULL,
	PRIMARY KEY("receipt_id"),
	--เมื่อรักษาเสร็จและชำระเงิน ระบบจะออกใบเสร็จได้เพียงแค่ 1 ใบเท่านั้นนะจ๊ะ
	--UNIQUE เพื่อป้องกันไม่ให้ออกใบเสร็จซ้ำซ้อนในการรักษาครั้งนั้นๆและล็อคยอดเงินกันการแก้ไขทีหลัง
	CONSTRAINT "uq_receipt_visit" UNIQUE ("animal_id","visit_no"),
	--ใบเสร็จจะไม่มี ถ้าไม่มีสัตว์ตัวนั้นๆมาเข้ารับบริการรักษาที่คลินิก
	CONSTRAINT "fk_receipt_visit"
		FOREIGN KEY ("animal_id", "visit_no") REFERENCES "visit"("animal_id","visit_no")
);
