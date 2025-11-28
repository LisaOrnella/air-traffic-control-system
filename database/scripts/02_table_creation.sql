
-- Sequences for primary keys
CREATE SEQUENCE flight_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE resource_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE assignment_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE weather_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE alert_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE holiday_seq START WITH 1 INCREMENT BY 1;

-- FLIGHTS TABLE - Core flight information
CREATE TABLE flights (
    flight_id NUMBER(10) PRIMARY KEY,
    flight_number VARCHAR2(10) NOT NULL,
    airline VARCHAR2(50) NOT NULL,
    origin_airport VARCHAR2(3) NOT NULL,
    destination_airport VARCHAR2(3) NOT NULL,
    scheduled_arrival TIMESTAMP NOT NULL,
    scheduled_departure TIMESTAMP NOT NULL,
    status VARCHAR2(20) DEFAULT 'Scheduled',
    aircraft_type VARCHAR2(30),
    passenger_count NUMBER(4),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AIRPORT_RESOURCES TABLE - Runways and gates
CREATE TABLE airport_resources (
    resource_id NUMBER(10) PRIMARY KEY,
    resource_type VARCHAR2(10) NOT NULL,
    resource_name VARCHAR2(20) NOT NULL UNIQUE,
    status VARCHAR2(20) DEFAULT 'Available',
    capacity NUMBER(3),
    maintenance_schedule TIMESTAMP,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FLIGHT_ASSIGNMENTS TABLE - Resource allocation
CREATE TABLE flight_assignments (
    assignment_id NUMBER(10) PRIMARY KEY,
    flight_id NUMBER(10) NOT NULL REFERENCES flights(flight_id),
    resource_id NUMBER(10) NOT NULL REFERENCES airport_resources(resource_id),
    planned_time TIMESTAMP NOT NULL,
    actual_time TIMESTAMP,
    assignment_status VARCHAR2(20) DEFAULT 'Scheduled',
    priority_level NUMBER(1) DEFAULT 5,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- EMERGENCY_ALERTS TABLE - Emergency tracking
CREATE TABLE emergency_alerts (
    alert_id NUMBER(10) PRIMARY KEY,
    flight_id NUMBER(10) NOT NULL REFERENCES flights(flight_id),
    alert_type VARCHAR2(20) NOT NULL,
    priority_level NUMBER(1) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolution_status VARCHAR2(20) DEFAULT 'Active',
    resolved_by VARCHAR2(50),
    resolution_time TIMESTAMP,
    description VARCHAR2(500),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- WEATHER_CONDITIONS TABLE - Weather data
CREATE TABLE weather_conditions (
    weather_id NUMBER(10) PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    wind_speed NUMBER(5,2),
    wind_direction VARCHAR2(10),
    visibility NUMBER(5,2),
    condition VARCHAR2(20),
    temperature NUMBER(3,1),
    precipitation NUMBER(5,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AUDIT_LOG TABLE - Security and auditing
CREATE TABLE audit_log (
    log_id NUMBER(10) PRIMARY KEY,
    table_name VARCHAR2(30) NOT NULL,
    operation_type VARCHAR2(10) NOT NULL,
    old_values CLOB,
    new_values CLOB,
    user_name VARCHAR2(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success_flag CHAR(1),
    error_message VARCHAR2(500)
);

-- HOLIDAYS TABLE - Business rule enforcement
CREATE TABLE holidays (
    holiday_id NUMBER(10) PRIMARY KEY,
    holiday_date DATE NOT NULL UNIQUE,
    holiday_name VARCHAR2(50) NOT NULL,
    is_active CHAR(1) DEFAULT 'Y',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add constraints
ALTER TABLE flights ADD CONSTRAINT chk_flight_status 
CHECK (status IN ('Scheduled', 'Landed', 'Departed', 'Delayed', 'Cancelled'));

ALTER TABLE airport_resources ADD CONSTRAINT chk_resource_type 
CHECK (resource_type IN ('Runway', 'Gate'));

ALTER TABLE airport_resources ADD CONSTRAINT chk_resource_status 
CHECK (status IN ('Available', 'Occupied', 'Under Maintenance'));

-- Display success message
BEGIN
    DBMS_OUTPUT.PUT_LINE('✅ All tables created successfully!');
END;
/
