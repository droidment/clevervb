-- Create storage buckets for user assets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('user-assets', 'user-assets', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

-- Create RLS policies for user-assets bucket
CREATE POLICY "Users can upload their own avatars" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'user-assets' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view all user avatars" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'user-assets');

CREATE POLICY "Users can update their own avatars" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'user-assets' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatars" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'user-assets' AND auth.uid()::text = (storage.foldername(name))[1]);
