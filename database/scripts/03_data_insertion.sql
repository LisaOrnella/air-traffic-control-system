-- =============================================
-- SAMPLE DATA INSERTION
-- Created by: UWASE Lisa Ornella | ID: 28753
-- =============================================

-- Insert Airport Resources
INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Runway', 'Runway 09L', 'Available', 1);

INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Runway', 'Runway 27R', 'Available', 1);

INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Runway', 'Runway 18', 'Under Maintenance', 1);

INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Gate', 'Gate A1', 'Available', 200);

INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Gate', 'Gate A2', 'Available', 180);

INSERT INTO airport_resources (resource_id, resource_type, resource_name, status, capacity) 
VALUES (resource_seq.NEXTVAL, 'Gate', 'Gate B1', 'Available', 220);

COMMIT;

-- Insert Flights - International Airlines
INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'AA101', 'American Airlines', 'JFK', 'LAX', 
        TIMESTAMP '2025-12-01 08:00:00', TIMESTAMP '2025-12-01 10:00:00', 
        'Scheduled', 'Boeing 737', 150);

INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'UA202', 'United Airlines', 'ORD', 'DFW', 
        TIMESTAMP '2025-12-01 08:30:00', TIMESTAMP '2025-12-01 09:30:00', 
        'Scheduled', 'Airbus A320', 180);

-- Insert Flights - RWANDA AIR (African Focus)
INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'WB501', 'Rwanda Air', 'KGL', 'NBO', 
        TIMESTAMP '2025-12-01 10:00:00', TIMESTAMP '2025-12-01 11:30:00', 
        'Scheduled', 'Bombardier CRJ', 90);

INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'WB502', 'Rwanda Air', 'KGL', 'JRO', 
        TIMESTAMP '2025-12-01 11:00:00', TIMESTAMP '2025-12-01 12:15:00', 
        'Scheduled', 'Bombardier CRJ', 78);

-- Insert Flights - ETHIOPIAN AIRLINES (African Focus)
INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'ET601', 'Ethiopian Airlines', 'ADD', 'NBO', 
        TIMESTAMP '2025-12-01 09:30:00', TIMESTAMP '2025-12-01 11:00:00', 
        'Scheduled', 'Boeing 737', 160);

INSERT INTO flights (flight_id, flight_number, airline, origin_airport, destination_airport, scheduled_arrival, scheduled_departure, status, aircraft_type, passenger_count)
VALUES (flight_seq.NEXTVAL, 'ET602', 'Ethiopian Airlines', 'ADD', 'KGL', 
        TIMESTAMP '2025-12-01 10:30:00', TIMESTAMP '2025-12-01 12:00:00', 
        'Scheduled', 'Boeing 737', 155);

COMMIT;

-- Insert Flight Assignments
INSERT INTO flight_assignments (assignment_id, flight_id, resource_id, planned_time, assignment_status, priority_level)
SELECT assignment_seq.NEXTVAL, f.flight_id, r.resource_id, f.scheduled_arrival, 'Scheduled', 5
FROM flights f, airport_resources r
WHERE f.flight_number = 'WB501' AND r.resource_name = 'Runway 09L'
AND ROWNUM = 1;

INSERT INTO flight_assignments (assignment_id, flight_id, resource_id, planned_time, assignment_status, priority_level)
SELECT assignment_seq.NEXTVAL, f.flight_id, r.resource_id, f.scheduled_arrival, 'Scheduled', 5
FROM flights f, airport_resources r
WHERE f.flight_number = 'ET601' AND r.resource_name = 'Runway 27R'
AND ROWNUM = 1;

COMMIT;

-- Insert Holidays for business rules
INSERT INTO holidays (holiday_id, holiday_date, holiday_name) 
VALUES (holiday_seq.NEXTVAL, DATE '2025-12-25', 'Christmas Day');

INSERT INTO holidays (holiday_id, holiday_date, holiday_name) 
VALUES (holiday_seq.NEXTVAL, DATE '2026-01-01', 'New Years Day');

COMMIT;

-- Insert Weather Data
INSERT INTO weather_conditions (weather_id, wind_speed, wind_direction, visibility, condition, temperature, precipitation)
VALUES (weather_seq.NEXTVAL, 12.5, 'NE', 15.2, 'Clear', 25.5, 0);

INSERT INTO weather_conditions (weather_id, wind_speed, wind_direction, visibility, condition, temperature, precipitation)
VALUES (weather_seq.NEXTVAL, 25.3, 'SW', 5.8, 'Rain', 18.7, 3.2);

COMMIT;

-- Verification
SELECT 'Data insertion completed successfully!' AS status FROM dual;
SELECT 'Total flights: ' || COUNT(*) FROM flights
UNION ALL SELECT 'African airlines: ' || COUNT(*) FROM flights WHERE airline IN ('Rwanda Air', 'Ethiopian Airlines')
UNION ALL SELECT 'Resources: ' || COUNT(*) FROM airport_resources;
