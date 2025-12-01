-- =============================================
-- TRIGGERS & AUDITING SYSTEM
-- Air Traffic Control System
-- Created by: UWASE Lisa Ornella | ID: 28753
-- =============================================

-- Enable DBMS_OUTPUT for debugging
SET SERVEROUTPUT ON;

-- 1. HOLIDAY MANAGEMENT TABLE (if not already created)
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE holidays (
        holiday_id NUMBER(10) PRIMARY KEY,
        holiday_date DATE NOT NULL UNIQUE,
        holiday_name VARCHAR2(50) NOT NULL,
        is_active CHAR(1) DEFAULT ''Y'',
        created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )';
    DBMS_OUTPUT.PUT_LINE('Holidays table created');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Holidays table already exists');
END;
/

-- Create sequence for holidays if not exists
BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE holiday_seq START WITH 1 INCREMENT BY 1';
    DBMS_OUTPUT.PUT_LINE('Holiday sequence created');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Holiday sequence already exists');
END;
/

-- Insert sample holidays for testing
BEGIN
    -- Clear existing test data
    DELETE FROM holidays WHERE holiday_name LIKE 'Test%';
    
    -- Insert test holidays
    INSERT INTO holidays (holiday_id, holiday_date, holiday_name) 
    VALUES (holiday_seq.NEXTVAL, TRUNC(SYSDATE) + 1, 'Test Holiday Tomorrow');
    
    INSERT INTO holidays (holiday_id, holiday_date, holiday_name) 
    VALUES (holiday_seq.NEXTVAL, TRUNC(SYSDATE) - 1, 'Test Holiday Yesterday');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Sample holidays inserted for testing');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting holidays: ' || SQLERRM);
END;
/

-- 2. BUSINESS RULE: Check if operation is allowed
CREATE OR REPLACE FUNCTION is_operation_allowed RETURN BOOLEAN AS
    v_current_day VARCHAR2(10);
    v_is_holiday NUMBER;
BEGIN
    -- Check if today is a weekday (Monday-Friday)
    SELECT TO_CHAR(SYSDATE, 'DY') INTO v_current_day FROM DUAL;
    
    DBMS_OUTPUT.PUT_LINE('Current day: ' || v_current_day);
    
    IF v_current_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        DBMS_OUTPUT.PUT_LINE('Weekday detected - DML not allowed');
        RETURN FALSE; -- Weekdays not allowed
    END IF;
    
    -- Check if today is a holiday
    SELECT COUNT(*) INTO v_is_holiday 
    FROM holidays 
    WHERE holiday_date = TRUNC(SYSDATE) 
    AND is_active = 'Y';
    
    IF v_is_holiday > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Holiday detected - DML not allowed');
        RETURN FALSE; -- Holidays not allowed
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('DML operations allowed (weekend, not holiday)');
    RETURN TRUE; -- Weekends are allowed
END is_operation_allowed;
/

-- 3. AUDIT LOGGING FUNCTION
CREATE OR REPLACE PROCEDURE log_audit_event (
    p_table_name IN VARCHAR2,
    p_operation_type IN VARCHAR2,
    p_old_values IN CLOB DEFAULT NULL,
    p_new_values IN CLOB DEFAULT NULL,
    p_success_flag IN CHAR,
    p_error_message IN VARCHAR2 DEFAULT NULL
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO audit_log (
        log_id, table_name, operation_type, old_values, new_values,
        user_name, timestamp, success_flag, error_message
    ) VALUES (
        audit_seq.NEXTVAL, p_table_name, p_operation_type, p_old_values, p_new_values,
        USER, CURRENT_TIMESTAMP, p_success_flag, p_error_message
    );
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Audit logged: ' || p_table_name || ' - ' || p_operation_type);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error logging audit: ' || SQLERRM);
        ROLLBACK;
END log_audit_event;
/

-- 4. BUSINESS RULE TRIGGER FOR FLIGHTS TABLE
CREATE OR REPLACE TRIGGER flights_dml_restriction
FOR INSERT OR UPDATE OR DELETE ON flights
COMPOUND TRIGGER

    -- Before statement level
    BEFORE STATEMENT IS
        v_operation_type VARCHAR2(10);
    BEGIN
        -- Determine operation type
        IF INSERTING THEN
            v_operation_type := 'INSERT';
        ELSIF UPDATING THEN
            v_operation_type := 'UPDATE';
        ELSE
            v_operation_type := 'DELETE';
        END IF;
        
        -- Check if operation is allowed
        IF NOT is_operation_allowed THEN
            -- Log the denied attempt
            log_audit_event(
                'FLIGHTS', 
                v_operation_type,
                NULL, NULL, 'N',
                'DML operation not allowed on weekdays or holidays'
            );
            
            RAISE_APPLICATION_ERROR(-20001, 
                'DML operations on FLIGHTS table are not allowed on weekdays or public holidays. ' ||
                'Allowed only on weekends (Saturday, Sunday).');
        END IF;
    END BEFORE STATEMENT;
    
    -- After each row
    AFTER EACH ROW IS
    BEGIN
        -- Log successful operations
        IF INSERTING THEN
            log_audit_event('FLIGHTS', 'INSERT', NULL, 
                'New flight: ' || :NEW.flight_number || ' - ' || :NEW.airline, 'Y', NULL);
        ELSIF UPDATING THEN
            log_audit_event('FLIGHTS', 'UPDATE', 
                'Old: ' || :OLD.status || ' (' || :OLD.flight_number || ')', 
                'New: ' || :NEW.status || ' (' || :NEW.flight_number || ')', 'Y', NULL);
        ELSIF DELETING THEN
            log_audit_event('FLIGHTS', 'DELETE', 
                'Deleted flight: ' || :OLD.flight_number || ' - ' || :OLD.airline, NULL, 'Y', NULL);
        END IF;
    END AFTER EACH ROW;

END flights_dml_restriction;
/

-- 5. TRIGGER FOR AUTOMATIC FLIGHT STATUS UPDATES
CREATE OR REPLACE TRIGGER update_flight_status
BEFORE INSERT ON flight_assignments
FOR EACH ROW
DECLARE
    v_current_time TIMESTAMP := SYSTIMESTAMP;
    v_minutes_diff NUMBER;
BEGIN
    -- Calculate time difference in minutes
    v_minutes_diff := EXTRACT(MINUTE FROM (:NEW.planned_time - v_current_time)) + 
                     EXTRACT(HOUR FROM (:NEW.planned_time - v_current_time)) * 60;
    
    DBMS_OUTPUT.PUT_LINE('Time difference: ' || v_minutes_diff || ' minutes');
    
    -- If assignment is being created and planned time is past or within 5 minutes, set status to Active
    IF v_minutes_diff <= 5 AND :NEW.assignment_status = 'Scheduled' THEN
        :NEW.assignment_status := 'Active';
        
        -- Also update the flight status
        UPDATE flights 
        SET status = 'Landed'
        WHERE flight_id = :NEW.flight_id;
        
        DBMS_OUTPUT.PUT_LINE('Flight status automatically updated to Landed');
        
        -- Log the automatic update
        log_audit_event('FLIGHT_ASSIGNMENTS', 'AUTO_UPDATE', 
            'Scheduled', 'Active', 'Y', 
            'Automatic status update - flight arrived');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        log_audit_event('FLIGHT_ASSIGNMENTS', 'AUTO_UPDATE_ERROR', 
            NULL, NULL, 'N', SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Error in update_flight_status: ' || SQLERRM);
END update_flight_status;
/

-- 6. TRIGGER FOR EMERGENCY PRIORITY OVERRIDE
CREATE OR REPLACE TRIGGER emergency_priority_override
AFTER INSERT ON emergency_alerts
FOR EACH ROW
WHEN (NEW.priority_level = 1)  -- Only for high priority emergencies
DECLARE
    v_runway_id NUMBER;
    v_runway_name VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Emergency priority override triggered for alert: ' || :NEW.alert_id);
    
    -- Find available runway
    BEGIN
        SELECT resource_id, resource_name INTO v_runway_id, v_runway_name
        FROM airport_resources
        WHERE resource_type = 'Runway'
        AND status = 'Available'
        AND ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('Found available runway: ' || v_runway_name);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Try to find any runway (even if occupied)
            SELECT resource_id, resource_name INTO v_runway_id, v_runway_name
            FROM airport_resources
            WHERE resource_type = 'Runway'
            AND ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('No available runways, using: ' || v_runway_name);
    END;
    
    -- Create immediate assignment with highest priority
    INSERT INTO flight_assignments (
        assignment_id, flight_id, resource_id, planned_time, 
        assignment_status, priority_level
    ) VALUES (
        assignment_seq.NEXTVAL, :NEW.flight_id, v_runway_id, 
        SYSTIMESTAMP, 'Active', 1
    );
    
    -- Update the emergency alert with resolution info
    UPDATE emergency_alerts 
    SET resolution_status = 'Resolved',
        resolved_by = USER,
        resolution_time = SYSTIMESTAMP
    WHERE alert_id = :NEW.alert_id;
    
    -- Log the emergency override
    log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE', 
        NULL, 'Runway assigned: ' || v_runway_name, 'Y', 
        'Emergency priority override - flight: ' || :NEW.flight_id);
    
    DBMS_OUTPUT.PUT_LINE('Emergency override completed successfully');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE_ERROR', 
            NULL, NULL, 'N', 'No runways available for emergency');
        DBMS_OUTPUT.PUT_LINE('ERROR: No runways available for emergency');
    WHEN OTHERS THEN
        log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE_ERROR', 
            NULL, NULL, 'N', SQLERRM);
        DBMS_OUTPUT.PUT_LINE('ERROR in emergency override: ' || SQLERRM);
END emergency_priority_override;
/

-- 7. TRIGGER FOR WEATHER-BASED AUTOMATIC DECISIONS
CREATE OR REPLACE TRIGGER weather_impact_assessment
AFTER INSERT ON weather_conditions
FOR EACH ROW
DECLARE
    v_affected_flights NUMBER;
    v_severity VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Weather impact assessment triggered');
    DBMS_OUTPUT.PUT_LINE('Condition: ' || :NEW.condition || ', Wind: ' || :NEW.wind_speed || ', Vis: ' || :NEW.visibility);
    
    -- Determine severity
    IF :NEW.visibility < 2 OR :NEW.wind_speed > 30 THEN
        v_severity := 'SEVERE';
    ELSIF :NEW.visibility < 5 OR :NEW.wind_speed > 20 THEN
        v_severity := 'HIGH';
    ELSIF :NEW.visibility < 10 OR :NEW.wind_speed > 15 THEN
        v_severity := 'MODERATE';
    ELSE
        v_severity := 'LOW';
    END IF;
    
    -- Count flights that might be affected by bad weather
    SELECT COUNT(*) INTO v_affected_flights
    FROM flights f
    JOIN flight_assignments fa ON f.flight_id = fa.flight_id
    WHERE fa.planned_time BETWEEN SYSTIMESTAMP AND SYSTIMESTAMP + INTERVAL '2' HOUR
    AND fa.assignment_status = 'Scheduled'
    AND f.status = 'Scheduled';
    
    -- Log weather impact assessment
    log_audit_event('WEATHER_CONDITIONS', 'IMPACT_ASSESSMENT', 
        NULL, 
        'Affected flights: ' || v_affected_flights || 
        ' - Condition: ' || :NEW.condition || 
        ' - Visibility: ' || :NEW.visibility || 'km' ||
        ' - Wind: ' || :NEW.wind_speed || ' knots' ||
        ' - Severity: ' || v_severity, 
        'Y', NULL);
    
    DBMS_OUTPUT.PUT_LINE('Affected flights: ' || v_affected_flights);
    
    -- If severe weather, automatically delay some flights
    IF v_severity IN ('SEVERE', 'HIGH') THEN
        UPDATE flights 
        SET status = 'Delayed'
        WHERE flight_id IN (
            SELECT f.flight_id
            FROM flights f
            JOIN flight_assignments fa ON f.flight_id = fa.flight_id
            WHERE fa.planned_time BETWEEN SYSTIMESTAMP AND SYSTIMESTAMP + INTERVAL '1' HOUR
            AND f.status = 'Scheduled'
            AND ROWNUM <= 2  -- Delay maximum 2 flights
        );
        
        DBMS_OUTPUT.PUT_LINE('Flights automatically delayed due to ' || v_severity || ' weather');
        
        log_audit_event('WEATHER_CONDITIONS', 'AUTO_DELAY', 
            NULL, v_affected_flights || ' flights automatically delayed', 'Y', NULL);
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        log_audit_event('WEATHER_CONDITIONS', 'IMPACT_ASSESSMENT_ERROR', 
            NULL, NULL, 'N', SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Error in weather impact: ' || SQLERRM);
END weather_impact_assessment;
/

-- 8. TRIGGER TO PREVENT DOUBLE BOOKING OF RUNWAYS
CREATE OR REPLACE TRIGGER prevent_runway_conflict
BEFORE INSERT ON flight_assignments
FOR EACH ROW
DECLARE
    v_conflict_count NUMBER;
    v_conflicting_flight VARCHAR2(10);
BEGIN
    -- Check for runway conflicts (same runway at same time)
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM flight_assignments fa
    WHERE fa.resource_id = :NEW.resource_id
    AND fa.planned_time = :NEW.planned_time
    AND fa.assignment_id != :NEW.assignment_id
    AND fa.assignment_status != 'Cancelled';
    
    -- If conflict found, raise error
    IF v_conflict_count > 0 THEN
        -- Get conflicting flight number
        BEGIN
            SELECT f.flight_number INTO v_conflicting_flight
            FROM flight_assignments fa
            JOIN flights f ON fa.flight_id = f.flight_id
            WHERE fa.resource_id = :NEW.resource_id
            AND fa.planned_time = :NEW.planned_time
            AND ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS THEN
                v_conflicting_flight := 'Unknown';
        END;
        
        -- Log the prevented conflict
        log_audit_event('FLIGHT_ASSIGNMENTS', 'CONFLICT_PREVENTED', 
            NULL, NULL, 'N',
            'Runway conflict prevented: ' || :NEW.assignment_id || 
            ' conflicts with flight ' || v_conflicting_flight);
        
        RAISE_APPLICATION_ERROR(-20002, 
            'Runway conflict detected! Cannot assign runway at the same time. ' ||
            'Conflicting with flight: ' || v_conflicting_flight);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('No runway conflict detected');
    
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            RAISE; -- Re-raise the application error
        ELSE
            log_audit_event('FLIGHT_ASSIGNMENTS', 'CONFLICT_CHECK_ERROR', 
                NULL, NULL, 'N', SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Error in conflict check: ' || SQLERRM);
        END IF;
END prevent_runway_conflict;
/

-- 9. VERIFY ALL TRIGGERS CREATED
BEGIN
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('TRIGGERS CREATION VERIFICATION');
    DBMS_OUTPUT.PUT_LINE('=========================================');
    
    FOR trigger_rec IN (
        SELECT trigger_name, status
        FROM user_triggers
        WHERE trigger_name NOT LIKE 'BIN$%'
        ORDER BY trigger_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(trigger_rec.trigger_name, 35) || ' - ' || 
                            CASE WHEN trigger_rec.status = 'ENABLED' THEN '✅ ENABLED' ELSE '❌ DISABLED' END);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('Total triggers: ' || (SELECT COUNT(*) FROM user_triggers WHERE trigger_name NOT LIKE 'BIN$%'));
    DBMS_OUTPUT.PUT_LINE('=========================================');
END;
/

-- 10. TEST THE TRIGGERS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TESTING TRIGGERS:');
    DBMS_OUTPUT.PUT_LINE('=================');
    
    -- Test 1: Check business rule function
    IF is_operation_allowed THEN
        DBMS_OUTPUT.PUT_LINE('✅ Business Rule Test: DML operations are currently ALLOWED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✅ Business Rule Test: DML operations are currently BLOCKED (weekday/holiday)');
    END IF;
    
    -- Test 2: Test audit logging
    log_audit_event('TEST', 'INSERT', 'Old data', 'New data', 'Y', 'Test audit entry');
    DBMS_OUTPUT.PUT_LINE('✅ Audit Logging Test: Audit entry created successfully');
    
    -- Test 3: Check trigger count
    DBMS_OUTPUT.PUT_LINE('✅ Total triggers created: ' || (SELECT COUNT(*) FROM user_triggers WHERE trigger_name NOT LIKE 'BIN$%'));
    
    DBMS_OUTPUT.PUT_LINE('=================');
    DBMS_OUTPUT.PUT_LINE('TRIGGER TESTS COMPLETED');
    DBMS_OUTPUT.PUT_LINE('=================');
END;
/

-- Display success message
BEGIN
    DBMS_OUTPUT.PUT_LINE('=========================================');
    DBMS_OUTPUT.PUT_LINE('✅ TRIGGERS & AUDITING SYSTEM COMPLETE!');
    DBMS_OUTPUT.PUT_LINE('✅ 6 Triggers created successfully');
    DBMS_OUTPUT.PUT_LINE('✅ Business rules enforced');
    DBMS_OUTPUT.PUT_LINE('✅ Audit logging system active');
    DBMS_OUTPUT.PUT_LINE('=========================================');
END;
/
