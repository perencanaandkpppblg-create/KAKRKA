# Aplikasi KAK / RKA PPEPD

Aplikasi web untuk menyusun **Kerangka Acuan Kerja (KAK)** per Sub Kegiatan, dikelompokkan per Bidang/SKPD, dengan data tersimpan di **Supabase** dan bisa di-**export ke Word (.docx) dan PDF**. Login menggunakan email/password (Supabase Auth). Tidak perlu proses build — cukup 3 file statis (`index.html`, `style.css`, `config.js`) yang langsung bisa dideploy ke **Netlify**.

Setiap **Sub Kegiatan = 1 dokumen KAK** (1 baris data di database), dan bagian tanda tangan (jabatan, nama, NIP) bisa diisi/diubah sendiri langsung dari form — tidak hardcode ke satu nama pejabat.

## 1. Setup Supabase (5-10 menit)

1. Buat akun/project baru di [supabase.com](https://supabase.com) (gratis).
2. Buka **SQL Editor** → **New query** → tempel seluruh isi file `supabase_schema.sql` → **Run**.
   Ini akan membuat tabel `bidang`, `kak_documents`, beserta aturan keamanan (Row Level Security) yang mengizinkan **semua pengguna yang sudah login** untuk melihat & mengelola data — cocok untuk tim satu instansi yang berbagi data lintas bidang.
3. Aktifkan login email/password: **Authentication → Providers → Email** (biasanya sudah aktif secara default).
   - Jika ingin pengguna langsung bisa login tanpa verifikasi email saat mendaftar sendiri, matikan "Confirm email" di **Authentication → Settings**.
   - Untuk lingkungan kantor, disarankan: nonaktifkan pendaftaran mandiri (sign-up) dan buat akun staf secara manual lewat **Authentication → Users → Add user**, supaya tidak sembarang orang bisa mendaftar sendiri lewat halaman publik.
4. Ambil kredensial API: **Project Settings → API**
   - `Project URL`
   - `anon public` key

## 2. Isi kredensial di `config.js`

Buka `config.js`, ganti dua baris berikut dengan nilai dari langkah di atas:

```js
window.SUPABASE_URL = "https://xxxxxxxx.supabase.co";
window.SUPABASE_ANON_KEY = "eyJhbGciOi....";
```

## 3. Deploy ke Netlify

**Cara termudah (drag & drop):**
1. Buka [app.netlify.com/drop](https://app.netlify.com/drop)
2. Seret folder ini (berisi `index.html`, `style.css`, `config.js`, `netlify.toml`) ke halaman tersebut.
3. Selesai — Netlify akan memberi Anda URL langsung.

**Cara lewat Git (opsional, untuk update berkelanjutan):**
1. Push folder ini ke repository GitHub.
2. Di Netlify: **Add new site → Import an existing project** → pilih repo tsb.
3. Build command: kosongkan. Publish directory: `.` (folder root).

## 4. Pemakaian aplikasi

1. Buka URL Netlify Anda → daftar/masuk (Supabase Auth).
2. Tambahkan **Bidang/SKPD** lewat tombol di sidebar kiri.
3. Klik **"+ Sub Kegiatan Baru"** di bawah nama bidang untuk membuat 1 dokumen KAK.
4. Isi seluruh bagian formulir (Identitas, A–I, hingga Tanda Tangan). Bagian tanda tangan (jabatan/nama/NIP) bebas diisi sesuai pejabat yang berlaku saat itu.
5. Klik **"Simpan & Pratinjau / Export"** untuk melihat hasil sesuai format dokumen resmi, lalu:
   - **Export PDF** — mengunduh dokumen sebagai PDF siap cetak.
   - **Export Word (.docx)** — mengunduh dokumen sebagai file Word yang bisa diedit lebih lanjut.

## Catatan teknis

- Struktur field KAK mengikuti dokumen contoh yang diberikan (Identitas Kegiatan, A. Latar Belakang s.d. I. Mitigasi Risiko, Jadwal & Rincian Belanja, Tanda Tangan).
- Data disimpan di tabel `kak_documents`; kolom `bidang_id` menghubungkan dokumen ke tabel `bidang` (SKPD).
- Export DOCX menggunakan library `html-docx-js` (konversi HTML → .docx sederhana, cukup baik untuk dokumen berbasis paragraf & tabel seperti KAK). Untuk kebutuhan format Word yang sangat presisi (font/margin identik 100% dengan template asli instansi), dokumen hasil export tetap bisa dirapikan kembali secara manual di Microsoft Word.
- Jika ingin membatasi supaya pengguna hanya bisa mengubah dokumen miliknya sendiri (bukan berbagi penuh antar staf), lihat catatan di bagian bawah `supabase_schema.sql`.
