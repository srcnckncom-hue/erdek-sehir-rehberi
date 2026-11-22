// Erdek Şehir Rehberi — panelden "Bildirim gönder" (Supabase Edge Function).
//
// Yalnızca public.admins tablosundaki kullanıcılar çağırabilir. Bildirim,
// uygulamada seçilen konuyu (Ayarlar › Bildirim konuları) açan herkese gider.
// Konu adları uygulamadaki PushTopic ve paneldeki pushTopics ile AYNI. Firebase servis hesabı anahtarı FIREBASE_SERVICE_ACCOUNT
// adlı Supabase secret'ında durur; koda ya da depoya ASLA yazılmaz.
//
// Kurulum: docs/BILDIRIM_GONDER.md

const TOPICS = ["duyurular", "kesintiler", "ulasim", "etkinlikler"];
const DAILY_LIMIT = 10;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json; charset=utf-8" },
  });
}

const env = (name: string): string => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} tanımlı değil`);
  return value;
};

// ─── Google OAuth (servis hesabı → erişim anahtarı) ─────────────────────────

function base64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(body);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out.buffer;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

async function googleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const assertion = `${header}.${claims}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(`Google erişim anahtarı alınamadı: ${data.error_description ?? data.error ?? res.status}`);
  }
  return data.access_token as string;
}

// ─── Supabase yardımcıları ───────────────────────────────────────────────

async function callerIsAdmin(authorization: string): Promise<boolean> {
  const res = await fetch(`${env("SUPABASE_URL")}/rest/v1/rpc/is_admin`, {
    method: "POST",
    headers: {
      apikey: env("SUPABASE_ANON_KEY"),
      Authorization: authorization,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (!res.ok) return false;
  return (await res.json()) === true;
}

async function callerEmail(authorization: string): Promise<{ id?: string; email?: string }> {
  const res = await fetch(`${env("SUPABASE_URL")}/auth/v1/user`, {
    headers: { apikey: env("SUPABASE_ANON_KEY"), Authorization: authorization },
  });
  if (!res.ok) return {};
  const user = await res.json();
  return { id: user.id, email: user.email };
}

const serviceHeaders = () => ({
  apikey: env("SUPABASE_SERVICE_ROLE_KEY"),
  Authorization: `Bearer ${env("SUPABASE_SERVICE_ROLE_KEY")}`,
  "Content-Type": "application/json",
});

async function sentToday(): Promise<number> {
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const res = await fetch(
    `${env("SUPABASE_URL")}/rest/v1/push_log?select=id&ok=eq.true&sent_at=gte.${encodeURIComponent(since)}`,
    { headers: { ...serviceHeaders(), Prefer: "count=exact", Range: "0-0" } },
  );
  const range = res.headers.get("content-range") ?? "*/0";
  return Number(range.split("/")[1] ?? 0) || 0;
}

async function log(row: Record<string, unknown>): Promise<void> {
  await fetch(`${env("SUPABASE_URL")}/rest/v1/push_log`, {
    method: "POST",
    headers: serviceHeaders(),
    body: JSON.stringify(row),
  });
}

// ─── İstek ───────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "Yalnızca POST" });

  try {
    const authorization = req.headers.get("Authorization") ?? "";
    if (!authorization.startsWith("Bearer ") || !(await callerIsAdmin(authorization))) {
      return json(403, { error: "Bu işlem için yönetici girişi gerekli." });
    }

    const input = await req.json().catch(() => ({}));
    const title = String(input.title ?? "").trim();
    const body = String(input.body ?? "").trim();
    if (title.length < 1 || title.length > 80) return json(400, { error: "Başlık 1–80 karakter olmalı." });
    if (body.length < 1 || body.length > 240) return json(400, { error: "Metin 1–240 karakter olmalı." });
    const topic = String(input.topic ?? "duyurular");
    if (!TOPICS.includes(topic)) return json(400, { error: `Bilinmeyen konu: ${topic}` });

    if ((await sentToday()) >= DAILY_LIMIT) {
      return json(429, { error: `Son 24 saatte en fazla ${DAILY_LIMIT} bildirim gönderilebilir.` });
    }

    const sa = JSON.parse(env("FIREBASE_SERVICE_ACCOUNT")) as ServiceAccount;
    const token = await googleAccessToken(sa);
    const fcm = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          topic,
          notification: { title, body },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    });
    const result = await fcm.json().catch(() => ({}));
    const who = await callerEmail(authorization);
    await log({
      title,
      body,
      topic,
      sent_by: who.id ?? null,
      sent_by_email: who.email ?? null,
      ok: fcm.ok,
      result: fcm.ok ? String(result.name ?? "") : JSON.stringify(result).slice(0, 500),
    });

    if (!fcm.ok) {
      return json(502, { error: `Firebase reddetti: ${result?.error?.message ?? fcm.status}` });
    }
    return json(200, { ok: true, id: result.name });
  } catch (e) {
    return json(500, { error: e instanceof Error ? e.message : String(e) });
  }
});
