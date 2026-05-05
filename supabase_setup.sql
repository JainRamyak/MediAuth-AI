-- ==========================================
-- 1. Create a public 'users' table
-- ==========================================
CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text,
  date_of_birth timestamp with time zone,
  insurer text,
  policy_number text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  
  PRIMARY KEY (id)
);

-- Secure it with RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON public.users FOR SELECT
  USING ( true );

CREATE POLICY "Users can insert their own profile."
  ON public.users FOR INSERT
  WITH CHECK ( auth.uid() = id );

CREATE POLICY "Users can update own profile."
  ON public.users FOR UPDATE
  USING ( auth.uid() = id );

-- ==========================================
-- 2. Trigger to sync 'auth.users' to 'public.users'
-- ==========================================
-- This function runs automatically whenever a user signs up OR updates their profile.
CREATE OR REPLACE FUNCTION public.handle_user_sync()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    id, email, full_name, date_of_birth, insurer, policy_number
  )
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name',
    (new.raw_user_meta_data->>'date_of_birth')::timestamp with time zone,
    new.raw_user_meta_data->>'insurer',
    new.raw_user_meta_data->>'policy_number'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    date_of_birth = EXCLUDED.date_of_birth,
    insurer = EXCLUDED.insurer,
    policy_number = EXCLUDED.policy_number;
  RETURN new;
END;
$$;

-- Attach the trigger to 'auth.users' for both insert and update
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_user_sync();

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_user_sync();

-- ==========================================
-- 3. RPC Function to check if an email exists
-- ==========================================
-- The Flutter app securely calls this to check if a user needs to sign up first.
CREATE OR REPLACE FUNCTION public.check_email_exists(lookup_email text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE email = lookup_email
  );
$$;
