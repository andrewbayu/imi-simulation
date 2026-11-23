-- ============================================================================
-- IMI Vessel Builder & Project Finance Simulator — Supabase Cloud Schema
-- Target Project: cjcjlkmsygjggiqcopbb (PT Inovasi Maritim Indonesia)
-- Jalankan script ini sekali di Supabase Dashboard -> SQL Editor -> New Query
-- ============================================================================

-- 1. Tabel Master Harga Material & Upah Galangan
CREATE TABLE IF NOT EXISTS public.sim_materials (
  id text PRIMARY KEY,
  cat text NOT NULL,
  name text NOT NULL,
  unit text NOT NULL,
  price numeric NOT NULL DEFAULT 0 CHECK (price >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2. Tabel Kartu Komponen Custom + Formula BoM
CREATE TABLE IF NOT EXISTS public.sim_custom_cards (
  id text PRIMARY KEY,
  category text NOT NULL,
  name text NOT NULL,
  card_data jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Tabel Konfigurasi / Preset Kapal & Simulasi Finansial Tersimpan
CREATE TABLE IF NOT EXISTS public.sim_saved_configs (
  id text PRIMARY KEY,
  name text NOT NULL,
  vessel_class text NOT NULL,
  config_data jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Trigger updated_at otomatis (terisolasi dengan prefix sim_)
CREATE OR REPLACE FUNCTION public.sim_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sim_materials_updated_at ON public.sim_materials;
CREATE TRIGGER trg_sim_materials_updated_at
  BEFORE UPDATE ON public.sim_materials
  FOR EACH ROW EXECUTE FUNCTION public.sim_set_updated_at();

DROP TRIGGER IF EXISTS trg_sim_custom_cards_updated_at ON public.sim_custom_cards;
CREATE TRIGGER trg_sim_custom_cards_updated_at
  BEFORE UPDATE ON public.sim_custom_cards
  FOR EACH ROW EXECUTE FUNCTION public.sim_set_updated_at();

DROP TRIGGER IF EXISTS trg_sim_saved_configs_updated_at ON public.sim_saved_configs;
CREATE TRIGGER trg_sim_saved_configs_updated_at
  BEFORE UPDATE ON public.sim_saved_configs
  FOR EACH ROW EXECUTE FUNCTION public.sim_set_updated_at();

-- 5. Row Level Security (akses tim internal simulator via anon & authenticated)
ALTER TABLE public.sim_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sim_custom_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sim_saved_configs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sim_materials_team_rw" ON public.sim_materials;
CREATE POLICY "sim_materials_team_rw"
  ON public.sim_materials
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "sim_custom_cards_team_rw" ON public.sim_custom_cards;
CREATE POLICY "sim_custom_cards_team_rw"
  ON public.sim_custom_cards
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "sim_saved_configs_team_rw" ON public.sim_saved_configs;
CREATE POLICY "sim_saved_configs_team_rw"
  ON public.sim_saved_configs
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.sim_materials TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sim_custom_cards TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.sim_saved_configs TO anon, authenticated;

-- 6. Seed Data Awal DB Material IMI (tidak menimpa harga yang sudah diupdate)
INSERT INTO public.sim_materials (id, cat, name, unit, price) VALUES
  ('res-ortho',    'Komposit FRP',     'Resin Orthophthalic Marine Grade',        'kg',    45000),
  ('mat-csm',      'Komposit FRP',     'Fiberglass CSM 450 & WR 600',             'kg',    38000),
  ('gelcoat',      'Komposit FRP',     'Gelcoat, Primer, Top Coat & Antifouling', 'kg',    68000),
  ('alu-5083',     'Logam & Insulasi', 'Pelat & Profil Marine Aluminium 5083',    'kg',    115000),
  ('timber-kayu',  'Logam & Insulasi', 'Kayu Gading 6×8 & Triplek Marine',        'm³',    9500000),
  ('pu-foam',      'Logam & Insulasi', 'Polyurethane Foam 2-Komponen (Coolbox)',  'kg',    85000),
  ('hardware-ss',  'Tambat & Deck',    'Hardware SS316, Cleat, Bollard & Valve',  'set',   550000),
  ('tali-nylon',   'Tambat & Deck',    'Tali Jangkar & Tambat Nylon 14–20mm',     'meter', 14000),
  ('bilge-pump',   'Tambat & Deck',    'Pompa Bilga Otomatis DC 12V 1500 GPH',    'set',   1500000),
  ('seat-pax',     'Akomodasi',        'Kursi Penumpang FRP High Density Foam',   'set',   2000000),
  ('obm-pk',       'Permesinan',       'Estimasi Mesin Tempel OBM (per PK)',      'PK',    1400000),
  ('rigging-har',  'Permesinan',       'Wire Harness, Controls & Racor Filter',   'set',   5000000),
  ('aki-marine',   'Permesinan',       'Aki Marine Heavy Duty 100–120 Ah',        'unit',  2500000),
  ('steering-hyd', 'Permesinan',       'Hydraulic Steering Dual Cylinder',        'set',   25000000),
  ('nav-garmin',   'Navigasi & El.',   'GPS Chartplotter & Sounder Garmin 585+',  'unit',  15500000),
  ('vhf-marine',   'Navigasi & El.',   'Radio Komunikasi VHF Marine + Antena',    'unit',  6500000),
  ('nav-lights',   'Navigasi & El.',   'Lampu Navigasi LED / Ceiling / Switch',   'set',   500000),
  ('genset-3kva',  'Navigasi & El.',   'Generator Industrial 3.0 kVA + Bracket',  'unit',  15000000),
  ('ac-split',     'Navigasi & El.',   'AC Split Marine / Kabin + Bracket',       'unit',  6000000),
  ('solas-vest',   'Safety SOLAS',     'Life Jacket SOLAS Approved w/ Whistle',   'pcs',   150000),
  ('solas-buoy',   'Safety SOLAS',     'Life Buoy + Tali 30m / APAR 3kg',         'pcs',   500000),
  ('labor-yard',   'Tenaga Kerja',     'Tenaga Kerja Galangan & Teknisi',         'HOK',   220000),
  ('doc-survey',   'Izin & Kirim',     'Jasa Dokumen Hubla / BKI / Launching',    'paket', 1000000),
  ('vendor-unit',  'Vendor / Subkon',  'Item / Subkontrak Eksternal Vendor',      'unit',  1000000)
ON CONFLICT (id) DO NOTHING;
