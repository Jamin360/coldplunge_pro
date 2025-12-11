-- Migration: Remove rating column from plunge_sessions table
-- Created: 2025-12-10 23:16:13
-- Description: Removes the rating field from cold plunge sessions as it is no longer needed

-- Drop the rating column from plunge_sessions table
ALTER TABLE plunge_sessions 
DROP COLUMN IF EXISTS rating;

-- No indexes or constraints to update since rating was a simple nullable integer column