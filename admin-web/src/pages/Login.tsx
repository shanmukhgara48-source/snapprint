import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../lib/auth";
import { Button, Input } from "../components/ui";

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(username, password);
      navigate("/");
    } catch {
      setError("Invalid username or password");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex h-full items-center justify-center bg-bg">
      <form onSubmit={handleSubmit} className="w-full max-w-sm rounded-xl border border-border bg-surface p-6">
        <div className="mb-6 flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-sm font-bold text-black">
            SP
          </div>
          <span className="text-lg font-semibold text-white">SnapPrint Admin</span>
        </div>
        <label className="mb-1 block text-xs font-medium text-neutral-400">Username</label>
        <Input value={username} onChange={(e) => setUsername(e.target.value)} className="mb-4" autoFocus />
        <label className="mb-1 block text-xs font-medium text-neutral-400">Password</label>
        <Input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mb-4"
        />
        {error && <p className="mb-3 text-sm text-red-400">{error}</p>}
        <Button type="submit" disabled={loading} className="w-full justify-center">
          {loading ? "Signing in…" : "Sign in"}
        </Button>
      </form>
    </div>
  );
}
