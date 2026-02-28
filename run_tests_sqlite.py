#!/usr/bin/env python3
"""
Movie Booking Database System - SQLite Test Script
===================================================
Test and setup script for the SQLite movie booking database.

Usage:
    python run_tests_sqlite.py --setup      # Setup database with sample data
    python run_tests_sqlite.py --verify     # Verify setup
    python run_tests_sqlite.py --test-p2    # Test P2 query
    python run_tests_sqlite.py --test       # Run all tests
    python run_tests_sqlite.py --teardown   # Remove database file
"""

import sqlite3
import os
import sys
import argparse

DB_FILE = 'movie_booking_system.db'
SCHEMA_FILE = 'movie_booking_schema_sqlite.sql'


def get_connection():
    """Create and return a database connection with foreign keys enabled."""
    conn = sqlite3.connect(DB_FILE)
    conn.execute('PRAGMA foreign_keys = ON;')
    return conn


def setup_database():
    """Initialize the database by executing the schema SQL file."""
    if not os.path.exists(SCHEMA_FILE):
        print(f"ERROR: Schema file '{SCHEMA_FILE}' not found.")
        sys.exit(1)

    print(f"Setting up database from '{SCHEMA_FILE}'...")
    with open(SCHEMA_FILE, 'r') as f:
        schema_sql = f.read()

    conn = get_connection()
    try:
        conn.executescript(schema_sql)
        conn.commit()
        print("Database setup complete.")
    finally:
        conn.close()


def verify_setup():
    """Verify the database tables and sample data counts."""
    if not os.path.exists(DB_FILE):
        print(f"ERROR: Database file '{DB_FILE}' not found. Run --setup first.")
        sys.exit(1)

    expected = {
        'Theater': 2,
        'Movie': 6,
        'Hall': 5,
        'Seat': 9,
        'Booking': 3,
    }

    conn = get_connection()
    all_ok = True
    try:
        print("Verifying database setup...")
        for table, min_count in expected.items():
            cursor = conn.execute(f'SELECT COUNT(*) FROM {table}')
            count = cursor.fetchone()[0]
            status = 'OK' if count >= min_count else 'FAIL'
            if status == 'FAIL':
                all_ok = False
            print(f"  {table}: {count} rows (expected >= {min_count}) [{status}]")

        cursor = conn.execute('SELECT COUNT(*) FROM Show')
        show_count = cursor.fetchone()[0]
        status = 'OK' if show_count >= 20 else 'WARN'
        print(f"  Show: {show_count} rows (expected >= 20) [{status}]")

    finally:
        conn.close()

    if all_ok:
        print("Verification passed.")
    else:
        print("Verification failed. Some tables have fewer rows than expected.")
    return all_ok


def test_p2_query():
    """Run the P2 query and display results for today's shows at PVR: Nexus."""
    if not os.path.exists(DB_FILE):
        print(f"ERROR: Database file '{DB_FILE}' not found. Run --setup first.")
        sys.exit(1)

    query = """
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
        t.theater_name = 'PVR: Nexus'
        AND s.show_date = date('now')
        AND s.is_active = 1
        AND m.is_active = 1
    ORDER BY 
        s.start_time ASC;
    """

    conn = get_connection()
    try:
        print("Running P2 query: Shows at 'PVR: Nexus' for today...")
        cursor = conn.execute(query)
        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]

        if not rows:
            print("  No shows found for today. (This is expected if today has no scheduled shows.)")
        else:
            col_widths = [max(len(col), max((len(str(row[i])) for row in rows), default=0))
                          for i, col in enumerate(columns)]
            header = '  ' + '  '.join(col.ljust(col_widths[i]) for i, col in enumerate(columns))
            separator = '  ' + '  '.join('-' * w for w in col_widths)
            print(header)
            print(separator)
            for row in rows:
                print('  ' + '  '.join(str(val).ljust(col_widths[i]) for i, val in enumerate(row)))
            print(f"\n  {len(rows)} show(s) found.")

        print("P2 query test passed.")
        return True
    finally:
        conn.close()


def run_all_tests():
    """Run all tests: verify setup and test P2 query."""
    print("=" * 60)
    print("Running all tests")
    print("=" * 60)
    ok = verify_setup()
    print()
    ok = test_p2_query() and ok
    print()
    if ok:
        print("All tests passed.")
    else:
        print("Some tests failed.")
    return ok


def teardown_database():
    """Remove the SQLite database file."""
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)
        print(f"Database file '{DB_FILE}' removed.")
    else:
        print(f"Database file '{DB_FILE}' not found; nothing to remove.")


def main():
    parser = argparse.ArgumentParser(
        description='Movie Booking Database - SQLite test and setup script'
    )
    parser.add_argument('--setup', action='store_true', help='Setup database with sample data')
    parser.add_argument('--verify', action='store_true', help='Verify database setup')
    parser.add_argument('--test-p2', action='store_true', help='Test the P2 query')
    parser.add_argument('--test', action='store_true', help='Run all tests')
    parser.add_argument('--teardown', action='store_true', help='Remove the database file')

    args = parser.parse_args()

    if not any(vars(args).values()):
        parser.print_help()
        sys.exit(0)

    if args.setup:
        setup_database()
    if args.verify:
        verify_setup()
    if args.test_p2:
        test_p2_query()
    if args.test:
        success = run_all_tests()
        sys.exit(0 if success else 1)
    if args.teardown:
        teardown_database()


if __name__ == '__main__':
    main()
