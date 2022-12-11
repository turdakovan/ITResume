--

-- web_pages
CREATE TABLE IF NOT EXISTS web_pages (
	id_web_page int PRIMARY KEY,
	link TEXT NOT NULL
);

-- simulator
CREATE TABLE IF NOT EXISTS simulator (
	id_simulator int PRIMARY KEY,
	name varchar(200) NOT NULL,
	price REAL NOT NULL,
	is_demo int NOT NULL,
	id_web_page int REFERENCES web_pages(id_web_page) ON DELETE CASCADE
	
	CONSTRAINT chk_is_demo CHECK (is_demo) IN (0, 1)
);

-- chapters
CREATE TABLE IF EXISTS chapters (
	id_chapter int PRIMARY KEY,
	name varchar(200) NOT NULL ,
	is_demo int NOT NULL 
	
	CONSTRAINT chk_is_demo CHECK (is_demo) IN (0, 1)
);

-- simulator_chapter
CREATE TABLE IF NOT EXISTS simulator_chapter (
	id_simulator int REFERENCES simulator(id_simulator) ON DELETE CASCADE,
	id_chapter int REFERENCES chapters(id_chapter) ON DELETE CASCADE,
	
	CONSTRAINT simulator_chapter_PK PRIMARY KEY (id_simulator, id_chapter)
);

-- steps
CREATE TABLE IF NOT EXISTS steps (
	id_step int PRIMARY KEY,
	name varchar(200),
	type_step varchar(200),
	is_demo int,
	id_chapter int REFERENCES chapters(id_chapter) ON DELETE CASCADE 
	
	CONSTRAINT chk_is_demo CHECK (is_demo) IN (0, 1)
);

-- dialog
CREATE TABLE IF NOT EXISTS dialog (
	id_dialog int PRIMARY KEY,
	text_message text
	type_message varchar(20) NOT NULL,
	author varchar(100) NOT NULL DEFAULT 'Вы',
	id_step int REFERENCES steps(id_step) ON DELETE CASCADE
	
	CONSTRAINT chk_type_message CHECK (type_message) IN ('исходящее', 'входящее')
);

-- texts
CREATE TABLE IF NOT EXISTS texts (
	id_text int PRIMARY KEY,
	text_step TEXT NOT NULL,
	id_step int REFERENCES steps(id_step) ON DELETE CASCADE
);

-- video
CREATE TABLE IF NOT EXISTS video (
	id_video int PRIMARY KEY,
	web_page_id int REFERENCES web_pages(id_web_page) ON DELETE CASCADE,
	id_step int REFERENCES steps(id_step) ON DELETE CASCADE
);

-- questions
CREATE TABLE IF NOT EXISTS questions (
	id_question int PRIMARY KEY,
	question_type TEXT NOT NULL,
	question_text TEXT NOT NULL,
	id_step int REFERENCES steps(id_step) ON DELETE CASCADE
);

-- answers
CREATE TABLE IF NOT EXISTS answers (
	id_answer int PRIMARY KEY,
	answer TEXT,
	is_correct int NOT NULL,
	id_question REFERENCES questions(id_question) ON DELETE CASCADE
	
	CONSTRAINT chk_is_correct CHECK (is_correct) IN (0, 1)	
);

-- user_answers
CREATE TABLE IF NOT EXISTS user_answers (
	id_user_answer int PRIMARY KEY,
	user_answer TEXT,
	id_question int REFERENCES questions(id_question) ON DELETE CASCADE,
	id_answer int REFERENCES answers(id_answer) ON DELETE CASCADE 
);



