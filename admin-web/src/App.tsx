import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider, useAuth } from "./lib/auth";
import Layout from "./components/Layout";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Analytics from "./pages/Analytics";
import Categories from "./pages/Categories";
import ProductsList from "./pages/products/ProductsList";
import OrdersList from "./pages/orders/OrdersList";
import OrderDetail from "./pages/orders/OrderDetail";
import CustomersList from "./pages/customers/CustomersList";
import CustomerDetail from "./pages/customers/CustomerDetail";
import Coupons from "./pages/coupons/Coupons";
import DeliverySettings from "./pages/delivery-settings/DeliverySettings";
import Payments from "./pages/payments/Payments";
import Admins from "./pages/admins/Admins";
import Settings from "./pages/settings/Settings";
import Reports from "./pages/mock/Reports";
import PhotoUploads from "./pages/mock/PhotoUploads";
import PrintQueue from "./pages/mock/PrintQueue";
import Offers from "./pages/mock/Offers";
import Support from "./pages/mock/Support";
import Reviews from "./pages/mock/Reviews";
import Notifications from "./pages/mock/Notifications";
import Security from "./pages/mock/Security";
import SystemLogs from "./pages/mock/SystemLogs";
import Backup from "./pages/mock/Backup";

const queryClient = new QueryClient();

function RequireAuth({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route
              element={
                <RequireAuth>
                  <Layout />
                </RequireAuth>
              }
            >
              <Route path="/" element={<Dashboard />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/reports" element={<Reports />} />
              <Route path="/products" element={<ProductsList />} />
              <Route path="/categories" element={<Categories />} />
              <Route path="/photo-uploads" element={<PhotoUploads />} />
              <Route path="/print-queue" element={<PrintQueue />} />
              <Route path="/orders" element={<OrdersList />} />
              <Route path="/orders/:id" element={<OrderDetail />} />
              <Route path="/coupons" element={<Coupons />} />
              <Route path="/offers" element={<Offers />} />
              <Route path="/delivery-settings" element={<DeliverySettings />} />
              <Route path="/payments" element={<Payments />} />
              <Route path="/customers" element={<CustomersList />} />
              <Route path="/customers/:id" element={<CustomerDetail />} />
              <Route path="/admins" element={<Admins />} />
              <Route path="/support" element={<Support />} />
              <Route path="/reviews" element={<Reviews />} />
              <Route path="/notifications" element={<Notifications />} />
              <Route path="/security" element={<Security />} />
              <Route path="/system-logs" element={<SystemLogs />} />
              <Route path="/backup" element={<Backup />} />
              <Route path="/settings" element={<Settings />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
