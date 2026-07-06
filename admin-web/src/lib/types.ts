export interface ProductSize {
  label: string;
  price: number;
}

export interface Product {
  id: string;
  name: string;
  category: string;
  category_id?: string | null;
  base_price: number;
  sizes: ProductSize[];
  description?: string | null;
  images: string[];
  sort_order: number;
  stock_quantity: number;
  is_featured: boolean;
  is_trending: boolean;
  is_active: boolean;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  image_url?: string | null;
  sort_order: number;
  is_active: boolean;
}

export interface Banner {
  id: string;
  title: string;
  image_url: string;
  link_action?: string | null;
  sort_order: number;
  is_active: boolean;
  starts_at?: string | null;
  ends_at?: string | null;
}

export interface OrderListItem {
  id: string;
  status: string;
  total_price: number;
  customer_phone: string | null;
  item_count: number;
  created_at: string;
  delivery_partner_id: string | null;
}

export interface OrderItemDetail {
  id: string;
  product_name: string | null;
  quantity: number;
  selected_size: string | null;
  unit_price: number;
  image_url: string | null;
}

export interface OrderTimelineEvent {
  status: string;
  timestamp: string;
  proof_url: string | null;
}

export interface OrderDetail {
  id: string;
  status: string;
  notes: string | null;
  total_price: number;
  delivery_type: string;
  delivery_charge: number;
  discount: number;
  coupon_code: string | null;
  customer_phone: string | null;
  delivery_partner_id: string | null;
  address: string | null;
  razorpay_order_id: string | null;
  razorpay_payment_id: string | null;
  created_at: string;
  estimated_delivery: string | null;
  items: OrderItemDetail[];
  timeline: OrderTimelineEvent[];
}

export interface UserListItem {
  id: string;
  phone: string;
  role: string;
  is_active: boolean;
  created_at: string;
}

export interface UserDetail extends UserListItem {
  referral_code: string;
  addresses: {
    id: string;
    full_address: string;
    city: string;
    pincode: string;
    is_default: boolean;
  }[];
  orders: { id: string; status: string; total_price: number; created_at: string }[];
}

export interface Coupon {
  id: string;
  code: string;
  discount_type: "percent" | "flat";
  value: number;
  min_order: number;
  max_uses: number | null;
  used_count: number;
  expires_at: string | null;
  is_active: boolean;
  created_at: string;
}

export interface DeliverySetting {
  type: string;
  label: string;
  price: number;
  days_label: string;
  is_active: boolean;
}

export interface PaymentAttempt {
  id: string;
  razorpay_order_id: string | null;
  razorpay_payment_id: string | null;
  status: string;
  reason: string | null;
  user_id: string | null;
  created_at: string;
}

export interface AppSetting {
  key: string;
  value: Record<string, unknown>;
  updated_at: string;
}

export interface AuditLog {
  id: string;
  admin_user_id: string;
  action: string;
  resource_type: string;
  resource_id: string;
  details: Record<string, unknown> | null;
  ip_address: string | null;
  created_at: string;
}

export interface LoginHistoryEntry {
  id: string;
  admin_user_id: string | null;
  username_attempted: string;
  ip_address: string | null;
  success: boolean;
  created_at: string;
}

export interface AdminUserRecord {
  id: string;
  username: string;
  role: string;
  is_active: boolean;
  last_login_at: string | null;
  created_at: string;
}

export interface DashboardAnalytics {
  revenue: { today: number; week: number; month: number; year: number };
  orders: { today: number; by_status: Record<string, number> };
  users: { total: number; new_this_month: number };
  payments: { failed: number };
  photos: { total_uploaded: number };
  top_products: { name: string; quantity: number }[];
}

export interface ChartsAnalytics {
  revenue: { date: string; revenue: number }[];
  orders: { date: string; orders: number }[];
  users: { date: string; new_users: number }[];
}
