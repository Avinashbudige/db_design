-- ============================================================================
-- P2 Query: List All Shows at a Theater on a Specific Date (SQLite Version)
-- ============================================================================
-- Description: Retrieves all shows at a specific theater on a selected date
--              with movie details, hall information, and seat availability
-- Requirements: 6.1, 6.2, 6.3, 7.3
-- ============================================================================
-- Usage:
--   sqlite3 movie_booking_system.db
--   .read p2_query_shows_by_theater_date_sqlite.sql
--
-- Parameters to customize:
--   - theater_name: Replace 'PVR: Nexus' with desired theater name
--   - show_date:    Replace date('now') with specific date e.g., '2024-01-15'
-- ============================================================================

.headers on
.mode column

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
    t.theater_name = 'PVR: Nexus'  -- Parameter: change theater name here
    AND s.show_date = date('now')   -- Parameter: change date here (e.g., '2024-01-15')
    AND s.is_active = 1
    AND m.is_active = 1
ORDER BY 
    s.start_time ASC;
