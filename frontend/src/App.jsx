import { useEffect, useMemo, useRef, useState } from "react";
import {
  Activity, ArrowDownRight, ArrowRight, ArrowUpRight, Bell, Boxes,
  BriefcaseBusiness, CalendarDays, Check, ChevronDown, ChevronRight,
  CircleHelp, ClipboardCheck, ClipboardList, Clock3, CreditCard, Download,
  Factory, FileText, Filter, LayoutDashboard, Layers3, Menu, MoreHorizontal,
  Plus, Search, Settings, ShieldCheck, Sparkles, Truck, Users, WalletCards, X,
} from "lucide-react";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:5000";
const customerStatuses = ["active", "inactive", "prospect", "blocked"];
const modulePages = new Set(["Enquiries", "Quotations", "Orders", "Job Cards", "Production", "Inventory", "Quality Control", "Dispatch", "Invoices", "Payments"]);

function mapCustomer(row) {
  const details = [row.contact_name, row.billing_city].filter(Boolean).join(" · ") || row.notes || "—";
  const created = row.created_at
    ? new Date(row.created_at).toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" })
    : "—";
  return [row.customer_code, row.company_name, details, row.status.charAt(0).toUpperCase() + row.status.slice(1), created, 0];
}

function mapRecord(record) {
  return [record.reference, record.customer, record.details, record.status, record.date, record.value];
}

const navigation = [
  { label: "WORKSPACE", items: [["Dashboard", LayoutDashboard], ["Customers", Users], ["Enquiries", Activity], ["Quotations", FileText], ["Orders", BriefcaseBusiness]] },
  { label: "OPERATIONS", items: [["Job Cards", ClipboardList], ["Production", Factory], ["Inventory", Boxes], ["Quality Control", ShieldCheck], ["Dispatch", Truck]] },
  { label: "FINANCE", items: [["Invoices", FileText], ["Payments", CreditCard]] },
];

const orderTones = ["lavender", "peach", "blue", "mint"];
const stageColors = ["stage-blue", "stage-violet", "stage-orange", "stage-green"];
const dateLabel = new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "2-digit", year: "numeric" }).toUpperCase();

function initialsFor(name) {
  return name.split(/\s+/).filter(Boolean).slice(0, 2).map((word) => word[0].toUpperCase()).join("") || "—";
}

function formatCurrency(value) {
  return value ? `₹${Number(value).toLocaleString("en-IN")}` : "—";
}

function formatAxisValue(value) {
  if (value >= 100000) return `₹${(value / 100000).toFixed(1)}L`;
  if (value >= 1000) return `₹${Math.round(value / 1000)}k`;
  return `₹${value}`;
}

function statusClass(status) {
  const value = status.toLowerCase();
  if (["active", "passed", "paid", "received", "completed", "in stock", "accepted"].includes(value)) return "status-green";
  if (["in production", "in progress", "in review", "packing", "sent", "scheduled", "confirmed", "queued"].includes(value)) return "status-blue";
  if (["ready to ship", "low stock", "pending", "new", "draft"].includes(value)) return "status-amber";
  if (["overdue", "expired"].includes(value)) return "status-red";
  if (["dispatched", "in transit", "quality check", "converted"].includes(value)) return "status-violet";
  return "status-neutral";
}

function Sidebar({ activePage, onNavigate, isOpen, onClose }) {
  return <>
    {isOpen && <button className="sidebar-backdrop" aria-label="Close navigation" onClick={onClose} />}
    <aside className={`sidebar ${isOpen ? "sidebar-open" : ""}`}>
      <a className="brand" href="#" onClick={(event) => event.preventDefault()}>
        <span className="brand-mark"><Layers3 size={20} strokeWidth={2.2} /></span>
        <span className="brand-copy"><strong>coatflow</strong><small>WORKSHOP OS</small></span>
      </a>
      <button className="workspace-switcher">
        <span className="workspace-avatar"><Factory size={16} /></span>
        <span className="workspace-name"><strong>Vertex Coatings</strong><small>Manufacturing</small></span>
        <ChevronDown size={15} className="workspace-chevron" />
      </button>
      <nav className="side-nav" aria-label="Main navigation">
        {navigation.map((group) => <div className="nav-group" key={group.label}>
          <p className="nav-heading">{group.label}</p>
          {group.items.map(([name, Icon]) => <button className={`nav-item ${activePage === name ? "nav-item-active" : ""}`} key={name} onClick={() => onNavigate(name)} aria-current={activePage === name ? "page" : undefined}>
            <Icon size={17} strokeWidth={1.8} /><span>{name}</span>{name === "Enquiries" && <span className="nav-count">4</span>}
          </button>)}
        </div>)}
      </nav>
      <div className="sidebar-bottom">
        <div className="help-card"><span className="help-icon"><Sparkles size={15} /></span><strong>Need a hand?</strong><p>Our team is here to help you get more from CoatFlow.</p><button onClick={() => onNavigate("Help & support")}>Visit help center <ArrowRight size={13} /></button></div>
        <button className="nav-item utility-item" onClick={() => onNavigate("Settings")}><Settings size={17} /><span>Settings</span></button>
        <div className="profile"><span className="profile-avatar">RK</span><span className="profile-copy"><strong>Rahul Kulkarni</strong><small>Workshop admin</small></span><MoreHorizontal size={19} className="profile-more" /></div>
      </div>
    </aside>
  </>;
}

function Header({ activePage, searchTerm, setSearchTerm, onMenuClick, searchInputRef }) {
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  return <header className="topbar">
    <div className="topbar-left"><button className="mobile-menu icon-button" aria-label="Open navigation" onClick={onMenuClick}><Menu size={20} /></button><div className="breadcrumbs"><span>Workspace</span><ChevronRight size={14} /><strong>{activePage}</strong></div></div>
    <div className="topbar-actions">
      <label className="search-box"><Search size={16} /><input ref={searchInputRef} value={searchTerm} onChange={(event) => setSearchTerm(event.target.value)} placeholder="Search anything..." aria-label="Search current page" /><kbd>⌘ K</kbd></label>
      <div className="notification-wrap"><button className={`icon-button notification-button ${notificationsOpen ? "icon-button-active" : ""}`} aria-label="Notifications" onClick={() => setNotificationsOpen(!notificationsOpen)}><Bell size={18} /><span className="notification-dot" /></button>
        {notificationsOpen && <div className="notification-popover"><div className="popover-heading"><strong>Notifications</strong><span>2 new</span></div>
          <div className="notification-entry"><span className="notification-entry-icon amber-bg"><Boxes size={15} /></span><span><strong>Powder running low</strong><small>Signal red · RAL 3001 is below minimum stock.</small><em>12 min ago</em></span></div>
          <div className="notification-entry"><span className="notification-entry-icon blue-bg"><ClipboardCheck size={15} /></span><span><strong>Quality check due</strong><small>Order ORD-0588 is ready for inspection.</small><em>1 hour ago</em></span></div>
        </div>}
      </div>
      <button className="topbar-help" aria-label="Help"><CircleHelp size={18} /></button>
    </div>
  </header>;
}

function MetricCard({ metric }) {
  const Icon = metric.icon;
  const Trend = metric.trend === "down" ? ArrowDownRight : ArrowUpRight;
  return <article className="metric-card">
    <div className="metric-top"><span className={`metric-icon metric-icon-${metric.color}`}><Icon size={18} strokeWidth={1.8} /></span><button className="subtle-icon-button" aria-label={`More about ${metric.label}`}><MoreHorizontal size={18} /></button></div>
    <p className="metric-label">{metric.label}</p><div className="metric-value">{metric.value}</div>
    <div className="metric-foot"><span className={`metric-change ${metric.trend === "down" ? "change-alert" : metric.trend === "flat" ? "change-flat" : ""}`}>{metric.trend !== "flat" && <Trend size={14} />}{metric.change}</span><span>{metric.note}</span></div>
  </article>;
}

function RevenueChart({ data, timeRange, setTimeRange }) {
  const monthly = timeRange === "12 months";
  const values = monthly ? (data?.revenueSeries ?? []) : (data?.dailySeries ?? []);
  const keys = monthly ? (data?.months ?? []) : (data?.days ?? []);
  const labels = monthly
    ? keys.map((key) => new Date(`${key}-01T00:00:00Z`).toLocaleDateString("en-US", { month: "short", timeZone: "UTC" }))
    : keys.filter((_, index) => index % 3 === 0).map((key) => new Date(`${key}T00:00:00Z`).toLocaleDateString("en-US", { day: "numeric", timeZone: "UTC" }));
  const maxValue = Math.max(...values, 1);
  const path = values.map((value, index) => `${index ? "L" : "M"} ${(index / Math.max(values.length - 1, 1)) * 600} ${150 - (value / maxValue) * 130}`).join(" ");
  const periodTotal = values.reduce((sum, value) => sum + value, 0);
  const yLabels = [1, 0.75, 0.5, 0.25, 0].map((factor) => formatAxisValue(Math.round(maxValue * factor)));
  return <section className="panel revenue-panel">
    <div className="panel-heading"><div><p className="eyebrow">YOUR BUSINESS AT A GLANCE</p><h2>Revenue overview</h2></div>
      <div className="chart-controls"><span className="chart-legend"><i /> Revenue</span><button className="select-button" onClick={() => setTimeRange(monthly ? "30 days" : "12 months")}>{timeRange}<ChevronDown size={14} /></button></div>
    </div>
    <div className="chart-summary"><strong>{formatCurrency(periodTotal)}</strong>{monthly && data?.revenueChange !== "—" && <span className="chart-growth"><ArrowUpRight size={14} />{data.revenueChange}</span>}<small>{monthly ? "collected over 12 months" : "collected in the last 30 days"}</small></div>
    <div className="chart-wrap"><div className="chart-y-labels">{yLabels.map((label, index) => <span key={`${label}-${index}`}>{label}</span>)}</div>
      {values.length > 0 ? <>
        <svg className="revenue-chart" viewBox="0 0 600 170" preserveAspectRatio="none" role="img" aria-label={`Revenue trend for the last ${monthly ? "12 months" : "30 days"}`}>
          <defs><linearGradient id="chartFill" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#518b74" stopOpacity=".18" /><stop offset="100%" stopColor="#518b74" stopOpacity="0" /></linearGradient></defs>
          {[15, 50, 85, 120, 155].map((y) => <line key={y} x1="0" x2="600" y1={y} y2={y} className="chart-gridline" />)}
          <path d={`${path} L 600 160 L 0 160 Z`} fill="url(#chartFill)" /><path d={path} className="chart-line" />
          <circle cx="600" cy={150 - (values.at(-1) / maxValue) * 130} r="4.5" className="chart-last-point" />
        </svg>
        <div className="chart-x-labels">{labels.map((label, index) => <span key={`${label}-${index}`}>{label}</span>)}</div>
      </> : <div className="empty-search">No revenue recorded yet.</div>}
    </div>
  </section>;
}

function ProductionPanel({ data, onNavigate }) {
  const stages = data?.productionStages ?? [];
  const maxCount = Math.max(...stages.map((stage) => stage.count), 1);
  return <section className="panel production-panel">
    <div className="panel-heading"><div><p className="eyebrow">LIVE FLOOR STATUS</p><h2>Production overview</h2></div><button className="panel-link" onClick={onNavigate}>View board <ArrowRight size={14} /></button></div>
    <div className="production-total"><strong>{data?.inProduction ?? 0}</strong><span>active jobs</span><span className="live-indicator"><i /> Live</span></div>
    <div className="stage-stack">{stages.map((stage, index) => <div className="stage-row" key={stage.label}><div className="stage-label"><span>{stage.label}</span><strong>{stage.count}</strong></div><div className="stage-track"><span className={stageColors[index % stageColors.length]} style={{ width: `${(stage.count / maxCount) * 100}%` }} /></div></div>)}</div>
    <div className="production-note"><span className="note-icon"><Clock3 size={15} /></span><span><strong>{data?.dueToday ?? 0} jobs due today</strong><small>Keep an eye on the delivery queue.</small></span><ChevronRight size={16} /></div>
  </section>;
}

function OrdersTable({ orders, onViewAll }) {
  return <section className="panel orders-panel">
    <div className="panel-heading orders-heading"><div><p className="eyebrow">KEEP THINGS MOVING</p><h2>Recent orders <span className="heading-count">{String(orders.length).padStart(2, "0")}</span></h2></div><button className="panel-link" onClick={onViewAll}>All orders <ArrowRight size={14} /></button></div>
    <div className="table-scroll"><table className="orders-table">
      <thead><tr><th>ORDER</th><th>CUSTOMER</th><th>STATUS</th><th>DUE DATE</th><th className="align-right">AMOUNT</th></tr></thead>
      <tbody>{orders.map((order) => <tr key={order.id}><td><span className="order-id">{order.id}</span></td><td><span className="customer-cell"><span className={`customer-avatar avatar-${order.tone}`}>{order.initials}</span><span><strong>{order.customer}</strong><small>{order.details}</small></span></span></td><td><span className={`status-pill ${statusClass(order.status)}`}><i />{order.status}</span></td><td className="date-cell">{order.date}</td><td className="align-right amount-cell">{formatCurrency(order.amount)}</td></tr>)}</tbody>
    </table></div>
    {orders.length === 0 && <div className="empty-search">No orders match your search.</div>}
  </section>;
}

function Dashboard({ data, loading, error, searchTerm, timeRange, setTimeRange, onNavigate }) {
  const orders = useMemo(() => (data?.recentOrders ?? [])
    .filter((order) => Object.values(order).join(" ").toLowerCase().includes(searchTerm.toLowerCase()))
    .map((order, index) => ({ ...order, initials: initialsFor(order.customer), tone: orderTones[index % orderTones.length] })), [data, searchTerm]);
  const metrics = data ? [
    { label: "Total revenue", value: formatCurrency(data.totalRevenue), change: data.revenueChange === "—" ? "No prior data" : data.revenueChange, note: "vs. last month", icon: WalletCards, color: "mint", trend: data.revenueChange === "—" ? "flat" : data.revenueTrend },
    { label: "Active orders", value: String(data.activeOrders).padStart(2, "0"), change: `${data.customers} customers`, note: "in current pipeline", icon: BriefcaseBusiness, color: "blue", trend: "up" },
    { label: "In production", value: String(data.inProduction).padStart(2, "0"), change: `${data.dueToday} due today`, note: "on the floor", icon: Factory, color: "amber", trend: "flat" },
    { label: "Pending payments", value: formatCurrency(data.pendingPayments), change: `${data.pendingInvoices} invoices`, note: "need attention", icon: Clock3, color: "rose", trend: "down" },
  ] : [];
  return <>
    <div className="welcome-row"><div><div className="date-greeting"><CalendarDays size={14} /> {dateLabel} <span className="date-dot" /> SHIFT A</div><h1>Good morning, Rahul <span className="wave">✳</span></h1><p>Here&apos;s what&apos;s happening at your workshop today.</p></div><button className="primary-button" onClick={() => onNavigate("Orders", true)}><Plus size={17} /> Create an order</button></div>
    {error ? <section className="panel empty-state"><span><CircleHelp size={20} /></span><strong>Could not load dashboard</strong><p>{error}</p></section>
      : loading || !data ? <section className="panel empty-state"><span><Activity size={20} /></span><strong>Loading dashboard…</strong></section>
        : <>
          <div className="metrics-grid">{metrics.map((metric) => <MetricCard key={metric.label} metric={metric} />)}</div>
          <div className="analytics-grid"><RevenueChart data={data} timeRange={timeRange} setTimeRange={setTimeRange} /><ProductionPanel data={data} onNavigate={() => onNavigate("Production")} /></div>
          <OrdersTable orders={orders} onViewAll={() => onNavigate("Orders")} />
        </>}
    <footer className="page-footer"><span>Everything is up to date <Check size={13} /></span><span>Last synced just now</span></footer>
  </>;
}

const descriptions = {
  Customers: "Build stronger relationships and keep every customer detail in one place.",
  Enquiries: "Capture new opportunities and turn incoming requests into confirmed work.",
  Quotations: "Create clear, accurate quotes and follow every proposal through to a decision.",
  Orders: "Track every confirmed job from order intake to successful delivery.",
  "Job Cards": "Give your workshop a clear, actionable brief for every production batch.",
  Production: "Keep an eye on active batches, work center capacity, and delivery timelines.",
  Inventory: "Stay ahead of material levels and make sure production never has to wait.",
  "Quality Control": "Record inspections and make sure every finished part meets spec.",
  Dispatch: "Coordinate packing, carriers, and deliveries from one simple workspace.",
  Invoices: "Keep billing organized and see which invoices need a follow-up.",
  Payments: "Track incoming payments and quickly spot overdue customer balances.",
};
const createNouns = { Customers: "customer", Enquiries: "enquiry", Quotations: "quotation", Orders: "order", "Job Cards": "job card", Production: "batch", Inventory: "item", "Quality Control": "inspection", Dispatch: "shipment", Invoices: "invoice", Payments: "payment" };

function ModulePage({ activePage, records, searchTerm, onAdd, loading, error }) {
  const [statusFilter, setStatusFilter] = useState("All records");
  const rows = records;
  const statuses = [...new Set(rows.map((record) => record[3]))];
  const filtered = rows.filter((record) => record.join(" ").toLowerCase().includes(searchTerm.toLowerCase()) && (statusFilter === "All records" || record[3] === statusFilter));
  const total = rows.reduce((sum, record) => sum + record[5], 0);
  return <>
    <div className="module-welcome"><div><div className="date-greeting"><span>WORKSPACE</span><ChevronRight size={13} /> {activePage.toUpperCase()}</div><h1>{activePage}</h1><p>{descriptions[activePage] ?? "Manage your workshop workspace."}</p></div><button className="primary-button" onClick={onAdd}><Plus size={17} /> New {createNouns[activePage] ?? "record"}</button></div>
    <div className="module-stats">
      <article className="module-stat"><span className="module-stat-icon stat-mint"><Activity size={17} /></span><span><small>Total {activePage.toLowerCase()}</small><strong>{String(rows.length).padStart(2, "0")}</strong></span></article>
      <article className="module-stat"><span className="module-stat-icon stat-blue"><Check size={17} /></span><span><small>Active status types</small><strong>{String(statuses.length).padStart(2, "0")}</strong></span></article>
      <article className="module-stat"><span className="module-stat-icon stat-amber"><WalletCards size={17} /></span><span><small>Value in this view</small><strong>{formatCurrency(total)}</strong></span></article>
      <article className="module-stat"><span className="module-stat-icon stat-violet"><CalendarDays size={17} /></span><span><small>Last updated</small><strong className="updated-stat">Just now</strong></span></article>
    </div>
    <section className="panel records-panel">
      <div className="records-toolbar"><div><h2>All {activePage.toLowerCase()} <span className="heading-count">{String(filtered.length).padStart(2, "0")}</span></h2><p>A clear view of everything currently in your workspace.</p></div>
        <div className="records-actions"><label className="filter-select"><Filter size={15} /><select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)} aria-label="Filter records by status"><option>All records</option>{statuses.map((status) => <option key={status}>{status}</option>)}</select><ChevronDown size={14} /></label><button className="secondary-button" onClick={() => window.print()}><Download size={15} /> Export</button></div>
      </div>
      <div className="table-scroll"><table className="records-table"><thead><tr><th>REFERENCE</th><th>{activePage === "Inventory" ? "ITEM" : "CUSTOMER / ITEM"}</th><th>DETAILS</th><th>STATUS</th><th>{activePage === "Inventory" ? "REORDER NOTE" : "DUE DATE"}</th><th className="align-right">VALUE</th><th aria-label="Actions" /></tr></thead>
        <tbody>{filtered.map(([id, customer, details, status, due, value]) => <tr key={id}><td><span className="order-id">{id}</span></td><td><strong className="record-customer">{customer}</strong></td><td className="record-details">{details}</td><td><span className={`status-pill ${statusClass(status)}`}><i />{status}</span></td><td className="date-cell">{due}</td><td className="align-right amount-cell">{formatCurrency(value)}</td><td><button className="subtle-icon-button row-more" aria-label={`More options for ${id}`}><MoreHorizontal size={17} /></button></td></tr>)}</tbody>
      </table></div>
      {loading && <div className="empty-state"><span><Activity size={20} /></span><strong>Loading {activePage.toLowerCase()}…</strong></div>}
      {!loading && error && <div className="empty-state"><span><CircleHelp size={20} /></span><strong>Could not load {activePage.toLowerCase()}</strong><p>{error}</p></div>}
      {!loading && !error && filtered.length === 0 && <div className="empty-state"><span><Search size={20} /></span><strong>No records found</strong><p>Try a different search or status filter.</p></div>}
      <div className="table-pagination"><span>Showing <strong>{filtered.length ? "1" : "0"}–{filtered.length}</strong> of <strong>{rows.length}</strong> records</span><div><button disabled aria-label="Previous page"><ChevronRight size={15} className="flip-icon" /></button><button disabled aria-label="Next page"><ChevronRight size={15} /></button></div></div>
    </section>
    <footer className="page-footer"><span>Everything is up to date <Check size={13} /></span><span>Last synced just now</span></footer>
  </>;
}

function CreateRecordModal({ activePage, onClose, onCreate }) {
  const [name, setName] = useState("");
  const [details, setDetails] = useState("");
  const [status, setStatus] = useState(activePage === "Customers" ? "active" : "New");
  const [value, setValue] = useState("");
  const [error, setError] = useState("");
  function submit(event) {
    event.preventDefault();
    if (!name.trim() || !details.trim()) return setError("Please enter a name and a short description.");
    onCreate({ name: name.trim(), details: details.trim(), status, value: Number(value) || 0 });
  }
  return <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
    <section className="create-modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <div className="modal-heading"><span className="modal-icon"><Plus size={18} /></span><button className="icon-button" aria-label="Close dialog" onClick={onClose}><X size={18} /></button></div>
      <h2 id="modal-title">Create {createNouns[activePage] ?? "record"}</h2><p className="modal-description">Add a new record to your {activePage.toLowerCase()} workspace.</p>
      <form onSubmit={submit}><label>{activePage === "Inventory" ? "Item name" : activePage === "Customers" ? "Customer name" : "Customer or company"}<input autoFocus value={name} onChange={(event) => setName(event.target.value)} placeholder={activePage === "Inventory" ? "e.g. Matte black, RAL 9005" : "e.g. Acme Industries"} /></label>
        <label>Description<input value={details} onChange={(event) => setDetails(event.target.value)} placeholder="Add a short description" /></label>
        <div className="modal-form-row"><label>Status<select value={status} onChange={(event) => setStatus(event.target.value)}>{(activePage === "Customers" ? customerStatuses : ["New", "In progress", "In review", "Confirmed"]).map((option) => <option key={option}>{option}</option>)}</select></label><label>Value (₹)<input type="number" min="0" value={value} onChange={(event) => setValue(event.target.value)} placeholder="0" /></label></div>
        {error && <p className="form-error">{error}</p>}<div className="modal-footer"><button type="button" className="secondary-button" onClick={onClose}>Cancel</button><button type="submit" className="primary-button"><Plus size={15} /> Create record</button></div>
      </form>
    </section>
  </div>;
}

function App() {
  const [activePage, setActivePage] = useState(() => localStorage.getItem("coatflow.activePage") || "Dashboard");
  const [searchTerm, setSearchTerm] = useState("");
  const [timeRange, setTimeRange] = useState("12 months");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [moduleRecords, setModuleRecords] = useState({});
  const [moduleLoading, setModuleLoading] = useState(false);
  const [moduleError, setModuleError] = useState("");
  const [dashboard, setDashboard] = useState(null);
  const [dashboardLoading, setDashboardLoading] = useState(true);
  const [dashboardError, setDashboardError] = useState("");
  const [customers, setCustomers] = useState([]);
  const [customersLoading, setCustomersLoading] = useState(true);
  const [customersError, setCustomersError] = useState("");
  const [toast, setToast] = useState("");
  const [toastError, setToastError] = useState(false);
  const searchInputRef = useRef(null);
  const loadedModules = useRef(new Set());
  const navigateTo = (page) => { setActivePage(page); setSearchTerm(""); setSidebarOpen(false); localStorage.setItem("coatflow.activePage", page); };
  useEffect(() => {
    let cancelled = false;
    async function loadCustomers() {
      try {
        const response = await fetch(`${API_URL}/api/customers`);
        if (!response.ok) throw new Error(`Request failed (${response.status})`);
        const data = await response.json();
        if (!cancelled) {
          setCustomers((data.customers ?? []).map(mapCustomer));
          setCustomersError("");
        }
      } catch (error) {
        if (!cancelled) setCustomersError(error.message);
      } finally {
        if (!cancelled) setCustomersLoading(false);
      }
    }
    loadCustomers();
    return () => { cancelled = true; };
  }, []);
  useEffect(() => {
    let cancelled = false;
    async function loadDashboard() {
      try {
        const response = await fetch(`${API_URL}/api/dashboard`);
        if (!response.ok) throw new Error(`Request failed (${response.status})`);
        const data = await response.json();
        if (!cancelled) {
          setDashboard(data);
          setDashboardError("");
        }
      } catch (error) {
        if (!cancelled) setDashboardError(error.message);
      } finally {
        if (!cancelled) setDashboardLoading(false);
      }
    }
    loadDashboard();
    return () => { cancelled = true; };
  }, []);
  useEffect(() => {
    if (!modulePages.has(activePage) || loadedModules.current.has(activePage)) return;
    let cancelled = false;
    setModuleLoading(true);
    setModuleError("");
    fetch(`${API_URL}/api/modules/${encodeURIComponent(activePage)}`)
      .then((response) => {
        if (!response.ok) throw new Error(`Request failed (${response.status})`);
        return response.json();
      })
      .then((data) => {
        if (cancelled) return;
        loadedModules.current.add(activePage);
        setModuleRecords((current) => ({ ...current, [activePage]: data.records.map(mapRecord) }));
      })
      .catch((error) => {
        if (!cancelled) setModuleError(error.message);
      })
      .finally(() => {
        if (!cancelled) setModuleLoading(false);
      });
    return () => { cancelled = true; };
  }, [activePage]);
  useEffect(() => {
    const handler = (event) => navigateTo(event.detail);
    window.addEventListener("navigate-crm", handler);
    return () => window.removeEventListener("navigate-crm", handler);
  }, []);
  useEffect(() => {
    const handler = (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        searchInputRef.current?.focus();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);
  function showToast(message, isError = false) {
    setToast(message); setToastError(isError);
    window.setTimeout(() => { setToast(""); setToastError(false); }, isError ? 4000 : 3000);
  }
  async function createRecord(record) {
    if (activePage === "Customers") {
      try {
        const response = await fetch(`${API_URL}/api/customers`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            company_name: record.name,
            contact_name: "",
            notes: record.details,
            status: customerStatuses.includes(record.status) ? record.status : "active",
          }),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || data.error || "Request failed");
        setCustomers((current) => [mapCustomer(data.customer), ...current]);
        setModalOpen(false);
        showToast("Customer created successfully");
      } catch (error) {
        showToast(`Could not create customer: ${error.message}`, true);
      }
      return;
    }
    try {
      const response = await fetch(`${API_URL}/api/modules/${encodeURIComponent(activePage)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: record.name,
          details: record.details,
          status: record.status,
          value: record.value,
        }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || data.error || "Request failed");
      setModuleRecords((current) => ({
        ...current,
        [activePage]: [mapRecord(data.record), ...(current[activePage] ?? [])],
      }));
      setModalOpen(false);
      showToast(`${createNouns[activePage] ?? "Record"} created successfully`);
    } catch (error) {
      showToast(`Could not create record: ${error.message}`, true);
    }
  }
  function dashboardNavigate(page, openCreate = false) {
    navigateTo(page);
    if (openCreate) setModalOpen(true);
  }
  return <div className="app-shell">
    <Sidebar activePage={activePage} onNavigate={navigateTo} isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
    <main className="main-area"><Header activePage={activePage} searchTerm={searchTerm} setSearchTerm={setSearchTerm} onMenuClick={() => setSidebarOpen(true)} searchInputRef={searchInputRef} />
      <div className="page-content">{activePage === "Dashboard"
        ? <Dashboard data={dashboard} loading={dashboardLoading} error={dashboardError} searchTerm={searchTerm} timeRange={timeRange} setTimeRange={setTimeRange} onNavigate={dashboardNavigate} />
        : <ModulePage activePage={activePage} records={activePage === "Customers" ? customers : (moduleRecords[activePage] ?? [])} searchTerm={searchTerm} onAdd={() => setModalOpen(true)} loading={activePage === "Customers" ? customersLoading : moduleLoading} error={activePage === "Customers" ? customersError : moduleError} />}</div>
    </main>
    {modalOpen && <CreateRecordModal activePage={activePage} onClose={() => setModalOpen(false)} onCreate={createRecord} />}
    {toast && <div className={`toast-message ${toastError ? "toast-error" : ""}`}><span>{toastError ? <CircleHelp size={15} /> : <Check size={15} />}</span>{toast}</div>}
  </div>;
}

export default App;