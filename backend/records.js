const { pool } = require("./config/db");

function cleanText(value, maxLength) {
  if (value === undefined || value === null) return null;
  const text = String(value).trim();
  if (!text) return null;
  return text.slice(0, maxLength);
}

function toAmount(value) {
  const amount = Number(value);
  return Number.isFinite(amount) && amount > 0 ? amount : 0;
}

async function nextCode(table, column, prefix) {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const code = `${prefix}-${String(Date.now()).slice(-6)}${Math.floor(Math.random() * 90 + 10)}`;
    const [rows] = await pool.execute(`SELECT 1 FROM ${table} WHERE ${column} = ? LIMIT 1`, [code]);
    if (rows.length === 0) return code;
  }
  throw new Error(`Unable to generate a unique ${column}`);
}

function nextCustomerCode() {
  return nextCode("customers", "customer_code", "CUS");
}

async function resolveCustomer(name) {
  const [rows] = await pool.execute("SELECT id FROM customers WHERE company_name = ? LIMIT 1", [name]);
  if (rows.length > 0) return rows[0].id;
  const [result] = await pool.execute(
    "INSERT INTO customers (customer_code, company_name, status) VALUES (?, ?, 'active')",
    [await nextCustomerCode(), name]
  );
  return result.insertId;
}

async function resolveOrder(customerId) {
  const [rows] = await pool.execute(
    "SELECT id FROM sales_orders WHERE customer_id = ? ORDER BY id DESC LIMIT 1",
    [customerId]
  );
  if (rows.length > 0) return rows[0].id;
  const [result] = await pool.execute(
    "INSERT INTO sales_orders (order_number, customer_id, order_date, status) VALUES (?, ?, CURDATE(), 'draft')",
    [await nextCode("sales_orders", "order_number", "ORD"), customerId]
  );
  return result.insertId;
}

async function firstId(table) {
  const [rows] = await pool.execute(`SELECT id FROM ${table} ORDER BY id LIMIT 1`);
  if (rows.length === 0) throw new Error(`No ${table} available to link this record`);
  return rows[0].id;
}

function displayStatus(value) {
  if (!value) return "—";
  return String(value)
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function formatDate(value) {
  if (!value) return "—";
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return String(value).slice(0, 16);
  return date.toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" });
}

const statusMaps = {
  Enquiries: { New: "new", "In progress": "qualified", "In review": "quoted", Confirmed: "converted" },
  Quotations: { New: "draft", "In progress": "sent", "In review": "sent", Confirmed: "approved" },
  Orders: { New: "draft", "In progress": "in_production", "In review": "confirmed", Confirmed: "confirmed" },
  "Job Cards": { New: "draft", "In progress": "in_progress", "In review": "quality_check", Confirmed: "queued" },
  Production: { New: "queued", "In progress": "in_progress", "In review": "completed", Confirmed: "completed" },
  Inventory: { New: "active", "In progress": "active", "In review": "active", Confirmed: "active" },
  "Quality Control": { New: "pending", "In progress": "pending", "In review": "pending", Confirmed: "passed" },
  Dispatch: { New: "draft", "In progress": "packing", "In review": "ready", Confirmed: "dispatched" },
  Invoices: { New: "draft", "In progress": "issued", "In review": "issued", Confirmed: "paid" },
  Payments: { New: "pending", "In progress": "pending", "In review": "pending", Confirmed: "completed" },
};

function mapStatus(module, status, fallback) {
  return statusMaps[module]?.[status] ?? fallback;
}

const modules = {
  Enquiries: {
    select: `SELECT e.enquiry_number AS reference, c.company_name AS customer,
      e.subject AS details, e.status AS status, e.received_at AS date, NULL AS value
      FROM customer_enquiries e JOIN customers c ON c.id = e.customer_id
      ORDER BY e.received_at DESC, e.id DESC`,
    create: async (input) => {
      const reference = await nextCode("customer_enquiries", "enquiry_number", "ENQ");
      await pool.execute(
        "INSERT INTO customer_enquiries (enquiry_number, customer_id, subject, status, notes) VALUES (?, ?, ?, ?, ?)",
        [reference, await resolveCustomer(input.name), input.name, mapStatus("Enquiries", input.status, "new"), input.details]
      );
      return reference;
    },
  },
  Quotations: {
    select: `SELECT q.quotation_number AS reference, c.company_name AS customer,
      q.notes AS details, q.status AS status, q.issue_date AS date, q.total_amount AS value
      FROM quotations q JOIN customers c ON c.id = q.customer_id
      ORDER BY q.issue_date DESC, q.id DESC`,
    create: async (input) => {
      const reference = await nextCode("quotations", "quotation_number", "QT");
      const amount = toAmount(input.value);
      await pool.execute(
        `INSERT INTO quotations (quotation_number, customer_id, issue_date, valid_until, status, total_amount, subtotal, notes)
         VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), ?, ?, ?, ?)`,
        [reference, await resolveCustomer(input.name), mapStatus("Quotations", input.status, "draft"), amount, amount, input.details]
      );
      return reference;
    },
  },
  Orders: {
    select: `SELECT o.order_number AS reference, c.company_name AS customer,
      o.notes AS details, o.status AS status, o.order_date AS date, o.total_amount AS value
      FROM sales_orders o JOIN customers c ON c.id = o.customer_id
      ORDER BY o.order_date DESC, o.id DESC`,
    create: async (input) => {
      const reference = await nextCode("sales_orders", "order_number", "ORD");
      const amount = toAmount(input.value);
      await pool.execute(
        `INSERT INTO sales_orders (order_number, customer_id, order_date, status, total_amount, subtotal, notes)
         VALUES (?, ?, CURDATE(), ?, ?, ?, ?)`,
        [reference, await resolveCustomer(input.name), mapStatus("Orders", input.status, "draft"), amount, amount, input.details]
      );
      return reference;
    },
  },
  "Job Cards": {
    select: `SELECT j.job_card_number AS reference, c.company_name AS customer,
      j.instructions AS details, j.status AS status, j.created_at AS date, NULL AS value
      FROM job_cards j JOIN sales_orders o ON o.id = j.sales_order_id
      JOIN customers c ON c.id = o.customer_id
      ORDER BY j.created_at DESC, j.id DESC`,
    create: async (input) => {
      const customerId = await resolveCustomer(input.name);
      const reference = await nextCode("job_cards", "job_card_number", "JC");
      await pool.execute(
        "INSERT INTO job_cards (job_card_number, sales_order_id, status, instructions) VALUES (?, ?, ?, ?)",
        [reference, await resolveOrder(customerId), mapStatus("Job Cards", input.status, "draft"), input.details]
      );
      return reference;
    },
  },
  Production: {
    select: `SELECT CONCAT('BATCH-', LPAD(pr.id, 3, '0')) AS reference, c.company_name AS customer,
      CONCAT(ps.name, ' · ', jci.quantity_planned, ' pcs') AS details,
      pr.status AS status, pr.started_at AS date, NULL AS value
      FROM production_records pr
      JOIN job_card_items jci ON jci.id = pr.job_card_item_id
      JOIN job_cards j ON j.id = jci.job_card_id
      JOIN sales_orders o ON o.id = j.sales_order_id
      JOIN customers c ON c.id = o.customer_id
      JOIN production_stages ps ON ps.id = pr.production_stage_id
      ORDER BY pr.started_at DESC, pr.id DESC`,
    create: async (input) => {
      const [result] = await pool.execute(
        `INSERT INTO production_records (job_card_item_id, production_stage_id, started_at, status, notes)
         VALUES (?, ?, NOW(), ?, ?)`,
        [await firstId("job_card_items"), await firstId("production_stages"), mapStatus("Production", input.status, "queued"), input.details]
      );
      return `BATCH-${String(result.insertId).padStart(3, "0")}`;
    },
  },
  Inventory: {
    select: `SELECT i.item_code AS reference, i.name AS customer,
      CONCAT(i.item_type, ' · ', i.unit_of_measure) AS details,
      i.status AS status, i.created_at AS date, i.average_unit_cost AS value
      FROM inventory_items i ORDER BY i.created_at DESC, i.id DESC`,
    create: async (input) => {
      const reference = await nextCode("inventory_items", "item_code", "ITEM");
      await pool.execute(
        `INSERT INTO inventory_items (item_code, name, item_type, unit_of_measure, status, average_unit_cost, notes)
         VALUES (?, ?, 'other', 'piece', ?, ?, ?)`,
        [reference, input.name, mapStatus("Inventory", input.status, "active"), toAmount(input.value), input.details]
      );
      return reference;
    },
  },
  "Quality Control": {
    select: `SELECT qc.inspection_number AS reference, c.company_name AS customer,
      qc.notes AS details, qc.result AS status, qc.inspected_at AS date, NULL AS value
      FROM quality_control_checks qc
      JOIN job_card_items jci ON jci.id = qc.job_card_item_id
      JOIN job_cards j ON j.id = jci.job_card_id
      JOIN sales_orders o ON o.id = j.sales_order_id
      JOIN customers c ON c.id = o.customer_id
      ORDER BY qc.inspected_at DESC, qc.id DESC`,
    create: async (input) => {
      const reference = await nextCode("quality_control_checks", "inspection_number", "QC");
      const result = mapStatus("Quality Control", input.status, "pending");
      await pool.execute(
        `INSERT INTO quality_control_checks (inspection_number, job_card_item_id, quantity_inspected, quantity_passed, result, notes)
         VALUES (?, ?, 1, ?, ?, ?)`,
        [reference, await firstId("job_card_items"), result === "passed" ? 1 : 0, result, input.details]
      );
      return reference;
    },
  },
  Dispatch: {
    select: `SELECT d.dispatch_number AS reference, c.company_name AS customer,
      CONCAT(COALESCE(d.carrier_name, '—'), ' · ', COALESCE(d.tracking_number, '—')) AS details,
      d.status AS status, d.created_at AS date, NULL AS value
      FROM dispatches d JOIN sales_orders o ON o.id = d.sales_order_id
      JOIN customers c ON c.id = o.customer_id
      ORDER BY d.created_at DESC, d.id DESC`,
    create: async (input) => {
      const customerId = await resolveCustomer(input.name);
      const reference = await nextCode("dispatches", "dispatch_number", "SHP");
      await pool.execute(
        "INSERT INTO dispatches (dispatch_number, sales_order_id, status, delivery_notes) VALUES (?, ?, ?, ?)",
        [reference, await resolveOrder(customerId), mapStatus("Dispatch", input.status, "draft"), input.details]
      );
      return reference;
    },
  },
  Invoices: {
    select: `SELECT i.invoice_number AS reference, c.company_name AS customer,
      CONCAT('Order ', COALESCE(o.order_number, '—'), ' · Net 30') AS details,
      i.status AS status, i.due_date AS date, i.total_amount AS value
      FROM invoices i JOIN customers c ON c.id = i.customer_id
      LEFT JOIN sales_orders o ON o.id = i.sales_order_id
      ORDER BY i.due_date DESC, i.id DESC`,
    create: async (input) => {
      const reference = await nextCode("invoices", "invoice_number", "INV");
      const amount = toAmount(input.value) || 1;
      await pool.execute(
        `INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, status, total_amount, subtotal, notes)
         VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), ?, ?, ?, ?)`,
        [reference, await resolveCustomer(input.name), mapStatus("Invoices", input.status, "draft"), amount, amount, input.details]
      );
      return reference;
    },
  },
  Payments: {
    select: `SELECT p.payment_number AS reference, c.company_name AS customer,
      CONCAT(p.payment_method, ' · ', COALESCE(p.reference_number, '—')) AS details,
      p.status AS status, p.payment_date AS date, p.amount AS value
      FROM payments p JOIN customers c ON c.id = p.customer_id
      ORDER BY p.payment_date DESC, p.id DESC`,
    create: async (input) => {
      const reference = await nextCode("payments", "payment_number", "PAY");
      await pool.execute(
        "INSERT INTO payments (payment_number, customer_id, payment_date, amount, status, notes) VALUES (?, ?, NOW(), ?, ?, ?)",
        [reference, await resolveCustomer(input.name), toAmount(input.value) || 1, mapStatus("Payments", input.status, "pending"), input.details]
      );
      return reference;
    },
  },
};

function normalize(row) {
  return {
    reference: row.reference,
    customer: row.customer,
    details: row.details || "—",
    status: displayStatus(row.status),
    date: formatDate(row.date),
    value: Number(row.value) || 0,
  };
}

async function getRecords(module) {
  const config = modules[module];
  const [rows] = await pool.execute(config.select);
  return rows.map(normalize);
}

async function findRecord(module, reference) {
  const records = await getRecords(module);
  return records.find((record) => record.reference === reference) ?? null;
}

module.exports = { modules, getRecords, findRecord, nextCustomerCode, cleanText };
