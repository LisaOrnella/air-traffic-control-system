-- =============================================
-- ANALYTICS QUERIES
-- =============================================

-- 1. AIRLINE PERFORMANCE ANALYTICS
SELECT 
    airline,
    COUNT(*) AS total_flights,
    ROUND(AVG(passenger_count), 0) AS avg_passengers,
    SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS on_time_rate,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS delay_rate,
    ROUND(SUM(passenger_count) * 100.0 / (SELECT SUM(passenger_count) FROM flights), 2) AS passenger_market_share
FROM flights
GROUP BY airline
ORDER BY on_time_rate DESC;

-- 2. PEAK HOUR ANALYSIS USING WINDOW FUNCTIONS
SELECT 
    EXTRACT(HOUR FROM planned_time) AS hour_of_day,
    COUNT(*) AS flight_count,
    ROUND(AVG(priority_level), 2) AS avg_priority,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS hour_rank,
    LAG(COUNT(*)) OVER (ORDER BY EXTRACT(HOUR FROM planned_time)) AS previous_hour_count,
    ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY EXTRACT(HOUR FROM planned_time))) * 100.0 / 
        NULLIF(LAG(COUNT(*)) OVER (ORDER BY EXTRACT(HOUR FROM planned_time)), 0), 2) AS percent_change
FROM flight_assignments
GROUP BY EXTRACT(HOUR FROM planned_time)
ORDER BY hour_of_day;

-- 3. RUNWAY UTILIZATION TREND
SELECT 
    resource_name,
    resource_type,
    COUNT(*) AS total_assignments,
    SUM(CASE WHEN assignment_status = 'Completed' THEN 1 ELSE 0 END) AS completed_assignments,
    ROUND(SUM(CASE WHEN assignment_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS completion_rate,
    ROUND(AVG(priority_level), 2) AS avg_priority,
    ROUND(MIN(EXTRACT(HOUR FROM planned_time))) AS earliest_hour,
    ROUND(MAX(EXTRACT(HOUR FROM planned_time))) AS latest_hour
FROM flight_assignments fa
JOIN airport_resources ar ON fa.resource_id = ar.resource_id
GROUP BY resource_name, resource_type
ORDER BY total_assignments DESC;

-- 4. WEATHER IMPACT CORRELATION
WITH weather_flights AS (
    SELECT 
        wc.condition,
        wc.visibility,
        wc.wind_speed,
        COUNT(f.flight_id) AS total_flights,
        SUM(CASE WHEN f.status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
        ROUND(SUM(CASE WHEN f.status = 'Delayed' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.flight_id), 2) AS delay_percentage
    FROM flights f
    CROSS JOIN LATERAL (
        SELECT * FROM weather_conditions w
        WHERE w.timestamp <= f.scheduled_arrival
        ORDER BY ABS(EXTRACT(EPOCH FROM (w.timestamp - f.scheduled_arrival)))
        FETCH FIRST 1 ROW ONLY
    ) wc
    GROUP BY wc.condition, wc.visibility, wc.wind_speed
)
SELECT 
    condition,
    visibility_range,
    wind_range,
    total_flights,
    delayed_flights,
    delay_percentage,
    RANK() OVER (ORDER BY delay_percentage DESC) AS delay_rank
FROM (
    SELECT 
        condition,
        CASE 
            WHEN visibility < 2 THEN 'Very Low (<2km)'
            WHEN visibility < 5 THEN 'Low (2-5km)'
            WHEN visibility < 10 THEN 'Medium (5-10km)'
            ELSE 'Good (>10km)'
        END AS visibility_range,
        CASE 
            WHEN wind_speed > 25 THEN 'Very High (>25)'
            WHEN wind_speed > 15 THEN 'High (15-25)'
            WHEN wind_speed > 5 THEN 'Medium (5-15)'
            ELSE 'Low (<5)'
        END AS wind_range,
        total_flights,
        delayed_flights,
        delay_percentage
    FROM weather_flights
) subquery
ORDER BY delay_percentage DESC;

-- 5. EMERGENCY RESPONSE ANALYTICS
SELECT 
    alert_type,
    COUNT(*) AS total_emergencies,
    ROUND(AVG(priority_level), 2) AS avg_priority,
    ROUND(AVG(EXTRACT(MINUTE FROM (resolution_time - timestamp))), 2) AS avg_response_minutes,
    MIN(EXTRACT(MINUTE FROM (resolution_time - timestamp))) AS min_response_time,
    MAX(EXTRACT(MINUTE FROM (resolution_time - timestamp))) AS max_response_time,
    ROUND(STDDEV(EXTRACT(MINUTE FROM (resolution_time - timestamp))), 2) AS response_std_dev
FROM emergency_alerts
WHERE resolution_time IS NOT NULL
GROUP BY alert_type
ORDER BY total_emergencies DESC;

-- 6. PASSENGER LOAD FORECASTING
SELECT 
    EXTRACT(HOUR FROM scheduled_arrival) AS hour_of_day,
    COUNT(*) AS flight_count,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 0) AS avg_passengers_per_flight,
    ROUND(SUM(passenger_count) * 100.0 / (SELECT SUM(passenger_count) FROM flights), 2) AS passenger_percentage,
    ROW_NUMBER() OVER (ORDER BY SUM(passenger_count) DESC) AS passenger_rank
FROM flights
GROUP BY EXTRACT(HOUR FROM scheduled_arrival)
ORDER BY hour_of_day;

-- 7. AIRLINE RELIABILITY INDEX
WITH airline_stats AS (
    SELECT 
        airline,
        COUNT(*) AS total_flights,
        SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) AS on_time_flights,
        SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_flights,
        ROUND(AVG(passenger_count), 0) AS avg_passengers,
        COUNT(DISTINCT aircraft_type) AS fleet_variety
    FROM flights
    GROUP BY airline
)
SELECT 
    airline,
    total_flights,
    on_time_flights,
    delayed_flights,
    ROUND(on_time_flights * 100.0 / total_flights, 2) AS reliability_score,
    avg_passengers,
    fleet_variety,
    NTILE(4) OVER (ORDER BY ROUND(on_time_flights * 100.0 / total_flights, 2) DESC) AS reliability_quartile
FROM airline_stats
ORDER BY reliability_score DESC;

-- 8. RESOURCE OPTIMIZATION ANALYSIS
SELECT 
    ar.resource_type,
    ar.resource_name,
    ar.status,
    ar.capacity,
    COUNT(fa.assignment_id) AS usage_count,
    ROUND(COUNT(fa.assignment_id) * 100.0 / (SELECT COUNT(*) FROM flight_assignments), 2) AS usage_percentage,
    CASE 
        WHEN ar.status = 'Under Maintenance' THEN 'Maintenance Required'
        WHEN COUNT(fa.assignment_id) = 0 THEN 'Underutilized'
        WHEN COUNT(fa.assignment_id) > ar.capacity * 0.8 THEN 'Overutilized'
        ELSE 'Optimally Utilized'
    END AS utilization_status
FROM airport_resources ar
LEFT JOIN flight_assignments fa ON ar.resource_id = fa.resource_id
GROUP BY ar.resource_type, ar.resource_name, ar.status, ar.capacity
ORDER BY ar.resource_type, usage_count DESC;
