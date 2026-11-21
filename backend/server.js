const express = require("express");
const cors = require("cors");
const { pool, testConnection } = require("./config/db");
const { modules, getRecords, findRecord, nextCustomerCode, cleanText } = require("./records");

const app = express();
const port = Number(process.env.PORT || 5000);

app.set("etag", false);
app.use(cors());
app.use(express.json());
app.use("/api", (_req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});

app.get("/api/health", async (_req, res) => {
  try {
    await testConnection();
    res.json({ status: "ok", database: "connected" });
  } catch (error) {
    res.status(500).json({ status: "error", database: "disconnected", message: error.message });
  }
});

app.get("/api/customers", async (_req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT id, customer_code, company_name, contact_name, email, phone, status, notes, billing_city, created_at FROM customers ORDER BY created_at DESC"
    );
    res.json({ customers: rows });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch customers", message: error.message });
  }
});

const customerStatuses = new Set(["active", "inactive", "prospect", "blocked"]);

app.post("/api/customers", async (req, res) => {
  const body = req.body ?? {};
  const companyName = cleanText(body.company_name, 180);
  if (!companyName) {
    return res.status(400).json({ error: "Validation failed", message: "company_name is required" });
  }
  const email = cleanText(body.email, 190);
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: "Validation failed", message: "email is invalid" });
  }
  const contactName = cleanText(body.contact_name, 160);
  const phone = cleanText(body.phone, 30);
  const notes = cleanText(body.notes, 2000);
  const status = customerStatuses.has(body.status) ? body.status : "active";
  try {
    const customerCode = await nextCustomerCode();
    const [result] = await pool.execute(
      "INSERT INTO customers (customer_code, company_name, contact_name, email, phone, status, notes) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [customerCode, companyName, contactName, email, phone, status, notes]
    );
    const [rows] = await pool.execute(
      "SELECT id, customer_code, company_name, contact_name, email, phone, status, notes, billing_city, created_at FROM customers WHERE id = ?",
      [result.insertId]
    );
    res.status(201).json({ customer: rows[0] });
  } catch (error) {
    res.status(500).json({ error: "Failed to create customer", message: error.message });
  }
});

app.get("/api/modules/:module", async (req, res) => {
  const { module } = req.params;
  if (!Object.hasOwn(modules, module)) {
    return res.status(404).json({ error: "Unknown module", module });
  }
  try {
    res.json({ module, records: await getRecords(module) });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch records", module, message: error.message });
  }
});

app.post("/api/modules/:module", async (req, res) => {
  const { module } = req.params;
  if (!Object.hasOwn(modules, module)) {
    return res.status(404).json({ error: "Unknown module", module });
  }
  const body = req.body ?? {};
  const name = cleanText(body.name, 180);
  const details = cleanText(body.details, 2000);
  if (!name || !details) {
    return res.status(400).json({ error: "Validation failed", message: "name and details are required" });
  }
  try {
    const reference = await modules[module].create({ name, details, status: body.status, value: body.value });
    const record = await findRecord(module, reference);
    if (!record) throw new Error("Created record could not be read back");
    res.status(201).json({ module, record });
  } catch (error) {
    res.status(500).json({ error: "Failed to create record", module, message: error.message });
  }
});

app.get("/api/users", async (_req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT id, first_name, last_name, email, phone, status, created_at FROM users ORDER BY created_at DESC"
    );
    res.json({ users: rows });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch users", message: error.message });
  }
});

function recentKeys(count, unit) {
  const now = new Date();
  const keys = [];
  for (let offset = count - 1; offset >= 0; offset -= 1) {
    const date = unit === "month"
      ? new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - offset, 1))
      : new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - offset));
    keys.push(date.toISOString().slice(0, unit === "month" ? 7 : 10));
  }
  return keys;
}

app.get("/api/dashboard", async (_req, res) => {
  const months = recentKeys(12, "month");
  const days = recentKeys(30, "day");
  try {
    const [
      [countRows],
      [pendingRows],
      [stageRows],
      [orderRows],
      [monthRows],
      [dayRows],
    ] = await Promise.all([
      pool.execute(`SELECT
        (SELECT COUNT(*) FROM customers) AS customers,
        (SELECT COUNT(*) FROM users) AS users,
        (SELECT COUNT(*) FROM sales_orders WHERE status IN ('confirmed', 'in_production', 'ready_to_ship', 'partially_dispatched')) AS active_orders,
        (SELECT COUNT(*) FROM sales_orders WHERE status = 'in_production') AS in_production,
        (SELECT COUNT(*) FROM sales_orders WHERE requested_delivery_date = CURDATE() AND status NOT IN ('completed', 'cancelled')) AS due_today,
        (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'completed') AS total_revenue`),
      pool.execute(`SELECT
        COALESCE(SUM(i.total_amount - COALESCE((SELECT SUM(pa.amount_applied) FROM payment_allocations pa WHERE pa.invoice_id = i.id), 0)), 0) AS pending,
        COUNT(*) AS invoice_count
        FROM invoices i WHERE i.status IN ('issued', 'partially_paid', 'overdue')`),
      pool.execute(`SELECT ps.name AS label, COUNT(pr.id) AS count
        FROM production_stages ps
        LEFT JOIN production_records pr ON pr.production_stage_id = ps.id AND pr.status IN ('queued', 'in_progress')
        WHERE ps.is_active = 1
        GROUP BY ps.id, ps.name, ps.sequence_number
        ORDER BY ps.sequence_number`),
      pool.execute(`SELECT so.order_number AS id, c.company_name AS customer, so.status, so.requested_delivery_date AS date, so.total_amount AS amount,
        COALESCE(GROUP_CONCAT(CONCAT(COALESCE(si.color_name, si.finish, 'Standard'), ' · ', CAST(si.quantity_ordered AS UNSIGNED), ' pcs') SEPARATOR ', '), '—') AS details
        FROM sales_orders so
        JOIN customers c ON c.id = so.customer_id
        LEFT JOIN sales_order_items si ON si.sales_order_id = so.id
        GROUP BY so.id, so.order_number, c.company_name, so.status, so.requested_delivery_date, so.total_amount, so.order_date
        ORDER BY so.order_date DESC, so.id DESC
        LIMIT 8`),
      pool.execute(`SELECT DATE_FORMAT(payment_date, '%Y-%m') AS period, COALESCE(SUM(amount), 0) AS total
        FROM payments WHERE status = 'completed' AND payment_date >= ?
        GROUP BY period`, [`${months[0]}-01`]),
      pool.execute(`SELECT DATE_FORMAT(payment_date, '%Y-%m-%d') AS period, COALESCE(SUM(amount), 0) AS total
        FROM payments WHERE status = 'completed' AND payment_date >= ?
        GROUP BY period`, [days[0]]),
    ]);

    const counts = countRows[0];
    const monthlyTotals = new Map(monthRows.map((row) => [row.period, Number(row.total)]));
    const dailyTotals = new Map(dayRows.map((row) => [row.period, Number(row.total)]));
    const currentRevenue = monthlyTotals.get(months.at(-1)) ?? 0;
    const previousRevenue = monthlyTotals.get(months.at(-2)) ?? 0;
    const orders = orderRows.map((row) => ({
      id: row.id,
      customer: row.customer,
      details: row.details,
      status: String(row.status).split("_").map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(" "),
      date: row.date ? new Date(row.date).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" }) : "—",
      amount: Number(row.amount) || 0,
    }));

    res.json({
      customers: Number(counts.customers),
      users: Number(counts.users),
      totalRevenue: Number(counts.total_revenue),
      activeOrders: Number(counts.active_orders),
      inProduction: Number(counts.in_production),
      dueToday: Number(counts.due_today),
      pendingPayments: Number(pendingRows[0].pending),
      pendingInvoices: Number(pendingRows[0].invoice_count),
      revenueChange: previousRevenue > 0 ? `${(((currentRevenue - previousRevenue) / previousRevenue) * 100).toFixed(1)}%` : "—",
      revenueTrend: currentRevenue >= previousRevenue ? "up" : "down",
      months,
      days,
      revenueSeries: months.map((key) => monthlyTotals.get(key) ?? 0),
      dailySeries: days.map((key) => dailyTotals.get(key) ?? 0),
      productionStages: stageRows.map((row) => ({ label: row.label, count: Number(row.count) })),
      recentOrders: orders,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch dashboard stats", message: error.message });
  }
});

app.use((err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal server error" });
});

app.listen(port, async () => {
  try {
    await testConnection();
    console.log(`Server running on http://localhost:${port}`);
    console.log("Database: connected");
  } catch (error) {
    console.error(`Server running on http://localhost:${port}`);
    console.error("Database connection failed:", error.message);
  }
});

module.exports = app;
