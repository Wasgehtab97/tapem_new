-- =============================================================================
-- Tap'em — Username Constraints (V1 spec alignment)
-- Enforces: lowercase + dot allowed, 3–20 chars, reserved words blocked,
--           rename cooldown tracking.
-- Existing users are grandfathered; new registrations and future changes
-- must satisfy the new rules.
-- =============================================================================

-- ─── Drop old constraint (if any) ─────────────────────────────────────────────

ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS username_format;

-- ─── New format constraint ────────────────────────────────────────────────────
-- Allowed: a-z  0-9  _  .    Length: 3–20
-- Note: the app already lowercases on write, so uppercase is impossible in
--       practice; the CHECK ensures DB-level enforcement.

ALTER TABLE public.user_profiles
  ADD CONSTRAINT username_format
    CHECK (username ~ '^[a-z0-9_.]{3,20}$');

-- ─── Reserved words ───────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_reserved_username(p_username TEXT)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT LOWER(p_username) = ANY(ARRAY[
    'admin', 'administrator', 'support', 'help',
    'tapem', 'tapemapp', 'system', 'root',
    'api', 'null', 'undefined', 'anonymous',
    'guest', 'moderator', 'mod', 'owner',
    'staff', 'official', 'team', 'service'
  ]);
$$;

COMMENT ON FUNCTION public.is_reserved_username IS
  'Returns true if the username matches a platform-reserved term. '
  'Extend the ARRAY to add future reserved words.';

ALTER TABLE public.user_profiles
  ADD CONSTRAINT username_not_reserved
    CHECK (NOT public.is_reserved_username(username));

-- ─── Rename cooldown ──────────────────────────────────────────────────────────
-- Track the last time a user changed their username (NULL = never changed).
-- The 30-day cooldown is enforced by a trigger below.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS username_changed_at TIMESTAMPTZ;

COMMENT ON COLUMN public.user_profiles.username_changed_at IS
  'Timestamp of the last username change. NULL on initial creation. '
  'Users may change their username at most once every 30 days.';

-- Trigger function: block username changes within 30-day cooldown window.
CREATE OR REPLACE FUNCTION public.enforce_username_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only applies when the username actually changes.
  IF NEW.username = OLD.username THEN
    RETURN NEW;
  END IF;

  -- Allow first-ever rename (username_changed_at IS NULL = initial setup).
  IF OLD.username_changed_at IS NOT NULL
     AND OLD.username_changed_at > NOW() - INTERVAL '30 days' THEN
    RAISE EXCEPTION 'username_cooldown'
      USING DETAIL = 'Username may only be changed once every 30 days.',
            HINT   = OLD.username_changed_at::TEXT;
  END IF;

  -- Record the time of this change.
  NEW.username_changed_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_username_cooldown ON public.user_profiles;

CREATE TRIGGER trg_username_cooldown
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_username_cooldown();
