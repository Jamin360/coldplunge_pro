-- ==========================================
-- PHOTO STORAGE FOR POSTS AND SESSIONS
-- ==========================================
-- Created: 2025-12-17 01:54:02
-- Purpose: Add photo storage capabilities to community_posts and plunge_sessions
-- Dependencies: Extends existing community_posts and plunge_sessions tables
-- Integration: Adds photo_path columns and creates storage buckets with RLS policies

-- ==========================================
-- SECTION 1: TABLE MODIFICATIONS
-- ==========================================

-- Add photo path to community_posts table (image_url already exists)
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS photo_path TEXT;

-- Add photo columns to plunge_sessions table
ALTER TABLE plunge_sessions ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE plunge_sessions ADD COLUMN IF NOT EXISTS photo_path TEXT;

-- ==========================================
-- SECTION 2: INDEXES
-- ==========================================

-- Add indexes for performance on photo queries
CREATE INDEX IF NOT EXISTS idx_community_posts_photo_path ON community_posts(photo_path) WHERE photo_path IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_photo_path ON plunge_sessions(photo_path) WHERE photo_path IS NOT NULL;

-- ==========================================
-- SECTION 3: STORAGE BUCKETS
-- ==========================================

-- Create storage bucket for post photos (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-photos', 'post-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage bucket for session photos (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('session-photos', 'session-photos', true)
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- SECTION 4: STORAGE RLS POLICIES
-- ==========================================

-- Post Photos Policies
CREATE POLICY "Users can upload post photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Anyone can view post photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'post-photos');

CREATE POLICY "Users can delete own post photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'post-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Session Photos Policies
CREATE POLICY "Users can upload session photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'session-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Anyone can view session photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'session-photos');

CREATE POLICY "Users can delete own session photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'session-photos' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);