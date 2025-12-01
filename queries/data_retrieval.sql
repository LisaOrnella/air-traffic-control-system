-- =============================================
-- DATA RETRIEVAL QUERIES
-- Air Traffic Control System
-- =============================================

-- 1. GET ALL FLIGHTS WITH DETAILS
SELECT 
    flight_id,
    flight_number,
    airline,
    origin_airport || ' → ' || destination_airport AS route,
    TO_CHAR(scheduled_arrival, 'DD-MON-YYYY HH24:MI') AS scheduled_arrival,
    TO_CHAR(scheduled_departure, 'DD-MON-YYYY HH24:MI') AS scheduled_departure,
    status,
    aircraft_type,
    passenger_count,
    TO_CHAR(created_date, 'DD-MON-YYYY') AS created_date
FROM flights
ORDER BY scheduled_arrival;

-- 2. GET AFRICAN AIRLINES FLIGHTS
SELECT 
    flight_number,
    airline,
    origin_airport || ' to ' || destination_airport AS route,
    status,
    aircraft_type,
    passenger_count,
    TO_CHAR(scheduled_arrival, 'HH24:MI') AS arrival_time
FROM flights
WHERE airline IN ('Rwanda Air', 'Ethiopian Airlines')
ORDER BY airline, flight_number;

-- 3. GET RUNWAY ASSIGNMENTS WITH FLIGHT DETAILS
SELECT 
    fa.assignment_id,
    f.flight_number,
    f.airline,
    ar.resource_name AS runway_gate,
    ar.resource_type,
    TO_CHAR(fa.planned_time, 'DD-MON HH24:MI') AS scheduled_time,
    TO_CHAR(fa.actual_time, 'DD-MON HH24:MI') AS actual_time,
    fa.assignment_status,
    fa.priority_level,
    CASE 
        WHEN fa.actual_time IS NULL THEN 'Pending'
        WHEN fa.actual_time <= fa.planned_time THEN 'On Time'
        ELSE 'Delayed'
    END AS timing_status
FROM flight_assignments fa
JOIN flights f ON fa.flight_id = f.flight_id
JOIN airport_resources ar ON fa.resource_id = ar.resource_id
ORDER BY fa.planned_time;

-- 4. GET AVAILABLE RUNWAYS
SELECT 
    resource_id,
    resource_name,
    resource_type,
    status,
    capacity,
    TO_CHAR(maintenance_schedule, 'DD-MON-YYYY') AS next_maintenance
FROM airport_resources
WHERE resource_type = 'Runway'
AND status = 'Available'
ORDER BY resource_name;

-- 5. GET EMERGENCY ALERTS WITH FLIGHT INFO
SELECT 
    ea.alert_id,
    f.flight_number,
    f.airline,
    ea.alert_type,
    ea.priority_level,
    TO_CHAR(ea.timestamp, 'DD-MON-YYYY HH24:MI:SS') AS alert_time,
    ea.resolution_status,
    ea.resolved_by,
    TO_CHAR(ea.resolution_time, 'DD-MON-YYYY HH24:MI:SS') AS resolved_time,
    ea.description
FROM emergency_alerts ea
JOIN flights f ON ea.flight_id = f.flight_id
ORDER BY ea.timestamp DESC;

-- 6. GET WEATHER CONDITIONS
SELECT 
    weather_id,
    TO_CHAR(timestamp, 'DD-MON-YYYY HH24:MI') AS reading_time,
    condition,
    wind_speed || ' knots ' || wind_direction AS wind_info,
    visibility || ' km' AS visibility,
    temperature || '°C' AS temperature,
    precipitation || ' mm' AS precipitation
FROM weather_conditions
ORDER BY timestamp DESC;

-- 7. GET FLIGHTS BY STATUS
SELECT 
    status,
    COUNT(*) AS flight_count,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 0) AS avg_passengers_per_flight
FROM flights
GROUP BY status
ORDER BY flight_count DESC;

-- 8. GET AIRLINE PERFORMANCE SUMMARY
SELECT 
    airline,
    COUNT(*) AS total_flights,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 0) AS avg_passengers,
    SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) AS landed_flights,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND((SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) / COUNT(*) * 100), 2) AS on_time_percentage
FROM flights
GROUP BY airline
ORDER BY total_flights DESC;

-- 9. GET AUDIT LOG ENTRIES
SELECT 
    log_id,
    table_name,
    operation_type,
    user_name,
    TO_CHAR(timestamp, 'DD-MON HH24:MI:SS') AS operation_time,
    success_flag,
    CASE 
        WHEN error_message IS NOT NULL THEN error_message
        ELSE 'Success'
    END AS result
FROM audit_log
ORDER BY timestamp DESC;

-- 10. GET HOLIDAYS FOR BUSINESS RULES
SELECT 
    holiday_id,
    holiday_name,
    TO_CHAR(holiday_date, 'DD-MON-YYYY') AS holiday_date,
    is_active,
    TO_CHAR(created_date, 'DD-MON-YYYY') AS record_created
FROM holidays
WHERE is_active = 'Y'
ORDER BY holiday_date;

-- 11. GET RUNWAY CONFLICT CHECK
-- Find potential runway conflicts
SELECT 
    fa1.planned_time,
    ar.resource_name,
    f1.flight_number AS flight_1,
    f2.flight_number AS flight_2,
    'CONFLICT DETECTED' AS status
FROM flight_assignments fa1
JOIN flight_assignments fa2 ON fa1.resource_id = fa2.resource_id 
    AND fa1.planned_time = fa2.planned_time 
    AND fa1.assignment_id != fa2.assignment_id
JOIN flights f1 ON fa1.flight_id = f1.flight_id
JOIN flights f2 ON fa2.flight_id = f2.flight_id
JOIN airport_resources ar ON fa1.resource_id = ar.resource_id
WHERE ar.resource_type = 'Runway'
ORDER BY fa1.planned_time;

-- 12. GET WEATHER IMPACT ON FLIGHTS
SELECT 
    f.flight_number,
    f.airline,
    TO_CHAR(f.scheduled_arrival, 'DD-MON HH24:MI') AS scheduled_time,
    wc.condition,
    wc.visibility,
    wc.wind_speed,
    CASE 
        WHEN wc.visibility < 5 OR wc.wind_speed > 20 THEN 'High Impact'
        WHEN wc.visibility < 10 OR wc.wind_speed > 15 THEN 'Medium Impact'
        ELSE 'Low Impact'
    END AS weather_impact
FROM flights f
CROSS JOIN (
    SELECT * FROM weather_conditions 
    ORDER BY timestamp DESC 
    FETCH FIRST 1 ROW ONLY
) wc
WHERE f.status = 'Scheduled'
ORDER BY f.scheduled_arrival;

-- 13. GET RESOURCE UTILIZATION
SELECT 
    ar.resource_type,
    ar.resource_name,
    ar.status,
    COUNT(fa.assignment_id) AS total_assignments,
    TO_CHAR(MIN(fa.planned_time), 'DD-MON') AS first_assignment,
    TO_CHAR(MAX(fa.planned_time), 'DD-MON') AS last_assignment
FROM airport_resources ar
LEFT JOIN flight_assignments fa ON ar.resource_id = fa.resource_id
GROUP BY ar.resource_type, ar.resource_name, ar.status
ORDER BY ar.resource_type, ar.resource_name;

-- 14. GET EMERGENCY RESPONSE TIME
SELECT 
    ea.alert_id,
    f.flight_number,
    ea.alert_type,
    TO_CHAR(ea.timestamp, 'HH24:MI:SS') AS alert_time,
    TO_CHAR(ea.resolution_time, 'HH24:MI:SS') AS resolution_time,
    ROUND((ea.resolution_time - ea.timestamp) * 24 * 60, 2) AS response_time_minutes,
    ea.resolution_status
FROM emergency_alerts ea
JOIN flights f ON ea.flight_id = f.flight_id
WHERE ea.resolution_time IS NOT NULL
ORDER BY response_time_minutes;

-- 15. GET SYSTEM HEALTH CHECK
SELECT 'Total Flights' AS metric, COUNT(*) AS value FROM flights
UNION ALL
SELECT 'Active Assignments', COUNT(*) FROM flight_assignments WHERE assignment_status = 'Active'
UNION ALL
SELECT 'Pending Emergencies', COUNT(*) FROM emergency_alerts WHERE resolution_status = 'Active'
UNION ALL
SELECT 'Available Runways', COUNT(*) FROM airport_resources WHERE resource_type = 'Runway' AND status = 'Available'
UNION ALL
SELECT 'Weather Readings', COUNT(*) FROM weather_conditions
UNION ALL
SELECT 'Audit Entries', COUNT(*) FROM audit_log
ORDER BY value DESC;
