# Critical Design Decisions for ATC-MS

This document outlines the justification for key design choices made throughout the project phases, particularly concerning normalization, performance, and security.

## A. Logical Model Decisions (Phase III)

| Decision | Implementation | Rationale |
| :--- | :--- | :--- |
| **Normalization to 3NF** | Separated Airline details into the `AIRLINES` table; `FLIGHTS` uses only `AIRLINE_CODE` (FK). | **Eliminates Transitive Dependency.** Avoids storing the full airline name multiple times in the `FLIGHTS` table, saving space and ensuring data integrity upon updates. |
| **Linking Table** | Introduced `FLIGHT_ASSIGNMENTS` as a bridge between `FLIGHTS` and `AIRPORT_RESOURCES`. | **Resolves Many-to-Many Relationship.** A flight can use many resources (runway, then gate), and a resource can serve many flights. This table tracks the specific event (Fact Table). |
| **Surrogate Keys** | Used Sequences (`FLIGHT_SEQ`, `ASSIGNMENT_SEQ`, etc.) for all Primary Keys. | **Ensures Stability for BI.** Provides simple, non-meaningful keys that are ideal for foreign key joins, preventing schema changes if business rules (like flight number format) change. |

## B. PL/SQL and Logic Decisions (Phase IV)

| Decision | Implementation | Rationale |
| :--- | :--- | :--- |
| **Packages over Standalone Procedures** | All core logic is housed in `atc_manager_pkg`. | **Improved Performance and Security.** Packages are compiled once and stored efficiently, reducing parsing overhead. They also grant execution rights at the package level, minimizing exposed permissions. |
| **Cursor Logic for Assignments** | Used `FOR UPDATE` cursors within the assignment procedure. | **Prevents Concurrency Issues.** The `FOR UPDATE` clause locks the selected resources temporarily, preventing two controllers from assigning the same runway to two different flights simultaneously, ensuring data consistency in a multi-user environment. |

## C. Security and Auditing Decisions (Phase VII)

| Decision | Implementation | Rationale |
| :--- | :--- | :--- |
| **Compound Trigger** | Used a single Compound Trigger on the `FLIGHTS` table. | **Efficient Transaction Control.** Allows combining multiple timing points (`BEFORE STATEMENT`, `BEFORE ROW`, `AFTER STATEMENT`) within a single object, simplifying the logic for the complex security rule (block DML AND log the attempt). |
| **AUDIT\_LOG Table** | Separate, dedicated table for logging all changes. | **Compliance and Immutability.** Guarantees that audit records are physically separate from the operational data. Even if a transaction is rolled back, the audit record can be committed (if designed properly), ensuring a permanent, tamper-proof security log. |
