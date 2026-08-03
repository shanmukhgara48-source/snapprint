import { lazy, Suspense, useEffect } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "./lib/auth";
import { navigate, routeId, usePathname } from "./lib/router";
import Layout from "./components/Layout";
import Login from "./pages/Login";

const Dashboard = lazy(() => import("./pages/Dashboard"));
const Analytics = lazy(() => import("./pages/Analytics"));
const Categories = lazy(() => import("./pages/Categories"));
const ProductsList = lazy(() => import("./pages/products/ProductsList"));
const OrdersList = lazy(() => import("./pages/orders/OrdersList"));
const OrderDetail = lazy(() => import("./pages/orders/OrderDetail"));
const CustomersList = lazy(() => import("./pages/customers/CustomersList"));
const CustomerDetail = lazy(() => import("./pages/customers/CustomerDetail"));
const Coupons = lazy(() => import("./pages/coupons/Coupons"));
const Banners = lazy(() => import("./pages/banners/Banners"));
const DeliverySettings = lazy(() => import("./pages/delivery-settings/DeliverySettings"));
const Payments = lazy(() => import("./pages/payments/Payments"));
const Admins = lazy(() => import("./pages/admins/Admins"));
const Settings = lazy(() => import("./pages/settings/Settings"));
const Notifications = lazy(() => import("./pages/notifications/Notifications"));

const queryClient = new QueryClient();
function AppRoutes() {
  const { isAuthenticated } = useAuth();
  const pathname = usePathname();
  useEffect(() => {
    if (!isAuthenticated && pathname !== "/login") navigate("/login", true);
    if (isAuthenticated && pathname === "/login") navigate("/", true);
  }, [isAuthenticated, pathname]);

  if (!isAuthenticated) return <Login />;
  if (pathname === "/login") return null;

  const orderId = routeId(pathname, "orders");
  const customerId = routeId(pathname, "customers");
  const page = orderId ? (
    <OrderDetail id={orderId} />
  ) : customerId ? (
    <CustomerDetail id={customerId} />
  ) : (
    {
      "/": <Dashboard />,
      "/analytics": <Analytics />,
      "/products": <ProductsList />,
      "/categories": <Categories />,
      "/orders": <OrdersList />,
      "/coupons": <Coupons />,
      "/banners": <Banners />,
      "/delivery-settings": <DeliverySettings />,
      "/payments": <Payments />,
      "/customers": <CustomersList />,
      "/admins": <Admins />,
      "/notifications": <Notifications />,
      "/settings": <Settings />,
    }[pathname] ?? <Dashboard />
  );

  return (
    <Layout>
      <Suspense fallback={<div className="text-sm text-neutral-500">Loading...</div>}>
        {page}
      </Suspense>
    </Layout>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </QueryClientProvider>
  );
}
