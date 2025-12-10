# Database Architecture Overview: Smart ATC Management System (ATC-MS)

## 1. The Three-Tier Architecture

The ATC-MS employs a standardized three-tier architecture, ensuring scalability, security, and maintainability.

### A. Presentation Tier
* **Component:** SQL Developer, Web Dashboard (Conceptual BI Layer), or Command Line (SQL*Plus).
* **Role:** User Interface for operators (Controllers) and analysts to interact with the system.

### B. Application Tier (PL/SQL Layer)
* **Component:** Oracle Database Server (PL/SQL Stored Procedures, Packages, Triggers).
* **Role:** Houses all the business logic, security enforcement, and operational automation.
    * **Core Logic:** `atc_manager_pkg` handles transactional assignments and conflict detection.
    * **Security Logic:** Compound Triggers (`trg_flights_audit_secure`) enforce business rules (Weekday DML block).
    * **Data Integrity:** All foreign key checks and validation logic are executed here before hitting the data layer.

### C. Data Tier
* **Component:** Oracle Database Tables (`FLIGHTS`, `AIRPORT_RESOURCES`, `AUDIT_LOG`, etc.) and Storage.
* **Role:** Persistent storage of all flight data, assignment records, and audit history. This layer is only directly accessible by the Application Tier, maintaining security.

## 2. Component Diagram

[![](https://mermaid.ink/img/pako:eNplUm1v2jAQ_isnfwIphUAJ0Hxjoe2Q0pUWqklTJGSSI1g4dmY7VVnFf98lQLSXKIrsi5-Xe86fLNUZspBFo0grx4VCkyigxwknEWbrCJ644jkWqBysjtZhAZ3bm7VAAzOT7oXD1FUGu4k6A1ueTiU8SNjqJYY5vqPUJUH68B23sFAOzY6nmLD6yNKgJXruhFZQM5_LbxYz2B4bRqOlRGOBqwxmiksyYhPWin7Rlcq4OXa04anEjUXzjqYmeW4KMOeOb7lFWDV_CAqfZ-jfnktpf8rGU9yvncc6FykseXqgDGx_bUSek4-zwVlZSpH-a_tCRl6lhG1liddaMJVEG9ZKO8I4iPaYHqwHM2tFrpp0z1od7tJN0WRuNuUh73pN0ytMKyPcEa4Wek37_3eQUae1jbbjNd-SNHQe4sXj1_XKg9f71fPba3RPy9nbfLHexM-P3bP3GvRHK0vSETRyMlfTgnWUb450Ab49dFv903UKryibobchRhSBhaXRKWZ0R2z_pUIj8BIf5dtfxvRtmWqCC_jaBlnYaVNYmD_F_Xl99gIlEPNYbkTGQmcq9FiBpuD1ljWjTZjb07VNWEjLDHe8ki5hiToRrOTqh9bFFWl0le9ZuOPS0q4qSRzngueGF23VoMrQRHTRHAsnfsPBwk_2wcKb6W1vPByMBvU7HAWTO48dqTwa9MbTYBiM_Ukw9KfB6OSxX43soOePJ5ORfzeYDP1gOvCD0284JiI4?type=png)](https://mermaid.live/edit#pako:eNplUm1v2jAQ_isnfwIphUAJ0Hxjoe2Q0pUWqklTJGSSI1g4dmY7VVnFf98lQLSXKIrsi5-Xe86fLNUZspBFo0grx4VCkyigxwknEWbrCJ644jkWqBysjtZhAZ3bm7VAAzOT7oXD1FUGu4k6A1ueTiU8SNjqJYY5vqPUJUH68B23sFAOzY6nmLD6yNKgJXruhFZQM5_LbxYz2B4bRqOlRGOBqwxmiksyYhPWin7Rlcq4OXa04anEjUXzjqYmeW4KMOeOb7lFWDV_CAqfZ-jfnktpf8rGU9yvncc6FykseXqgDGx_bUSek4-zwVlZSpH-a_tCRl6lhG1liddaMJVEG9ZKO8I4iPaYHqwHM2tFrpp0z1od7tJN0WRuNuUh73pN0ytMKyPcEa4Wek37_3eQUae1jbbjNd-SNHQe4sXj1_XKg9f71fPba3RPy9nbfLHexM-P3bP3GvRHK0vSETRyMlfTgnWUb450Ab49dFv903UKryibobchRhSBhaXRKWZ0R2z_pUIj8BIf5dtfxvRtmWqCC_jaBlnYaVNYmD_F_Xl99gIlEPNYbkTGQmcq9FiBpuD1ljWjTZjb07VNWEjLDHe8ki5hiToRrOTqh9bFFWl0le9ZuOPS0q4qSRzngueGF23VoMrQRHTRHAsnfsPBwk_2wcKb6W1vPByMBvU7HAWTO48dqTwa9MbTYBiM_Ukw9KfB6OSxX43soOePJ5ORfzeYDP1gOvCD0284JiI4)
The Component Diagram above visually represents the separation of concerns in the ATC-MS. It highlights the Oracle PL/SQL layer as the dedicated Application Tier, which is responsible for executing all business logic (Packages and Triggers) before interacting with the core tables in the Data Tier.
## 3. Data Flow within the Architecture

| Step | Initiator | Action | Destination | Technology/Logic Used |
| :--- | :--- | :--- | :--- | :--- |
| **1. Request** | Controller/External System | Calls `atc_manager_pkg.assign_runway` | Application Tier | PL/SQL Procedure Call |
| **2. Validation** | Application Tier | Checks for conflicts and resource status | Data Tier (FLIGHTS, RESOURCES) | SELECT queries, Cursor Logic |
| **3. Security Check**| Application Tier | Detects DML (Insert/Delete/Update) | Data Tier (AUDIT_LOG) | Compound Trigger (`BEFORE STATEMENT`) |
| **4. Assignment** | Application Tier | Executes `INSERT` into `FLIGHT_ASSIGNMENTS` | Data Tier | DML Transaction (COMMIT/ROLLBACK) |
| **5. BI Analysis** | Analyst | Executes `SELECT` query | Data Tier | SQL Views, Aggregate Functions |
