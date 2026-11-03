"use client";

import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const signIn = async () => {
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "github",
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    });
  };

  return (
    <main className="flex min-h-screen items-center justify-center">
      <button
        onClick={signIn}
        className="rounded bg-black px-6 py-3 text-white dark:bg-white dark:text-black"
      >
        Sign in with GitHub
      </button>
    </main>
  );
}