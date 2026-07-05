import { NavLink, Outlet, useNavigate } from "react-router-dom";
import clsx from "clsx";
import {
  LayoutDashboard,
  Package,
  Tags,
  Image,
  Printer,
  ShoppingCart,
  Ticket,
  BadgePercent,
  Truck,
  CreditCard,
  Users,
  UserCog,
  MessageCircle,
  Star,
  Bell,
  BarChart3,
  FileText,
  ShieldAlert,
  Settings as SettingsIcon,
  ScrollText,
  DatabaseBackup,
  LogOut,
} from "lucide-react";
import { useAuth } from "../lib/auth";

const sections: { label: string; items: { to: string; label: string; icon: typeof Package }[] }[] = [
  {
    label: "Overview",
    items: [
      { to: "/", label: "Dashboard", icon: LayoutDashboard },
      { to: "/analytics", label: "Analytics", icon: BarChart3 },
      { to: "/reports", label: "Reports", icon: FileText },
    ],
  },
  {
    label: "Catalog",
    items: [
      { to: "/products", label: "Products", icon: Package },
      { to: "/categories", label: "Categories", icon: Tags },
      { to: "/photo-uploads", label: "Photo Uploads", icon: Image },
      { to: "/print-queue", label: "Print Queue", icon: Printer },
    ],
  },
  {
    label: "Sales",
    items: [
      { to: "/orders", label: "Orders", icon: ShoppingCart },
      { to: "/coupons", label: "Coupons", icon: Ticket },
      { to: "/offers", label: "Offers", icon: BadgePercent },
      { to: "/delivery-settings", label: "Delivery Settings", icon: Truck },
      { to: "/payments", label: "Payments", icon: CreditCard },
    ],
  },
  {
    label: "People",
    items: [
      { to: "/customers", label: "Customers", icon: Users },
      { to: "/admins", label: "Employees", icon: UserCog },
      { to: "/support", label: "Support", icon: MessageCircle },
      { to: "/reviews", label: "Reviews", icon: Star },
    ],
  },
  {
    label: "System",
    items: [
      { to: "/notifications", label: "Notifications", icon: Bell },
      { to: "/security", label: "Security", icon: ShieldAlert },
      { to: "/system-logs", label: "System Logs", icon: ScrollText },
      { to: "/backup", label: "Backup", icon: DatabaseBackup },
      { to: "/settings", label: "Settings", icon: SettingsIcon },
    ],
  },
];

export default function Layout() {
  const { username, role, logout } = useAuth();
  const navigate = useNavigate();

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
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === "/"}
                  className={({ isActive }) =>
                    clsx(
                      "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm transition-colors",
                      isActive ? "bg-accent/10 text-accent" : "text-neutral-300 hover:bg-surface-2",
                    )
                  }
                >
                  <item.icon size={16} />
                  {item.label}
                </NavLink>
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
              navigate("/login");
            }}
            className="flex items-center gap-2 text-xs text-neutral-400 hover:text-white"
          >
            <LogOut size={14} /> Log out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-y-auto p-8">
        <Outlet />
      </main>
    </div>
  );
}
