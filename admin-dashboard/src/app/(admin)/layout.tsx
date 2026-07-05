"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  LayoutDashboard,
  Package,
  ShoppingCart,
  Users,
  Ticket,
  Truck,
  CreditCard,
  ShieldCheck,
  Settings,
  LogOut,
} from "lucide-react";
import { AdminRole, clearSession, getRole, getUsername, isLoggedIn } from "@/lib/auth";

interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ size?: number }>;
  roles: AdminRole[]; // which admin_role values can see this
}

const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard, roles: ["super_admin", "manager", "support_staff", "printing_staff", "delivery_staff"] },
  { href: "/products", label: "Products", icon: Package, roles: ["super_admin", "manager"] },
  { href: "/orders", label: "Orders", icon: ShoppingCart, roles: ["super_admin", "manager", "printing_staff", "delivery_staff", "support_staff"] },
  { href: "/users", label: "Users", icon: Users, roles: ["super_admin", "manager", "support_staff"] },
  { href: "/coupons", label: "Coupons", icon: Ticket, roles: ["super_admin", "manager"] },
  { href: "/delivery-settings", label: "Delivery Settings", icon: Truck, roles: ["super_admin", "manager"] },
  { href: "/payments", label: "Payments", icon: CreditCard, roles: ["super_admin", "manager"] },
  { href: "/admins", label: "Admin Users", icon: ShieldCheck, roles: ["super_admin"] },
  { href: "/settings", label: "Settings", icon: Settings, roles: ["super_admin"] },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [role] = useState<AdminRole | null>(() => getRole());
  const [username] = useState<string | null>(() => getUsername());
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!isLoggedIn()) {
      router.replace("/login");
      return;
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect -- client-only auth guard, no external-system alternative
    setReady(true);
  }, [router]);

  function handleLogout() {
    clearSession();
    router.replace("/login");
  }

  if (!ready) {
    return <div className="flex min-h-screen items-center justify-center text-sm text-gray-400">Loading...</div>;
  }

  const visibleItems = NAV_ITEMS.filter((item) => !role || item.roles.includes(role));

  return (
    <div className="flex min-h-screen w-full">
      <aside className="flex w-60 flex-col border-r border-gray-200 bg-white">
        <div className="border-b border-gray-200 px-5 py-4">
          <div className="text-sm font-semibold">SnapPrint Admin</div>
          <div className="text-xs text-gray-500">Master Control Center</div>
        </div>
        <nav className="flex-1 space-y-1 px-3 py-4">
          {visibleItems.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-2 rounded-md px-3 py-2 text-sm ${
                  active
                    ? "bg-gray-900 text-white"
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                <Icon size={16} />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="border-t border-gray-200 px-5 py-4">
          <div className="mb-2 text-xs text-gray-500">
            {username} · {role?.replace("_", " ")}
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900"
          >
            <LogOut size={14} /> Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-y-auto p-8">{children}</main>
    </div>
  );
}
