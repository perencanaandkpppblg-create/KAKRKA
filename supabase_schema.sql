-- ============================================================
-- SKEMA DATABASE: Aplikasi KAK / RKA PPEPD
-- Jalankan seluruh isi file ini di Supabase Dashboard
-- -> SQL Editor -> New Query -> paste -> Run
-- ============================================================

-- Aktifkan ekstensi UUID (biasanya sudah aktif di Supabase)
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- Tabel: bidang (SKPD / Bidang pengampu sub kegiatan)
-- ------------------------------------------------------------
create table if not exists public.bidang (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Tabel: kak_documents (1 baris = 1 dokumen KAK per sub kegiatan)
-- ------------------------------------------------------------
create table if not exists public.kak_documents (
  id uuid primary key default gen_random_uuid(),
  bidang_id uuid references public.bidang(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,

  -- I. IDENTITAS KEGIATAN
  sub_kegiatan_nama text default '',
  tahun_anggaran text default '2027',
  bidang_urusan text default '',
  program_text text default '',
  program_indikator text default '',
  kegiatan_text text default '',
  kegiatan_indikator text default '',
  kegiatan_target text default '',
  sub_kegiatan_indikator text default '',
  sub_kegiatan_target text default '',
  sumber_dana text default '',
  alokasi_anggaran text default '',
  lokasi text default '',

  -- A - E narasi
  latar_belakang text default '',
  dasar_hukum jsonb default '[]'::jsonb,        -- array of string
  maksud text default '',
  tujuan jsonb default '[]'::jsonb,              -- array of string
  analisis_dampak text default '',
  keluaran text default '',

  -- F. CARA PELAKSANAAN
  metode_pelaksanaan jsonb default '[]'::jsonb,  -- array of string
  tahapan_kegiatan jsonb default '[]'::jsonb,    -- array of string
  tempat_pelaksanaan text default '',

  -- G. PELAKSANA & PENANGGUNG JAWAB
  pelaksana_kegiatan text default '',
  penanggung_jawab text default '',
  kelompok_sasaran text default '',
  pihak_terkait text default '',

  -- H. JADWAL
  waktu_pelaksanaan text default '',
  jadwal jsonb default '[]'::jsonb,
  -- format: [{ "tahapan": "Persiapan", "bulan": [true,false,...12x] }]
  rincian_belanja jsonb default '[]'::jsonb,
  -- format: [{ "uraian":"", "volume":"", "total":"", "sektor":"", "keterangan":"" }]

  -- I. MITIGASI RISIKO
  mitigasi_risiko jsonb default '[]'::jsonb,
  -- format: [{ "uraian":"", "tingkat":"", "dampak":"", "mitigasi":"" }]

  -- TANDA TANGAN (bisa diisi/diubah sendiri oleh pengguna)
  tempat_tanggal text default '',
  ttd_pa_jabatan text default 'Pengguna Anggaran (PA)',
  ttd_pa_nama text default '',
  ttd_pa_nip text default '',
  ttd_pptk_jabatan text default 'Penanggung Jawab / PPTK',
  ttd_pptk_nama text default '',
  ttd_pptk_nip text default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger untuk update updated_at otomatis
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_kak_documents_updated_at on public.kak_documents;
create trigger trg_kak_documents_updated_at
before update on public.kak_documents
for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Semua pengguna yang sudah login (authenticated) bisa melihat
-- dan mengelola seluruh data -- cocok untuk tim satu instansi
-- yang berkolaborasi lintas bidang/SKPD.
-- ------------------------------------------------------------
alter table public.bidang enable row level security;
alter table public.kak_documents enable row level security;

drop policy if exists "bidang_select_auth" on public.bidang;
create policy "bidang_select_auth" on public.bidang
  for select using (auth.role() = 'authenticated');

drop policy if exists "bidang_insert_auth" on public.bidang;
create policy "bidang_insert_auth" on public.bidang
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "bidang_update_auth" on public.bidang;
create policy "bidang_update_auth" on public.bidang
  for update using (auth.role() = 'authenticated');

drop policy if exists "bidang_delete_auth" on public.bidang;
create policy "bidang_delete_auth" on public.bidang
  for delete using (auth.role() = 'authenticated');

drop policy if exists "kak_select_auth" on public.kak_documents;
create policy "kak_select_auth" on public.kak_documents
  for select using (auth.role() = 'authenticated');

drop policy if exists "kak_insert_auth" on public.kak_documents;
create policy "kak_insert_auth" on public.kak_documents
  for insert with check (auth.role() = 'authenticated');

drop policy if exists "kak_update_auth" on public.kak_documents;
create policy "kak_update_auth" on public.kak_documents
  for update using (auth.role() = 'authenticated');

drop policy if exists "kak_delete_auth" on public.kak_documents;
create policy "kak_delete_auth" on public.kak_documents
  for delete using (auth.role() = 'authenticated');

-- ============================================================
-- CATATAN:
-- Kebijakan di atas mengizinkan SEMUA pengguna yang sudah login
-- untuk melihat & mengubah SEMUA dokumen (cocok untuk tim kecil
-- satu instansi, misalnya BAPPEDA, yang saling berbagi data lintas
-- bidang). Jika ingin membatasi agar user hanya bisa mengubah
-- dokumen miliknya sendiri, ganti kondisi "using"/"with check" pada
-- kebijakan update & delete kak_documents menjadi:
--   auth.uid() = user_id
-- ============================================================
