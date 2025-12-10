# Data Dictionary

## FLIGHTS (Core Flight Information)

| Column Name   | Data Type       | Constraint                                  | Description                          |
|---------------|---------------- |--------------------------------------------|---------------------------------------|
| FLIGHT_ID     | NUMBER(10)      | PK, NN                                     | Unique identifier for each flight     |
| FLIGHT_NUMBER | VARCHAR2(10)    | NN                                         | Commercial flight number (e.g., WB402)|
| AIRLINE_CODE  | VARCHAR2(3)     | FK → AIRLINES.AIRLINE_CODE, NN             | Airline operating the flight          |
| AIRCRAFT_TYPE | VARCHAR2(20)    | NN                                         | Model of aircraft (e.g., A330)        |
| SCHED_ARRIVAL | TIMESTAMP       | NN                                         | Planned arrival time                  |
| SCHED_DEPART  | TIMESTAMP       | NN                                         | Planned departure time                |
| STATUS        | VARCHAR2(20)    | Check ('Scheduled','Landed','Delayed')     | Current flight status                 |
