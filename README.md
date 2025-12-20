# ✈️ Smart Air Traffic Control Management System (ATC-MS)

**Course:** PL/SQL Database Development (INSY 8311)  
**Student:** UWASE Lisa Ornella  
**ID:** 28753  
**Group:** Tuesday  (B)                                                                                                                                              
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
## 📊 Project Artifacts & Proof of Implementation

The following table maps the project requirements to technical evidence captured during development.

| Artifact | Purpose | Evidence Description |
| :--- | :--- | :--- |
| **ER Diagram** | Shows the 3rd Normal Form (3NF) relational design. | Visual layout of `FLIGHTS`, `RESOURCES`, `ASSIGNMENTS`, `HOLIDAYS`, and `AUDIT_LOG`.![ER Diagram](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/database_objects/er_diagram.png?raw=true)
 |
| **Database Structure** | Confirms isolation in the `PLSQL_AIRTRAFFIC2025` PDB. | SQL Developer Tree view showing all Tables, Packages, and Triggers.[![database structure]([images/er.png](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/database_objects/er_diagram.png?raw=true))](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/database_objects/data_structure.png?raw=true)] |
| **Sample Data** | Demonstrates handling of 115+ flight records. | Result grid output showing 10 sample rows from the `FLIGHTS` table.[View sample data](https://github.com/LisaOrnella/air-traffic-control-system/blob/main/screenshots/test_results/Aiport_resources.png?raw=true) |
| **Procedures & Triggers** | Displays the core PL/SQL logic and security rules. | Editor screenshot of `atc_manager_pkg` and `trg_security_and_holidays`. |
| **Test Execution** | Verifies functional automation and package calls. | Script output showing "PL/SQL procedure successfully completed." |
| **Audit Log Entries** | Validates security tracking for "Phase VII". | Query results from the `AUDIT_LOG` showing blocked unauthorized actions. |

---
## 📂 Repository Structure

```text
tue_28753_lisa_airtraffic_ctrl/
├── README.md                      # Project documentation (this file)
├── database/
│   ├── scripts/                   # SQL execution order: 01 -> 05
│   │   ├── 01_setup.sql           # PDB and User creation
│   │   ├── 02_tables.sql          # DDL (CREATE TABLE/FKs/PKs)
│   │   ├── 03_data.sql            # Bulk INSERT data (500+ records)
│   │   ├── 04_packages.sql        # PL/SQL Logic (ATC_MANAGER_PKG)
│   │   └── 05_triggers.sql        # Security Triggers & Auditing
│   └── documentation/             # Detailed Documentation
│       ├── data_dictionary.md     # Phase III: Column and Constraint definitions
│       ├── architecture.md        # Phase III: 3-Tier Architecture explanation
│       └── design_decisions.md    # Phase III: Rationale for 3NF, Triggers, Packages
├── queries/
│   ├── analytics.sql              # BI Dashboard queries (OTP, Utilization)
│   └── test_validation.sql        # Verification Script for Package/Trigger tests
└── screenshots/                   # Proof of execution
