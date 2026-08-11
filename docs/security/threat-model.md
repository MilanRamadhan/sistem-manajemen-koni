# Threat Model Audit Trail Data Prestasi KONI Aceh

## Batas sistem

Model ini mencakup mutasi data prestasi, pencatatan audit PostgreSQL, konteks
request, dan API pembacaan audit. Backend, autentikasi, otorisasi, deployment,
backup, dan monitoring belum tersedia sehingga sejumlah kontrol masih menjadi
ketergantungan.

Skala risiko: **tinggi** bila dapat merusak integritas/akuntabilitas secara
langsung atau membocorkan credential; **sedang** bila dampaknya berarti tetapi
membutuhkan kondisi tambahan; **rendah** bila dampaknya terbatas.

| # | Ancaman dan deskripsi | Dampak | Risiko | Kontrol pencegahan | Kontrol deteksi | Ketergantungan |
|---:|---|---|---|---|---|---|
| 1 | Admin mengubah medali Perak menjadi Emas tanpa dasar yang benar. | Integritas hasil lomba rusak; laporan dan keputusan organisasi salah. | Tinggi | Otorisasi berbasis role, validasi domain, transaksi mutasi+audit, snapshot sebelum/sesudah. | Review log UPDATE, alert perubahan medali berisiko, rekonsiliasi dengan dokumen sumber. | Backend, autentikasi, role, monitoring. |
| 2 | Admin menghapus data prestasi. | Riwayat prestasi hilang atau tidak lengkap. | Tinggi | Prioritaskan ARCHIVE, izin DELETE khusus, audit dalam transaksi yang sama. | Laporan aksi DELETE/ARCHIVE dan pemeriksaan berkala. | Kebijakan retensi, backend, otorisasi. |
| 3 | Pelaku mencoba menghapus audit log. | Keterlacakan dan bukti aktivitas sistem hilang. | Tinggi | Trigger menolak DELETE/TRUNCATE; runtime role tanpa izin tersebut; pisahkan owner dan runtime. | Pantau error SQLSTATE 42501 dan aktivitas administratif database. | Role database, logging/monitoring infrastruktur. |
| 4 | Pelaku mencoba mengubah audit log. | Riwayat dapat dipalsukan dan akuntabilitas menurun. | Tinggi | Trigger menolak UPDATE; runtime role tanpa UPDATE; backup/WORM bila dibutuhkan. | Pantau error trigger, bandingkan backup atau checksum eksternal. | Role database, backup, monitoring. |
| 5 | Perubahan terjadi tanpa identitas actor. | Sulit menentukan penanggung jawab; non-repudiation terbatas. | Tinggi | Mutasi manusia wajib terautentikasi; `actor_id=null` hanya untuk proses sistem yang dikenal. | Alert audit mutasi dengan actor null dan review request_id. | Autentikasi, service account policy. |
| 6 | Audit gagal disimpan tetapi data utama tetap berubah. | Perubahan tidak terlacak walau data bisnis berubah. | Tinggi | Audit dan mutasi wajib satu transaksi; kegagalan audit harus dilempar dan rollback. | Test rollback, metric kegagalan transaksi/audit. | Implementasi transaksi backend dan integration test. |
| 7 | Password atau token bocor melalui audit log. | Pengambilalihan akun/sistem dan kebocoran data. | Tinggi | Redaction rekursif, snapshot dari row terpilih, larangan request/header mentah dan file bytes. | Test sanitizer, scan sampel log untuk key sensitif tanpa menampilkan nilainya. | Sanitizer backend, review schema/payload. |
| 8 | Banyak request menghasilkan spam audit log. | Storage penuh, query lambat, sinyal penting tertutup. | Sedang | Rate limit, idempotency, validasi, batas panjang payload/User-Agent, hanya audit mutasi berhasil. | Monitor laju insert, ukuran tabel, pola actor/IP/request_id. | Gateway/backend, observability, capacity plan. |
| 9 | Timestamp atau informasi request tidak konsisten. | Korelasi kejadian dan urutan insiden menjadi salah. | Sedang | Gunakan `NOW()` dari database, UUID request dari middleware, trusted proxy untuk IP, sinkronisasi waktu host. | Deteksi request_id hilang/duplikat dan perbedaan waktu abnormal. | Middleware, proxy config, infrastruktur waktu. |
| 10 | Pengguna tidak berwenang membaca audit log. | Informasi sensitif operasional, IP, dan pola aktivitas bocor. | Tinggi | Endpoint GET wajib policy khusus; principle of least privilege pada DB; response tidak memuat secret. | Audit akses baca di gateway/backend dan alert akses ditolak berulang. | Autentikasi, otorisasi, access logging. |

## Asumsi dan batasan

Append-only pada trigger meningkatkan integritas data, akuntabilitas, dan
keterlacakan terhadap akun aplikasi biasa. Kontrol ini tidak melindungi dari
superuser/pemilik schema yang dapat menonaktifkan trigger atau mengubah database.
Untuk kebutuhan lebih tinggi, organisasi dapat menambahkan pemisahan tugas,
backup immutable, ekspor ke sistem log terpisah, hash chaining, dan prosedur
review.

Audit trail menyediakan bukti aktivitas sistem dan mendukung non-repudiation
secara terbatas. Ia tidak otomatis menjadikan catatan sah secara hukum tanpa
kebijakan organisasi, kontrol identitas, tata kelola barang bukti, retensi, dan
mekanisme hukum tambahan.
