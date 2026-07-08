import { useState, type ChangeEvent } from "react";
import { isAxiosError } from "axios";
import { api } from "../lib/api";
import { Pencil, Plus, X } from "lucide-react";

export const ACCEPTED_IMAGE_TYPES = "image/jpeg,image/png,image/webp,image/gif";

function uploadErrorMessage(err: unknown): string {
  if (isAxiosError(err)) {
    return err.response?.data?.detail ?? "Upload failed";
  }
  return "Upload failed";
}

async function uploadImage(file: File, onProgress: (pct: number) => void): Promise<string> {
  const body = new FormData();
  body.append("file", file);
  const res = await api.post<{ url: string }>("/admin/upload", body, {
    onUploadProgress: (evt) => {
      if (evt.total) onProgress(Math.round((evt.loaded / evt.total) * 100));
    },
  });
  return res.data.url;
}

function UploadProgress({ progress, error }: { progress: number | null; error: string | null }) {
  return (
    <>
      {progress !== null && (
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-surface-2">
          <div className="h-full bg-accent transition-all" style={{ width: `${progress}%` }} />
        </div>
      )}
      {error && <p className="mt-1 text-xs text-red-400">{error}</p>}
    </>
  );
}

/** Single-image slot with upload/replace/remove — for banners, category art, etc. */
export function SingleImageUploader({ url, onChange }: { url: string; onChange: (next: string) => void }) {
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleFile(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setError(null);
    setProgress(0);
    try {
      onChange(await uploadImage(file, setProgress));
    } catch (err) {
      setError(uploadErrorMessage(err));
    } finally {
      setProgress(null);
    }
  }

  return (
    <div>
      <label className="mb-1 block text-xs text-neutral-400">Image</label>
      <div className="flex items-center gap-3">
        <div className="relative h-16 w-16 shrink-0 overflow-hidden rounded-lg border border-border bg-surface-2">
          {url && (
            <img
              src={url}
              alt=""
              className="h-full w-full object-cover"
              onError={(e) => {
                e.currentTarget.style.visibility = "hidden";
              }}
            />
          )}
          {url && (
            <button
              type="button"
              onClick={() => onChange("")}
              className="absolute -right-1.5 -top-1.5 rounded-full bg-red-600 p-0.5 text-white hover:bg-red-500"
            >
              <X size={10} />
            </button>
          )}
        </div>
        <label className="flex cursor-pointer items-center gap-2 rounded-lg border border-dashed border-border px-3 py-2 text-xs text-neutral-400 hover:border-accent hover:text-accent">
          <Pencil size={13} />
          {url ? "Replace" : "Upload image"}
          <input type="file" accept={ACCEPTED_IMAGE_TYPES} className="hidden" onChange={handleFile} />
        </label>
      </div>
      <UploadProgress progress={progress} error={error} />
    </div>
  );
}

function parseImages(raw: string): string[] {
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
}

/** Multi-image gallery with upload/replace/remove — for products. */
export function ImageGalleryUploader({ images, onChange }: { images: string; onChange: (next: string) => void }) {
  const urls = parseImages(images);
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function withUpload(file: File, apply: (url: string) => void) {
    setError(null);
    setProgress(0);
    try {
      apply(await uploadImage(file, setProgress));
    } catch (err) {
      setError(uploadErrorMessage(err));
    } finally {
      setProgress(null);
    }
  }

  function handleAdd(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    withUpload(file, (url) => onChange([...urls, url].join(", ")));
  }

  function handleReplace(index: number, e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    withUpload(file, (url) => {
      const next = [...urls];
      next[index] = url;
      onChange(next.join(", "));
    });
  }

  function handleRemove(index: number) {
    onChange(urls.filter((_, i) => i !== index).join(", "));
  }

  return (
    <div>
      <label className="mb-1 block text-xs text-neutral-400">Images</label>
      <div className="flex flex-wrap gap-2">
        {urls.map((url, i) => (
          <div key={`${url}-${i}`} className="group relative h-16 w-16 overflow-hidden rounded-lg border border-border bg-surface-2">
            <img
              src={url}
              alt=""
              className="h-full w-full object-cover"
              onError={(e) => {
                e.currentTarget.style.visibility = "hidden";
              }}
            />
            <label className="absolute inset-0 flex cursor-pointer items-center justify-center bg-black/0 opacity-0 transition-opacity group-hover:bg-black/50 group-hover:opacity-100">
              <Pencil size={14} className="text-white" />
              <input type="file" accept={ACCEPTED_IMAGE_TYPES} className="hidden" onChange={(e) => handleReplace(i, e)} />
            </label>
            <button
              type="button"
              onClick={() => handleRemove(i)}
              className="absolute -right-1.5 -top-1.5 rounded-full bg-red-600 p-0.5 text-white hover:bg-red-500"
            >
              <X size={10} />
            </button>
          </div>
        ))}
        <label className="flex h-16 w-16 cursor-pointer items-center justify-center rounded-lg border border-dashed border-border text-neutral-500 hover:border-accent hover:text-accent">
          <Plus size={18} />
          <input type="file" accept={ACCEPTED_IMAGE_TYPES} className="hidden" onChange={handleAdd} />
        </label>
      </div>
      <UploadProgress progress={progress} error={error} />
    </div>
  );
}
