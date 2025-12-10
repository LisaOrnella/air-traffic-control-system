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
📸 Visual Proof and Verification Links

This table contains direct links to the key screenshots and diagrams required to verify the system's functionality and adherence to the design goals.

| Artifact | Purpose | Proof File Link |
| :--- | :--- | :--- |
| **Business Process Model (Assignment)** | Shows the automation flow from request to assignment and auditing (Phase II). | [View Diagram](screenshots/ATC_Landing_Request_Flow.png) |
| **Business Process Model (Emergency)** | Shows the complex flow for handling emergencies and manual controller override. [View Diagram](screenshots/Air_Traffic_Emergency_Flow.png) 
| **System Architecture** | Proves the design utilizes the professional 3-Tier Model with PL/SQL as the Application Tier (Phase III). | [View Diagram](screenshots/tier.png) |
| **Package/Trigger Verification** | The combined output from running the `validation_test.sql` script, confirming the success of the package and trigger. | [View Screenshot](screenshots/validation_test.png) |
| **Schema Structure** | Visual proof of table creation, column details, and Foreign Key relationships (Phase III). | [View Screenshot](screenshots/foreign keys and relationships.png) |
| **Security Audit Log Entry** | Proof that the system recorded the security event (a "BLOCKED" entry) in the `AUDIT_LOG` table for compliance (Phase VII). | [View Screenshot](screenshots/Only_recent_audits.png) |
| **Summary of Verification** | A final consolidated output showing overall test results. | [View Screenshot](screenshots/summary.png) |

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
