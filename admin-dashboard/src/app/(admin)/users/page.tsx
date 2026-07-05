"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { api } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { UserListItem } from "@/lib/types";

const ROLES = ["customer", "delivery", "admin"];

export default function UsersPage() {
  const [role, setRole] = useState("");
  const [q, setQ] = useState("");

  const { data: users, isLoading } = useQuery({
    queryKey: ["admin", "users", role, q],
    queryFn: async () =>
      (await api.get<UserListItem[]>("/admin/users", { params: { role: role || undefined, q: q || undefined } })).data,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Users</h1>
          <p className="text-sm text-gray-500">Customers and delivery partners</p>
        </div>
        <button
          onClick={() => users && exportCsv("users.csv", users as unknown as Record<string, unknown>[])}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
        >
          Export CSV
        </button>
      </div>

      <div className="flex gap-3">
        <input
          placeholder="Search by phone..."
          value={q}
          onChange={(e) => setQ(e.target.value)}
          className="w-full max-w-sm rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
        />
        <select value={role} onChange={(e) => setRole(e.target.value)} className="rounded-md border border-gray-300 px-3 py-2 text-sm">
          <option value="">All roles</option>
          {ROLES.map((r) => (
            <option key={r} value={r}>{r}</option>
          ))}
        </select>
      </div>

      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left text-gray-500">
            <tr>
              <th className="px-4 py-2 font-medium">Phone</th>
              <th className="px-4 py-2 font-medium">Role</th>
              <th className="px-4 py-2 font-medium">Status</th>
              <th className="px-4 py-2 font-medium">Joined</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={4} className="px-4 py-6 text-center text-gray-400">Loading...</td>
              </tr>
            )}
            {users?.map((u) => (
              <tr key={u.id} className="border-t border-gray-100 hover:bg-gray-50">
                <td className="px-4 py-2">
                  <Link href={`/users/${u.id}`} className="text-blue-600 hover:underline">{u.phone}</Link>
                </td>
                <td className="px-4 py-2 capitalize">{u.role}</td>
                <td className="px-4 py-2">
                  <span className={`rounded-full px-2 py-0.5 text-xs ${u.is_active ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                    {u.is_active ? "Active" : "Suspended"}
                  </span>
                </td>
                <td className="px-4 py-2 text-gray-500">{new Date(u.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
            {!isLoading && users?.length === 0 && (
              <tr>
                <td colSpan={4} className="px-4 py-6 text-center text-gray-400">No users found</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
