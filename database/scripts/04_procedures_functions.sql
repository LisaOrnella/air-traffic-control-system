

-- 1. PROCEDURE: Assign Runway with Conflict Detection
CREATE OR REPLACE PROCEDURE assign_runway_to_flight (
    p_flight_number IN VARCHAR2,
    p_planned_time IN TIMESTAMP,
    p_out_assignment_id OUT NUMBER,
    p_out_message OUT VARCHAR2
) AS
    v_flight_id NUMBER;
    v_resource_id NUMBER;
    v_conflict_count NUMBER;
BEGIN
    -- Get flight ID
    SELECT flight_id INTO v_flight_id
    FROM flights 
    WHERE flight_number = p_flight_number;
    
    -- Check for runway conflicts
    SELECT COUNT(*) INTO v_conflict_count
    FROM flight_assignments fa
    JOIN airport_resources ar ON fa.resource_id = ar.resource_id
    WHERE ar.resource_type = 'Runway'
    AND fa.planned_time = p_planned_time
    AND fa.assignment_status != 'Cancelled';
    
    IF v_conflict_count > 0 THEN
        p_out_message := 'ERROR: Runway conflict detected at ' || TO_CHAR(p_planned_time, 'HH24:MI');
        p_out_assignment_id := -1;
        RETURN;
    END IF;
    
    -- Find available runway
    SELECT resource_id INTO v_resource_id
    FROM airport_resources
    WHERE resource_type = 'Runway'
    AND status = 'Available'
    AND ROWNUM = 1;
    
    -- Create assignment
    INSERT INTO flight_assignments (assignment_id, flight_id, resource_id, planned_time, assignment_status)
    VALUES (assignment_seq.NEXTVAL, v_flight_id, v_resource_id, p_planned_time, 'Scheduled')
    RETURNING assignment_id INTO p_out_assignment_id;
    
    p_out_message := 'SUCCESS: Runway assigned to ' || p_flight_number;
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_out_message := 'ERROR: No available runways or flight not found';
        p_out_assignment_id := -1;
    WHEN OTHERS THEN
        p_out_message := 'ERROR: ' || SQLERRM;
        p_out_assignment_id := -1;
        ROLLBACK;
END assign_runway_to_flight;
/

-- 2. FUNCTION: Check Runway Availability
CREATE OR REPLACE FUNCTION check_runway_availability (
    p_check_time IN TIMESTAMP
) RETURN VARCHAR2 AS
    v_available_runways NUMBER;
    v_total_runways NUMBER;
BEGIN
    -- Count available runways at given time
    SELECT COUNT(*) INTO v_available_runways
    FROM airport_resources ar
    WHERE ar.resource_type = 'Runway'
    AND ar.status = 'Available'
    AND NOT EXISTS (
        SELECT 1 FROM flight_assignments fa
        WHERE fa.resource_id = ar.resource_id
        AND fa.planned_time = p_check_time
        AND fa.assignment_status = 'Scheduled'
    );
    
    -- Count total runways
    SELECT COUNT(*) INTO v_total_runways
    FROM airport_resources 
    WHERE resource_type = 'Runway';
    
    RETURN v_available_runways || ' of ' || v_total_runways || ' runways available at ' || TO_CHAR(p_check_time, 'HH24:MI');
END check_runway_availability;
/

-- 3. PROCEDURE: Handle Emergency Landing
CREATE OR REPLACE PROCEDURE handle_emergency_landing (
    p_flight_number IN VARCHAR2,
    p_emergency_type IN VARCHAR2,
    p_out_message OUT VARCHAR2
) AS
    v_flight_id NUMBER;
    v_runway_id NUMBER;
BEGIN
    -- Get flight ID
    SELECT flight_id INTO v_flight_id
    FROM flights WHERE flight_number = p_flight_number;
    
    -- Find available runway
    SELECT resource_id INTO v_runway_id
    FROM airport_resources
    WHERE resource_type = 'Runway'
    AND status = 'Available'
    AND ROWNUM = 1;
    
    -- Create emergency assignment with high priority
    INSERT INTO flight_assignments (assignment_id, flight_id, resource_id, planned_time, assignment_status, priority_level)
    VALUES (assignment_seq.NEXTVAL, v_flight_id, v_runway_id, SYSTIMESTAMP, 'Active', 1);
    
    -- Log emergency
    INSERT INTO emergency_alerts (alert_id, flight_id, alert_type, priority_level, description)
    VALUES (alert_seq.NEXTVAL, v_flight_id, p_emergency_type, 1, 'Emergency landing procedure activated');
    
    -- Update flight status
    UPDATE flights SET status = 'Landed' WHERE flight_id = v_flight_id;
    
    p_out_message := 'EMERGENCY: ' || p_flight_number || ' cleared for immediate landing';
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_out_message := 'ERROR: No runways available for emergency landing';
        ROLLBACK;
    WHEN OTHERS THEN
        p_out_message := 'ERROR: ' || SQLERRM;
        ROLLBACK;
END handle_emergency_landing;
/

-- 4. FUNCTION: Get Flight Information
CREATE OR REPLACE FUNCTION get_flight_info (
    p_flight_number IN VARCHAR2
) RETURN VARCHAR2 AS
    v_airline VARCHAR2(50);
    v_origin VARCHAR2(3);
    v_destination VARCHAR2(3);
    v_status VARCHAR2(20);
BEGIN
    SELECT airline, origin_airport, destination_airport, status
    INTO v_airline, v_origin, v_destination, v_status
    FROM flights
    WHERE flight_number = p_flight_number;
    
    RETURN 'Flight ' || p_flight_number || ' (' || v_airline || ') ' ||
           v_origin || ' → ' || v_destination || ' - Status: ' || v_status;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Flight ' || p_flight_number || ' not found';
    WHEN OTHERS THEN
        RETURN 'Error retrieving flight information';
END get_flight_info;
/

-- 5. PROCEDURE: Generate Daily Report
CREATE OR REPLACE PROCEDURE generate_daily_report AS
    v_total_flights NUMBER;
    v_landed_flights NUMBER;
    v_delayed_flights NUMBER;
    
    CURSOR flight_cursor IS
        SELECT flight_number, airline, status, scheduled_arrival
        FROM flights
        WHERE TRUNC(scheduled_arrival) = TRUNC(SYSDATE)
        ORDER BY scheduled_arrival;
BEGIN
    -- Calculate statistics
    SELECT COUNT(*) INTO v_total_flights FROM flights WHERE TRUNC(scheduled_arrival) = TRUNC(SYSDATE);
    SELECT COUNT(*) INTO v_landed_flights FROM flights WHERE status = 'Landed' AND TRUNC(scheduled_arrival) = TRUNC(SYSDATE);
    SELECT COUNT(*) INTO v_delayed_flights FROM flights WHERE status = 'Delayed' AND TRUNC(scheduled_arrival) = TRUNC(SYSDATE);
    
    -- Display report
    DBMS_OUTPUT.PUT_LINE('=== DAILY AIR TRAFFIC REPORT ===');
    DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Total Flights: ' || v_total_flights);
    DBMS_OUTPUT.PUT_LINE('Landed: ' || v_landed_flights);
    DBMS_OUTPUT.PUT_LINE('Delayed: ' || v_delayed_flights);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Display individual flights
    FOR flight_rec IN flight_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(flight_rec.flight_number, 8) ||
            RPAD(flight_rec.airline, 18) ||
            RPAD(flight_rec.status, 12) ||
            TO_CHAR(flight_rec.scheduled_arrival, 'HH24:MI')
        );
    END LOOP;
    
END generate_daily_report;
/

-- Verification
BEGIN
    DBMS_OUTPUT.PUT_LINE('✅ Procedures and functions created successfully!');
END;
/
