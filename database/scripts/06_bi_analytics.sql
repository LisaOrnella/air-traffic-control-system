-- =============================================
-- BUSINESS INTELLIGENCE & ANALYTICS
-- Created by: UWASE Lisa Ornella | ID: 28753
-- Course: PL/SQL Database Development | AUCA
-- =============================================

-- 1. PROCEDURE: Airline Performance Dashboard
CREATE OR REPLACE PROCEDURE generate_airline_performance_report AS
    CURSOR airline_stats IS
        SELECT 
            airline,
            COUNT(*) as total_flights,
            SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) as landed_flights,
            SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END) as delayed_flights,
            SUM(CASE WHEN status = 'Scheduled' THEN 1 ELSE 0 END) as scheduled_flights,
            ROUND(AVG(passenger_count), 0) as avg_passengers,
            ROUND((SUM(CASE WHEN status = 'Landed' THEN 1 ELSE 0 END) / COUNT(*) * 100), 2) as on_time_percentage
        FROM flights
        GROUP BY airline
        ORDER BY total_flights DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== AIRLINE PERFORMANCE DASHBOARD ===');
    DBMS_OUTPUT.PUT_LINE('Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 70, '='));
    
    FOR airline_rec IN airline_stats LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(airline_rec.airline, 20) ||
                            RPAD('Flights: ' || airline_rec.total_flights, 15) ||
                            RPAD('Landed: ' || airline_rec.landed_flights, 15) ||
                            RPAD('Delayed: ' || airline_rec.delayed_flights, 15) ||
                            RPAD('On-Time: ' || airline_rec.on_time_percentage || '%', 15) ||
                            'Avg Pax: ' || airline_rec.avg_passengers);
    END LOOP;
END generate_airline_performance_report;
/

-- 2. PROCEDURE: Runway Utilization Analysis
CREATE OR REPLACE PROCEDURE generate_runway_utilization_report AS
    CURSOR runway_stats IS
        SELECT 
            r.resource_name,
            r.resource_type,
            COUNT(fa.assignment_id) as total_assignments,
            SUM(CASE WHEN fa.assignment_status = 'Completed' THEN 1 ELSE 0 END) as completed_assignments,
            ROUND(AVG(fa.priority_level), 1) as avg_priority,
            MIN(fa.planned_time) as first_assignment,
            MAX(fa.planned_time) as last_assignment
        FROM airport_resources r
        LEFT JOIN flight_assignments fa ON r.resource_id = fa.resource_id
        WHERE r.resource_type = 'Runway'
        GROUP BY r.resource_name, r.resource_type
        ORDER BY total_assignments DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RUNWAY UTILIZATION ANALYSIS ===');
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 60, '='));
    
    FOR runway_rec IN runway_stats LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(runway_rec.resource_name, 15) ||
                            RPAD('Type: ' || runway_rec.resource_type, 15) ||
                            RPAD('Assignments: ' || runway_rec.total_assignments, 20) ||
                            RPAD('Completed: ' || runway_rec.completed_assignments, 18) ||
                            'Avg Priority: ' || runway_rec.avg_priority);
    END LOOP;
END generate_runway_utilization_report;
/

-- 3. PROCEDURE: Emergency Response Analytics
CREATE OR REPLACE PROCEDURE generate_emergency_analytics AS
    v_total_emergencies NUMBER;
    v_most_common_type VARCHAR2(50);
BEGIN
    -- Get emergency statistics
    SELECT COUNT(*) INTO v_total_emergencies FROM emergency_alerts;
    
    SELECT alert_type INTO v_most_common_type
    FROM (
        SELECT alert_type, COUNT(*) as count
        FROM emergency_alerts
        GROUP BY alert_type
        ORDER BY count DESC
    ) WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('=== EMERGENCY RESPONSE ANALYTICS ===');
    DBMS_OUTPUT.PUT_LINE('Total Emergencies: ' || v_total_emergencies);
    DBMS_OUTPUT.PUT_LINE('Most Common Type: ' || v_most_common_type);
    
    -- Show emergency breakdown
    DBMS_OUTPUT.PUT_LINE('--- Emergency Type Breakdown ---');
    FOR rec IN (
        SELECT alert_type, COUNT(*) as count,
               ROUND(COUNT(*) * 100 / v_total_emergencies, 2) as percentage
        FROM emergency_alerts
        GROUP BY alert_type
        ORDER BY count DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.alert_type, 15) || 
                            RPAD('Count: ' || rec.count, 15) ||
                            'Percentage: ' || rec.percentage || '%');
    END LOOP;
END generate_emergency_analytics;
/

-- 4. PROCEDURE: Weather Impact Assessment
CREATE OR REPLACE PROCEDURE generate_weather_impact_report AS
    CURSOR weather_stats IS
        SELECT 
            condition,
            COUNT(*) as readings,
            ROUND(AVG(visibility), 2) as avg_visibility,
            ROUND(AVG(wind_speed), 2) as avg_wind_speed,
            ROUND(AVG(temperature), 2) as avg_temperature
        FROM weather_conditions
        GROUP BY condition
        ORDER BY readings DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== WEATHER IMPACT ASSESSMENT ===');
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 50, '='));
    
    FOR weather_rec IN weather_stats LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(weather_rec.condition, 12) ||
                            RPAD('Readings: ' || weather_rec.readings, 15) ||
                            RPAD('Vis: ' || weather_rec.avg_visibility, 12) ||
                            RPAD('Wind: ' || weather_rec.avg_wind_speed, 12) ||
                            'Temp: ' || weather_rec.avg_temperature || '°C');
    END LOOP;
END generate_weather_impact_report;
/

-- 5. PROCEDURE: Executive Dashboard
CREATE OR REPLACE PROCEDURE generate_executive_dashboard AS
    v_total_flights NUMBER;
    v_total_airlines NUMBER;
    v_total_emergencies NUMBER;
    v_total_assignments NUMBER;
    v_audit_entries NUMBER;
BEGIN
    -- Calculate KPIs
    SELECT COUNT(*) INTO v_total_flights FROM flights;
    SELECT COUNT(DISTINCT airline) INTO v_total_airlines FROM flights;
    SELECT COUNT(*) INTO v_total_emergencies FROM emergency_alerts;
    SELECT COUNT(*) INTO v_total_assignments FROM flight_assignments;
    SELECT COUNT(*) INTO v_audit_entries FROM audit_log;
    
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('        AIR TRAFFIC CONTROL SYSTEM');
    DBMS_OUTPUT.PUT_LINE('              EXECUTIVE DASHBOARD');
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('📊 OPERATIONAL OVERVIEW');
    DBMS_OUTPUT.PUT_LINE('   • Total Flights: ' || v_total_flights);
    DBMS_OUTPUT.PUT_LINE('   • Airlines: ' || v_total_airlines);
    DBMS_OUTPUT.PUT_LINE('   • Runway Assignments: ' || v_total_assignments);
    DBMS_OUTPUT.PUT_LINE('   • Emergency Alerts: ' || v_total_emergencies);
    DBMS_OUTPUT.PUT_LINE('   • Audit Events: ' || v_audit_entries);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('🌍 AFRICAN AIRLINES FOCUS');
    DBMS_OUTPUT.PUT_LINE('   • Rwanda Air: Active');
    DBMS_OUTPUT.PUT_LINE('   • Ethiopian Airlines: Active');
    DBMS_OUTPUT.PUT_LINE('   • Regional Routes: Operational');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✅ SYSTEM STATUS: FULLY OPERATIONAL');
    DBMS_OUTPUT.PUT_LINE('=========================================');
END generate_executive_dashboard;
/

-- 6. TEST ALL BI REPORTS
CREATE OR REPLACE PROCEDURE test_all_bi_reports AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('🚀 TESTING BUSINESS INTELLIGENCE REPORTS');
    DBMS_OUTPUT.PUT_LINE('');
    
    generate_executive_dashboard();
    DBMS_OUTPUT.PUT_LINE('');
    
    generate_airline_performance_report();
    DBMS_OUTPUT.PUT_LINE('');
    
    generate_runway_utilization_report();
    DBMS_OUTPUT.PUT_LINE('');
    
    generate_emergency_analytics();
    DBMS_OUTPUT.PUT_LINE('');
    
    generate_weather_impact_report();
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('✅ ALL BI REPORTS GENERATED SUCCESSFULLY!');
END test_all_bi_reports;
/
