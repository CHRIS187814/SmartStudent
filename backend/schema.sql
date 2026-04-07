-- ============================================================
-- Smart Student Task Prioritizer — Supabase SQL Setup
-- Paste this into Supabase → SQL Editor → Run
-- ============================================================

-- 1. TASKS TABLE
CREATE TABLE IF NOT EXISTS public.tasks (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name             TEXT        NOT NULL,
    deadline         TIMESTAMPTZ NOT NULL,
    task_weight      FLOAT       NOT NULL CHECK (task_weight BETWEEN 0.01 AND 1.0),
    effort_level     INT         NOT NULL CHECK (effort_level BETWEEN 1 AND 5),
    category         TEXT        NOT NULL CHECK (category IN ('Academic','Personal','Extracurricular')),
    description      TEXT,
    priority_score   FLOAT       DEFAULT 0.0,
    hours_remaining  FLOAT       DEFAULT 0.0,
    status           TEXT        DEFAULT 'Pending' CHECK (status IN ('Pending','In Progress','Completed')),
    nudge_message    TEXT,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ROW LEVEL SECURITY — users can only see their own tasks
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own tasks"
    ON public.tasks FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. INDEXES for fast queries
CREATE INDEX IF NOT EXISTS idx_tasks_user_id       ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_priority      ON public.tasks(priority_score DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline      ON public.tasks(deadline);

-- 4. USER PROFILES (optional — stores peak focus hours, FCM token)
CREATE TABLE IF NOT EXISTS public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       TEXT,
    peak_hour_start INT  DEFAULT 9,    -- 9 AM
    peak_hour_end   INT  DEFAULT 11,   -- 11 AM
    fcm_token       TEXT,              -- Firebase Cloud Messaging device token
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own profile"
    ON public.profiles FOR ALL
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 5. AUTO-CREATE PROFILE ON SIGNUP (trigger)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
