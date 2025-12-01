-- =============================================
-- SAMPLE BI QUERIES
-- Business Intelligence Examples
-- =============================================

-- 1. DAILY OPERATIONS SUMMARY
SELECT 
    TO_CHAR(TRUNC(scheduled_arrival), 'DD-MON-YYYY') AS operation_date,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) AS landed_flights,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_flights,
    ROUND(SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_percentage,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 0) AS avg_passengers_per_flight
FROM flights
WHERE TRUNC(scheduled_arrival) = TRUNC(SYSDATE)
GROUP BY TRUNC(scheduled_arrival)
ORDER BY operation_date;

-- 2. AIRLINE PERFORMANCE RANKING
WITH airline_stats AS (
    SELECT 
        airline,
        COUNT(*) AS total_flights,
        SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) AS on_time_flights,
        SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
        SUM(passenger_count) AS total_passengers,
        ROUND(AVG(passenger_count), 0) AS avg_passengers
    FROM flights
    GROUP BY airline
)
SELECT 
    airline,
    total_flights,
    on_time_flights,
    delayed_flights,
    ROUND(on_time_flights * 100.0 / total_flights, 2) AS on_time_rate,
    total_passengers,
    avg_passengers,
    RANK() OVER (ORDER BY ROUND(on_time_flights * 100.0 / total_flights, 2) DESC) AS performance_rank,
    CASE 
        WHEN ROUND(on_time_flights * 100.0 / total_flights, 2) >= 90 THEN 'Excellent'
        WHEN ROUND(on_time_flights * 100.0 / total_flights, 2) >= 80 THEN 'Good'
        WHEN ROUND(on_time_flights * 100.0 / total_flights, 2) >= 70 THEN 'Fair'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM airline_stats
ORDER BY performance_rank;

-- 3. RUNWAY UTILIZATION ANALYSIS
SELECT 
    ar.resource_name AS runway,
    TO_CHAR(fa.planned_time, 'HH24') AS hour_of_day,
    COUNT(*) AS assignments_count,
    ROUND(AVG(fa.priority_level), 2) AS avg_priority,
    MIN(TO_CHAR(fa.planned_time, 'HH24:MI')) AS first_assignment,
    MAX(TO_CHAR(fa.planned_time, 'HH24:MI')) AS last_assignment,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM flight_assignments WHERE resource_id = ar.resource_id), 2) AS hour_percentage
FROM flight_assignments fa
JOIN airport_resources ar ON fa.resource_id = ar.resource_id
WHERE ar.resource_type = 'Runway'
GROUP BY ar.resource_name, TO_CHAR(fa.planned_time, 'HH24')
ORDER BY ar.resource_name, hour_of_day;

-- 4. PEAK HOUR IDENTIFICATION
WITH hour_stats AS (
    SELECT 
        EXTRACT(HOUR FROM planned_time) AS hour_of_day,
        COUNT(*) AS flight_count,
        ROUND(AVG(priority_level), 2) AS avg_priority,
        SUM(CASE WHEN assignment_status = 'Completed' THEN 1 ELSE 0 END) AS completed_flights
    FROM flight_assignments
    GROUP BY EXTRACT(HOUR FROM planned_time)
)
SELECT 
    hour_of_day,
    flight_count,
    avg_priority,
    completed_flights,
    ROUND(completed_flights * 100.0 / flight_count, 2) AS completion_rate,
    RANK() OVER (ORDER BY flight_count DESC) AS volume_rank,
    RANK() OVER (ORDER BY avg_priority DESC) AS priority_rank,
    CASE 
        WHEN flight_count > (SELECT AVG(flight_count) * 1.5 FROM hour_stats) THEN 'Peak Hour'
        WHEN flight_count < (SELECT AVG(flight_count) * 0.5 FROM hour_stats) THEN 'Off-Peak'
        ELSE 'Normal'
    END AS traffic_category
FROM hour_stats
ORDER BY hour_of_day;

-- 5. EMERGENCY RESPONSE ANALYTICS
SELECT 
    alert_type,
    COUNT(*) AS total_emergencies,
    SUM(CASE WHEN resolution_status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_emergencies,
    ROUND(AVG(EXTRACT(MINUTE FROM (resolution_time - timestamp))), 2) AS avg_response_minutes,
    MIN(EXTRACT(MINUTE FROM (resolution_time - timestamp))) AS min_response_time,
    MAX(EXTRACT(MINUTE FROM (resolution_time - timestamp))) AS max_response_time,
    ROUND(STDDEV(EXTRACT(MINUTE FROM (resolution_time - timestamp))), 2) AS response_std_dev,
    ROUND(SUM(CASE WHEN resolution_status = 'Resolved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS resolution_rate
FROM emergency_alerts
WHERE resolution_time IS NOT NULL
GROUP BY alert_type
ORDER BY total_emergencies DESC;

-- 6. WEATHER IMPACT CORRELATION
SELECT 
    wc.condition,
    COUNT(f.flight_id) AS total_flights,
    SUM(CASE WHEN f.status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    SUM(CASE WHEN f.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_flights,
    ROUND(SUM(CASE WHEN f.status = 'Delayed' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.flight_id), 2) AS delay_percentage,
    ROUND(AVG(wc.visibility), 2) AS avg_visibility,
    ROUND(AVG(wc.wind_speed), 2) AS avg_wind_speed
FROM flights f
CROSS JOIN LATERAL (
    SELECT * FROM weather_conditions w
    WHERE w.timestamp <= f.scheduled_arrival
    ORDER BY ABS(EXTRACT(EPOCH FROM (w.timestamp - f.scheduled_arrival)))
    FETCH FIRST 1 ROW ONLY
) wc
GROUP BY wc.condition
ORDER BY delay_percentage DESC;

-- 7. RESOURCE OPTIMIZATION REPORT
SELECT 
    ar.resource_type,
    ar.resource_name,
    ar.status,
    ar.capacity,
    COUNT(fa.assignment_id) AS total_assignments,
    ROUND(COUNT(fa.assignment_id) * 100.0 / (SELECT COUNT(*) FROM flight_assignments), 2) AS system_usage_percentage,
    ROUND(COUNT(fa.assignment_id) * 100.0 / ar.capacity, 2) AS capacity_utilization,
    CASE 
        WHEN ar.status = 'Under Maintenance' THEN 'Maintenance Required'
        WHEN COUNT(fa.assignment_id) = 0 THEN 'Underutilized (<10%)'
        WHEN COUNT(fa.assignment_id) > ar.capacity * 0.9 THEN 'Overutilized (>90%)'
        WHEN COUNT(fa.assignment_id) < ar.capacity * 0.3 THEN 'Underutilized (<30%)'
        WHEN COUNT(fa.assignment_id) BETWEEN ar.capacity * 0.3 AND ar.capacity * 0.7 THEN 'Optimally Utilized'
        ELSE 'Highly Utilized'
    END AS utilization_status
FROM airport_resources ar
LEFT JOIN flight_assignments fa ON ar.resource_id = fa.resource_id
GROUP BY ar.resource_type, ar.resource_name, ar.status, ar.capacity
ORDER BY ar.resource_type, capacity_utilization DESC;

-- 8. AFRICAN AIRLINES PERFORMANCE
SELECT 
    airline,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) AS landed_flights,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 0) AS avg_passengers,
    ROUND(SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_rate,
    LISTAGG(DISTINCT origin_airport || '→' || destination_airport, ', ') WITHIN GROUP (ORDER BY origin_airport) AS routes_served
FROM flights
WHERE airline IN ('Rwanda Air', 'Ethiopian Airlines')
GROUP BY airline
ORDER BY on_time_rate DESC;

-- 9. SYSTEM HEALTH MONITORING
SELECT 
    'Operational Flights' AS metric, 
    COUNT(*) AS value,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM flights), 2) AS percentage
FROM flights 
WHERE status IN ('Landed', 'Scheduled', 'Active')
UNION ALL
SELECT 
    'Available Runways', 
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM airport_resources WHERE resource_type = 'Runway'), 2)
FROM airport_resources 
WHERE resource_type = 'Runway' AND status = 'Available'
UNION ALL
SELECT 
    'Active Emergencies', 
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM emergency_alerts), 2)
FROM emergency_alerts 
WHERE resolution_status = 'Active'
UNION ALL
SELECT 
    'System Uptime', 
    99.8,  -- This would come from monitoring system
    99.8
FROM dual
UNION ALL
SELECT 
    'Data Accuracy', 
    99.5,  -- This would come from data quality checks
    99.5
FROM dual
ORDER BY percentage DESC;

-- 10. PREDICTIVE CAPACITY FORECAST
WITH historical_patterns AS (
    SELECT 
        EXTRACT(HOUR FROM planned_time) AS hour_of_day,
        EXTRACT(DOW FROM planned_time) AS day_of_week,
        COUNT(*) AS historical_flights,
        ROUND(AVG(priority_level), 2) AS avg_priority
    FROM flight_assignments
    WHERE planned_time >= SYSDATE - INTERVAL '30' DAY
    GROUP BY EXTRACT(HOUR FROM planned_time), EXTRACT(DOW FROM planned_time)
)
SELECT 
    hour_of_day,
    CASE day_of_week
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS weekday,
    historical_flights AS expected_flights,
    avg_priority,
    ROUND(historical_flights * 1.1, 0) AS forecast_with_buffer,
    CASE 
        WHEN historical_flights > 10 THEN 'High Demand - Add Resources'
        WHEN historical_flights > 5 THEN 'Medium Demand - Monitor'
        ELSE 'Low Demand - Normal Operations'
    END AS recommendation
FROM historical_patterns
WHERE day_of_week = EXTRACT(DOW FROM SYSDATE + 1)  -- Forecast for tomorrow
ORDER BY hour_of_day;
