import { type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode } from "react";
import clsx from "clsx";

export function Card({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={clsx("rounded-xl border border-border bg-surface p-5", className)}>
      {children}
    </div>
  );
}

export function PageHeader({ title, subtitle, action }: { title: string; subtitle?: string; action?: ReactNode }) {
  return (
    <div className="flex items-start justify-between mb-6">
      <div>
        <h1 className="text-xl font-semibold text-white">{title}</h1>
        {subtitle && <p className="text-sm text-neutral-400 mt-1">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

export function Button({
  className,
  variant = "primary",
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "danger" | "ghost" }) {
  return (
    <button
      className={clsx(
        "inline-flex items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed",
        variant === "primary" && "bg-accent text-black hover:bg-accent-hover",
        variant === "secondary" && "bg-surface-2 text-white border border-border hover:bg-neutral-800",
        variant === "danger" && "bg-red-950 text-red-400 border border-red-900 hover:bg-red-900/50",
        variant === "ghost" && "text-neutral-300 hover:bg-surface-2",
        className,
      )}
      {...props}
    />
  );
}

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={clsx(
        "w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-white placeholder:text-neutral-500 outline-none focus:border-accent",
        props.className,
      )}
    />
  );
}

export function Badge({ children, tone = "neutral" }: { children: ReactNode; tone?: "neutral" | "success" | "warning" | "danger" | "info" }) {
  const tones: Record<string, string> = {
    neutral: "bg-neutral-800 text-neutral-300",
    success: "bg-green-950 text-green-400",
    warning: "bg-yellow-950 text-yellow-400",
    danger: "bg-red-950 text-red-400",
    info: "bg-blue-950 text-blue-400",
  };
  return (
    <span className={clsx("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize", tones[tone])}>
      {children}
    </span>
  );
}

export function EmptyState({ message }: { message: string }) {
  return <div className="py-12 text-center text-sm text-neutral-500">{message}</div>;
}

export function Spinner() {
  return (
    <div className="flex justify-center py-12">
      <div className="h-5 w-5 animate-spin rounded-full border-2 border-neutral-700 border-t-accent" />
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="py-12 text-center text-sm">
      <p className="text-red-400">{message}</p>
      {onRetry && (
        <Button variant="secondary" className="mx-auto mt-3" onClick={onRetry}>
          Retry
        </Button>
      )}
    </div>
  );
}

export function MockBanner({ note }: { note?: string }) {
  return (
    <div className="mb-5 rounded-lg border border-yellow-900/60 bg-yellow-950/40 px-4 py-2.5 text-xs text-yellow-400">
      <span className="font-semibold">Mock data.</span> No backend endpoint exists for this yet — changes here are local-only and reset on reload.
      {note && <span className="text-yellow-500/80"> {note}</span>}
    </div>
  );
}

export function Modal({ open, onClose, title, children }: { open: boolean; onClose: () => void; title: string; children: ReactNode }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={onClose}>
      <div
        className="w-full max-w-lg rounded-xl border border-border bg-surface p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="mb-4 text-base font-semibold text-white">{title}</h2>
        {children}
      </div>
    </div>
  );
}

export function Table({ children }: { children: ReactNode }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-border">
      <table className="w-full text-left text-sm">{children}</table>
    </div>
  );
}

export function Th({ children }: { children: ReactNode }) {
  return <th className="border-b border-border bg-surface-2 px-4 py-2.5 font-medium text-neutral-400">{children}</th>;
}

export function Td({ children, className }: { children: ReactNode; className?: string }) {
  return <td className={clsx("border-b border-border px-4 py-3 text-neutral-200", className)}>{children}</td>;
}
