# Kontrak Integrasi Audit Trail

## Status dan tujuan

Dokumen ini adalah kontrak konseptual untuk Mahasiswa Backend. Belum ada backend,
framework, model autentikasi, atau modul prestasi di repository. Modul audit
bukan aplikasi terpisah; implementasinya nanti berada dalam backend dan koneksi
database yang sama dengan modul prestasi.

## Kontrak fungsi generik

```text
recordAuditLog({
  actorId,
  action,
  entityType,
  entityId,
  oldValues,
  newValues,
  changedFields,
  ipAddress,
  userAgent,
  requestId
}) -> auditLogId
```

| Parameter | Tipe konseptual | Wajib | Fungsi |
|---|---|---:|---|
| `actorId` | integer atau null | Tidak | ID pengguna terautentikasi. Null hanya untuk proses sistem/keadaan yang dapat dijelaskan. |
| `action` | `CREATE`, `UPDATE`, `DELETE`, `ARCHIVE` | Ya | Jenis mutasi data. |
| `entityType` | string non-kosong | Ya | Nama domain stabil, misalnya `prestasi`. |
| `entityId` | integer | Ya | ID entitas yang dimutasi. |
| `oldValues` | object JSON atau null | Kondisional | Snapshot sebelum mutasi; null untuk CREATE. |
| `newValues` | object JSON atau null | Kondisional | Snapshot sesudah mutasi; null untuk DELETE. |
| `changedFields` | array string atau null | Tidak | Nama field tingkat atas yang berubah. |
| `ipAddress` | alamat IP atau null | Tidak | IP client dari konfigurasi trusted proxy. |
| `userAgent` | string atau null | Tidak | User-Agent yang telah dibatasi panjangnya. |
| `requestId` | UUID atau null | Tidak | ID korelasi yang konsisten selama satu request. |

Fungsi harus memakai transaction/connection yang diberikan caller, menjalankan
redaction rekursif sebelum insert, dan melempar error bila audit gagal. Fungsi
tidak boleh membuka atau melakukan commit transaksi sendiri serta tidak boleh
menyediakan update/delete audit log.

## Aturan snapshot dan field berubah

- Snapshot dibentuk dari row database, bukan request mentah, sehingga default,
  normalisasi, dan perubahan yang dilakukan database ikut tercatat.
- `changedFields` memuat nama field tingkat atas. Perubahan isi
  `metadata_dinamis` dicatat sebagai `metadata_dinamis`; detail sebelum/sesudah
  tetap terlihat di snapshot.
- Urutan key object JSON tidak dianggap perubahan. Arti urutan array mengikuti
  aturan domain.
- Semua snapshot harus melalui `sanitizeAuditPayload`.

## Alur transaksi UPDATE

1. Mulai transaksi dan ambil data sebelum perubahan, idealnya dengan row lock.
2. Validasi input.
3. Jalankan perubahan prestasi.
4. Ambil atau bentuk snapshot sesudah perubahan dari hasil database.
5. Simpan audit log dalam transaksi/koneksi yang sama.
6. Commit transaksi bila mutasi dan audit berhasil.
7. Jika audit gagal, rollback perubahan prestasi.

```text
transaction(tx):
  before = prestasi.findByIdForUpdate(tx, entityId)
  input = validate(request)
  after = prestasi.updateAndReturn(tx, entityId, input)
  fields = changedTopLevelKeys(before, after)

  recordAuditLog(tx, {
    actorId: currentUser?.id,
    action: "UPDATE",
    entityType: "prestasi",
    entityId: entityId,
    oldValues: before,
    newValues: after,
    changedFields: fields,
    ipAddress: requestContext.ipAddress,
    userAgent: requestContext.userAgent,
    requestId: requestContext.requestId
  })
```

## Contoh pemanggilan

### CREATE prestasi

```text
recordAuditLog({
  actorId: 7,
  action: "CREATE",
  entityType: "prestasi",
  entityId: 15,
  oldValues: null,
  newValues: { id: 15, atlet_id: 42, medali: "Perak" },
  changedFields: ["id", "atlet_id", "medali"],
  ipAddress: "192.0.2.10",
  userAgent: "Mozilla/5.0",
  requestId: "7ef52038-f23e-4b7f-b51d-cd53c8987e2a"
})
```

### UPDATE medali Perak menjadi Emas

```text
recordAuditLog({
  actorId: 7,
  action: "UPDATE",
  entityType: "prestasi",
  entityId: 15,
  oldValues: { id: 15, medali: "Perak" },
  newValues: { id: 15, medali: "Emas" },
  changedFields: ["medali"],
  ipAddress: "192.0.2.10",
  userAgent: "Mozilla/5.0",
  requestId: "85e509ab-564b-4518-9028-0f79450e465c"
})
```

### UPDATE `metadata_dinamis` JSONB

```text
recordAuditLog({
  actorId: 7,
  action: "UPDATE",
  entityType: "prestasi",
  entityId: 15,
  oldValues: { metadata_dinamis: { jumlah_ronde_menang: 2 } },
  newValues: { metadata_dinamis: { jumlah_ronde_menang: 3 } },
  changedFields: ["metadata_dinamis"],
  requestId: "aa3a4e2c-c916-4d54-ab85-51f37eef64e4"
})
```

### DELETE atau ARCHIVE prestasi

```text
recordAuditLog({
  actorId: 7,
  action: "DELETE",
  entityType: "prestasi",
  entityId: 15,
  oldValues: rowBeforeDelete,
  newValues: null,
  changedFields: keys(rowBeforeDelete),
  requestId: requestId
})

recordAuditLog({
  actorId: 7,
  action: "ARCHIVE",
  entityType: "prestasi",
  entityId: 15,
  oldValues: { status: "AKTIF", archived_at: null },
  newValues: { status: "DIARSIPKAN", archived_at: archivedAt },
  changedFields: ["status", "archived_at"],
  requestId: requestId
})
```

## Titik integrasi backend

| Operasi | Titik panggil audit | Snapshot |
|---|---|---|
| CREATE | Setelah insert mengembalikan row, sebelum commit | `old=null`, `new=row hasil insert` |
| UPDATE | Setelah update mengembalikan row, sebelum commit | `old=row terkunci`, `new=row hasil update` |
| DELETE | Setelah row lama dikunci, sebelum commit penghapusan | `old=row lama`, `new=null` |
| ARCHIVE | Setelah status/waktu arsip diperbarui, sebelum commit | `old=row lama`, `new=row hasil archive` |

Backend juga perlu menyediakan middleware/context untuk actor, request UUID, IP,
dan User-Agent; policy otorisasi pembaca audit; sanitizer; serta test transaksi
PostgreSQL nyata.
