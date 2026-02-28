# Movie Booking Database System (SQLite Version)

A normalized SQLite database system for a BookMyShow-style movie ticket booking platform. This system manages theaters, movies, showtimes, and bookings with complete referential integrity and optimized query performance.

## Features

- **Normalized Schema**: Complies with BCNF (Boyce-Codd Normal Form)
- **Referential Integrity**: Foreign key constraints with cascade delete
- **Optimized Queries**: Strategic indexes for fast query performance
- **Sample Data**: Pre-populated with realistic test data
- **Seat Management**: Track seat availability and bookings per show
- **Multi-format Support**: Movies in multiple languages and formats (2D, 3D, IMAX)
- **Lightweight**: Uses SQLite - no server installation required

## Requirements

- **Python**: Version 3.7 or higher (includes sqlite3 module)
- **SQLite**: Version 3.x (built-in with Python)

## Quick Start

### 1. Verify Python Installation

```bash
# Check Python version
python --version

# Or on some systems
python3 --version
```

### 2. Initialize the Database

**Option A: Using Python Test Script (Recommended)**

```bash
# Setup database with sample data
python run_tests_sqlite.py --setup

# Verify setup
python run_tests_sqlite.py --verify

# Test P2 query
python run_tests_sqlite.py --test-p2
```

**Option B: Using SQLite Command Line**

```bash
# Create database and execute schema
sqlite3 movie_booking_system.db < movie_booking_schema_sqlite.sql

# Or interactively
sqlite3 movie_booking_system.db
.read movie_booking_schema_sqlite.sql
.exit
```

**Option C: Using Python Directly**

```python
import sqlite3

# Connect to database (creates if doesn't exist)
conn = sqlite3.connect('movie_booking_system.db')

# Read and execute schema file
with open('movie_booking_schema_sqlite.sql', 'r') as f:
    conn.executescript(f.read())

conn.close()
```

### 3. Verify Installation

```bash
# Using Python script
python run_tests_sqlite.py --verify

# Or using SQLite CLI
sqlite3 movie_booking_system.db
```

```sql
-- Check tables
.tables

-- Verify sample data
SELECT COUNT(*) FROM Theater;  -- Should return 2
SELECT COUNT(*) FROM Movie;    -- Should return 6
SELECT COUNT(*) FROM Hall;     -- Should return 5
SELECT COUNT(*) FROM Show;     -- Should return 20+
SELECT COUNT(*) FROM Booking;  -- Should return 3
```

## Database Schema

### Tables

1. **Theater** - Cinema locations with address and contact details
2. **Hall** - Screens/auditoriums within theaters
3. **Movie** - Movie catalog with language, format, and metadata
4. **Show** - Scheduled screenings with date, time, and pricing
5. **Seat** - Seat configuration for each hall
6. **Booking** - Customer booking records
7. **Booking_Seat** - Junction table linking bookings to seats

### Entity Relationships

```
Theater (1) ──→ (N) Hall
Hall (1) ──→ (N) Seat
Hall (1) ──→ (N) Show
Movie (1) ──→ (N) Show
Show (1) ──→ (N) Booking_Seat
Booking (1) ──→ (N) Booking_Seat
Seat (1) ──→ (N) Booking_Seat
```

## Usage Examples

### Query 1: List All Shows at a Theater on a Specific Date (P2 Query)

This is the primary query for retrieving shows with seat availability.

```sql
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
    t.theater_name = 'PVR: Nexus'     -- Change theater name here
    AND s.show_date = date('now')      -- Change date here (e.g., '2024-01-15')
    AND s.is_active = 1
    AND m.is_active = 1
ORDER BY 
    s.start_time ASC;
```

**Parameters to customize:**
- `theater_name`: Replace `'PVR: Nexus'` with desired theater
- `show_date`: Replace `date('now')` with specific date like `'2024-01-15'` or `date('now', '+1 day')`

### Query 2: Get All Theaters

```sql
SELECT theater_name, location, city, contact_number
FROM Theater
WHERE is_active = 1;
```

### Query 3: Get All Movies Currently Showing

```sql
SELECT DISTINCT m.title, m.language, m.format, m.rating, m.genre
FROM Movie m
INNER JOIN Show s ON m.movie_id = s.movie_id
WHERE m.is_active = 1
  AND s.show_date >= date('now')
ORDER BY m.title;
```

### Query 4: Check Seat Availability for a Specific Show

```sql
SELECT 
    h.seating_capacity,
    COUNT(bs.seat_id) AS booked_seats,
    (h.seating_capacity - COUNT(bs.seat_id)) AS available_seats
FROM 
    Show s
    INNER JOIN Hall h ON s.hall_id = h.hall_id
    LEFT JOIN Booking b ON s.show_id = b.show_id AND b.booking_status = 'Confirmed'
    LEFT JOIN Booking_Seat bs ON b.booking_id = bs.booking_id
WHERE 
    s.show_id = 1  -- Replace with desired show_id
GROUP BY 
    h.seating_capacity;
```

### Query 5: Get Customer Booking History

```sql
SELECT 
    b.booking_id,
    m.title AS movie_title,
    t.theater_name,
    h.hall_name,
    s.show_date,
    s.start_time,
    b.total_amount,
    b.booking_status,
    COUNT(bs.seat_id) AS seats_booked
FROM 
    Booking b
    INNER JOIN Show s ON b.show_id = s.show_id
    INNER JOIN Movie m ON s.movie_id = m.movie_id
    INNER JOIN Hall h ON s.hall_id = h.hall_id
    INNER JOIN Theater t ON h.theater_id = t.theater_id
    INNER JOIN Booking_Seat bs ON b.booking_id = bs.booking_id
WHERE 
    b.customer_email = 'rajesh.k@email.com'  -- Replace with customer email
GROUP BY 
    b.booking_id, m.title, t.theater_name, h.hall_name, s.show_date, s.start_time, b.total_amount, b.booking_status
ORDER BY 
    b.booking_time DESC;
```

## Sample Data

The database includes pre-populated sample data:

### Theaters
- **PVR: Nexus** - Koramangala, Bangalore (3 halls)
- **INOX: Forum Mall** - Whitefield, Bangalore (2 halls)

### Movies
- Dasara (Telugu, 2D)
- Kisi Ka Bhai Kisi Ki Jaan (Hindi, 2D)
- Guardians of the Galaxy Vol. 3 (English, 3D & IMAX)
- Ponniyin Selvan II (Tamil, 2D)
- The Super Mario Bros Movie (English, 2D)

### Shows
- 20+ shows spanning 7 days
- Multiple showtimes per day
- Varied pricing (₹220 - ₹450)

### Bookings
- 3 sample bookings with confirmed status
- Demonstrates single and multiple seat bookings

## Testing

### Using Python Test Script

```bash
# Run all tests
python run_tests_sqlite.py --test

# Individual operations
python run_tests_sqlite.py --setup      # Setup database
python run_tests_sqlite.py --verify     # Verify setup
python run_tests_sqlite.py --test-p2    # Test P2 query
python run_tests_sqlite.py --teardown   # Remove database
```

### Using SQLite CLI

```bash
# Open database
sqlite3 movie_booking_system.db

# Enable headers and column mode for better output
.headers on
.mode column

# Test P2 query
.read p2_query_shows_by_theater_date_sqlite.sql
```

## SQLite-Specific Features

### Date Functions

SQLite uses different date functions than MySQL:

```sql
-- Current date
date('now')

-- Tomorrow
date('now', '+1 day')

-- Specific date
'2024-01-15'

-- Date arithmetic
date('now', '+7 days')
date('now', '-1 month')
```

### Boolean Values

SQLite uses INTEGER for boolean values:
- `1` = TRUE
- `0` = FALSE

```sql
-- Check active theaters
SELECT * FROM Theater WHERE is_active = 1;
```

### Data Types

SQLite uses simplified data types:
- `INTEGER` - for whole numbers (replaces INT, BIGINT, etc.)
- `REAL` - for floating point (replaces DECIMAL, FLOAT, etc.)
- `TEXT` - for strings (replaces VARCHAR, CHAR, etc.)
- `BLOB` - for binary data

### Foreign Keys

Foreign keys must be explicitly enabled:

```sql
PRAGMA foreign_keys = ON;
```

This is automatically done in the schema file and test scripts.

## Database Maintenance

### Reset Database

```bash
# Using Python script
python run_tests_sqlite.py --teardown
python run_tests_sqlite.py --setup

# Or manually
rm movie_booking_system.db
sqlite3 movie_booking_system.db < movie_booking_schema_sqlite.sql
```

### Backup Database

```bash
# Simple file copy
cp movie_booking_system.db movie_booking_system_backup.db

# Or using SQLite backup command
sqlite3 movie_booking_system.db ".backup movie_booking_system_backup.db"
```

### Restore from Backup

```bash
# Simple file copy
cp movie_booking_system_backup.db movie_booking_system.db
```

### Database File Location

The SQLite database is stored in a single file: `movie_booking_system.db`

You can move this file anywhere and open it with:

```bash
sqlite3 /path/to/movie_booking_system.db
```

## Useful SQLite Commands

```sql
-- Show all tables
.tables

-- Show table schema
.schema Theater

-- Show indexes
.indexes

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- Check foreign key constraints
PRAGMA foreign_key_check;

-- Show database info
.dbinfo

-- Export to CSV
.mode csv
.output theaters.csv
SELECT * FROM Theater;
.output stdout

-- Import from CSV
.mode csv
.import data.csv Theater

-- Better output formatting
.headers on
.mode column
.width 20 10 10 15
```

## Architecture & Design

### Normalization

The database schema follows normalization principles:

- **1NF (First Normal Form)**: All attributes contain atomic values
- **2NF (Second Normal Form)**: No partial dependencies
- **3NF (Third Normal Form)**: No transitive dependencies
- **BCNF (Boyce-Codd Normal Form)**: Every determinant is a candidate key

### Indexes

Strategic indexes for optimal query performance:

- `Theater`: Indexed on `city` and `theater_name`
- `Movie`: Indexed on `title` and `language`
- `Show`: Composite index on `(show_date, hall_id)` for P2 query optimization
- `Booking`: Indexed on `show_id`, `customer_email`, and `booking_time`

### Foreign Key Constraints

All relationships use `ON DELETE CASCADE` to maintain referential integrity:

- Deleting a Theater automatically deletes its Halls, Shows, and Bookings
- Deleting a Show automatically deletes its Bookings
- Deleting a Booking automatically deletes its Booking_Seat records

## Troubleshooting

### Issue: "no such table: Theater"

**Solution**: The database wasn't created. Run the setup:

```bash
python run_tests_sqlite.py --setup
```

### Issue: "FOREIGN KEY constraint failed"

**Solution**: Foreign keys may not be enabled. Enable them:

```sql
PRAGMA foreign_keys = ON;
```

### Issue: Query returns no results

**Solution**: Check if sample data was loaded and verify date parameters:

```sql
-- Check if shows exist
SELECT COUNT(*) FROM Show;

-- Check show dates
SELECT DISTINCT show_date FROM Show ORDER BY show_date;

-- Use a date that has shows
SELECT * FROM Show WHERE show_date = date('now');
```

### Issue: "database is locked"

**Solution**: Another process has the database open. Close all connections:

```bash
# Find processes using the database (Linux/Mac)
lsof movie_booking_system.db

# Or just remove the lock file
rm movie_booking_system.db-journal
```

## Project Structure

```
.
├── movie_booking_schema_sqlite.sql    # SQLite schema file
├── p2_query_shows_by_theater_date_sqlite.sql  # Standalone P2 query
├── run_tests_sqlite.py                # Python test script
├── README_SQLITE.md                   # This file
├── movie_booking_system.db            # SQLite database file (created after setup)
└── .kiro/specs/movie-booking-database/
    ├── requirements.md                # System requirements
    ├── design.md                      # Database design document
    └── tasks.md                       # Implementation tasks
```

## Advantages of SQLite

1. **No Server Required**: Runs directly from a file
2. **Zero Configuration**: No setup or administration needed
3. **Portable**: Single file can be copied anywhere
4. **Fast**: Excellent performance for small to medium datasets
5. **Reliable**: ACID-compliant transactions
6. **Cross-Platform**: Works on Windows, Mac, Linux
7. **Built-in**: Included with Python, no installation needed

## Limitations

1. **Concurrent Writes**: Limited support for multiple simultaneous writers
2. **Network Access**: Not designed for client-server architecture
3. **Database Size**: Best for databases under 1TB
4. **User Management**: No built-in user authentication

For production systems with high concurrency or large scale, consider MySQL or PostgreSQL.

## Requirements Validation

This implementation satisfies all 11 requirements:

- ✅ **Requirement 1**: Theater Management
- ✅ **Requirement 2**: Movie Catalog Management
- ✅ **Requirement 3**: Hall/Screen Management
- ✅ **Requirement 4**: Seat Configuration
- ✅ **Requirement 5**: Show Scheduling
- ✅ **Requirement 6**: Date-Based Show Retrieval (P2 Query)
- ✅ **Requirement 7**: Seat Availability Tracking
- ✅ **Requirement 8**: Booking Management
- ✅ **Requirement 9**: Database Normalization (BCNF)
- ✅ **Requirement 10**: Referential Integrity
- ✅ **Requirement 11**: Sample Data Population

## License

This is an educational project for database design and implementation.

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the SQLite documentation: https://www.sqlite.org/docs.html
3. Consult the design document in `.kiro/specs/movie-booking-database/design.md`
