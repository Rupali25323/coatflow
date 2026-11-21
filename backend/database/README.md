# Powder Coating CRM database

The schema targets **MySQL 8.0.16 or newer**. It creates the `powder_coating_crm`
database and normalized tables for authentication and permissions, customers and
suppliers, enquiries and quotations, sales orders, production, powder inventory,
quality and rework, dispatch and delivery, invoices, payments, expenses, and
activity history.

The schema file uses `CREATE DATABASE IF NOT EXISTS` and `CREATE TABLE IF NOT
EXISTS`; it contains no `DROP`, `TRUNCATE`, or `ALTER` statements. It does not
delete existing data. `seed.sql` inserts sample users and workflow data using
`INSERT IGNORE`. Review both SQL files before running them, especially if this
database already contains records.

## Review the SQL first

Open and review:

- `backend/database/schema.sql`
- `backend/database/seed.sql`

No database commands are run automatically by this project setup.

## Run from the project root

After you have reviewed the SQL and approved applying it to your MySQL server,
run the following from the project root in a terminal:

```sh
mysql -h localhost -u your_mysql_user -p < backend/database/schema.sql
mysql -h localhost -u your_mysql_user -p < backend/database/seed.sql
```

The MySQL client prompts for the user's password. Use a MySQL account that has
permission to create the database and tables. Do not put database passwords in
these command lines or commit them to source control.

Alternatively, open `schema.sql` in MySQL Workbench, inspect it, and execute it.
After the schema finishes, inspect and execute `seed.sql` in the same way.

## Configure the Node.js connection

From `backend/`, install the declared dependencies, then copy `.env.example` to
`.env` and set your local MySQL credentials:

```sh
npm install
```

The backend pool is exported from `backend/config/db.js`. Example usage:

```js
const { pool, testConnection } = require("./config/db");

await testConnection();
const [rows] = await pool.execute("SELECT id, company_name FROM customers");
```

Do not commit `backend/.env`. The existing `.env` file is left untouched.

## Seed-account security

Seeded users have `invited` status and a sentinel password hash, not usable
credentials. Replace each sentinel with a hash produced by the authentication
library selected by the application before inviting or activating those users.
The `.example.test` email addresses and GST identifiers are fictional sample
data.

## Design notes

- InnoDB foreign keys enforce relational integrity; indexes support common
  lookups by customer, status, due date, order, and transaction date.
- Order and invoice lines retain descriptions, tax, pricing, and customer tax
  identifiers as snapshots so later master-data edits do not rewrite history.
- Partial payments are represented by `payments` and `payment_allocations`.
  Application transactions should lock affected invoices and ensure total
  allocations never exceed the payment amount or invoice balance.
- Powder quantities are recorded as positive values in
  `powder_stock_transactions`; `transaction_type` determines whether a backend
  operation adds to or deducts from stock. Update the inventory balance and
  insert the ledger row atomically.
- Completed and rejected quantities are recorded separately in production and
  quality tables. The backend should enforce cumulative quantities against
  each job-card item.
- Cross-row/business rules (for example, allocations not exceeding balances,
  dispatch quantities not exceeding the unshipped order quantity, and
  inventory item type being `powder` for powder transactions) belong in
  transactional backend logic in addition to the database constraints.
