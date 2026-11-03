import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  let supabase = "skipped";
  if (url && key) {
    try {
      const res = await fetch(`${url}/auth/v1/health`, {
        headers: { apikey: key },
      });
      supabase = res.ok ? "reachable" : `error ${res.status}`;
    } catch {
      supabase = "unreachable";
    }
  }

  return NextResponse.json({
    hasUrl: Boolean(url),
    hasKey: Boolean(key),
    supabase,
  });
}