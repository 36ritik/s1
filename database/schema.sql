-- Pipe Management System Schema
-- MySQL 8.x

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS targets;
DROP TABLE IF EXISTS dpr_photos;
DROP TABLE IF EXISTS dpr_custom_fields;
DROP TABLE IF EXISTS dpr_fittings;
DROP TABLE IF EXISTS dprs;
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS inventory_items;
DROP TABLE IF EXISTS vendors;
DROP TABLE IF EXISTS engineers;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin','engineer','viewer') NOT NULL DEFAULT 'viewer',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    last_login_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_role_active (role, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE engineers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    employee_code VARCHAR(50) NOT NULL,
    phone VARCHAR(25) NULL,
    zone VARCHAR(80) NULL,
    designation VARCHAR(100) NULL,
    is_available TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_engineers_user_id (user_id),
    UNIQUE KEY uq_engineers_employee_code (employee_code),
    KEY idx_engineers_zone_available (zone, is_available),
    CONSTRAINT fk_engineers_user FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vendors (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(120) NULL,
    contact_phone VARCHAR(25) NULL,
    email VARCHAR(190) NULL,
    gst_number VARCHAR(30) NULL,
    address TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_vendors_name (vendor_name),
    KEY idx_vendors_contact_phone (contact_phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventory_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(80) NOT NULL,
    item_name VARCHAR(150) NOT NULL,
    category VARCHAR(80) NOT NULL DEFAULT 'pipe',
    diameter_mm DECIMAL(10,2) NULL,
    unit VARCHAR(30) NOT NULL DEFAULT 'pcs',
    current_stock DECIMAL(14,3) NOT NULL DEFAULT 0,
    reorder_level DECIMAL(14,3) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0,
    location_code VARCHAR(60) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_inventory_sku (sku),
    KEY idx_inventory_name (item_name),
    KEY idx_inventory_low_stock (is_active, current_stock, reorder_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE purchases (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_id BIGINT UNSIGNED NOT NULL,
    inventory_item_id BIGINT UNSIGNED NOT NULL,
    purchase_ref VARCHAR(80) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL,
    unit_price DECIMAL(14,2) NOT NULL,
    purchased_on DATE NOT NULL,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_purchase_ref_item (purchase_ref, inventory_item_id),
    KEY idx_purchases_vendor_date (vendor_id, purchased_on),
    KEY idx_purchases_item_date (inventory_item_id, purchased_on),
    CONSTRAINT fk_purchases_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_inventory FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_purchases_created_by FOREIGN KEY (created_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_purchases_qty CHECK (quantity > 0),
    CONSTRAINT chk_purchases_unit_price CHECK (unit_price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE assignments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    engineer_id BIGINT UNSIGNED NOT NULL,
    inventory_item_id BIGINT UNSIGNED NOT NULL,
    assigned_qty DECIMAL(14,3) NOT NULL,
    used_qty DECIMAL(14,3) NOT NULL DEFAULT 0,
    status ENUM('assigned','in_progress','completed','cancelled') NOT NULL DEFAULT 'assigned',
    assigned_by BIGINT UNSIGNED NOT NULL,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NULL,
    remarks TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_assignments_engineer_status (engineer_id, status),
    KEY idx_assignments_item_status (inventory_item_id, status),
    KEY idx_assignments_due_date (due_date),
    CONSTRAINT fk_assignments_engineer FOREIGN KEY (engineer_id) REFERENCES engineers(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_assignments_inventory FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_assignments_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_assignments_qty CHECK (assigned_qty > 0),
    CONSTRAINT chk_assignments_used_qty CHECK (used_qty >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dprs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    engineer_id BIGINT UNSIGNED NOT NULL,
    assignment_id BIGINT UNSIGNED NULL,
    report_date DATE NOT NULL,
    site_name VARCHAR(190) NOT NULL,
    work_summary TEXT NOT NULL,
    pipes_used_qty DECIMAL(14,3) NOT NULL DEFAULT 0,
    status ENUM('draft','submitted','approved','rejected') NOT NULL DEFAULT 'submitted',
    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,
    rejection_reason VARCHAR(255) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_dprs_engineer_date (engineer_id, report_date),
    KEY idx_dprs_status_date (status, report_date),
    KEY idx_dprs_assignment (assignment_id),
    CONSTRAINT fk_dprs_engineer FOREIGN KEY (engineer_id) REFERENCES engineers(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_dprs_assignment FOREIGN KEY (assignment_id) REFERENCES assignments(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_dprs_approved_by FOREIGN KEY (approved_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_dprs_pipes_used CHECK (pipes_used_qty >= 0),
    CONSTRAINT chk_dprs_latitude CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT chk_dprs_longitude CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dpr_fittings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dpr_id BIGINT UNSIGNED NOT NULL,
    inventory_item_id BIGINT UNSIGNED NOT NULL,
    fitting_name VARCHAR(150) NOT NULL,
    quantity DECIMAL(14,3) NOT NULL,
    unit VARCHAR(30) NOT NULL DEFAULT 'pcs',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_dpr_fittings_dpr (dpr_id),
    KEY idx_dpr_fittings_inventory (inventory_item_id),
    CONSTRAINT fk_dpr_fittings_dpr FOREIGN KEY (dpr_id) REFERENCES dprs(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_dpr_fittings_inventory FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_dpr_fittings_qty CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dpr_custom_fields (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dpr_id BIGINT UNSIGNED NOT NULL,
    field_key VARCHAR(80) NOT NULL,
    field_label VARCHAR(120) NOT NULL,
    field_value TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dpr_custom_fields_key (dpr_id, field_key),
    KEY idx_dpr_custom_fields_dpr (dpr_id),
    CONSTRAINT fk_dpr_custom_fields_dpr FOREIGN KEY (dpr_id) REFERENCES dprs(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dpr_photos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dpr_id BIGINT UNSIGNED NOT NULL,
    photo_path VARCHAR(255) NOT NULL,
    photo_caption VARCHAR(160) NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by BIGINT UNSIGNED NOT NULL,
    KEY idx_dpr_photos_dpr (dpr_id),
    CONSTRAINT fk_dpr_photos_dpr FOREIGN KEY (dpr_id) REFERENCES dprs(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_dpr_photos_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE targets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    engineer_id BIGINT UNSIGNED NOT NULL,
    target_month DATE NOT NULL,
    target_pipes_qty DECIMAL(14,3) NOT NULL,
    target_sites_count INT UNSIGNED NOT NULL DEFAULT 0,
    created_by BIGINT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_targets_engineer_month (engineer_id, target_month),
    KEY idx_targets_month (target_month),
    CONSTRAINT fk_targets_engineer FOREIGN KEY (engineer_id) REFERENCES engineers(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_targets_created_by FOREIGN KEY (created_by) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_targets_pipes CHECK (target_pipes_qty >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    action VARCHAR(120) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id BIGINT UNSIGNED NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_audit_logs_user_date (user_id, created_at),
    KEY idx_audit_logs_entity (entity_type, entity_id),
    KEY idx_audit_logs_action (action),
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample Data
INSERT INTO users (full_name, email, password_hash, role, is_active) VALUES
('System Admin', 'admin@pipes.local', '$argon2id$v=19$m=65536,t=4,p=1$ZmFrZXNhbHQxMjM0NTY3OA$5XrF6gKPg9g3Qh6O0gX90Ql7Co6Y5dfYw8W18yG9z2k', 'admin', 1),
('Engr. John Carter', 'john.carter@pipes.local', '$argon2id$v=19$m=65536,t=4,p=1$ZmFrZXNhbHQxMjM0NTY3OA$5XrF6gKPg9g3Qh6O0gX90Ql7Co6Y5dfYw8W18yG9z2k', 'engineer', 1),
('Report Viewer', 'viewer@pipes.local', '$argon2id$v=19$m=65536,t=4,p=1$ZmFrZXNhbHQxMjM0NTY3OA$5XrF6gKPg9g3Qh6O0gX90Ql7Co6Y5dfYw8W18yG9z2k', 'viewer', 1);

INSERT INTO engineers (user_id, employee_code, phone, zone, designation) VALUES
(2, 'ENG-1001', '+1-555-0101', 'North Zone', 'Field Engineer');

INSERT INTO vendors (vendor_name, contact_person, contact_phone, email, gst_number, address) VALUES
('Prime Pipe Supplies', 'Martha Lee', '+1-555-0201', 'sales@primepipe.com', 'GST-PRM-1021', '101 Industrial Park, Houston, TX'),
('Metro Industrial', 'Dan Miller', '+1-555-0202', 'contact@metroind.com', 'GST-MET-5561', '77 Harbor Road, Austin, TX');

INSERT INTO inventory_items (sku, item_name, category, diameter_mm, unit, current_stock, reorder_level, unit_cost, location_code) VALUES
('PIPE-PVC-110', 'PVC Pipe 110mm', 'pipe', 110.00, 'mtr', 800.000, 150.000, 5.20, 'A1-R1'),
('PIPE-HDPE-90', 'HDPE Pipe 90mm', 'pipe', 90.00, 'mtr', 420.000, 120.000, 4.80, 'A1-R2'),
('FIT-ELBOW-110', 'Elbow Fitting 110mm', 'fitting', 110.00, 'pcs', 350.000, 80.000, 1.25, 'B2-R1');

INSERT INTO purchases (vendor_id, inventory_item_id, purchase_ref, quantity, unit_price, purchased_on, created_by) VALUES
(1, 1, 'PO-2026-0001', 500.000, 5.00, '2026-01-15', 1),
(2, 2, 'PO-2026-0002', 300.000, 4.50, '2026-01-18', 1),
(1, 3, 'PO-2026-0003', 200.000, 1.10, '2026-01-20', 1);

INSERT INTO assignments (engineer_id, inventory_item_id, assigned_qty, used_qty, status, assigned_by, due_date, remarks) VALUES
(1, 1, 120.000, 0.000, 'assigned', 1, '2026-04-15', 'Pipeline expansion at Site Delta');

INSERT INTO dprs (engineer_id, assignment_id, report_date, site_name, work_summary, pipes_used_qty, status, latitude, longitude) VALUES
(1, 1, '2026-04-01', 'Site Delta', 'Excavation and laying primary 110mm line.', 30.000, 'submitted', 29.7604000, -95.3698000);

INSERT INTO dpr_fittings (dpr_id, inventory_item_id, fitting_name, quantity, unit) VALUES
(1, 3, 'Elbow Fitting 110mm', 10.000, 'pcs');

INSERT INTO dpr_custom_fields (dpr_id, field_key, field_label, field_value) VALUES
(1, 'weather', 'Weather Condition', 'Sunny'),
(1, 'crew_size', 'Crew Size', '6');

INSERT INTO dpr_photos (dpr_id, photo_path, photo_caption, uploaded_by) VALUES
(1, 'uploads/dpr/2026/04/site-delta-line-1.jpg', 'Primary trench completion', 2);

INSERT INTO targets (engineer_id, target_month, target_pipes_qty, target_sites_count, created_by) VALUES
(1, '2026-04-01', 350.000, 4, 1);

INSERT INTO audit_logs (user_id, action, entity_type, entity_id, ip_address, user_agent, old_values, new_values) VALUES
(1, 'CREATE', 'assignment', 1, '127.0.0.1', 'Seeder', NULL, JSON_OBJECT('engineer_id', 1, 'inventory_item_id', 1, 'assigned_qty', 120.000)),
(2, 'SUBMIT_DPR', 'dpr', 1, '127.0.0.1', 'Seeder', NULL, JSON_OBJECT('status', 'submitted', 'pipes_used_qty', 30.000));
