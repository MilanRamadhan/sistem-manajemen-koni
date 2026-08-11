# Test Plan Audit Trail

## Status

PostgreSQL dan backend/testing framework belum tersedia di repository.
Pengujian SQL manual telah disiapkan, tetapi belum dijalankan. Karena itu tidak
ada test case berstatus `PASSED`.

| Test ID | Skenario | Prasyarat | Langkah Pengujian | Expected Result | Status | Catatan |
|---|---|---|---|---|---|---|
| AT-01 | CREATE prestasi menghasilkan audit log. | Backend dan PostgreSQL terintegrasi. | Buat prestasi valid lalu cari audit berdasarkan request_id. | Tepat satu log `CREATE`, `old_values=null`, `new_values` berisi row. | NOT IMPLEMENTED | Menunggu backend. |
| AT-02 | UPDATE Perak menjadi Emas menghasilkan audit log. | Data medali Perak tersedia. | Update ke Emas dalam transaksi. | Tepat satu log `UPDATE`. | NOT IMPLEMENTED | Menunggu backend. |
| AT-03 | `old_values` berisi nilai sebelum perubahan. | AT-02 dapat dijalankan. | Baca log UPDATE. | `old_values.medali` adalah `Perak`. | NOT IMPLEMENTED | Menunggu integrasi CRUD. |
| AT-04 | `new_values` berisi nilai sesudah perubahan. | AT-02 dapat dijalankan. | Baca log UPDATE. | `new_values.medali` adalah `Emas`. | NOT IMPLEMENTED | Menunggu integrasi CRUD. |
| AT-05 | `changed_fields` hanya memuat field berubah. | AT-02 dapat dijalankan. | Ubah hanya medali lalu baca log. | Nilai tepat `["medali"]`. | NOT IMPLEMENTED | Bandingkan nilai ternormalisasi. |
| AT-06 | Perubahan `metadata_dinamis` JSONB tercatat. | Prestasi memiliki metadata ronde. | Ubah jumlah ronde 2 menjadi 3. | Snapshot memuat kedua nilai dan changed field `metadata_dinamis`. | NOT IMPLEMENTED | Menunggu backend. |
| AT-07 | `actor_id` tercatat. | Pengguna terautentikasi. | Mutasi data sebagai user ID 7. | Audit berisi `actor_id=7`. | NOT IMPLEMENTED | Menunggu autentikasi. |
| AT-08 | IP dan User-Agent tercatat jika tersedia. | Trusted proxy/context request tersedia. | Kirim mutasi dengan context request. | IP valid dan User-Agent yang dibatasi panjangnya tercatat. | NOT IMPLEMENTED | Menunggu middleware. |
| AT-09 | Audit log tidak dapat diubah. | Skema SQL diterapkan. | Jalankan langkah UPDATE pada `audit_logs_test.sql`. | Trigger menolak dengan SQLSTATE 42501. | READY FOR MANUAL TEST | Belum dijalankan pada PostgreSQL. |
| AT-10 | Audit log tidak dapat dihapus. | Skema SQL diterapkan. | Jalankan langkah DELETE pada `audit_logs_test.sql`. | Trigger menolak dengan SQLSTATE 42501. | READY FOR MANUAL TEST | Belum dijalankan pada PostgreSQL. |
| AT-11 | Password dan token ter-redact. | Sanitizer backend tersedia. | Audit payload dengan key sensitif bersarang. | Semua nilai sensitif menjadi `[REDACTED]`; nilai asli tidak tersimpan. | NOT IMPLEMENTED | Contoh JSON tersedia. |
| AT-12 | Kegagalan audit me-rollback transaksi utama. | Integrasi transaksi tersedia. | Paksa insert audit gagal dengan action invalid. | Mutasi prestasi dan audit tidak tersimpan. | NOT IMPLEMENTED | Wajib test PostgreSQL nyata. |
| AT-13 | Endpoint daftar memakai pagination. | API audit tersedia. | GET page 1, per_page 10 pada data >10. | Meta benar dan maksimal 10 item dikembalikan. | NOT IMPLEMENTED | Menunggu API. |
| AT-14 | Endpoint daftar mendukung filter. | API audit dan data variasi tersedia. | Uji setiap filter dan kombinasinya. | Hanya record yang cocok dikembalikan, urutan terbaru dahulu. | NOT IMPLEMENTED | Termasuk rentang tanggal. |
| AT-15 | Pengguna tanpa izin ditolak. | Autentikasi/otorisasi tersedia. | GET endpoint sebagai anonim dan role biasa. | Request ditolak sesuai standar error proyek tanpa kebocoran data. | NOT IMPLEMENTED | Menunggu auth/role. |
| AT-16 | `request_id` menelusuri satu request. | Middleware request UUID tersedia. | Mutasi lalu cari UUID yang sama. | Audit ditemukan melalui UUID dan dapat dikorelasikan dengan log request. | NOT IMPLEMENTED | Menunggu middleware. |

## Pengujian tambahan yang disarankan

- Action selain allow-list dan `changed_fields` bukan array ditolak constraint.
- CREATE dengan `entity_id` null ditolak.
- UPDATE/DELETE/TRUNCATE ditolak bagi runtime role.
- Dua update bersamaan menghasilkan urutan snapshot konsisten dengan row lock.
- Kombinasi filter API menggunakan query parameter terikat dan tidak rentan SQL
  injection.
- Pagination menggunakan `created_at DESC, id DESC`.
- Payload besar/User-Agent panjang dibatasi backend untuk mencegah log abuse.
