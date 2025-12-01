-- =============================================
-- AUDIT AND SECURITY QUERIES
-- Compliance and Monitoring
-- =============================================

-- 1. AUDIT TRAIL SUMMARY
SELECT 
    table_name,
    operation_type,
    success_flag,
    COUNT(*) AS operation_count,
    MIN(timestamp) AS first_operation,
    MAX(timestamp) AS last_operation,
    ROUND(AVG(LENGTH(error_message)), 0) AS avg_error_length
FROM audit_log
GROUP BY table_name, operation_type, success_flag
ORDER BY operation_count DESC;

-- 2. SECURITY VIOLATIONS DETECTION
SELECT 
    log_id,
    table_name,
    operation_type,
    user_name,
    TO_CHAR(timestamp, 'DD-MON-YYYY HH24:MI:SS') AS violation_time,
    error_message,
    CASE 
        WHEN error_message LIKE '%weekday%' OR error_message LIKE '%holiday%' THEN 'Business Rule Violation'
        WHEN error_message LIKE '%privilege%' OR error_message LIKE '%permission%' THEN 'Security Violation'
        WHEN error_message LIKE '%constraint%' OR error_message LIKE '%foreign key%' THEN 'Data Integrity Violation'
        ELSE 'Other Violation'
    END AS violation_type
FROM audit_log
WHERE success_flag = 'N'
ORDER BY timestamp DESC;

-- 3. USER ACTIVITY MONITORING
SELECT 
    user_name,
    COUNT(*) AS total_operations,
    SUM(CASE WHEN success_flag = 'Y' THEN 1 ELSE 0 END) AS successful_ops,
    SUM(CASE WHEN success_flag = 'N' THEN 1 ELSE 0 END) AS failed_ops,
    MIN(timestamp) AS first_activity,
    MAX(timestamp) AS last_activity,
    ROUND(SUM(CASE WHEN success_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM audit_log
GROUP BY user_name
ORDER BY total_operations DESC;

-- 4. BUSINESS RULE COMPLIANCE CHECK
SELECT 
    'Weekday DML Restriction' AS rule_name,
    COUNT(*) AS violation_count,
    TO_CHAR(MIN(timestamp), 'DD-MON-YYYY') AS first_violation,
    TO_CHAR(MAX(timestamp), 'DD-MON-YYYY') AS last_violation,
    LISTAGG(DISTINCT TO_CHAR(timestamp, 'DAY'), ', ') WITHIN GROUP (ORDER BY timestamp) AS violation_days
FROM audit_log
WHERE error_message LIKE '%weekday%' OR error_message LIKE '%holiday%'
UNION ALL
SELECT 
    'Emergency Priority Override' AS rule_name,
    COUNT(*) AS application_count,
    TO_CHAR(MIN(timestamp), 'DD-MON-YYYY') AS first_application,
    TO_CHAR(MAX(timestamp), 'DD-MON-YYYY') AS last_application,
    LISTAGG(DISTINCT table_name, ', ') WITHIN GROUP (ORDER BY table_name) AS affected_tables
FROM audit_log
WHERE operation_type = 'PRIORITY_OVERRIDE' AND success_flag = 'Y';

-- 5. DATA MODIFICATION AUDIT
SELECT 
    al.table_name,
    al.operation_type,
    TO_CHAR(al.timestamp, 'DD-MON-YYYY') AS operation_date,
    al.user_name,
    COUNT(*) AS operation_count,
    SUBSTR(MIN(al.new_values), 1, 50) AS sample_new_value,
    SUBSTR(MIN(al.old_values), 1, 50) AS sample_old_value
FROM audit_log al
WHERE al.operation_type IN ('INSERT', 'UPDATE', 'DELETE')
AND al.success_flag = 'Y'
GROUP BY al.table_name, al.operation_type, TO_CHAR(al.timestamp, 'DD-MON-YYYY'), al.user_name
ORDER BY operation_date DESC, operation_count DESC;

-- 6. SYSTEM HEALTH AUDIT
WITH daily_audit AS (
    SELECT 
        TRUNC(timestamp) AS audit_date,
        COUNT(*) AS total_operations,
        SUM(CASE WHEN success_flag = 'Y' THEN 1 ELSE 0 END) AS successful_ops,
        SUM(CASE WHEN success_flag = 'N' THEN 1 ELSE 0 END) AS failed_ops,
        COUNT(DISTINCT user_name) AS active_users,
        COUNT(DISTINCT table_name) AS tables_accessed
    FROM audit_log
    GROUP BY TRUNC(timestamp)
)
SELECT 
    audit_date,
    total_operations,
    successful_ops,
    failed_ops,
    ROUND(successful_ops * 100.0 / total_operations, 2) AS success_rate,
    active_users,
    tables_accessed,
    CASE 
        WHEN successful_ops * 100.0 / total_operations >= 95 THEN 'Excellent'
        WHEN successful_ops * 100.0 / total_operations >= 85 THEN 'Good'
        WHEN successful_ops * 100.0 / total_operations >= 70 THEN 'Fair'
        ELSE 'Needs Attention'
    END AS system_health
FROM daily_audit
ORDER BY audit_date DESC;

-- 7. EMERGENCY OPERATIONS AUDIT
SELECT 
    TO_CHAR(timestamp, 'DD-MON-YYYY') AS operation_date,
    operation_type,
    table_name,
    user_name,
    COUNT(*) AS operation_count,
    LISTAGG(DISTINCT SUBSTR(error_message, 1, 30), '; ') WITHIN GROUP (ORDER BY timestamp) AS error_samples
FROM audit_log
WHERE operation_type IN ('EMERGENCY', 'PRIORITY_OVERRIDE', 'AUTO_DELAY')
OR error_message LIKE '%emergency%'
OR error_message LIKE '%priority%'
GROUP BY TO_CHAR(timestamp, 'DD-MON-YYYY'), operation_type, table_name, user_name
ORDER BY operation_date DESC, operation_count DESC;

-- 8. COMPREHENSIVE SECURITY REPORT
SELECT 
    'Total Audit Entries' AS metric, COUNT(*) AS value FROM audit_log
UNION ALL
SELECT 'Successful Operations', SUM(CASE WHEN success_flag = 'Y' THEN 1 ELSE 0 END) FROM audit_log
UNION ALL
SELECT 'Failed Operations', SUM(CASE WHEN success_flag = 'N' THEN 1 ELSE 0 END) FROM audit_log
UNION ALL
SELECT 'Unique Users', COUNT(DISTINCT user_name) FROM audit_log
UNION ALL
SELECT 'Monitored Tables', COUNT(DISTINCT table_name) FROM audit_log
UNION ALL
SELECT 'Business Rule Violations', COUNT(*) FROM audit_log WHERE error_message LIKE '%weekday%' OR error_message LIKE '%holiday%'
UNION ALL
SELECT 'Emergency Overrides', COUNT(*) FROM audit_log WHERE operation_type = 'PRIORITY_OVERRIDE'
UNION ALL
SELECT 'System Health Score', ROUND(SUM(CASE WHEN success_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM audit_log;
