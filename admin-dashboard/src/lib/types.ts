export interface ProductSize {
  label: string;
  price: number;
}

export interface Product {
  id: string;
  name: string;
  category: string;
  base_price: number;
  sizes: ProductSize[];
  image_url: string;
  description: string | null;
  is_active: boolean;
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
  items: {
    id: string;
    product_name: string | null;
    quantity: number;
    selected_size: string | null;
    unit_price: number;
    image_url: string | null;
  }[];
  timeline: { status: string; timestamp: string; proof_url: string | null }[];
}

export interface UserListItem {
  id: string;
  phone: string;
  role: string;
  is_active: boolean;
  created_at: string;
}

export interface UserDetail {
  id: string;
  phone: string;
  role: string;
  is_active: boolean;
  referral_code: string | null;
  created_at: string;
  addresses: { id: string; full_address: string; city: string; pincode: string; is_default: boolean }[];
  orders: { id: string; status: string; total_price: number; created_at: string }[];
}

export interface Coupon {
  id: string;
  code: string;
  discount_type: string;
  value: number;
  min_order: number;
  expires_at: string | null;
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
  razorpay_order_id: string;
  razorpay_payment_id: string | null;
  status: string;
  reason: string | null;
  user_id: string | null;
  created_at: string;
}

export interface AdminAccount {
  id: string;
  username: string;
  role: string;
  is_active: boolean;
  last_login_at: string | null;
  created_at: string;
}

export interface AuditLog {
  id: string;
  admin_user_id: string;
  action: string;
  resource_type: string;
  resource_id: string | null;
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

export interface AppSettingEntry {
  key: string;
  value: Record<string, unknown>;
  updated_at: string;
}
