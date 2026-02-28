-- ============================================================================
-- Movie Booking Database System - SQLite Schema
-- ============================================================================
-- Description: Database initialization script for BookMyShow-style movie 
--              ticket booking system
-- Database: SQLite 3
-- Character Set: UTF-8 (default in SQLite)
-- Requirements: 1.1, 9.1, 9.2, 9.3, 9.4
-- ============================================================================

-- Enable foreign key constraints (required for SQLite)
PRAGMA foreign_keys = ON;

-- ============================================================================
-- CORE ENTITY TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: Theater
-- Description: Stores information about cinema locations
-- Requirements: 1.1, 1.2, 1.3
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (theater_name, location, city, state, pincode)
-- 2NF: ✓ Single-attribute primary key (theater_id), no partial dependencies
-- 3NF: ✓ No transitive dependencies (city does not determine state in this schema)
-- BCNF: ✓ Only determinant is theater_id (primary key/candidate key)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Theater (
    theater_id INTEGER PRIMARY KEY AUTOINCREMENT,
    theater_name TEXT NOT NULL,
    location TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT NOT NULL,
    contact_number TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_city ON Theater(city);
CREATE INDEX IF NOT EXISTS idx_theater_name ON Theater(theater_name);

-- ----------------------------------------------------------------------------
-- Table: Movie
-- Description: Stores movie catalog information
-- Requirements: 2.1, 2.4
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Note: Each movie-language-format combination is stored as a separate record
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (title, language, format are single values)
--      Design: Each movie-language-format combo is a separate record (maintains 1NF)
-- 2NF: ✓ Single-attribute primary key (movie_id), no partial dependencies
-- 3NF: ✓ No transitive dependencies (duration does not determine release_date, etc.)
-- BCNF: ✓ Only determinant is movie_id (primary key/candidate key)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Movie (
    movie_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    language TEXT NOT NULL,
    format TEXT NOT NULL,
    rating TEXT,
    duration_minutes INTEGER NOT NULL,
    genre TEXT,
    release_date TEXT,
    description TEXT,
    is_active INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_title ON Movie(title);
CREATE INDEX IF NOT EXISTS idx_language ON Movie(language);

-- ----------------------------------------------------------------------------
-- Table: Hall
-- Description: Stores information about screens/auditoriums within theaters
-- Requirements: 3.1, 3.2, 3.3, 3.4, 10.1, 10.2
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Foreign Keys: theater_id references Theater(theater_id) with CASCADE delete
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (hall_name, seating_capacity, screen_type)
-- 2NF: ✓ Single-attribute primary key (hall_id), no partial dependencies
--      Composite candidate key {theater_id, hall_name} has no partial dependencies
-- 3NF: ✓ No transitive dependencies (seating_capacity does not determine screen_type)
-- BCNF: ✓ Two determinants: hall_id and {theater_id, hall_name} (both candidate keys)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Hall (
    hall_id INTEGER PRIMARY KEY AUTOINCREMENT,
    theater_id INTEGER NOT NULL,
    hall_name TEXT NOT NULL,
    seating_capacity INTEGER NOT NULL,
    screen_type TEXT DEFAULT 'Standard',
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (theater_id) REFERENCES Theater(theater_id) ON DELETE CASCADE,
    UNIQUE (theater_id, hall_name)
);

CREATE INDEX IF NOT EXISTS idx_hall_theater ON Hall(theater_id);

-- ============================================================================
-- SEAT AND SHOW TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: Seat
-- Description: Stores seat configuration for each hall
-- Requirements: 4.1, 4.2, 4.3, 4.4, 10.1, 10.2
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Foreign Keys: hall_id references Hall(hall_id) with CASCADE delete
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (row_label, seat_number, seat_type)
-- 2NF: ✓ Single-attribute primary key (seat_id), no partial dependencies
--      Composite candidate key {hall_id, row_label, seat_number} has no partial deps
-- 3NF: ✓ No transitive dependencies (seat_type does not determine row/number)
-- BCNF: ✓ Two determinants: seat_id and {hall_id, row_label, seat_number} (both candidate keys)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Seat (
    seat_id INTEGER PRIMARY KEY AUTOINCREMENT,
    hall_id INTEGER NOT NULL,
    row_label TEXT NOT NULL,
    seat_number INTEGER NOT NULL,
    seat_type TEXT DEFAULT 'Regular',
    FOREIGN KEY (hall_id) REFERENCES Hall(hall_id) ON DELETE CASCADE,
    UNIQUE (hall_id, row_label, seat_number)
);

CREATE INDEX IF NOT EXISTS idx_seat_hall ON Seat(hall_id);

-- ----------------------------------------------------------------------------
-- Table: Show
-- Description: Stores scheduled screenings of movies
-- Requirements: 5.1, 5.2, 5.3, 5.5, 10.1, 10.2
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Foreign Keys: movie_id references Movie(movie_id) with CASCADE delete
--               hall_id references Hall(hall_id) with CASCADE delete
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (show_date, start_time, end_time, base_price)
-- 2NF: ✓ Single-attribute primary key (show_id), no partial dependencies
--      Composite candidate key {hall_id, show_date, start_time} has no partial deps
-- 3NF: ✓ No transitive dependencies (end_time is derived data for performance)
--      Note: end_time stored for query optimization (acceptable denormalization)
-- BCNF: ✓ Two determinants: show_id and {hall_id, show_date, start_time} (both candidate keys)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Show (
    show_id INTEGER PRIMARY KEY AUTOINCREMENT,
    movie_id INTEGER NOT NULL,
    hall_id INTEGER NOT NULL,
    show_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    base_price REAL NOT NULL,
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id) ON DELETE CASCADE,
    FOREIGN KEY (hall_id) REFERENCES Hall(hall_id) ON DELETE CASCADE,
    UNIQUE (hall_id, show_date, start_time)
);

CREATE INDEX IF NOT EXISTS idx_show_date ON Show(show_date);
CREATE INDEX IF NOT EXISTS idx_show_movie ON Show(movie_id);
CREATE INDEX IF NOT EXISTS idx_show_hall ON Show(hall_id);
CREATE INDEX IF NOT EXISTS idx_date_hall ON Show(show_date, hall_id);

-- ============================================================================
-- BOOKING TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: Booking
-- Description: Stores customer booking information
-- Requirements: 8.1, 8.2, 8.5, 10.1, 10.2
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Foreign Keys: show_id references Show(show_id) with CASCADE delete
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (customer_name, email, phone are single values)
-- 2NF: ✓ Single-attribute primary key (booking_id), no partial dependencies
-- 3NF: ✓ No transitive dependencies (customer_email does not determine name/phone)
--      Note: Customer info stored per booking (no separate Customer table by design)
-- BCNF: ✓ Only determinant is booking_id (primary key/candidate key)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Booking (
    booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    show_id INTEGER NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    booking_time TEXT DEFAULT CURRENT_TIMESTAMP,
    total_amount REAL NOT NULL,
    payment_status TEXT DEFAULT 'Pending',
    booking_status TEXT DEFAULT 'Confirmed',
    FOREIGN KEY (show_id) REFERENCES Show(show_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_booking_show ON Booking(show_id);
CREATE INDEX IF NOT EXISTS idx_customer_email ON Booking(customer_email);
CREATE INDEX IF NOT EXISTS idx_booking_time ON Booking(booking_time);

-- ----------------------------------------------------------------------------
-- Table: Booking_Seat
-- Description: Junction table linking bookings to specific seats
-- Requirements: 7.1, 7.2, 8.2, 8.4, 10.1, 10.2
-- Normalization: 1NF, 2NF, 3NF, BCNF compliant
-- Foreign Keys: booking_id references Booking(booking_id) with CASCADE delete
--               seat_id references Seat(seat_id) with CASCADE delete
-- 
-- Normalization Analysis (Task 12.1):
-- 1NF: ✓ All attributes are atomic (booking_id, seat_id, seat_price)
--      Junction table properly resolves many-to-many relationship
-- 2NF: ✓ Single-attribute primary key (booking_seat_id), no partial dependencies
--      Composite candidate key {booking_id, seat_id} has no partial dependencies
-- 3NF: ✓ No transitive dependencies (seat_price does not determine booking/seat)
--      Note: seat_price stored to preserve historical pricing and support flexible pricing
-- BCNF: ✓ Two determinants: booking_seat_id and {booking_id, seat_id} (both candidate keys)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Booking_Seat (
    booking_seat_id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id INTEGER NOT NULL,
    seat_id INTEGER NOT NULL,
    seat_price REAL NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES Seat(seat_id) ON DELETE CASCADE,
    UNIQUE (booking_id, seat_id)
);

CREATE INDEX IF NOT EXISTS idx_booking_seat_booking ON Booking_Seat(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_seat_seat ON Booking_Seat(seat_id);

-- ============================================================================
-- SAMPLE DATA INSERTION
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Sample Theater Data
-- Requirements: 11.1
-- Description: Insert sample theaters for testing
-- ----------------------------------------------------------------------------
INSERT INTO Theater (theater_name, location, city, state, pincode, contact_number) VALUES
('PVR: Nexus', 'Nexus Mall, Koramangala', 'Bangalore', 'Karnataka', '560095', '080-12345678'),
('INOX: Forum Mall', 'Forum Mall, Whitefield', 'Bangalore', 'Karnataka', '560066', '080-87654321');

-- ----------------------------------------------------------------------------
-- Sample Movie Data
-- Requirements: 2.2, 2.3, 11.2
-- Description: Insert sample movies with varied languages and formats
-- ----------------------------------------------------------------------------
INSERT INTO Movie (title, language, format, rating, duration_minutes, genre, release_date) VALUES
('Dasara', 'Telugu', '2D', 'UA', 158, 'Action/Drama', '2023-03-30'),
('Kisi Ka Bhai Kisi Ki Jaan', 'Hindi', '2D', 'UA', 145, 'Action/Comedy', '2023-04-21'),
('Guardians of the Galaxy Vol. 3', 'English', '3D', 'UA', 150, 'Action/Sci-Fi', '2023-05-05'),
('Ponniyin Selvan II', 'Tamil', '2D', 'UA', 164, 'Historical/Drama', '2023-04-28'),
('The Super Mario Bros Movie', 'English', '2D', 'U', 92, 'Animation/Adventure', '2023-04-05'),
('Guardians of the Galaxy Vol. 3', 'English', 'IMAX', 'UA', 150, 'Action/Sci-Fi', '2023-05-05');

-- ----------------------------------------------------------------------------
-- Sample Hall Data
-- Requirements: 11.3
-- Description: Insert sample halls for each theater
-- ----------------------------------------------------------------------------
INSERT INTO Hall (theater_id, hall_name, seating_capacity, screen_type) VALUES
(1, 'Audi 11', 150, 'Standard'),
(1, 'Playhouse 3K', 200, '3D'),
(1, 'IMAX Screen', 250, 'IMAX'),
(2, 'Screen 1', 180, 'Standard'),
(2, 'Screen 2', 160, '3D');

-- ----------------------------------------------------------------------------
-- Sample Seat Data
-- Requirements: 4.1, 4.4
-- Description: Insert sample seats for Audi 11 (Hall 1)
-- ----------------------------------------------------------------------------
INSERT INTO Seat (hall_id, row_label, seat_number, seat_type) VALUES
(1, 'A', 1, 'Regular'), (1, 'A', 2, 'Regular'), (1, 'A', 3, 'Regular'),
(1, 'B', 1, 'Regular'), (1, 'B', 2, 'Regular'), (1, 'B', 3, 'Regular'),
(1, 'C', 1, 'Premium'), (1, 'C', 2, 'Premium'), (1, 'C', 3, 'Premium');

-- ----------------------------------------------------------------------------
-- Sample Show Data
-- Requirements: 5.4, 11.4
-- Description: Insert sample shows spanning 7 days with calculated end times
-- Note: SQLite uses date('now') instead of CURDATE() and date('now', '+N days')
-- ----------------------------------------------------------------------------
INSERT INTO Show (movie_id, hall_id, show_date, start_time, end_time, base_price) VALUES
-- Today's shows at PVR Nexus
(1, 1, date('now'), '12:15:00', '14:53:00', 250.00),
(2, 1, date('now'), '15:30:00', '17:55:00', 280.00),
(3, 2, date('now'), '16:10:00', '18:40:00', 350.00),
(5, 1, date('now'), '18:30:00', '20:02:00', 220.00),

-- Tomorrow's shows
(1, 1, date('now', '+1 day'), '11:00:00', '13:38:00', 250.00),
(3, 3, date('now', '+1 day'), '14:00:00', '16:30:00', 450.00),
(4, 2, date('now', '+1 day'), '17:00:00', '19:44:00', 300.00),

-- Day 3 shows
(2, 1, date('now', '+2 days'), '13:00:00', '15:25:00', 280.00),
(3, 2, date('now', '+2 days'), '16:00:00', '18:30:00', 350.00),

-- Day 4 shows
(1, 1, date('now', '+3 days'), '10:30:00', '13:08:00', 250.00),
(5, 2, date('now', '+3 days'), '14:00:00', '15:32:00', 220.00),

-- Day 5 shows
(4, 1, date('now', '+4 days'), '12:00:00', '14:44:00', 280.00),
(6, 3, date('now', '+4 days'), '16:00:00', '18:30:00', 450.00),

-- Day 6 shows
(2, 2, date('now', '+5 days'), '11:30:00', '13:55:00', 280.00),
(3, 1, date('now', '+5 days'), '15:00:00', '17:30:00', 350.00),

-- Day 7 shows
(1, 1, date('now', '+6 days'), '13:00:00', '15:38:00', 250.00),
(5, 2, date('now', '+6 days'), '17:00:00', '18:32:00', 220.00),

-- Shows at INOX Forum Mall
(4, 4, date('now'), '12:00:00', '14:44:00', 270.00),
(5, 5, date('now'), '15:30:00', '17:02:00', 240.00),
(2, 4, date('now', '+1 day'), '14:00:00', '16:25:00', 270.00),
(3, 5, date('now', '+2 days'), '18:00:00', '20:30:00', 340.00);

-- ----------------------------------------------------------------------------
-- Sample Booking Data
-- Requirements: 11.5
-- Description: Insert sample bookings with customer details
-- ----------------------------------------------------------------------------
INSERT INTO Booking (show_id, customer_name, customer_email, customer_phone, total_amount, payment_status, booking_status) VALUES
(1, 'Rajesh Kumar', 'rajesh.k@email.com', '9876543210', 500.00, 'Completed', 'Confirmed'),
(3, 'Priya Sharma', 'priya.s@email.com', '9876543211', 700.00, 'Completed', 'Confirmed'),
(5, 'Amit Patel', 'amit.p@email.com', '9876543212', 250.00, 'Completed', 'Confirmed');

-- ----------------------------------------------------------------------------
-- Sample Booking Seat Data
-- Requirements: 8.4, 11.5
-- Description: Link bookings to specific seats
-- ----------------------------------------------------------------------------
INSERT INTO Booking_Seat (booking_id, seat_id, seat_price) VALUES
(1, 1, 250.00),
(1, 2, 250.00),
(2, 7, 350.00),
(2, 8, 350.00),
(3, 4, 250.00);

-- ============================================================================
-- End of Sample Data Insertion
-- ============================================================================

-- ============================================================================
-- P2 QUERY: LIST SHOWS BY THEATER AND DATE (SQLite Version)
-- ============================================================================
-- Description: Retrieves all shows at a specific theater on a selected date
--              with movie details, hall information, and seat availability
-- Requirements: 6.1, 6.2, 6.3, 7.3
-- ============================================================================

-- Query to list all shows at a specific theater on a specific date
-- Parameters to replace:
--   - theater_name: Replace 'PVR: Nexus' with desired theater name
--   - show_date: Replace date('now') with desired date (e.g., '2024-01-15')

SELECT 
    m.title AS movie_title,
    m.language,
    m.format,
    m.rating,
    h.hall_name,
    s.start_time AS show_timing,
    s.base_price,
    (h.seating_capacity - COALESCE(booked_seats.booked_count, 0)) AS available_seats
FROM 
    Show s
    INNER JOIN Movie m ON s.movie_id = m.movie_id
    INNER JOIN Hall h ON s.hall_id = h.hall_id
    INNER JOIN Theater t ON h.theater_id = t.theater_id
    LEFT JOIN (
        SELECT 
            b.show_id,
            COUNT(bs.seat_id) AS booked_count
        FROM 
            Booking b
            INNER JOIN Booking_Seat bs ON b.booking_id = bs.booking_id
        WHERE 
            b.booking_status = 'Confirmed'
        GROUP BY 
            b.show_id
    ) booked_seats ON s.show_id = booked_seats.show_id
WHERE 
    t.theater_name = 'PVR: Nexus' -- Parameter: theater name
    AND s.show_date = date('now') -- Parameter: show date
    AND s.is_active = 1
    AND m.is_active = 1
ORDER BY 
    s.start_time ASC;

-- ============================================================================
-- SQLite-Specific Notes
-- ============================================================================
-- 1. BOOLEAN values: SQLite uses INTEGER (0 = false, 1 = true)
-- 2. Date functions: Use date('now') instead of CURDATE()
-- 3. Date arithmetic: Use date('now', '+1 day') instead of DATE_ADD()
-- 4. No backticks needed: Table name "Show" doesn't need backticks in SQLite
-- 5. AUTOINCREMENT: SQLite uses AUTOINCREMENT instead of AUTO_INCREMENT
-- 6. Data types: TEXT instead of VARCHAR, INTEGER instead of INT, REAL instead of DECIMAL
-- 7. Foreign keys: Must enable with PRAGMA foreign_keys = ON
-- ============================================================================
