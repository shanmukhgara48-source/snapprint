import { useState } from "react";
import clsx from "clsx";
import { useQuery } from "@tanstack/react-query";
import {
  LayoutDashboard,
  Package,
  Tags,
  ShoppingCart,
  Ticket,
  GalleryHorizontal,
  Truck,
  CreditCard,
  Users,
  UserCog,
  Bell,
  BarChart3,
  FileDown,
  Inbox as InboxIcon,
  Star,
  Undo2,
  ShieldCheck,
  Settings as SettingsIcon,
  LogOut,
  Search,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { useAdminRealtime } from "../lib/realtime";
import { useNavigate, usePathname } from "../lib/router";
import { api } from "../lib/api";
import { Link } from "./Link";

const sections: { label: string; items: { to: string; label: string; icon: typeof Package; badge?: number }[] }[] = [
  {
    label: "Overview",
    items: [
      { to: "/", label: "Dashboard", icon: LayoutDashboard },
      { to: "/analytics", label: "Analytics", icon: BarChart3 },
      { to: "/reports", label: "Reports", icon: FileDown },
    ],
  },
  {
    label: "Catalog",
    items: [
      { to: "/products", label: "Products", icon: Package },
      { to: "/categories", label: "Categories", icon: Tags },
    ],
  },
  {
    label: "Sales",
    items: [
      { to: "/orders", label: "Orders", icon: ShoppingCart },
      { to: "/returns", label: "Returns", icon: Undo2 },
      { to: "/coupons", label: "Offers & Coupons", icon: Ticket },
      { to: "/banners", label: "Banners", icon: GalleryHorizontal },
      { to: "/delivery-settings", label: "Delivery Settings", icon: Truck },
      { to: "/payments", label: "Payments", icon: CreditCard },
    ],
  },
  {
    label: "People",
    items: [
      { to: "/customers", label: "Customers", icon: Users },
      { to: "/admins", label: "Employees", icon: UserCog },
    ],
  },
  {
    label: "Support",
    items: [
      { to: "/inbox", label: "Inbox", icon: InboxIcon },
      { to: "/reviews", label: "Reviews", icon: Star },
    ],
  },
  {
    label: "System",
    items: [
      { to: "/notifications", label: "Notifications", icon: Bell },
      { to: "/audit", label: "Audit Log", icon: ShieldCheck },
      { to: "/settings", label: "Settings", icon: SettingsIcon },
    ],
  },
];

const SEARCH_SCOPES = [
  { value: "orders", label: "Orders" },
  { value: "products", label: "Products" },
  { value: "customers", label: "Customers" },
];

function GlobalSearch() {
  const navigate = useNavigate();
  const [q, setQ] = useState("");
  const [scope, setScope] = useState("orders");

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const query = q.trim();
    navigate(query ? `/${scope}?q=${encodeURIComponent(query)}` : `/${scope}`, { replace: true });
  }

  return (
    <form onSubmit={submit} className="flex items-center gap-2">
      <select
        value={scope}
        onChange={(e) => setScope(e.target.value)}
        aria-label="Search scope"
        className="rounded-lg border border-border bg-surface-2 px-2 py-1.5 text-xs text-neutral-300 outline-none"
      >
        {SEARCH_SCOPES.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </select>
      <div className="relative">
        <Search size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-neutral-500" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search order, product, phone…"
          className="w-64 rounded-lg border border-border bg-surface-2 py-1.5 pl-8 pr-3 text-xs text-white placeholder:text-neutral-500 outline-none focus:border-accent"
        />
      </div>
    </form>
  );
}

function InboxBell() {
  const { data } = useQuery({
    queryKey: ["inbox-unread-count"],
    queryFn: async () =>
      (await api.get<{ id: string }[]>("/admin/contact-messages", { params: { unread_only: true, limit: 50 } })).data,
    refetchInterval: 60_000,
  });
  const count = data?.length ?? 0;
  return (
    <Link to="/inbox" className="relative rounded-lg p-2 text-neutral-400 hover:bg-surface-2 hover:text-white" aria-label="Support inbox">
      <Bell size={17} />
      {count > 0 && (
        <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-black">
          {count > 50 ? "50+" : count}
        </span>
      )}
    </Link>
  );
}

export default function Layout({ children }: { children: React.ReactNode }) {
  const { username, role, logout } = useAuth();
  const navigate = useNavigate();
  const pathname = usePathname();
  useAdminRealtime(); // live cache invalidation for every screen

  return (
    <div className="flex h-full">
      <aside className="flex w-64 shrink-0 flex-col border-r border-border bg-surface">
        <div className="flex items-center gap-2 px-5 py-4 border-b border-border">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent text-sm font-bold text-black">
            SP
          </div>
          <span className="font-semibold text-white">SnapPrint Admin</span>
        </div>
        <nav className="flex-1 overflow-y-auto px-3 py-4">
          {sections.map((section) => (
            <div key={section.label} className="mb-4">
              <div className="px-2 pb-1.5 text-[11px] font-semibold uppercase tracking-wider text-neutral-500">
                {section.label}
              </div>
              {section.items.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className={clsx(
                    "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm transition-colors",
                    pathname === item.to ||
                      (item.to !== "/" && pathname.startsWith(`${item.to}/`))
                      ? "bg-accent/10 text-accent"
                      : "text-neutral-300 hover:bg-surface-2",
                  )}
                >
                  <item.icon size={16} />
                  {item.label}
                </Link>
              ))}
            </div>
          ))}
        </nav>
        <div className="border-t border-border px-4 py-3">
          <div className="mb-2 text-xs">
            <div className="text-white">{username}</div>
            <div className="text-neutral-500 capitalize">{role?.replace("_", " ")}</div>
          </div>
          <button
            onClick={() => {
              logout();
              navigate("/login", { replace: true });
            }}
            className="flex items-center gap-2 text-xs text-neutral-400 hover:text-white"
          >
            <LogOut size={14} /> Log out
          </button>
        </div>
      </aside>
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-border bg-surface px-8 py-2.5">
          <GlobalSearch />
          <InboxBell />
        </header>
        <main className="flex-1 overflow-y-auto p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
