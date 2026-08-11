# Kontrak API Audit Log Read-only

## Status

Kontrak ini belum diimplementasikan. Endpoint baru dapat dibuat setelah router,
format error, autentikasi, dan otorisasi backend tersedia.

## Endpoint daftar

```http
GET /api/v1/audit-logs
```

Query parameter:

| Parameter | Tipe | Aturan |
|---|---|---|
| `page` | integer | Default 1, minimum 1. |
| `per_page` | integer | Default 10, minimum 1, maksimum 100. |
| `entity_type` | string | Filter persis, misalnya `prestasi`. |
| `entity_id` | integer | Filter ID entitas. |
| `actor_id` | integer | Filter ID pelaku. |
| `action` | enum | Salah satu `CREATE`, `UPDATE`, `DELETE`, `ARCHIVE`. |
| `date_from` | ISO 8601 | Batas awal `created_at`, inklusif. |
| `date_to` | ISO 8601 | Batas akhir `created_at`, inklusif. |

Hasil selalu diurutkan dengan `created_at DESC, id DESC` agar terbaru tampil
lebih dahulu dan urutan deterministik. Semua filter harus memakai parameter
query database terikat, bukan interpolasi string SQL.

```json
{
  "status": "success",
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total_records": 1
  },
  "data": [
    {
      "id": 1001,
      "actor_id": 7,
      "action": "UPDATE",
      "entity_type": "prestasi",
      "entity_id": 15,
      "old_values": {
        "id": 15,
        "medali": "Perak"
      },
      "new_values": {
        "id": 15,
        "medali": "Emas"
      },
      "changed_fields": [
        "medali"
      ],
      "ip_address": "192.0.2.10",
      "user_agent": "Mozilla/5.0",
      "request_id": "85e509ab-564b-4518-9028-0f79450e465c",
      "created_at": "2026-07-23T10:05:00+07:00"
    }
  ]
}
```

## Endpoint detail

```http
GET /api/v1/audit-logs/{id}
```

`id` harus berupa integer positif. Response sukses memakai envelope konsisten:

```json
{
  "status": "success",
  "data": {
    "id": 1001,
    "actor_id": 7,
    "action": "UPDATE",
    "entity_type": "prestasi",
    "entity_id": 15,
    "old_values": {
      "medali": "Perak"
    },
    "new_values": {
      "medali": "Emas"
    },
    "changed_fields": [
      "medali"
    ],
    "ip_address": "192.0.2.10",
    "user_agent": "Mozilla/5.0",
    "request_id": "85e509ab-564b-4518-9028-0f79450e465c",
    "created_at": "2026-07-23T10:05:00+07:00"
  }
}
```

Status HTTP dan bentuk error mengikuti standar backend proyek setelah tersedia.
Record yang tidak ditemukan tidak boleh mengungkap data lain.

## Pembatasan keamanan

Endpoint berikut tidak boleh tersedia:

```http
PUT /api/v1/audit-logs/{id}
PATCH /api/v1/audit-logs/{id}
DELETE /api/v1/audit-logs/{id}
```

Tidak ada endpoint write publik untuk audit log. Akses kedua endpoint GET wajib
dibatasi melalui autentikasi dan policy/role khusus pembaca audit setelah modul
user dan role tersedia. Log tidak boleh tampil kepada pengguna biasa hanya
karena pengguna tersebut dapat mengubah data prestasi.
