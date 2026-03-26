-- 00042_avatars.sql
-- Avatar support: Storage bucket, RLS policies, avatar_url column on user_profiles.

-- ── 1. Storage bucket ─────────────────────────────────────────────────────────
-- Public bucket: CDN-served reads, no auth required for GET.
-- Writes are controlled by the RLS policies below.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  524288,  -- 512 KB hard limit per file (enforced at storage layer)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ── 2. Storage RLS policies ───────────────────────────────────────────────────
-- Path convention: avatars/{userId}/avatar.jpg
-- (storage.foldername(name))[1] returns the first path segment = userId

-- Anyone authenticated may read any avatar (shown in friend lists, leaderboards).
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'avatars_public_read'
  ) THEN
    CREATE POLICY "avatars_public_read"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'avatars');
  END IF;
END $$;

-- Each user may only upload into their own folder.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'avatars_owner_insert'
  ) THEN
    CREATE POLICY "avatars_owner_insert"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'avatars_owner_update'
  ) THEN
    CREATE POLICY "avatars_owner_update"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'avatars_owner_delete'
  ) THEN
    CREATE POLICY "avatars_owner_delete"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

-- ── 3. user_profiles: avatar_url column ──────────────────────────────────────
-- Safe with IF NOT EXISTS — idempotent if column was added manually.
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;
