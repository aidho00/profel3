-- ============================================================
-- SCHOOL DATABASE SETUP SCRIPT
-- Fundamentals of Database Systems
-- Instructor: Dave Bryan J. Beatingo
-- ============================================================
-- This script creates the complete school_db database with
-- sample data for classroom exercises and SQL practice.
-- 
-- HOW TO USE:
-- 1. Open phpMyAdmin (localhost/phpmyadmin)
-- 2. Click the "Import" tab
-- 3. Choose this file
-- 4. Click "Go"
-- 
-- Or paste this entire script into the SQL tab and run it.
-- Safe to re-run: it drops and recreates everything.
-- ============================================================

-- Create and select database
CREATE DATABASE IF NOT EXISTS school_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE school_db;

-- Disable foreign key checks for clean drops
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in any order (FK checks disabled)
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS faculty;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- TABLE: departments
-- ============================================================
CREATE TABLE departments (
    dept_id INT AUTO_INCREMENT,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (dept_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: faculty
-- ============================================================
CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    dept_id INT,
    rank_title ENUM('Instructor', 'Assistant Professor', 'Associate Professor', 'Professor') DEFAULT 'Instructor',
    hire_date DATE,
    salary DECIMAL(10,2),
    status ENUM('Active', 'On Leave', 'Retired') DEFAULT 'Active',
    PRIMARY KEY (faculty_id),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: courses
-- ============================================================
CREATE TABLE courses (
    course_code VARCHAR(10),
    course_name VARCHAR(100) NOT NULL,
    units INT NOT NULL CHECK(units >= 1 AND units <= 6),
    description TEXT,
    dept_id INT,
    semester ENUM('1st', '2nd', 'Summer') NOT NULL,
    faculty_id INT,
    max_students INT DEFAULT 40,
    PRIMARY KEY (course_code),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE SET NULL,
    FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: students
-- ============================================================
CREATE TABLE students (
    student_id INT AUTO_INCREMENT,
    student_code VARCHAR(10) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    address VARCHAR(200),
    course ENUM('BSIS', 'BSIT', 'BSCS') NOT NULL,
    year_level INT CHECK(year_level >= 1 AND year_level <= 5),
    gpa DECIMAL(3,2) CHECK(gpa >= 1.00 AND gpa <= 5.00),
    status ENUM('Active', 'Inactive', 'Graduated', 'Dropped') DEFAULT 'Active',
    date_enrolled DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: enrollments
-- ============================================================
CREATE TABLE enrollments (
    enroll_id INT AUTO_INCREMENT,
    student_id INT NOT NULL,
    course_code VARCHAR(10) NOT NULL,
    school_year VARCHAR(9) NOT NULL,
    semester ENUM('1st', '2nd', 'Summer') NOT NULL,
    grade DECIMAL(3,2) CHECK(grade >= 1.00 AND grade <= 5.00),
    remarks ENUM('Passed', 'Failed', 'Incomplete', 'Dropped', 'In Progress') DEFAULT 'In Progress',
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (enroll_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_code) REFERENCES courses(course_code) ON DELETE RESTRICT,
    UNIQUE KEY unique_enrollment (student_id, course_code, school_year, semester)
) ENGINE=InnoDB;


-- ============================================================
-- INSERT DATA: departments
-- ============================================================
INSERT INTO departments (dept_code, dept_name, building, phone) VALUES
('CCS', 'College of Computer Studies', 'IT Building', '032-123-4567'),
('COE', 'College of Engineering', 'Engineering Hall', '032-123-4568'),
('CAS', 'College of Arts & Sciences', 'Main Building', '032-123-4569'),
('CBM', 'College of Business & Management', 'Business Center', '032-123-4570');


-- ============================================================
-- INSERT DATA: faculty
-- ============================================================
INSERT INTO faculty (first_name, last_name, email, dept_id, rank_title, hire_date, salary) VALUES
('Dave Bryan', 'Beatingo', 'dbeatingo@school.edu', 1, 'Instructor', '2022-06-01', 35000.00),
('Maria Elena', 'Cruz', 'mecruz@school.edu', 1, 'Assistant Professor', '2018-08-15', 45000.00),
('Roberto', 'Santos', 'rsantos@school.edu', 1, 'Associate Professor', '2015-01-10', 55000.00),
('Ana Lucia', 'Reyes', 'alreyes@school.edu', 2, 'Professor', '2010-06-20', 65000.00),
('Carlos', 'Garcia', 'cgarcia@school.edu', 3, 'Instructor', '2023-01-05', 32000.00),
('Patricia', 'Lopez', 'plopez@school.edu', 4, 'Assistant Professor', '2019-03-12', 42000.00);


-- ============================================================
-- INSERT DATA: courses
-- ============================================================
INSERT INTO courses (course_code, course_name, units, description, dept_id, semester, faculty_id, max_students) VALUES
('DB101', 'Fundamentals of Database Systems', 3, 'Introduction to databases, SQL, ER modeling, and normalization', 1, '1st', 1, 40),
('WEB201', 'Web Development', 3, 'HTML, CSS, JavaScript, PHP, and responsive design', 1, '1st', 2, 35),
('OOP101', 'Object-Oriented Programming', 3, 'Java/Python OOP concepts: classes, inheritance, polymorphism', 1, '2nd', 3, 40),
('NET301', 'Computer Networks', 3, 'Network fundamentals, TCP/IP, routing, switching', 1, '2nd', 2, 30),
('SYS401', 'Systems Analysis & Design', 3, 'SDLC, requirements gathering, UML diagrams', 1, '1st', 3, 35),
('HCI201', 'Human-Computer Interaction', 3, 'UI/UX design principles, usability testing', 1, '2nd', 1, 30),
('CAP401', 'Capstone Project', 6, 'Final year comprehensive project with industry partner', 1, '2nd', 3, 20),
('ENG101', 'English Communication', 3, 'Academic writing, oral presentation, business English', 3, '1st', 5, 45),
('MATH201', 'Discrete Mathematics', 3, 'Logic, sets, graphs, combinatorics for CS', 3, '1st', 5, 40),
('ITP101', 'Introduction to Programming', 3, 'Basic programming concepts using Python', 1, '1st', 2, 45),
('DSA201', 'Data Structures & Algorithms', 3, 'Arrays, linked lists, trees, sorting, searching', 1, '2nd', 3, 35),
('MIS301', 'Management Information Systems', 3, 'IS in organizations, decision support systems', 4, '1st', 6, 40);


-- ============================================================
-- INSERT DATA: students (20 students)
-- ============================================================
INSERT INTO students (student_code, first_name, last_name, email, phone, date_of_birth, gender, address, course, year_level, gpa, status, date_enrolled) VALUES
('2024-001', 'Maria', 'Santos', 'maria.santos@school.edu', '09171234501', '2003-05-15', 'Female', 'Cebu City', 'BSIS', 2, 1.50, 'Active', '2023-08-01'),
('2024-002', 'Juan', 'Cruz', 'juan.cruz@school.edu', '09171234502', '2002-11-22', 'Male', 'Mandaue City', 'BSIT', 3, 1.75, 'Active', '2022-08-01'),
('2024-003', 'Ana', 'Reyes', 'ana.reyes@school.edu', '09171234503', '2004-01-08', 'Female', 'Lapu-Lapu City', 'BSIS', 1, 1.25, 'Active', '2024-08-01'),
('2024-004', 'Pedro', 'Garcia', 'pedro.garcia@school.edu', '09171234504', '2003-07-30', 'Male', 'Talisay City', 'BSCS', 2, 2.00, 'Active', '2023-08-01'),
('2024-005', 'Lisa', 'Mendoza', 'lisa.mendoza@school.edu', '09171234505', '2002-09-14', 'Female', 'Cebu City', 'BSIT', 4, 1.50, 'Active', '2021-08-01'),
('2024-006', 'Carlo', 'Rivera', 'carlo.rivera@school.edu', '09171234506', '2003-03-21', 'Male', 'Minglanilla', 'BSIS', 2, 2.25, 'Active', '2023-08-01'),
('2024-007', 'Sophia', 'Tan', 'sophia.tan@school.edu', '09171234507', '2004-06-12', 'Female', 'Cebu City', 'BSCS', 1, 1.75, 'Active', '2024-08-01'),
('2024-008', 'Miguel', 'Lim', 'miguel.lim@school.edu', '09171234508', '2002-12-05', 'Male', 'Consolacion', 'BSIT', 3, 2.50, 'Active', '2022-08-01'),
('2024-009', 'Angela', 'Villanueva', 'angela.v@school.edu', '09171234509', '2003-08-18', 'Female', 'Liloan', 'BSIS', 2, 1.75, 'Active', '2023-08-01'),
('2024-010', 'Rafael', 'Dela Cruz', 'rafael.dc@school.edu', '09171234510', '2001-04-25', 'Male', 'Cebu City', 'BSIT', 4, 1.25, 'Active', '2021-08-01'),
('2024-011', 'Christine', 'Bautista', 'christine.b@school.edu', '09171234511', '2003-10-30', 'Female', 'Mandaue City', 'BSIS', 2, 3.00, 'Active', '2023-08-01'),
('2024-012', 'Mark', 'Gonzales', 'mark.gonzales@school.edu', '09171234512', '2002-02-14', 'Male', 'Talisay City', 'BSCS', 3, 2.75, 'Active', '2022-08-01'),
('2024-013', 'Jessica', 'Flores', 'jessica.flores@school.edu', '09171234513', '2004-09-03', 'Female', 'Cebu City', 'BSIT', 1, NULL, 'Active', '2024-08-01'),
('2024-014', 'Daniel', 'Ramos', 'daniel.ramos@school.edu', '09171234514', '2003-01-19', 'Male', 'Lapu-Lapu City', 'BSIS', 2, 1.50, 'Active', '2023-08-01'),
('2024-015', 'Patricia', 'Aquino', 'patricia.aquino@school.edu', '09171234515', '2001-11-07', 'Female', 'Cebu City', 'BSCS', 4, 1.75, 'Graduated', '2020-08-01'),
('2024-016', 'Kevin', 'Torres', 'kevin.torres@school.edu', '09171234516', '2003-05-28', 'Male', 'Minglanilla', 'BSIT', 2, 2.00, 'Active', '2023-08-01'),
('2024-017', 'Samantha', 'Uy', 'samantha.uy@school.edu', '09171234517', '2004-03-16', 'Female', 'Cebu City', 'BSIS', 1, NULL, 'Active', '2024-08-01'),
('2024-018', 'Gabriel', 'Chua', 'gabriel.chua@school.edu', '09171234518', '2002-07-09', 'Male', 'Mandaue City', 'BSCS', 3, 2.25, 'Active', '2022-08-01'),
('2024-019', 'Nicole', 'Pascual', 'nicole.pascual@school.edu', NULL, '2003-12-01', 'Female', 'Consolacion', 'BSIT', 2, 1.75, 'Active', '2023-08-01'),
('2024-020', 'Justin', 'Morales', 'justin.morales@school.edu', '09171234520', '2001-06-15', 'Male', 'Cebu City', 'BSIS', 4, 1.50, 'Inactive', '2020-08-01');


-- ============================================================
-- INSERT DATA: enrollments (35+ records)
-- ============================================================
INSERT INTO enrollments (student_id, course_code, school_year, semester, grade, remarks) VALUES
-- Maria Santos (student 1) - 2nd year BSIS
(1, 'DB101', '2024-2025', '1st', 1.50, 'Passed'),
(1, 'WEB201', '2024-2025', '1st', 1.75, 'Passed'),
(1, 'ENG101', '2023-2024', '1st', 1.50, 'Passed'),
(1, 'ITP101', '2023-2024', '1st', 1.25, 'Passed'),

-- Juan Cruz (student 2) - 3rd year BSIT
(2, 'DB101', '2024-2025', '1st', 2.00, 'Passed'),
(2, 'OOP101', '2024-2025', '2nd', NULL, 'In Progress'),
(2, 'NET301', '2024-2025', '2nd', NULL, 'In Progress'),
(2, 'WEB201', '2023-2024', '1st', 1.75, 'Passed'),

-- Ana Reyes (student 3) - 1st year BSIS
(3, 'DB101', '2024-2025', '1st', NULL, 'In Progress'),
(3, 'ENG101', '2024-2025', '1st', NULL, 'In Progress'),
(3, 'ITP101', '2024-2025', '1st', NULL, 'In Progress'),
(3, 'MATH201', '2024-2025', '1st', NULL, 'In Progress'),

-- Pedro Garcia (student 4) - 2nd year BSCS
(4, 'WEB201', '2024-2025', '1st', 2.25, 'Passed'),
(4, 'DSA201', '2024-2025', '2nd', NULL, 'In Progress'),
(4, 'OOP101', '2023-2024', '2nd', 2.00, 'Passed'),
(4, 'MATH201', '2023-2024', '1st', 2.50, 'Passed'),

-- Lisa Mendoza (student 5) - 4th year BSIT
(5, 'CAP401', '2024-2025', '2nd', NULL, 'In Progress'),
(5, 'SYS401', '2024-2025', '1st', 1.50, 'Passed'),
(5, 'NET301', '2023-2024', '2nd', 1.75, 'Passed'),

-- Carlo Rivera (student 6) - 2nd year BSIS
(6, 'DB101', '2024-2025', '1st', 2.25, 'Passed'),
(6, 'WEB201', '2024-2025', '1st', 2.50, 'Passed'),
(6, 'ENG101', '2023-2024', '1st', 2.00, 'Passed'),

-- Sophia Tan (student 7) - 1st year BSCS
(7, 'ITP101', '2024-2025', '1st', 1.75, 'Passed'),
(7, 'MATH201', '2024-2025', '1st', 1.50, 'Passed'),
(7, 'ENG101', '2024-2025', '1st', 2.00, 'Passed'),

-- Miguel Lim (student 8) - 3rd year BSIT
(8, 'SYS401', '2024-2025', '1st', 2.75, 'Passed'),
(8, 'NET301', '2024-2025', '2nd', NULL, 'In Progress'),
(8, 'OOP101', '2023-2024', '2nd', 2.50, 'Passed'),

-- Angela Villanueva (student 9) - 2nd year BSIS
(9, 'DB101', '2024-2025', '1st', 1.75, 'Passed'),
(9, 'HCI201', '2024-2025', '2nd', NULL, 'In Progress'),

-- Rafael Dela Cruz (student 10) - 4th year BSIT
(10, 'CAP401', '2024-2025', '2nd', NULL, 'In Progress'),
(10, 'SYS401', '2024-2025', '1st', 1.25, 'Passed'),
(10, 'MIS301', '2023-2024', '1st', 1.50, 'Passed'),

-- Christine Bautista (student 11) - 2nd year BSIS (at risk)
(11, 'DB101', '2024-2025', '1st', 3.00, 'Passed'),
(11, 'WEB201', '2024-2025', '1st', 3.25, 'Failed'),

-- Mark Gonzales (student 12) - 3rd year BSCS
(12, 'DSA201', '2024-2025', '2nd', NULL, 'In Progress'),
(12, 'NET301', '2024-2025', '2nd', NULL, 'In Progress'),
(12, 'OOP101', '2023-2024', '2nd', 2.75, 'Passed'),

-- Jessica Flores (student 13) - 1st year BSIT (new, no grades yet)
(13, 'ITP101', '2024-2025', '1st', NULL, 'In Progress'),
(13, 'ENG101', '2024-2025', '1st', NULL, 'In Progress'),

-- Daniel Ramos (student 14) - 2nd year BSIS
(14, 'DB101', '2024-2025', '1st', 1.50, 'Passed'),
(14, 'WEB201', '2024-2025', '1st', 1.75, 'Passed'),

-- Patricia Aquino (student 15) - 4th year BSCS (graduated)
(15, 'CAP401', '2023-2024', '2nd', 1.75, 'Passed'),
(15, 'SYS401', '2023-2024', '1st', 1.50, 'Passed');


-- ============================================================
-- VERIFICATION QUERIES (run these to check your setup)
-- ============================================================

-- Check all tables exist
-- SHOW TABLES;

-- Quick counts
-- SELECT 'departments' AS tbl, COUNT(*) AS rows FROM departments
-- UNION ALL SELECT 'faculty', COUNT(*) FROM faculty
-- UNION ALL SELECT 'courses', COUNT(*) FROM courses
-- UNION ALL SELECT 'students', COUNT(*) FROM students
-- UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments;

-- Expected: departments=4, faculty=6, courses=12, students=20, enrollments=45


-- ============================================================
-- SAMPLE QUERIES FOR PRACTICE
-- ============================================================

-- Uncomment and run these to test:

-- 1. All active BSIS students sorted by GPA
-- SELECT student_code, first_name, last_name, gpa 
-- FROM students 
-- WHERE course = 'BSIS' AND status = 'Active' 
-- ORDER BY gpa ASC;

-- 2. Student count per course
-- SELECT course, COUNT(*) AS total, ROUND(AVG(gpa), 2) AS avg_gpa 
-- FROM students 
-- WHERE status = 'Active' 
-- GROUP BY course;

-- 3. Courses with most enrollments
-- SELECT course_code, COUNT(*) AS enrolled 
-- FROM enrollments 
-- GROUP BY course_code 
-- ORDER BY enrolled DESC;

-- 4. Students with no GPA yet (freshmen)
-- SELECT first_name, last_name, course 
-- FROM students 
-- WHERE gpa IS NULL;

-- 5. Enrollment report with student names
-- SELECT s.first_name, s.last_name, e.course_code, e.grade, e.remarks
-- FROM students s
-- JOIN enrollments e ON s.student_id = e.student_id
-- WHERE e.school_year = '2024-2025'
-- ORDER BY s.last_name;

-- ============================================================
-- END OF SETUP SCRIPT
-- ============================================================
-- Database: school_db
-- Tables: 5 (departments, faculty, courses, students, enrollments)
-- Total records: ~87
-- 
-- This dataset supports all exercises from Week 4 through Week 18.
-- ============================================================
