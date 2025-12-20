# ✈️ Smart Air Traffic Control Management System (ATC-MS)

**Course:** PL/SQL Database Development (INSY 8311)  
**Student:** UWASE Lisa Ornella  
**ID:** 28753  
**Group:** Tuesday  (B)   
PL/SQL capstone project
**Institution:** Adventist University of Central Africa (AUCA)  
**Instructor:** Eric Maniraguha  

---

## 📖 Project Overview

The **Smart ATC-MS** is a comprehensive Oracle Database solution designed to modernize airport operations by automating critical air traffic control functions. It ensures **operational safety** through real-time conflict detection and **regulatory compliance** through robust security and auditing features.

### 🚩 Problem Statement
Manual scheduling leads to high runway conflict risk, slow emergency response times, and inefficient resource allocation.

### 🎯 Key Objectives
1.  **Safety & Automation:** Implement PL/SQL logic (`atc_manager_pkg`) for automated, conflict-free runway assignment.
2.  **Security:** Enforce strict business rules (e.g., blocking schedule modifications on weekdays) via database triggers.
3.  **Efficiency:** Provide actionable Business Intelligence (BI) for On-Time Performance (OTP) and resource utilization analysis.

---


## 🛠️ Technical Architecture

### 3-Tier Model
The system uses a 3-Tier Architecture where the **Application Tier** resides entirely within the Oracle Database, leveraging PL/SQL for fast, secure execution of business logic.

| Tier | Component | Role |
| :--- | :--- | :--- |
| **Presentation** | SQL Developer / Web Interface | User interaction (Controllers, Analysts). |
| **Application** | **PL/SQL Packages & Triggers** | Executes core logic, conflict checks, and security enforcement. |
| **Data** | Tables (`FLIGHTS`, `AUDIT_LOG`, etc.) | 3NF persistent data storage. |



### Database Schema (3NF)
The schema is normalized to 3NF, revolving around the core entities:
* `FLIGHTS`: Master data (Dim)
* `AIRPORT_RESOURCES`: Physical assets (Dim)
* `FLIGHT_ASSIGNMENTS`: The transactional link/Fact Table, tracking resource utilization time.
* `AUDIT_LOG`: Security and compliance tracking.

---

## Links to Documentation

For detailed analysis, model diagrams, and design rationale, please refer to the following clickable links:

| Document | Content Summary | Link |
| :--- | :--- | :--- |
| **Data Dictionary** | Detailed column definitions, data types, and constraints for all 3NF tables. | [View Dictionary](Documentation/data_dictionary.md) |
| **Architecture** | Explanation and diagram of the Three-Tier Model (Presentation $\to$ PL/SQL $\to$ Data). | [View Architecture](Documentation/architecture.md) |
| **Design Decisions** | Rationale for using PL/SQL packages, Compound Triggers, and 3NF normalization. | [View Design decisions](Documentation/design_decisions.md) |
| **Analytics Queries** | SQL scripts for calculating key BI metrics (OTP, Resource Utilization). | [View Queries](queries/analytics-querries.sql) |

---

### 📊 System Architecture & Schema (Phase III)
Verifies the foundational relational design and environment setup.

* **ER Diagram (3NF)**: Visual layout of the five core tables (`FLIGHTS`, `RESOURCES`, `ASSIGNMENTS`, `HOLIDAYS`, and `AUDIT_LOG`) showing Primary and Foreign Key relationships.
    * **Evidence:**
      [View ER Diagram](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/database_objects/er_diagram.png?raw=true)

* **Database Structure**: Confirms the schema tree and project isolation in the dedicated PDB.
    * **Evidence:**
      [View data structure](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/database_objects/data_structure.png?raw=true))


### 🧠 2. Application Logic (PL/SQL Tier)
Demonstrates the use of stored logic to handle airport operations.

* **ATC Manager Package**: Encapsulates procedures like `assign_resource` and functions like `calculate_delay_risk`.
    * **Evidence:**
      [View package](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/test_results/procedure_code.png?raw=true)
      
* **Security Trigger**: The `TRG_SECURITY_AND_HOLIDAYS` object enforces business rules by monitoring table modifications.
    * **Evidence:**
      [View trigger in editor](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/test_results/Triggers_in_editor.png?raw=true)

### 🧪 3. Test Execution & Sample Data
Verification of data integrity and system performance under load.

* **High-Volume Data**: Results showing the system handling 115+ flight records.
    * **Evidence:**
   [View sample](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/test_results/Aiport_resources.png?raw=true)


### 🛡️ 4. Security Auditing (Phase VII)
Compliance proof for automated security tracking.

* **Audit Log Entry**: Query output from the `AUDIT_LOG` table proving the system successfully blocks and records unauthorized holiday modifications.
    * **Evidence:** 
   [View recent audit](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/test_results/r_audit_log.png?raw=true)

---

## 🛠️ Folder Structure Reference

| Folder | Contents | Requirement Met |
| :--- | :--- | :--- |
| `/screenshots/oem_monitoring/` | Dashboard metrics | PDB Health & Environment |
| `/screenshots/database_objects/` | Diagrams & Trees | 3NF & Application Logic |
| `/screenshots/test_results/` | Data & Logs | Sample Data & Phase VII |
