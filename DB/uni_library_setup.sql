-- =============================================================
-- UniLibrary Database Setup Script
-- Database Systems Course - Project Workshop (W13)
-- Created for: school_db companion project
-- =============================================================

-- Drop database if exists (clean start)
DROP DATABASE IF EXISTS uni_library;

-- Create database
CREATE DATABASE uni_library
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE uni_library;

-- =============================================================
-- PHASE 1: Parent Tables (No Foreign Keys)
-- =============================================================

CREATE TABLE departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    building VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

CREATE TABLE member_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL UNIQUE,
    max_books TINYINT NOT NULL,
    loan_period_days INT NOT NULL
) ENGINE=InnoDB;

CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    nationality VARCHAR(50)
) ENGINE=InnoDB;

-- =============================================================
-- PHASE 2: Child Tables (With Foreign Keys)
-- =============================================================

CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(13) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    publisher VARCHAR(100),
    publication_year YEAR,
    edition TINYINT DEFAULT 1,
    category_id INT,
    -- Denormalized columns (W12S2 concepts)
    total_copies INT DEFAULT 0,
    available_copies INT DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    type_id INT NOT NULL,
    dept_id INT,
    registration_date DATE DEFAULT (CURDATE()),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    FOREIGN KEY (type_id) REFERENCES member_types(type_id),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    copy_number TINYINT NOT NULL,
    `condition` ENUM('new', 'good', 'fair', 'poor') DEFAULT 'new',
    status ENUM('available', 'borrowed', 'reserved', 'lost') DEFAULT 'available',
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE,
    UNIQUE(book_id, copy_number)
) ENGINE=InnoDB;

CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    author_order TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL DEFAULT (CURDATE()),
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('active', 'returned', 'overdue') DEFAULT 'active',
    -- Denormalized columns for faster reporting
    book_title VARCHAR(200),
    member_name VARCHAR(100),
    FOREIGN KEY (copy_id) REFERENCES copies(copy_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
) ENGINE=InnoDB;

CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    paid_status ENUM('unpaid', 'paid') DEFAULT 'unpaid',
    paid_date DATE NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================
-- PHASE 3: Denormalized Summary Table (W12S2 concepts)
-- =============================================================

CREATE TABLE member_dashboard (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    dept_name VARCHAR(100),
    member_type VARCHAR(20),
    books_borrowed INT DEFAULT 0,
    books_overdue INT DEFAULT 0,
    total_fines DECIMAL(10,2) DEFAULT 0,
    unpaid_fines DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================================
-- PHASE 4: Indexes (W14S1 concepts)
-- =============================================================

CREATE INDEX idx_copies_book ON copies(book_id);
CREATE INDEX idx_copies_status ON copies(status);
CREATE INDEX idx_loans_member ON loans(member_id);
CREATE INDEX idx_loans_copy ON loans(copy_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_loans_due_date ON loans(due_date);
CREATE INDEX idx_members_type ON members(type_id);
CREATE INDEX idx_members_dept ON members(dept_id);
CREATE INDEX idx_members_name ON members(last_name, first_name);
CREATE INDEX idx_books_category ON books(category_id);
CREATE INDEX idx_books_title ON books(title);
CREATE FULLTEXT INDEX ft_books_title ON books(title);

-- =============================================================
-- PHASE 5: Views (W14S1 concepts)
-- =============================================================

-- Public catalog view (hides internal IDs)
CREATE VIEW book_catalog AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    b.publisher,
    b.publication_year,
    b.edition,
    c.category_name,
    b.available_copies,
    b.total_copies,
    GROUP_CONCAT(
        CONCAT(a.first_name, ' ', a.last_name)
        ORDER BY ba.author_order SEPARATOR ', '
    ) AS authors
FROM books b
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
GROUP BY b.book_id;

-- Active loans view
CREATE VIEW active_loans AS
SELECT 
    l.loan_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    mt.type_name AS member_type,
    b.title AS book_title,
    l.loan_date,
    l.due_date,
    CASE 
        WHEN l.due_date < CURDATE() THEN 'OVERDUE'
        ELSE 'Active'
    END AS loan_status,
    CASE 
        WHEN l.due_date < CURDATE() 
        THEN DATEDIFF(CURDATE(), l.due_date) * 5
        ELSE 0
    END AS potential_fine
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN member_types mt ON m.type_id = mt.type_id
JOIN copies cp ON l.copy_id = cp.copy_id
JOIN books b ON cp.book_id = b.book_id
WHERE l.return_date IS NULL;

-- Department statistics view
CREATE VIEW department_stats AS
SELECT 
    d.dept_id,
    d.dept_name,
    COUNT(DISTINCT m.member_id) AS total_members,
    SUM(CASE WHEN mt.type_name = 'student' THEN 1 ELSE 0 END) AS students,
    SUM(CASE WHEN mt.type_name = 'faculty' THEN 1 ELSE 0 END) AS faculty
FROM departments d
LEFT JOIN members m ON d.dept_id = m.dept_id
LEFT JOIN member_types mt ON m.type_id = mt.type_id
GROUP BY d.dept_id;

-- =============================================================
-- PHASE 6: Triggers (W14S2 concepts)
-- =============================================================

-- Trigger: Update available_copies when copy status changes
DELIMITER //
CREATE TRIGGER update_book_copies_after_copy_update
AFTER UPDATE ON copies
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        UPDATE books SET
            available_copies = (
                SELECT COUNT(*) FROM copies
                WHERE book_id = NEW.book_id AND status = 'available'
            )
        WHERE book_id = NEW.book_id;
    END IF;
END //
DELIMITER ;

-- Trigger: Update counts when new copy is inserted
DELIMITER //
CREATE TRIGGER update_book_copies_after_copy_insert
AFTER INSERT ON copies
FOR EACH ROW
BEGIN
    UPDATE books SET
        total_copies = (
            SELECT COUNT(*) FROM copies WHERE book_id = NEW.book_id
        ),
        available_copies = (
            SELECT COUNT(*) FROM copies
            WHERE book_id = NEW.book_id AND status = 'available'
        )
    WHERE book_id = NEW.book_id;
END //
DELIMITER ;

-- Trigger: Cache book_title and member_name in loans
DELIMITER //
CREATE TRIGGER cache_loan_names
BEFORE INSERT ON loans
FOR EACH ROW
BEGIN
    SELECT b.title INTO NEW.book_title
    FROM copies c JOIN books b ON c.book_id = b.book_id
    WHERE c.copy_id = NEW.copy_id;
    
    SELECT CONCAT(first_name, ' ', last_name) INTO NEW.member_name
    FROM members WHERE member_id = NEW.member_id;
END //
DELIMITER ;

-- Trigger: Audit log for fine payments
DELIMITER //
CREATE TRIGGER log_fine_payment
AFTER UPDATE ON fines
FOR EACH ROW
BEGIN
    IF OLD.paid_status = 'unpaid' AND NEW.paid_status = 'paid' THEN
        -- Could insert into audit_log table here
        -- For now, just set the paid_date
        -- (paid_date should be set by the application)
    END IF;
END //
DELIMITER ;

-- =============================================================
-- PHASE 7: Stored Procedures (W14S2 concepts)
-- =============================================================

-- Procedure: Borrow a book
DELIMITER //
CREATE PROCEDURE borrow_book(
    IN p_member_id INT,
    IN p_copy_id INT,
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_member_type_id INT;
    DECLARE v_max_books INT;
    DECLARE v_current_loans INT;
    DECLARE v_copy_status VARCHAR(20);
    DECLARE v_loan_days INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction failed, rolled back';
    END;
    
    -- Check copy availability
    SELECT status INTO v_copy_status FROM copies WHERE copy_id = p_copy_id;
    IF v_copy_status != 'available' THEN
        SET p_result = 'ERROR: This copy is not available';
    ELSE
        -- Check member's borrowing limit
        SELECT m.type_id, mt.max_books, mt.loan_period_days
        INTO v_member_type_id, v_max_books, v_loan_days
        FROM members m
        JOIN member_types mt ON m.type_id = mt.type_id
        WHERE m.member_id = p_member_id;
        
        SELECT COUNT(*) INTO v_current_loans
        FROM loans
        WHERE member_id = p_member_id AND return_date IS NULL;
        
        IF v_current_loans >= v_max_books THEN
            SET p_result = CONCAT('ERROR: Borrowing limit reached (', v_max_books, ' books max)');
        ELSE
            -- Process the loan
            START TRANSACTION;
                INSERT INTO loans (copy_id, member_id, loan_date, due_date)
                VALUES (p_copy_id, p_member_id, CURDATE(), 
                        DATE_ADD(CURDATE(), INTERVAL v_loan_days DAY));
                
                UPDATE copies SET status = 'borrowed'
                WHERE copy_id = p_copy_id;
            COMMIT;
            
            SET p_result = CONCAT('SUCCESS: Book borrowed. Due date: ', 
                           DATE_ADD(CURDATE(), INTERVAL v_loan_days DAY));
        END IF;
    END IF;
END //
DELIMITER ;

-- Procedure: Return a book
DELIMITER //
CREATE PROCEDURE return_book(
    IN p_loan_id INT,
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_copy_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_days_overdue INT;
    DECLARE v_fine_amount DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction failed';
    END;
    
    SELECT copy_id, due_date INTO v_copy_id, v_due_date
    FROM loans WHERE loan_id = p_loan_id AND return_date IS NULL;
    
    IF v_copy_id IS NULL THEN
        SET p_result = 'ERROR: Loan not found or already returned';
    ELSE
        START TRANSACTION;
            -- Mark as returned
            UPDATE loans 
            SET return_date = CURDATE(), status = 'returned'
            WHERE loan_id = p_loan_id;
            
            -- Make copy available again
            UPDATE copies SET status = 'available'
            WHERE copy_id = v_copy_id;
            
            -- Calculate fine if overdue
            SET v_days_overdue = DATEDIFF(CURDATE(), v_due_date);
            IF v_days_overdue > 0 THEN
                SET v_fine_amount = v_days_overdue * 5.00;
                INSERT INTO fines (loan_id, amount)
                VALUES (p_loan_id, v_fine_amount);
                SET p_result = CONCAT('RETURNED with fine: ₱', v_fine_amount, 
                               ' (', v_days_overdue, ' days overdue)');
            ELSE
                SET p_result = 'RETURNED: On time. No fine.';
            END IF;
        COMMIT;
    END IF;
END //
DELIMITER ;

-- Procedure: Refresh member dashboard
DELIMITER //
CREATE PROCEDURE refresh_member_dashboard()
BEGIN
    TRUNCATE TABLE member_dashboard;
    
    INSERT INTO member_dashboard
    SELECT 
        m.member_id,
        CONCAT(m.first_name, ' ', m.last_name),
        d.dept_name,
        mt.type_name,
        COUNT(DISTINCT CASE WHEN l.status = 'active' THEN l.loan_id END),
        COUNT(DISTINCT CASE WHEN l.status = 'overdue' THEN l.loan_id END),
        COALESCE(SUM(f.amount), 0),
        COALESCE(SUM(CASE WHEN f.paid_status = 'unpaid' THEN f.amount END), 0),
        NOW()
    FROM members m
    LEFT JOIN departments d ON m.dept_id = d.dept_id
    LEFT JOIN member_types mt ON m.type_id = mt.type_id
    LEFT JOIN loans l ON m.member_id = l.member_id
    LEFT JOIN fines f ON l.loan_id = f.loan_id
    GROUP BY m.member_id;
END //
DELIMITER ;

-- =============================================================
-- PHASE 8: Sample Data
-- =============================================================

-- Reference data
INSERT INTO departments (dept_name, building) VALUES
('Computer Science', 'Tech Building'),
('Information Systems', 'IT Building'),
('Engineering', 'Engineering Hall'),
('Business Administration', 'Business Center'),
('Education', 'Education Building');

INSERT INTO categories (category_name, description) VALUES
('Programming', 'Software development and coding books'),
('Database', 'Database systems, design, and administration'),
('Networking', 'Computer networks and communications'),
('Mathematics', 'Mathematics and statistics'),
('Business', 'Business management and economics'),
('General Reference', 'Encyclopedias, dictionaries, general knowledge');

INSERT INTO member_types (type_name, max_books, loan_period_days) VALUES
('student', 3, 14),
('faculty', 5, 30);

-- Authors
INSERT INTO authors (first_name, last_name, nationality) VALUES
('Robert', 'Martin', 'American'),
('Abraham', 'Silberschatz', 'Israeli'),
('Thomas', 'Connolly', 'British'),
('Carolyn', 'Begg', 'British'),
('Andrew', 'Tanenbaum', 'American'),
('Martin', 'Fowler', 'British'),
('Ramez', 'Elmasri', 'Egyptian'),
('Shamkant', 'Navathe', 'Indian'),
('Thomas', 'Cormen', 'American'),
('Eric', 'Matthes', 'American');

-- Books
INSERT INTO books (isbn, title, publisher, publication_year, edition, category_id) VALUES
('9780132350884', 'Clean Code', 'Prentice Hall', 2008, 1, 1),
('9780073523323', 'Database System Concepts', 'McGraw-Hill', 2019, 7, 2),
('9780321884930', 'Database Systems: A Practical Approach', 'Pearson', 2015, 6, 2),
('9780132126953', 'Computer Networks', 'Pearson', 2010, 5, 3),
('9780201633610', 'Design Patterns', 'Addison-Wesley', 1994, 1, 1),
('9780133970777', 'Fundamentals of Database Systems', 'Pearson', 2015, 7, 2),
('9780262033848', 'Introduction to Algorithms', 'MIT Press', 2009, 3, 4),
('9781593279288', 'Python Crash Course', 'No Starch Press', 2019, 2, 1);

-- Book-Author relationships
INSERT INTO book_authors (book_id, author_id, author_order) VALUES
(1, 1, 1),   -- Clean Code by Robert Martin
(2, 2, 1),   -- DB System Concepts by Silberschatz
(3, 3, 1),   -- DB Systems by Connolly
(3, 4, 2),   -- DB Systems by Begg (co-author)
(4, 5, 1),   -- Computer Networks by Tanenbaum
(5, 6, 1),   -- Design Patterns by Fowler
(6, 7, 1),   -- Fundamentals of DB by Elmasri
(6, 8, 2),   -- Fundamentals of DB by Navathe (co-author)
(7, 9, 1),   -- Intro to Algorithms by Cormen
(8, 10, 1);  -- Python Crash Course by Matthes

-- Copies (multiple per book)
INSERT INTO copies (book_id, copy_number, `condition`, status) VALUES
(1, 1, 'good', 'available'),
(1, 2, 'new', 'borrowed'),
(1, 3, 'fair', 'available'),
(2, 1, 'good', 'available'),
(2, 2, 'fair', 'borrowed'),
(2, 3, 'new', 'available'),
(3, 1, 'new', 'available'),
(3, 2, 'good', 'borrowed'),
(4, 1, 'fair', 'available'),
(4, 2, 'good', 'borrowed'),
(5, 1, 'good', 'available'),
(5, 2, 'fair', 'available'),
(6, 1, 'new', 'available'),
(6, 2, 'good', 'available'),
(7, 1, 'good', 'available'),
(8, 1, 'new', 'borrowed'),
(8, 2, 'new', 'available');

-- Members
INSERT INTO members (first_name, last_name, email, phone, type_id, dept_id) VALUES
('Juan', 'Dela Cruz', 'juan@uni.edu.ph', '09171234567', 1, 1),
('Maria', 'Santos', 'maria@uni.edu.ph', '09181234567', 1, 2),
('Pedro', 'Reyes', 'pedro@uni.edu.ph', '09191234567', 1, 1),
('Ana', 'Garcia', 'ana.garcia@uni.edu.ph', '09201234567', 2, 2),
('Carlos', 'Ramos', 'carlos.ramos@uni.edu.ph', '09211234567', 2, 3),
('Sofia', 'Cruz', 'sofia@uni.edu.ph', '09221234567', 1, 4),
('Miguel', 'Torres', 'miguel@uni.edu.ph', '09231234567', 1, 1),
('Isabella', 'Flores', 'isabella@uni.edu.ph', '09241234567', 1, 3),
('Luis', 'Rivera', 'luis.rivera@uni.edu.ph', '09251234567', 2, 5),
('Carmen', 'Lopez', 'carmen@uni.edu.ph', '09261234567', 1, 2);

-- Loans (mix of active, returned, overdue)
INSERT INTO loans (copy_id, member_id, loan_date, due_date, return_date, status) VALUES
(2, 1, '2024-01-10', '2024-01-24', NULL, 'active'),
(5, 2, '2024-01-05', '2024-01-19', '2024-01-18', 'returned'),
(8, 3, '2024-01-01', '2024-01-15', NULL, 'overdue'),
(10, 4, '2024-01-12', '2024-02-11', NULL, 'active'),
(16, 7, '2024-01-08', '2024-01-22', '2024-01-20', 'returned'),
(5, 6, '2024-01-15', '2024-01-29', NULL, 'overdue'),
(2, 5, '2024-01-03', '2024-02-02', '2024-01-28', 'returned');

-- Fines
INSERT INTO fines (loan_id, amount, paid_status, paid_date) VALUES
(3, 75.00, 'unpaid', NULL),       -- Pedro: 15 days overdue
(6, 50.00, 'unpaid', NULL),       -- Sofia: 10 days overdue  
(7, 0.00, 'paid', '2024-01-28');  -- Carlos: paid on return

-- Update the fine for loan 7 to a valid amount
UPDATE fines SET amount = 5.00 WHERE loan_id = 7;

-- =============================================================
-- PHASE 9: Populate Denormalized Data
-- =============================================================

-- Update book copy counts (triggers handle future changes)
UPDATE books b SET
    total_copies = (SELECT COUNT(*) FROM copies c WHERE c.book_id = b.book_id),
    available_copies = (SELECT COUNT(*) FROM copies c WHERE c.book_id = b.book_id AND c.status = 'available');

-- Populate member dashboard
CALL refresh_member_dashboard();

-- =============================================================
-- VERIFICATION
-- =============================================================

-- Show all tables
SHOW TABLES;

-- Quick data verification
SELECT 'departments' AS tbl, COUNT(*) AS rows FROM departments
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'member_types', COUNT(*) FROM member_types
UNION ALL SELECT 'authors', COUNT(*) FROM authors
UNION ALL SELECT 'books', COUNT(*) FROM books
UNION ALL SELECT 'book_authors', COUNT(*) FROM book_authors
UNION ALL SELECT 'copies', COUNT(*) FROM copies
UNION ALL SELECT 'members', COUNT(*) FROM members
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'fines', COUNT(*) FROM fines
UNION ALL SELECT 'member_dashboard', COUNT(*) FROM member_dashboard;

-- Test the book catalog view
SELECT * FROM book_catalog;

-- Test the active loans view
SELECT * FROM active_loans;

-- =============================================================
-- END OF SETUP
-- =============================================================
-- To use: mysql -u root -p < uni_library_setup.sql
-- Or import via phpMyAdmin: Import tab → Choose this file
-- =============================================================