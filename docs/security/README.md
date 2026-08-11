# Dokumentasi Security

Folder ini memuat desain dan kontrak audit trail untuk perubahan data prestasi
KONI Aceh. Seluruh artefak bersifat bagian dari backend utama yang akan datang,
bukan aplikasi atau server terpisah.

## Indeks

- [`audit-trail.md`](audit-trail.md): gambaran utama, alur, skema, keamanan, dan
  batas implementasi.
- [`audit-integration-contract.md`](audit-integration-contract.md): kontrak
  `recordAuditLog` dan titik integrasi transaksi CRUD.
- [`audit-api-contract.md`](audit-api-contract.md): desain endpoint GET
  read-only, filter, pagination, dan response.
- [`audit-redaction-policy.md`](audit-redaction-policy.md): daftar data sensitif
  dan pseudocode sanitizer rekursif.
- [`threat-model.md`](threat-model.md): ancaman spesifik data prestasi, risiko,
  kontrol, dan ketergantungan.
- [`audit-test-plan.md`](audit-test-plan.md): acceptance test AT-01 sampai AT-16
  beserta status nyata.
- [`sql/audit_logs.sql`](sql/audit_logs.sql): skema PostgreSQL, constraint,
  index, komentar, dan trigger append-only.
- [`sql/audit_logs_test.sql`](sql/audit_logs_test.sql): skrip pengujian manual
  transaksional untuk insert, baca, penolakan UPDATE/DELETE, dan rollback.
- [`examples/prestasi-create-audit.json`](examples/prestasi-create-audit.json):
  contoh audit CREATE.
- [`examples/prestasi-update-audit.json`](examples/prestasi-update-audit.json):
  contoh UPDATE medali Perak menjadi Emas.
- [`examples/prestasi-delete-audit.json`](examples/prestasi-delete-audit.json):
  contoh audit DELETE.
- [`examples/prestasi-archive-audit.json`](examples/prestasi-archive-audit.json):
  contoh audit ARCHIVE.
- [`examples/metadata-jsonb-update-audit.json`](examples/metadata-jsonb-update-audit.json):
  contoh perubahan JSONB bertingkat.
- [`examples/sensitive-data-redaction-audit.json`](examples/sensitive-data-redaction-audit.json):
  contoh nilai password/token yang sudah di-redact.

## Current Status

| Area | Status |
|---|---|
| Database design | ready |
| Backend implementation | waiting for backend stack |
| Authentication integration | waiting |
| CRUD integration | waiting |
| Automated test | waiting for backend/testing framework |
| Manual PostgreSQL test | prepared |
