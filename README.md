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

## 🚀 Key Features & Deliverables by Phase

| Phase | Feature Implemented | Technical Components |
| :--- | :--- | :--- |
| **Phase II** | **Business Process Model** | Swimlane Diagram (`image_ecba15.jpg`) showing Pilot, System, and Controller interaction. |
| **Phase III** | **Logical Model Design (3NF)** | Fully normalized schema with detailed Data Dictionary. |
| **Phase IV** | **Core Logic** | `atc_manager_pkg.assign_runway` procedure and utility functions. |
| **Phase VII**| **Security & Auditing** | Compound Trigger (`05_triggers.sql`) to **block DML on weekdays** and record all attempts in `AUDIT_LOG`. |
| **Phase VIII**| **Business Intelligence** | Analytical queries in `queries/analytics.sql` for OTP calculation. |

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
