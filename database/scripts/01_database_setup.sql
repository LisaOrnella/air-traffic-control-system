-- =============================================
-- DATABASE SETUP & USER CREATION
-- Created by: UWASE Lisa Ornella
-- ID: 28753
-- Course: PL/SQL Database Development
-- Institution: AUCA
-- =============================================

-- Create user and grant privileges
CREATE USER air_traffic IDENTIFIED BY Lisa;

GRANT CONNECT, RESOURCE TO atc_user;
GRANT CREATE SESSION TO atc_user;
GRANT CREATE TABLE TO atc_user;
GRANT CREATE VIEW TO atc_user;
GRANT CREATE PROCEDURE TO atc_user;
GRANT CREATE FUNCTION TO atc_user;
GRANT CREATE TRIGGER TO atc_user;
GRANT CREATE SEQUENCE TO atc_user;
GRANT UNLIMITED TABLESPACE TO atc_user;

-- Verification
SELECT 'Database user created successfully' AS status FROM dual;
