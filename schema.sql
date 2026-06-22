-- Supabase Database Schema for Client Management and GST Compliance Portal

-- Create Clients Table
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_no INT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    gst_number TEXT,
    gst_id TEXT,
    gst_password TEXT, -- In production, ensure this is handled/encrypted as needed
    pan TEXT,
    status TEXT DEFAULT 'Active',
    fy TEXT DEFAULT '2025-2026',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security on Clients
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read/write clients (for portal administration)
CREATE POLICY "Allow public read access for clients" ON public.clients
    FOR SELECT TO public USING (true);

CREATE POLICY "Allow public insert/update/delete for clients" ON public.clients
    FOR ALL TO public USING (true) WITH CHECK (true);

-- Create GST Returns Table
CREATE TABLE IF NOT EXISTS public.gst_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_serial INT REFERENCES public.clients(serial_no) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'GSTR-1', 'GSTR-3B', 'ITR'
    month TEXT, -- 'April', 'May', etc. (or NULL for ITR)
    fy TEXT NOT NULL,
    status TEXT DEFAULT 'Pending' NOT NULL, -- 'Filed', 'Pending', 'Due Soon'
    filed_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on GST Returns
ALTER TABLE public.gst_returns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public access for gst_returns" ON public.gst_returns
    FOR ALL TO public USING (true) WITH CHECK (true);

-- Create TDS Summaries Table (Unified consolidated schema)
CREATE TABLE IF NOT EXISTS public.tds_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    s_no TEXT UNIQUE NOT NULL, -- S.No / Ref No
    customer_name TEXT NOT NULL,
    department_name TEXT,
    financial_year TEXT,
    prepared_by TEXT,
    monthly_data JSONB DEFAULT '[]'::jsonb,
    grand_total NUMERIC DEFAULT 0,
    admin_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on TDS Summaries
ALTER TABLE public.tds_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public access for public.tds_summaries" ON public.tds_summaries
    FOR ALL TO public USING (true) WITH CHECK (true);

-- Create Indexes for performance optimization on 700+ rows
CREATE INDEX IF NOT EXISTS idx_clients_serial ON public.clients(serial_no);
CREATE INDEX IF NOT EXISTS idx_gst_returns_client_serial ON public.gst_returns(client_serial);
CREATE INDEX IF NOT EXISTS idx_tds_summaries_s_no ON public.tds_summaries(s_no);

-- Function and trigger to update clients.updated_at automatically
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
    EXECUTE FUNCTION public.update_updated_at_column();
