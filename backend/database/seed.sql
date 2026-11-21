-- Demonstration data for powder_coating_crm.
-- Safe to re-run for this sample set: duplicate keys are ignored.
-- Seeded users are invitations only. Replace their password_hash with a
-- real application-generated password hash before enabling sign-in.

USE powder_coating_crm;

INSERT IGNORE INTO roles (id, name, description, is_system) VALUES
  (1, 'Administrator', 'Full access to workshop operations and configuration.', 1),
  (2, 'Sales', 'Customer relationships, enquiries, quotations, and orders.', 1),
  (3, 'Production', 'Job cards, production, inventory, and quality checks.', 1),
  (4, 'Finance', 'Invoices, payments, expenses, and financial reports.', 1);

INSERT IGNORE INTO permissions (id, permission_key, description) VALUES
  (1, 'customers.read', 'View customer records.'),
  (2, 'customers.write', 'Create and update customer records.'),
  (3, 'suppliers.read', 'View supplier records.'),
  (4, 'suppliers.write', 'Create and update supplier records.'),
  (5, 'enquiries.read', 'View customer enquiries.'),
  (6, 'enquiries.write', 'Create and update customer enquiries.'),
  (7, 'quotations.read', 'View quotations.'),
  (8, 'quotations.write', 'Create and update quotations.'),
  (9, 'orders.read', 'View sales orders.'),
  (10, 'orders.write', 'Create and update sales orders.'),
  (11, 'production.read', 'View job cards and production records.'),
  (12, 'production.write', 'Manage job cards and production records.'),
  (13, 'inventory.read', 'View inventory and stock transactions.'),
  (14, 'inventory.write', 'Manage inventory and stock transactions.'),
  (15, 'quality.read', 'View quality inspections and rework.'),
  (16, 'quality.write', 'Manage quality inspections and rework.'),
  (17, 'dispatch.read', 'View dispatches and delivery events.'),
  (18, 'dispatch.write', 'Manage dispatches and delivery events.'),
  (19, 'invoices.read', 'View invoices.'),
  (20, 'invoices.write', 'Create and update invoices.'),
  (21, 'payments.read', 'View payments and allocations.'),
  (22, 'payments.write', 'Record payments and allocations.'),
  (23, 'expenses.read', 'View expenses.'),
  (24, 'expenses.write', 'Create and update expenses.'),
  (25, 'users.manage', 'Manage users, roles, and sessions.'),
  (26, 'reports.read', 'View operational and financial reports.'),
  (27, 'settings.manage', 'Manage CRM settings.');

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.id = 1;

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions
WHERE permission_key IN (
  'customers.read', 'customers.write', 'enquiries.read', 'enquiries.write',
  'quotations.read', 'quotations.write', 'orders.read', 'orders.write',
  'dispatch.read', 'reports.read'
);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions
WHERE permission_key IN (
  'customers.read', 'orders.read', 'production.read', 'production.write',
  'inventory.read', 'inventory.write', 'quality.read', 'quality.write',
  'dispatch.read', 'dispatch.write'
);

INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions
WHERE permission_key IN (
  'customers.read', 'orders.read', 'invoices.read', 'invoices.write',
  'payments.read', 'payments.write', 'expenses.read', 'expenses.write',
  'reports.read'
);

INSERT IGNORE INTO users (id, role_id, first_name, last_name, email, phone, password_hash, status) VALUES
  (1, 1, 'Rahul', 'Kulkarni', 'rahul.kulkarni@example.test', '+91-9876501001', 'REPLACE_WITH_BCRYPT_HASH_BEFORE_LOGIN', 'invited'),
  (2, 2, 'Priya', 'Shah', 'priya.shah@example.test', '+91-9876501002', 'REPLACE_WITH_BCRYPT_HASH_BEFORE_LOGIN', 'invited'),
  (3, 3, 'Amit', 'Patil', 'amit.patil@example.test', '+91-9876501003', 'REPLACE_WITH_BCRYPT_HASH_BEFORE_LOGIN', 'invited'),
  (4, 4, 'Neha', 'Desai', 'neha.desai@example.test', '+91-9876501004', 'REPLACE_WITH_BCRYPT_HASH_BEFORE_LOGIN', 'invited');

INSERT IGNORE INTO powder_categories (id, name, description, default_unit) VALUES
  (1, 'Polyester', 'Durable general-purpose polyester powder coatings.', 'kg'),
  (2, 'Epoxy Polyester', 'Hybrid powder for indoor applications.', 'kg'),
  (3, 'Epoxy', 'Chemical-resistant powder coating for indoor use.', 'kg');

INSERT IGNORE INTO customers (
  id, customer_code, company_name, contact_name, email, phone, gstin, pan,
  billing_address_line1, billing_city, billing_state, billing_postal_code,
  shipping_address_line1, shipping_city, shipping_state, shipping_postal_code,
  payment_terms_days, credit_limit, status, created_by
) VALUES
  (1, 'CUS-0001', 'Apex Fabricators', 'Sanjay Mehta', 'accounts@apexfab.example.test', '+91-9822011101', '27AABCA1234F1Z5', 'AABCA1234F', '18 MIDC Industrial Estate', 'Pune', 'Maharashtra', '411019', 'Gate 2, 18 MIDC Industrial Estate', 'Pune', 'Maharashtra', '411019', 30, 250000.00, 'active', 2),
  (2, 'CUS-0002', 'Meridian Auto Parts', 'Kavita Joshi', 'purchase@meridianauto.example.test', '+91-9822011102', '27AABCM2345G1Z4', 'AABCM2345G', 'Plot 44, Satpur MIDC', 'Nashik', 'Maharashtra', '422007', 'Plot 44, Satpur MIDC', 'Nashik', 'Maharashtra', '422007', 15, 150000.00, 'active', 2),
  (3, 'CUS-0003', 'Northstar Rail Systems', 'Rohan Nair', 'procurement@northstarrail.example.test', '+91-9822011103', '27AABCN3456H1Z3', 'AABCN3456H', '2 Harbour View Road', 'Mumbai', 'Maharashtra', '400001', 'Warehouse 8, TTC Industrial Area', 'Navi Mumbai', 'Maharashtra', '400705', 30, 500000.00, 'active', 2),
  (4, 'CUS-0004', 'Vantage Solar Works', 'Meera Kulkarni', 'ops@vantagesolar.example.test', '+91-9822011104', '27AABCV4567J1Z2', 'AABCV4567J', '31 Waluj Industrial Area', 'Aurangabad', 'Maharashtra', '431136', '31 Waluj Industrial Area', 'Aurangabad', 'Maharashtra', '431136', 30, 300000.00, 'active', 2);

INSERT IGNORE INTO suppliers (
  id, supplier_code, company_name, contact_name, email, phone, gstin, city, state, country, payment_terms_days
) VALUES
  (1, 'SUP-0001', 'ColorChem Powders Pvt Ltd', 'Arun Rao', 'sales@colorchem.example.test', '+91-9822022101', '27AABCC5678K1Z1', 'Pune', 'Maharashtra', 'India', 30),
  (2, 'SUP-0002', 'Industrial Surface Supply', 'Deepa Shah', 'orders@surfacesupply.example.test', '+91-9822022102', '27AABCI6789L1Z0', 'Mumbai', 'Maharashtra', 'India', 15);

INSERT IGNORE INTO inventory_items (
  id, item_code, name, item_type, powder_category_id, manufacturer, shade_code,
  finish, unit_of_measure, quantity_on_hand, reorder_level, average_unit_cost, bin_location
) VALUES
  (1, 'POW-RAL9005-MB', 'Jet black powder', 'powder', 1, 'ColorChem', 'RAL 9005', 'Matte', 'kg', 18.000, 10.000, 620.0000, 'P-01-A'),
  (2, 'POW-RAL3001-GL', 'Signal red powder', 'powder', 1, 'ColorChem', 'RAL 3001', 'Gloss', 'kg', 7.000, 10.000, 680.0000, 'P-01-B'),
  (3, 'POW-RAL7035-SM', 'Light grey powder', 'powder', 2, 'SurfaceCoat', 'RAL 7035', 'Semi-matte', 'kg', 24.000, 10.000, 590.0000, 'P-02-A'),
  (4, 'CHEM-IRON-PHOS', 'Iron phosphate solution', 'chemical', NULL, 'SurfaceChem', NULL, NULL, 'L', 12.000, 5.000, 180.0000, 'C-01-A');

INSERT IGNORE INTO inventory_suppliers (inventory_item_id, supplier_id, supplier_item_code, last_purchase_price) VALUES
  (1, 1, 'CC-9005-M', 620.0000),
  (2, 1, 'CC-3001-G', 680.0000),
  (3, 2, 'ISS-7035-SM', 590.0000),
  (4, 2, 'ISS-IP-20', 180.0000);

INSERT IGNORE INTO customer_enquiries (
  id, enquiry_number, customer_id, assigned_to, source, subject, received_at, required_by, status, notes
) VALUES
  (1, 'ENQ-2026-001', 1, 2, 'email', 'Powder coating for aluminium enclosures', CURRENT_TIMESTAMP - INTERVAL 5 DAY, CURRENT_DATE + INTERVAL 10 DAY, 'converted', 'Customer supplied technical drawings and finish requirements.'),
  (2, 'ENQ-2026-002', 2, 2, 'phone', 'Automotive wheel hub coating', CURRENT_TIMESTAMP - INTERVAL 2 DAY, CURRENT_DATE + INTERVAL 7 DAY, 'quoted', 'Requires consistent RAL 3001 gloss finish.'),
  (3, 'ENQ-2026-003', 4, 2, 'website', 'Solar mounting bracket coating', CURRENT_TIMESTAMP - INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 14 DAY, 'qualified', 'Estimated first batch of 600 brackets.');

INSERT IGNORE INTO enquiry_items (
  id, enquiry_id, line_number, item_description, material, finish, color_name, color_code, quantity, unit_of_measure, approximate_area_sq_m
) VALUES
  (1, 1, 1, 'Aluminium electrical enclosure', 'Aluminium', 'Matte', 'Jet black', 'RAL 9005', 320.000, 'piece', 96.0000),
  (2, 2, 1, 'Steel wheel hub', 'Mild steel', 'Gloss', 'Signal red', 'RAL 3001', 80.000, 'piece', 28.0000),
  (3, 3, 1, 'Solar mounting bracket', 'Galvanized steel', 'Semi-matte', 'Light grey', 'RAL 7035', 600.000, 'piece', 180.0000);

INSERT IGNORE INTO quotations (
  id, quotation_number, enquiry_id, customer_id, prepared_by, revision, issue_date, valid_until,
  currency, status, subtotal, discount_amount, tax_amount, total_amount, terms, approved_at
) VALUES
  (1, 'QT-2026-001', 1, 1, 2, 1, CURRENT_DATE - INTERVAL 4 DAY, CURRENT_DATE + INTERVAL 26 DAY, 'INR', 'approved', 48000.00, 0.00, 8640.00, 56640.00, '30% advance; balance due within 30 days of invoice.', CURRENT_TIMESTAMP - INTERVAL 3 DAY),
  (2, 'QT-2026-002', 2, 2, 2, 1, CURRENT_DATE - INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 29 DAY, 'INR', 'sent', 32000.00, 500.00, 5670.00, 37170.00, 'Quote valid for 30 days.', NULL);

INSERT IGNORE INTO quotation_items (
  id, quotation_id, line_number, item_description, material, finish, color_name, color_code,
  quantity, unit_of_measure, unit_price, discount_percent, tax_percent, line_total
) VALUES
  (1, 1, 1, 'Powder coat aluminium electrical enclosure', 'Aluminium', 'Matte', 'Jet black', 'RAL 9005', 320.000, 'piece', 150.0000, 0.00, 18.00, 48000.00),
  (2, 2, 1, 'Powder coat steel wheel hub', 'Mild steel', 'Gloss', 'Signal red', 'RAL 3001', 80.000, 'piece', 400.0000, 1.56, 18.00, 31500.00);

INSERT IGNORE INTO sales_orders (
  id, order_number, customer_id, quotation_id, sales_person_id, order_date,
  requested_delivery_date, confirmed_delivery_date, currency, status, subtotal,
  discount_amount, tax_amount, total_amount, billing_address_snapshot,
  shipping_address_snapshot, customer_gstin_snapshot, terms, notes
) VALUES
  (1, 'ORD-2026-001', 1, 1, 2, CURRENT_DATE - INTERVAL 3 DAY, CURRENT_DATE + INTERVAL 7 DAY,
   CURRENT_DATE + INTERVAL 7 DAY, 'INR', 'in_production', 48000.00, 0.00, 8640.00, 56640.00,
   JSON_OBJECT('line1', '18 MIDC Industrial Estate', 'city', 'Pune', 'state', 'Maharashtra', 'postal_code', '411019', 'country', 'India'),
   JSON_OBJECT('line1', 'Gate 2, 18 MIDC Industrial Estate', 'city', 'Pune', 'state', 'Maharashtra', 'postal_code', '411019', 'country', 'India'),
   '27AABCA1234F1Z5', '30% advance; balance due within 30 days of invoice.', 'Demo order for powder-coated aluminium enclosures.'),
  (2, 'ORD-2026-002', 2, NULL, 2, CURRENT_DATE - INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 8 DAY,
   CURRENT_DATE + INTERVAL 8 DAY, 'INR', 'confirmed', 32000.00, 500.00, 5670.00, 37170.00,
   JSON_OBJECT('line1', 'Plot 44, Satpur MIDC', 'city', 'Nashik', 'state', 'Maharashtra', 'postal_code', '422007', 'country', 'India'),
   JSON_OBJECT('line1', 'Plot 44, Satpur MIDC', 'city', 'Nashik', 'state', 'Maharashtra', 'postal_code', '422007', 'country', 'India'),
   '27AABCM2345G1Z4', 'Net 15 from invoice date.', 'Follow-up demo order.');

INSERT IGNORE INTO sales_order_items (
  id, sales_order_id, quotation_item_id, line_number, item_description, material, finish,
  color_name, color_code, quantity_ordered, unit_of_measure, unit_price, discount_percent,
  tax_percent, line_total
) VALUES
  (1, 1, 1, 1, 'Powder coat aluminium electrical enclosure', 'Aluminium', 'Matte', 'Jet black', 'RAL 9005', 320.000, 'piece', 150.0000, 0.00, 18.00, 48000.00),
  (2, 2, NULL, 1, 'Powder coat steel wheel hub', 'Mild steel', 'Gloss', 'Signal red', 'RAL 3001', 80.000, 'piece', 400.0000, 1.56, 18.00, 31500.00);

INSERT IGNORE INTO job_cards (
  id, job_card_number, sales_order_id, created_by, assigned_to, planned_start_date,
  planned_end_date, actual_start_at, priority, status, instructions
) VALUES
  (1, 'JC-2026-001', 1, 1, 3, CURRENT_DATE - INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 4 DAY, CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'high', 'in_progress', 'Confirm surface preparation and matte finish before coating.'),
  (2, 'JC-2026-002', 2, 1, 3, CURRENT_DATE + INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 5 DAY, NULL, 'normal', 'draft', 'Use signal red gloss powder; retain one sample for approval.');

INSERT IGNORE INTO job_card_items (
  id, job_card_id, sales_order_item_id, line_number, quantity_planned, quantity_completed, quantity_rejected, status
) VALUES
  (1, 1, 1, 1, 320.000, 120.000, 3.000, 'in_progress'),
  (2, 2, 2, 1, 80.000, 0.000, 0.000, 'queued');

INSERT IGNORE INTO production_stages (id, stage_code, name, sequence_number, description) VALUES
  (1, 'PRETREAT', 'Pre-treatment', 1, 'Cleaning and chemical surface preparation.'),
  (2, 'COATING', 'Powder coating', 2, 'Electrostatic powder application.'),
  (3, 'CURING', 'Curing and cooling', 3, 'Oven curing followed by controlled cooling.'),
  (4, 'INSPECTION', 'Quality inspection', 4, 'Final visual and dimensional inspection.');

INSERT IGNORE INTO production_records (
  id, job_card_item_id, production_stage_id, operator_id, started_at, completed_at,
  quantity_processed, quantity_completed, quantity_rejected, status, machine_name,
  temperature_celsius, duration_minutes, notes
) VALUES
  (1, 1, 1, 3, CURRENT_TIMESTAMP - INTERVAL 1 DAY, CURRENT_TIMESTAMP - INTERVAL 20 HOUR, 123.000, 120.000, 3.000, 'completed', 'Pretreatment line A', NULL, 45, 'Three parts held for surface contamination review.'),
  (2, 1, 2, 3, CURRENT_TIMESTAMP - INTERVAL 18 HOUR, NULL, 80.000, 78.000, 2.000, 'in_progress', 'Coating booth A', NULL, NULL, 'First coating batch in progress.');

INSERT IGNORE INTO powder_stock_transactions (
  id, inventory_item_id, supplier_id, job_card_id, production_record_id, recorded_by,
  transaction_type, quantity, unit_cost, reference_number, transaction_at, notes
) VALUES
  (1, 1, 1, NULL, NULL, 3, 'purchase', 26.250, 620.0000, 'GRN-2026-0101', CURRENT_TIMESTAMP - INTERVAL 20 DAY, 'Opening sample stock receipt.'),
  (2, 1, NULL, NULL, NULL, 3, 'consumption', 7.000, NULL, 'OPENING-USE-001', CURRENT_TIMESTAMP - INTERVAL 10 DAY, 'Historical demo consumption.'),
  (3, 1, NULL, 1, 2, 3, 'consumption', 1.250, NULL, 'JC-2026-001-B1', CURRENT_TIMESTAMP - INTERVAL 12 HOUR, 'Powder issued to first coating batch.');

INSERT IGNORE INTO quality_control_checks (
  id, inspection_number, job_card_item_id, production_record_id, inspected_by, inspected_at,
  quantity_inspected, quantity_passed, quantity_rejected, result, film_thickness_microns,
  adhesion_result, color_match_delta_e, defects, notes
) VALUES
  (1, 'QC-2026-001', 1, 1, 1, CURRENT_TIMESTAMP - INTERVAL 18 HOUR, 20.000, 18.000, 2.000, 'partially_passed', 78.00, 'Pass', 0.650, 'Two parts have minor surface contamination.', 'Rework the rejected pieces before final inspection.');

INSERT IGNORE INTO rework_orders (
  id, rework_number, quality_check_id, job_card_item_id, assigned_to,
  quantity_to_rework, quantity_completed, reason, corrective_action, status, opened_at
) VALUES
  (1, 'RW-2026-001', 1, 1, 3, 2.000, 0.000, 'Surface contamination detected during inspection.', 'Clean, re-prepare, and recoat before reinspection.', 'open', CURRENT_TIMESTAMP - INTERVAL 17 HOUR);

INSERT IGNORE INTO dispatches (
  id, dispatch_number, sales_order_id, dispatched_by, carrier_name, tracking_number,
  vehicle_number, dispatch_date, expected_delivery_date, status, delivery_address_snapshot, delivery_notes
) VALUES
  (1, 'DSP-2026-001', 2, 1, 'Blue Dart', 'BD-DEMO-26001', NULL, CURRENT_TIMESTAMP - INTERVAL 2 DAY,
   CURRENT_DATE + INTERVAL 1 DAY, 'in_transit',
   JSON_OBJECT('line1', 'Plot 44, Satpur MIDC', 'city', 'Nashik', 'state', 'Maharashtra', 'postal_code', '422007'),
   'Sample delivery record.');

INSERT IGNORE INTO dispatch_items (id, dispatch_id, sales_order_item_id, job_card_item_id, quantity_dispatched, package_count, notes) VALUES
  (1, 1, 2, 2, 20.000, 2, 'Partial dispatch sample.');

INSERT IGNORE INTO delivery_events (id, dispatch_id, recorded_by, event_type, event_at, location, description) VALUES
  (1, 1, 1, 'picked_up', CURRENT_TIMESTAMP - INTERVAL 2 DAY, 'Nashik workshop', 'Shipment collected by carrier.'),
  (2, 1, NULL, 'in_transit', CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'Pune sorting hub', 'Shipment scanned at sorting hub.');

INSERT IGNORE INTO invoices (
  id, invoice_number, customer_id, sales_order_id, dispatch_id, issued_by, invoice_date, due_date,
  currency, customer_gstin_snapshot, billing_address_snapshot, subtotal, discount_amount,
  tax_amount, total_amount, status, notes
) VALUES
  (1, 'INV-2026-001', 1, 1, NULL, 4, CURRENT_DATE - INTERVAL 1 DAY, CURRENT_DATE + INTERVAL 29 DAY,
   'INR', '27AABCA1234F1Z5',
   JSON_OBJECT('line1', '18 MIDC Industrial Estate', 'city', 'Pune', 'state', 'Maharashtra', 'postal_code', '411019'),
   24000.00, 0.00, 4320.00, 28320.00, 'partially_paid', 'Progress invoice; remaining balance due on completion.'),
  (2, 'INV-2026-002', 2, 2, 1, 4, CURRENT_DATE - INTERVAL 2 DAY, CURRENT_DATE + INTERVAL 13 DAY,
   'INR', '27AABCM2345G1Z4',
   JSON_OBJECT('line1', 'Plot 44, Satpur MIDC', 'city', 'Nashik', 'state', 'Maharashtra', 'postal_code', '422007'),
   20000.00, 0.00, 3600.00, 23600.00, 'issued', 'Partial shipment billing sample.');

INSERT IGNORE INTO invoice_items (
  id, invoice_id, sales_order_item_id, line_number, description, hsn_sac_code,
  quantity, unit_of_measure, unit_price, discount_percent, tax_percent, line_total
) VALUES
  (1, 1, 1, 1, 'Progress billing - aluminium enclosure powder coating', '998873', 160.000, 'piece', 150.0000, 0.00, 18.00, 24000.00),
  (2, 2, 2, 1, 'Powder coating service - partial wheel hub dispatch', '998873', 50.000, 'piece', 400.0000, 0.00, 18.00, 20000.00);

INSERT IGNORE INTO payments (
  id, payment_number, customer_id, received_by, payment_date, amount, currency,
  payment_method, reference_number, status, notes
) VALUES
  (1, 'PAY-2026-001', 1, 4, CURRENT_TIMESTAMP - INTERVAL 1 DAY, 10000.00, 'INR', 'bank_transfer', 'NEFT-DEMO-001', 'completed', 'Part payment allocated to invoice INV-2026-001.'),
  (2, 'PAY-2026-002', 2, 4, CURRENT_TIMESTAMP - INTERVAL 1 DAY, 5000.00, 'INR', 'upi', 'UPI-DEMO-002', 'completed', 'Part payment allocated to invoice INV-2026-002.');

INSERT IGNORE INTO payment_allocations (id, payment_id, invoice_id, amount_applied, allocated_at) VALUES
  (1, 1, 1, 10000.00, CURRENT_TIMESTAMP - INTERVAL 1 DAY),
  (2, 2, 2, 5000.00, CURRENT_TIMESTAMP - INTERVAL 1 DAY);

INSERT IGNORE INTO expenses (
  id, expense_number, recorded_by, supplier_id, category, description, expense_date,
  amount, tax_amount, currency, payment_method, reference_number, status, notes
) VALUES
  (1, 'EXP-2026-001', 4, 1, 'Raw materials', 'Demo purchase of polyester powder coating', CURRENT_DATE - INTERVAL 20 DAY, 16275.00, 2929.50, 'INR', 'bank_transfer', 'GRN-2026-0101', 'paid', 'Linked inventory receipt is GRN-2026-0101.'),
  (2, 'EXP-2026-002', 4, NULL, 'Utilities', 'Workshop electricity bill', CURRENT_DATE - INTERVAL 5 DAY, 8200.00, 1476.00, 'INR', 'bank_transfer', 'UTIL-DEMO-002', 'approved', 'Monthly workshop utility expense.');

INSERT IGNORE INTO sales_order_status_history (id, sales_order_id, changed_by, old_status, new_status, changed_at, notes) VALUES
  (1, 1, 2, NULL, 'draft', CURRENT_TIMESTAMP - INTERVAL 3 DAY, 'Order created from approved quotation.'),
  (2, 1, 2, 'draft', 'confirmed', CURRENT_TIMESTAMP - INTERVAL 2 DAY, 'Customer confirmed the order.'),
  (3, 1, 2, 'confirmed', 'in_production', CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'Production started.'),
  (4, 2, 2, NULL, 'confirmed', CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'Customer confirmed the order.');

INSERT IGNORE INTO payment_status_history (id, payment_id, changed_by, old_status, new_status, changed_at, notes) VALUES
  (1, 1, 4, NULL, 'completed', CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'Bank transfer received and reconciled.'),
  (2, 2, 4, NULL, 'completed', CURRENT_TIMESTAMP - INTERVAL 1 DAY, 'UPI payment received.');

INSERT IGNORE INTO activity_logs (id, user_id, action, entity_type, entity_id, description, created_at) VALUES
  (1, 2, 'created', 'customer_enquiry', 1, 'Created enquiry ENQ-2026-001 for Apex Fabricators.', CURRENT_TIMESTAMP - INTERVAL 5 DAY),
  (2, 2, 'approved', 'quotation', 1, 'Quotation QT-2026-001 approved by the customer.', CURRENT_TIMESTAMP - INTERVAL 3 DAY),
  (3, 3, 'started', 'job_card', 1, 'Started production on job card JC-2026-001.', CURRENT_TIMESTAMP - INTERVAL 1 DAY),
  (4, 4, 'received', 'payment', 1, 'Recorded partial payment PAY-2026-001.', CURRENT_TIMESTAMP - INTERVAL 1 DAY);
