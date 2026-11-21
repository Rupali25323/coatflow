-- Powder Coating CRM schema
-- Requires MySQL 8.0.16+ for enforced CHECK constraints.
-- This script creates objects only; it does not drop or alter existing data.

CREATE DATABASE IF NOT EXISTS powder_coating_crm
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE powder_coating_crm;

CREATE TABLE IF NOT EXISTS roles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  description VARCHAR(255) NULL,
  is_system TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  permission_key VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_key (permission_key)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id BIGINT UNSIGNED NOT NULL,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(30) NULL,
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('active', 'invited', 'suspended', 'inactive') NOT NULL DEFAULT 'invited',
  last_login_at DATETIME NULL,
  password_changed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_status (role_id, status),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(512) NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_sessions_token_hash (token_hash),
  KEY idx_user_sessions_user_expiry (user_id, expires_at),
  CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_code VARCHAR(30) NOT NULL,
  company_name VARCHAR(180) NOT NULL,
  contact_name VARCHAR(160) NULL,
  email VARCHAR(190) NULL,
  phone VARCHAR(30) NULL,
  alternate_phone VARCHAR(30) NULL,
  gstin CHAR(15) NULL,
  pan CHAR(10) NULL,
  billing_address_line1 VARCHAR(180) NULL,
  billing_address_line2 VARCHAR(180) NULL,
  billing_city VARCHAR(100) NULL,
  billing_state VARCHAR(100) NULL,
  billing_postal_code VARCHAR(20) NULL,
  billing_country VARCHAR(80) NOT NULL DEFAULT 'India',
  shipping_address_line1 VARCHAR(180) NULL,
  shipping_address_line2 VARCHAR(180) NULL,
  shipping_city VARCHAR(100) NULL,
  shipping_state VARCHAR(100) NULL,
  shipping_postal_code VARCHAR(20) NULL,
  shipping_country VARCHAR(80) NOT NULL DEFAULT 'India',
  payment_terms_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  credit_limit DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  status ENUM('active', 'inactive', 'prospect', 'blocked') NOT NULL DEFAULT 'active',
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_code (customer_code),
  UNIQUE KEY uq_customers_gstin (gstin),
  KEY idx_customers_company_name (company_name),
  KEY idx_customers_status (status),
  CONSTRAINT chk_customers_credit_limit CHECK (credit_limit >= 0),
  CONSTRAINT fk_customers_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS suppliers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  supplier_code VARCHAR(30) NOT NULL,
  company_name VARCHAR(180) NOT NULL,
  contact_name VARCHAR(160) NULL,
  email VARCHAR(190) NULL,
  phone VARCHAR(30) NULL,
  gstin CHAR(15) NULL,
  billing_address_line1 VARCHAR(180) NULL,
  billing_address_line2 VARCHAR(180) NULL,
  city VARCHAR(100) NULL,
  state VARCHAR(100) NULL,
  postal_code VARCHAR(20) NULL,
  country VARCHAR(80) NOT NULL DEFAULT 'India',
  payment_terms_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('active', 'inactive', 'blocked') NOT NULL DEFAULT 'active',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_suppliers_code (supplier_code),
  UNIQUE KEY uq_suppliers_gstin (gstin),
  KEY idx_suppliers_company_name (company_name),
  KEY idx_suppliers_status (status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS powder_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  default_unit VARCHAR(20) NOT NULL DEFAULT 'kg',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_powder_categories_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_code VARCHAR(40) NOT NULL,
  name VARCHAR(180) NOT NULL,
  item_type ENUM('powder', 'chemical', 'packaging', 'spare_part', 'other') NOT NULL,
  powder_category_id BIGINT UNSIGNED NULL,
  manufacturer VARCHAR(120) NULL,
  shade_code VARCHAR(40) NULL,
  finish VARCHAR(80) NULL,
  unit_of_measure VARCHAR(20) NOT NULL,
  quantity_on_hand DECIMAL(14,3) NOT NULL DEFAULT 0.000,
  reorder_level DECIMAL(14,3) NOT NULL DEFAULT 0.000,
  average_unit_cost DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  bin_location VARCHAR(80) NULL,
  status ENUM('active', 'inactive', 'discontinued') NOT NULL DEFAULT 'active',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_inventory_items_code (item_code),
  KEY idx_inventory_items_name (name),
  KEY idx_inventory_items_type_status (item_type, status),
  KEY idx_inventory_items_category (powder_category_id),
  CONSTRAINT chk_inventory_items_quantities CHECK (quantity_on_hand >= 0 AND reorder_level >= 0 AND average_unit_cost >= 0),
  CONSTRAINT chk_powder_category_required CHECK (item_type <> 'powder' OR powder_category_id IS NOT NULL),
  CONSTRAINT fk_inventory_items_category FOREIGN KEY (powder_category_id) REFERENCES powder_categories (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory_suppliers (
  inventory_item_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  supplier_item_code VARCHAR(60) NULL,
  last_purchase_price DECIMAL(14,4) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (inventory_item_id, supplier_id),
  CONSTRAINT chk_inventory_suppliers_price CHECK (last_purchase_price IS NULL OR last_purchase_price >= 0),
  CONSTRAINT fk_inventory_suppliers_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_items (id) ON DELETE CASCADE,
  CONSTRAINT fk_inventory_suppliers_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customer_enquiries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  enquiry_number VARCHAR(30) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  assigned_to BIGINT UNSIGNED NULL,
  source ENUM('phone', 'email', 'website', 'referral', 'walk_in', 'other') NOT NULL DEFAULT 'other',
  subject VARCHAR(180) NOT NULL,
  received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  required_by DATE NULL,
  status ENUM('new', 'qualified', 'quoted', 'converted', 'lost', 'cancelled') NOT NULL DEFAULT 'new',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customer_enquiries_number (enquiry_number),
  KEY idx_customer_enquiries_customer_status (customer_id, status),
  KEY idx_customer_enquiries_assigned (assigned_to, status),
  CONSTRAINT fk_customer_enquiries_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_customer_enquiries_assigned FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS enquiry_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  enquiry_id BIGINT UNSIGNED NOT NULL,
  line_number SMALLINT UNSIGNED NOT NULL,
  item_description VARCHAR(255) NOT NULL,
  material VARCHAR(100) NULL,
  finish VARCHAR(80) NULL,
  color_name VARCHAR(80) NULL,
  color_code VARCHAR(40) NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'piece',
  approximate_area_sq_m DECIMAL(12,4) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_enquiry_items_line (enquiry_id, line_number),
  CONSTRAINT chk_enquiry_items_quantity CHECK (quantity > 0),
  CONSTRAINT chk_enquiry_items_area CHECK (approximate_area_sq_m IS NULL OR approximate_area_sq_m >= 0),
  CONSTRAINT fk_enquiry_items_enquiry FOREIGN KEY (enquiry_id) REFERENCES customer_enquiries (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quotations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  quotation_number VARCHAR(30) NOT NULL,
  enquiry_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  prepared_by BIGINT UNSIGNED NULL,
  revision SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  issue_date DATE NOT NULL,
  valid_until DATE NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  status ENUM('draft', 'sent', 'approved', 'rejected', 'expired', 'converted', 'cancelled') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  terms TEXT NULL,
  notes TEXT NULL,
  approved_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_quotations_number (quotation_number),
  KEY idx_quotations_customer_status (customer_id, status),
  KEY idx_quotations_enquiry (enquiry_id),
  KEY idx_quotations_prepared_by (prepared_by),
  CONSTRAINT chk_quotations_amounts CHECK (subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0),
  CONSTRAINT chk_quotations_dates CHECK (valid_until >= issue_date),
  CONSTRAINT fk_quotations_enquiry FOREIGN KEY (enquiry_id) REFERENCES customer_enquiries (id) ON DELETE SET NULL,
  CONSTRAINT fk_quotations_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_quotations_prepared_by FOREIGN KEY (prepared_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quotation_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  quotation_id BIGINT UNSIGNED NOT NULL,
  line_number SMALLINT UNSIGNED NOT NULL,
  item_description VARCHAR(255) NOT NULL,
  material VARCHAR(100) NULL,
  finish VARCHAR(80) NULL,
  color_name VARCHAR(80) NULL,
  color_code VARCHAR(40) NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'piece',
  unit_price DECIMAL(14,4) NOT NULL,
  discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  tax_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_quotation_items_line (quotation_id, line_number),
  CONSTRAINT chk_quotation_items_values CHECK (quantity > 0 AND unit_price >= 0 AND discount_percent BETWEEN 0 AND 100 AND tax_percent BETWEEN 0 AND 100 AND line_total >= 0),
  CONSTRAINT fk_quotation_items_quotation FOREIGN KEY (quotation_id) REFERENCES quotations (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales_orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_number VARCHAR(30) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  quotation_id BIGINT UNSIGNED NULL,
  sales_person_id BIGINT UNSIGNED NULL,
  order_date DATE NOT NULL,
  requested_delivery_date DATE NULL,
  confirmed_delivery_date DATE NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  status ENUM('draft', 'confirmed', 'in_production', 'ready_to_ship', 'partially_dispatched', 'dispatched', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  billing_address_snapshot JSON NULL,
  shipping_address_snapshot JSON NULL,
  customer_gstin_snapshot CHAR(15) NULL,
  terms TEXT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sales_orders_number (order_number),
  UNIQUE KEY uq_sales_orders_quotation (quotation_id),
  KEY idx_sales_orders_customer_status (customer_id, status),
  KEY idx_sales_orders_delivery_date (requested_delivery_date, status),
  KEY idx_sales_orders_sales_person (sales_person_id),
  CONSTRAINT chk_sales_orders_amounts CHECK (subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0),
  CONSTRAINT fk_sales_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_sales_orders_quotation FOREIGN KEY (quotation_id) REFERENCES quotations (id) ON DELETE SET NULL,
  CONSTRAINT fk_sales_orders_sales_person FOREIGN KEY (sales_person_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales_order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  quotation_item_id BIGINT UNSIGNED NULL,
  line_number SMALLINT UNSIGNED NOT NULL,
  item_description VARCHAR(255) NOT NULL,
  material VARCHAR(100) NULL,
  finish VARCHAR(80) NULL,
  color_name VARCHAR(80) NULL,
  color_code VARCHAR(40) NULL,
  quantity_ordered DECIMAL(12,3) NOT NULL,
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'piece',
  unit_price DECIMAL(14,4) NOT NULL,
  discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  tax_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sales_order_items_line (sales_order_id, line_number),
  KEY idx_sales_order_items_quotation_item (quotation_item_id),
  CONSTRAINT chk_sales_order_items_values CHECK (quantity_ordered > 0 AND unit_price >= 0 AND discount_percent BETWEEN 0 AND 100 AND tax_percent BETWEEN 0 AND 100 AND line_total >= 0),
  CONSTRAINT fk_sales_order_items_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders (id) ON DELETE CASCADE,
  CONSTRAINT fk_sales_order_items_quotation_item FOREIGN KEY (quotation_item_id) REFERENCES quotation_items (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_cards (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_card_number VARCHAR(30) NOT NULL,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  created_by BIGINT UNSIGNED NULL,
  assigned_to BIGINT UNSIGNED NULL,
  planned_start_date DATE NULL,
  planned_end_date DATE NULL,
  actual_start_at DATETIME NULL,
  actual_end_at DATETIME NULL,
  priority ENUM('low', 'normal', 'high', 'urgent') NOT NULL DEFAULT 'normal',
  status ENUM('draft', 'queued', 'in_progress', 'on_hold', 'quality_check', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
  instructions TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_job_cards_number (job_card_number),
  KEY idx_job_cards_order_status (sales_order_id, status),
  KEY idx_job_cards_assigned_status (assigned_to, status),
  CONSTRAINT chk_job_cards_planned_dates CHECK (planned_end_date IS NULL OR planned_start_date IS NULL OR planned_end_date >= planned_start_date),
  CONSTRAINT fk_job_cards_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders (id) ON DELETE RESTRICT,
  CONSTRAINT fk_job_cards_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_job_cards_assigned_to FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_card_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_card_id BIGINT UNSIGNED NOT NULL,
  sales_order_item_id BIGINT UNSIGNED NOT NULL,
  line_number SMALLINT UNSIGNED NOT NULL,
  quantity_planned DECIMAL(12,3) NOT NULL,
  quantity_completed DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  quantity_rejected DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  status ENUM('queued', 'in_progress', 'quality_check', 'completed', 'on_hold', 'cancelled') NOT NULL DEFAULT 'queued',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_job_card_items_line (job_card_id, line_number),
  KEY idx_job_card_items_order_item (sales_order_item_id),
  CONSTRAINT chk_job_card_items_quantities CHECK (quantity_planned > 0 AND quantity_completed >= 0 AND quantity_rejected >= 0),
  CONSTRAINT fk_job_card_items_job_card FOREIGN KEY (job_card_id) REFERENCES job_cards (id) ON DELETE CASCADE,
  CONSTRAINT fk_job_card_items_order_item FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_items (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS production_stages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  stage_code VARCHAR(30) NOT NULL,
  name VARCHAR(100) NOT NULL,
  sequence_number SMALLINT UNSIGNED NOT NULL,
  description VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_production_stages_code (stage_code),
  UNIQUE KEY uq_production_stages_sequence (sequence_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS production_records (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  job_card_item_id BIGINT UNSIGNED NOT NULL,
  production_stage_id BIGINT UNSIGNED NOT NULL,
  operator_id BIGINT UNSIGNED NULL,
  started_at DATETIME NOT NULL,
  completed_at DATETIME NULL,
  quantity_processed DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  quantity_completed DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  quantity_rejected DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  status ENUM('queued', 'in_progress', 'completed', 'on_hold', 'skipped') NOT NULL DEFAULT 'queued',
  machine_name VARCHAR(100) NULL,
  temperature_celsius DECIMAL(6,2) NULL,
  duration_minutes INT UNSIGNED NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_production_records_job_item_stage (job_card_item_id, production_stage_id),
  KEY idx_production_records_operator_status (operator_id, status),
  KEY idx_production_records_started_at (started_at),
  CONSTRAINT chk_production_record_quantities CHECK (
    quantity_processed >= 0 AND quantity_completed >= 0 AND quantity_rejected >= 0
    AND quantity_completed + quantity_rejected <= quantity_processed
  ),
  CONSTRAINT chk_production_record_dates CHECK (completed_at IS NULL OR completed_at >= started_at),
  CONSTRAINT fk_production_records_job_card_item FOREIGN KEY (job_card_item_id) REFERENCES job_card_items (id) ON DELETE CASCADE,
  CONSTRAINT fk_production_records_stage FOREIGN KEY (production_stage_id) REFERENCES production_stages (id) ON DELETE RESTRICT,
  CONSTRAINT fk_production_records_operator FOREIGN KEY (operator_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS powder_stock_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  inventory_item_id BIGINT UNSIGNED NOT NULL,
  supplier_id BIGINT UNSIGNED NULL,
  job_card_id BIGINT UNSIGNED NULL,
  production_record_id BIGINT UNSIGNED NULL,
  recorded_by BIGINT UNSIGNED NULL,
  transaction_type ENUM('purchase', 'consumption', 'adjustment_in', 'adjustment_out', 'return', 'waste') NOT NULL,
  quantity DECIMAL(14,3) NOT NULL,
  unit_cost DECIMAL(14,4) NULL,
  reference_number VARCHAR(80) NULL,
  transaction_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_powder_transactions_item_date (inventory_item_id, transaction_at),
  KEY idx_powder_transactions_job_card (job_card_id),
  KEY idx_powder_transactions_production_record (production_record_id),
  KEY idx_powder_transactions_supplier (supplier_id),
  CONSTRAINT chk_powder_transaction_values CHECK (quantity > 0 AND (unit_cost IS NULL OR unit_cost >= 0)),
  CONSTRAINT fk_powder_transactions_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_items (id) ON DELETE RESTRICT,
  CONSTRAINT fk_powder_transactions_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL,
  CONSTRAINT fk_powder_transactions_job_card FOREIGN KEY (job_card_id) REFERENCES job_cards (id) ON DELETE SET NULL,
  CONSTRAINT fk_powder_transactions_production_record FOREIGN KEY (production_record_id) REFERENCES production_records (id) ON DELETE SET NULL,
  CONSTRAINT fk_powder_transactions_recorded_by FOREIGN KEY (recorded_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quality_control_checks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  inspection_number VARCHAR(30) NOT NULL,
  job_card_item_id BIGINT UNSIGNED NOT NULL,
  production_record_id BIGINT UNSIGNED NULL,
  inspected_by BIGINT UNSIGNED NULL,
  inspected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  quantity_inspected DECIMAL(12,3) NOT NULL,
  quantity_passed DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  quantity_rejected DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  result ENUM('pending', 'passed', 'failed', 'partially_passed') NOT NULL DEFAULT 'pending',
  film_thickness_microns DECIMAL(7,2) NULL,
  adhesion_result VARCHAR(80) NULL,
  color_match_delta_e DECIMAL(6,3) NULL,
  defects TEXT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_quality_checks_number (inspection_number),
  KEY idx_quality_checks_job_item_result (job_card_item_id, result),
  KEY idx_quality_checks_inspected_at (inspected_at),
  CONSTRAINT chk_quality_check_quantities CHECK (
    quantity_inspected > 0 AND quantity_passed >= 0 AND quantity_rejected >= 0
    AND quantity_passed + quantity_rejected <= quantity_inspected
  ),
  CONSTRAINT chk_quality_check_measurements CHECK (
    (film_thickness_microns IS NULL OR film_thickness_microns >= 0)
    AND (color_match_delta_e IS NULL OR color_match_delta_e >= 0)
  ),
  CONSTRAINT fk_quality_checks_job_card_item FOREIGN KEY (job_card_item_id) REFERENCES job_card_items (id) ON DELETE RESTRICT,
  CONSTRAINT fk_quality_checks_production_record FOREIGN KEY (production_record_id) REFERENCES production_records (id) ON DELETE SET NULL,
  CONSTRAINT fk_quality_checks_inspector FOREIGN KEY (inspected_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rework_orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rework_number VARCHAR(30) NOT NULL,
  quality_check_id BIGINT UNSIGNED NOT NULL,
  job_card_item_id BIGINT UNSIGNED NOT NULL,
  assigned_to BIGINT UNSIGNED NULL,
  quantity_to_rework DECIMAL(12,3) NOT NULL,
  quantity_completed DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  reason VARCHAR(255) NOT NULL,
  corrective_action TEXT NULL,
  status ENUM('open', 'in_progress', 'quality_check', 'completed', 'cancelled') NOT NULL DEFAULT 'open',
  opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rework_orders_number (rework_number),
  KEY idx_rework_orders_status_assigned (status, assigned_to),
  CONSTRAINT chk_rework_order_quantities CHECK (quantity_to_rework > 0 AND quantity_completed >= 0 AND quantity_completed <= quantity_to_rework),
  CONSTRAINT fk_rework_orders_quality_check FOREIGN KEY (quality_check_id) REFERENCES quality_control_checks (id) ON DELETE RESTRICT,
  CONSTRAINT fk_rework_orders_job_item FOREIGN KEY (job_card_item_id) REFERENCES job_card_items (id) ON DELETE RESTRICT,
  CONSTRAINT fk_rework_orders_assigned_to FOREIGN KEY (assigned_to) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dispatches (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  dispatch_number VARCHAR(30) NOT NULL,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  dispatched_by BIGINT UNSIGNED NULL,
  carrier_name VARCHAR(120) NULL,
  tracking_number VARCHAR(100) NULL,
  vehicle_number VARCHAR(30) NULL,
  dispatch_date DATETIME NULL,
  expected_delivery_date DATE NULL,
  delivered_at DATETIME NULL,
  status ENUM('draft', 'packing', 'ready', 'dispatched', 'in_transit', 'delivered', 'delivery_failed', 'cancelled') NOT NULL DEFAULT 'draft',
  delivery_address_snapshot JSON NULL,
  delivery_notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dispatches_number (dispatch_number),
  KEY idx_dispatches_order_status (sales_order_id, status),
  KEY idx_dispatches_tracking (tracking_number),
  KEY idx_dispatches_expected_delivery (expected_delivery_date),
  CONSTRAINT fk_dispatches_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders (id) ON DELETE RESTRICT,
  CONSTRAINT fk_dispatches_user FOREIGN KEY (dispatched_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dispatch_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  dispatch_id BIGINT UNSIGNED NOT NULL,
  sales_order_item_id BIGINT UNSIGNED NOT NULL,
  job_card_item_id BIGINT UNSIGNED NULL,
  quantity_dispatched DECIMAL(12,3) NOT NULL,
  package_count SMALLINT UNSIGNED NULL,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dispatch_items_dispatch (dispatch_id),
  KEY idx_dispatch_items_order_item (sales_order_item_id),
  CONSTRAINT chk_dispatch_items_quantity CHECK (quantity_dispatched > 0),
  CONSTRAINT fk_dispatch_items_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches (id) ON DELETE CASCADE,
  CONSTRAINT fk_dispatch_items_order_item FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_items (id) ON DELETE RESTRICT,
  CONSTRAINT fk_dispatch_items_job_item FOREIGN KEY (job_card_item_id) REFERENCES job_card_items (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS delivery_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  dispatch_id BIGINT UNSIGNED NOT NULL,
  recorded_by BIGINT UNSIGNED NULL,
  event_type ENUM('packed', 'picked_up', 'in_transit', 'arrived_at_hub', 'out_for_delivery', 'delivered', 'delivery_failed', 'returned', 'other') NOT NULL,
  event_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  location VARCHAR(180) NULL,
  description VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_delivery_events_dispatch_time (dispatch_id, event_at),
  CONSTRAINT fk_delivery_events_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches (id) ON DELETE CASCADE,
  CONSTRAINT fk_delivery_events_user FOREIGN KEY (recorded_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoices (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invoice_number VARCHAR(30) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  sales_order_id BIGINT UNSIGNED NULL,
  dispatch_id BIGINT UNSIGNED NULL,
  issued_by BIGINT UNSIGNED NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  customer_gstin_snapshot CHAR(15) NULL,
  billing_address_snapshot JSON NULL,
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  status ENUM('draft', 'issued', 'partially_paid', 'paid', 'overdue', 'void') NOT NULL DEFAULT 'draft',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoices_number (invoice_number),
  KEY idx_invoices_customer_status_due (customer_id, status, due_date),
  KEY idx_invoices_order (sales_order_id),
  KEY idx_invoices_dispatch (dispatch_id),
  CONSTRAINT chk_invoice_amounts CHECK (subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0),
  CONSTRAINT chk_invoice_dates CHECK (due_date >= invoice_date),
  CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoices_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders (id) ON DELETE SET NULL,
  CONSTRAINT fk_invoices_dispatch FOREIGN KEY (dispatch_id) REFERENCES dispatches (id) ON DELETE SET NULL,
  CONSTRAINT fk_invoices_issued_by FOREIGN KEY (issued_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invoice_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invoice_id BIGINT UNSIGNED NOT NULL,
  sales_order_item_id BIGINT UNSIGNED NULL,
  line_number SMALLINT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  hsn_sac_code VARCHAR(20) NULL,
  quantity DECIMAL(12,3) NOT NULL,
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'piece',
  unit_price DECIMAL(14,4) NOT NULL,
  discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  tax_percent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_items_line (invoice_id, line_number),
  KEY idx_invoice_items_order_item (sales_order_item_id),
  CONSTRAINT chk_invoice_items_values CHECK (quantity > 0 AND unit_price >= 0 AND discount_percent BETWEEN 0 AND 100 AND tax_percent BETWEEN 0 AND 100 AND line_total >= 0),
  CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
  CONSTRAINT fk_invoice_items_order_item FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_items (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_number VARCHAR(30) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  received_by BIGINT UNSIGNED NULL,
  payment_date DATETIME NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  payment_method ENUM('cash', 'bank_transfer', 'upi', 'cheque', 'card', 'other') NOT NULL DEFAULT 'bank_transfer',
  reference_number VARCHAR(100) NULL,
  status ENUM('pending', 'completed', 'failed', 'refunded', 'void') NOT NULL DEFAULT 'completed',
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payments_number (payment_number),
  KEY idx_payments_customer_date (customer_id, payment_date),
  KEY idx_payments_status (status),
  CONSTRAINT chk_payments_amount CHECK (amount > 0),
  CONSTRAINT fk_payments_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_payments_received_by FOREIGN KEY (received_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_allocations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  amount_applied DECIMAL(14,2) NOT NULL,
  allocated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_invoice_allocation (payment_id, invoice_id),
  KEY idx_payment_allocations_invoice (invoice_id),
  CONSTRAINT chk_payment_allocation_amount CHECK (amount_applied > 0),
  CONSTRAINT fk_payment_allocations_payment FOREIGN KEY (payment_id) REFERENCES payments (id) ON DELETE RESTRICT,
  CONSTRAINT fk_payment_allocations_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS expenses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  expense_number VARCHAR(30) NOT NULL,
  recorded_by BIGINT UNSIGNED NULL,
  supplier_id BIGINT UNSIGNED NULL,
  category VARCHAR(100) NOT NULL,
  description VARCHAR(255) NOT NULL,
  expense_date DATE NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  currency CHAR(3) NOT NULL DEFAULT 'INR',
  payment_method ENUM('cash', 'bank_transfer', 'upi', 'cheque', 'card', 'other') NOT NULL DEFAULT 'bank_transfer',
  reference_number VARCHAR(100) NULL,
  status ENUM('draft', 'approved', 'paid', 'void') NOT NULL DEFAULT 'draft',
  receipt_path VARCHAR(500) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_expenses_number (expense_number),
  KEY idx_expenses_date_category (expense_date, category),
  KEY idx_expenses_supplier (supplier_id),
  CONSTRAINT chk_expenses_amounts CHECK (amount >= 0 AND tax_amount >= 0),
  CONSTRAINT fk_expenses_recorded_by FOREIGN KEY (recorded_by) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT fk_expenses_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales_order_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  old_status ENUM('draft', 'confirmed', 'in_production', 'ready_to_ship', 'partially_dispatched', 'dispatched', 'completed', 'cancelled') NULL,
  new_status ENUM('draft', 'confirmed', 'in_production', 'ready_to_ship', 'partially_dispatched', 'dispatched', 'completed', 'cancelled') NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes VARCHAR(500) NULL,
  PRIMARY KEY (id),
  KEY idx_order_status_history_order_time (sales_order_id, changed_at),
  CONSTRAINT fk_order_status_history_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders (id) ON DELETE CASCADE,
  CONSTRAINT fk_order_status_history_user FOREIGN KEY (changed_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payment_id BIGINT UNSIGNED NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  old_status ENUM('pending', 'completed', 'failed', 'refunded', 'void') NULL,
  new_status ENUM('pending', 'completed', 'failed', 'refunded', 'void') NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes VARCHAR(500) NULL,
  PRIMARY KEY (id),
  KEY idx_payment_status_history_payment_time (payment_id, changed_at),
  CONSTRAINT fk_payment_status_history_payment FOREIGN KEY (payment_id) REFERENCES payments (id) ON DELETE CASCADE,
  CONSTRAINT fk_payment_status_history_user FOREIGN KEY (changed_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  description VARCHAR(500) NULL,
  changes JSON NULL,
  ip_address VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_activity_logs_entity (entity_type, entity_id, created_at),
  KEY idx_activity_logs_user_time (user_id, created_at),
  KEY idx_activity_logs_created_at (created_at),
  CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;