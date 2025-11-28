
-- 1. FUNCTION: Check if operation is allowed (Business Rule)
CREATE OR REPLACE FUNCTION is_operation_allowed RETURN BOOLEAN AS
    v_current_day VARCHAR2(10);
    v_is_holiday NUMBER;
BEGIN
    -- Check if weekday (Monday-Friday)
    SELECT TO_CHAR(SYSDATE, 'DY') INTO v_current_day FROM DUAL;
    
    IF v_current_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        RETURN FALSE; -- Weekdays not allowed
    END IF;
    
    -- Check if holiday
    SELECT COUNT(*) INTO v_is_holiday 
    FROM holidays 
    WHERE holiday_date = TRUNC(SYSDATE) 
    AND is_active = 'Y';
    
    IF v_is_holiday > 0 THEN
        RETURN FALSE; -- Holidays not allowed
    END IF;
    
    RETURN TRUE; -- Weekends are allowed
END is_operation_allowed;
/

-- 2. PROCEDURE: Audit Logging
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
END log_audit_event;
/

-- 3. TRIGGER: Business Rule Enforcement for FLIGHTS
CREATE OR REPLACE TRIGGER flights_dml_restriction
FOR INSERT OR UPDATE OR DELETE ON flights
COMPOUND TRIGGER

    BEFORE STATEMENT IS
    BEGIN
        IF NOT is_operation_allowed THEN
            -- Log the denied attempt
            log_audit_event(
                'FLIGHTS', 
                CASE 
                    WHEN INSERTING THEN 'INSERT'
                    WHEN UPDATING THEN 'UPDATE' 
                    ELSE 'DELETE'
                END,
                NULL, NULL, 'N',
                'DML operation not allowed on weekdays or holidays'
            );
            
            RAISE_APPLICATION_ERROR(-20001, 
                'DML operations on FLIGHTS table are not allowed on weekdays or public holidays.');
        END IF;
    END BEFORE STATEMENT;
    
    AFTER EACH ROW IS
    BEGIN
        -- Log successful operations
        IF INSERTING THEN
            log_audit_event('FLIGHTS', 'INSERT', NULL, 
                'New flight: ' || :NEW.flight_number, 'Y', NULL);
        ELSIF UPDATING THEN
            log_audit_event('FLIGHTS', 'UPDATE', 
                'Old: ' || :OLD.status, 
                'New: ' || :NEW.status, 'Y', NULL);
        ELSIF DELETING THEN
            log_audit_event('FLIGHTS', 'DELETE', 
                'Deleted: ' || :OLD.flight_number, NULL, 'Y', NULL);
        END IF;
    END AFTER EACH ROW;

END flights_dml_restriction;
/

-- 4. TRIGGER: Automatic Flight Status Updates
CREATE OR REPLACE TRIGGER update_flight_status
BEFORE INSERT ON flight_assignments
FOR EACH ROW
DECLARE
    v_current_time TIMESTAMP := SYSTIMESTAMP;
BEGIN
    -- If assignment is being created and planned time is past, set status to Active
    IF :NEW.planned_time <= v_current_time AND :NEW.assignment_status = 'Scheduled' THEN
        :NEW.assignment_status := 'Active';
        
        -- Also update the flight status
        UPDATE flights 
        SET status = 'Landed'
        WHERE flight_id = :NEW.flight_id;
        
        -- Log the automatic update
        log_audit_event('FLIGHT_ASSIGNMENTS', 'AUTO_UPDATE', 
            'Scheduled', 'Active', 'Y', 
            'Automatic status update based on time');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        log_audit_event('FLIGHT_ASSIGNMENTS', 'AUTO_UPDATE_ERROR', 
            NULL, NULL, 'N', SQLERRM);
END update_flight_status;
/

-- 5. TRIGGER: Emergency Priority Override
CREATE OR REPLACE TRIGGER emergency_priority_override
AFTER INSERT ON emergency_alerts
FOR EACH ROW
DECLARE
    v_runway_id NUMBER;
BEGIN
    -- If emergency alert is created with high priority, reassign runway immediately
    IF :NEW.priority_level = 1 THEN
        -- Find available runway
        SELECT resource_id INTO v_runway_id
        FROM airport_resources
        WHERE resource_type = 'Runway'
        AND status = 'Available'
        AND ROWNUM = 1;
        
        -- Create immediate assignment
        INSERT INTO flight_assignments (
            assignment_id, flight_id, resource_id, planned_time, 
            assignment_status, priority_level
        ) VALUES (
            assignment_seq.NEXTVAL, :NEW.flight_id, v_runway_id, 
            SYSTIMESTAMP, 'Active', 1
        );
        
        -- Log the emergency override
        log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE', 
            NULL, 'Runway assigned for emergency', 'Y', NULL);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE_ERROR', 
            NULL, NULL, 'N', 'No available runways for emergency');
    WHEN OTHERS THEN
        log_audit_event('EMERGENCY_ALERTS', 'PRIORITY_OVERRIDE_ERROR', 
            NULL, NULL, 'N', SQLERRM);
END emergency_priority_override;
/

-- 6. TRIGGER: Weather Impact Assessment
CREATE OR REPLACE TRIGGER weather_impact_assessment
AFTER INSERT ON weather_conditions
FOR EACH ROW
WHEN (NEW.visibility < 5 OR NEW.wind_speed > 20)
DECLARE
    v_affected_flights NUMBER;
BEGIN
    -- Count flights that might be affected by bad weather
    SELECT COUNT(*) INTO v_affected_flights
    FROM flights f
    JOIN flight_assignments fa ON f.flight_id = fa.flight_id
    WHERE fa.planned_time BETWEEN SYSTIMESTAMP AND SYSTIMESTAMP + INTERVAL '2' HOUR
    AND fa.assignment_status = 'Scheduled';
    
    -- Log weather impact assessment
    log_audit_event('WEATHER_CONDITIONS', 'IMPACT_ASSESSMENT', 
        NULL, 
        'Affected flights: ' || v_affected_flights || 
        ' - Condition: ' || :NEW.condition, 
        'Y', NULL);
        
EXCEPTION
    WHEN OTHERS THEN
        log_audit_event('WEATHER_CONDITIONS', 'IMPACT_ASSESSMENT_ERROR', 
            NULL, NULL, 'N', SQLERRM);
END weather_impact_assessment;
/

-- Verification
BEGIN
    DBMS_OUTPUT.PUT_LINE('✅ Triggers and auditing system created successfully!');
    DBMS_OUTPUT.PUT_LINE('✅ Business rules enforcement active');
    DBMS_OUTPUT.PUT_LINE('✅ Audit logging system operational');
END;
/
