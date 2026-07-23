# Kebijakan Redaction Audit Log

## Tujuan

Audit log diperlukan untuk keterlacakan, bukan untuk menyimpan credential,
session, isi dokumen, atau body upload. Redaction dilakukan sebelum data masuk
database dan berlaku rekursif pada object maupun array JSON bertingkat.

## Field sensitif

Nilai field berikut tidak boleh disimpan dalam bentuk asli dan harus diganti
dengan string `"[REDACTED]"`:

- `password`
- `password_confirmation`
- `access_token`
- `refresh_token`
- `authorization`
- `cookie`
- `session`
- `api_key`
- `secret`
- `private_key`
- `token`
- isi file PDF atau file biner

Pencocokan key harus tidak peka huruf besar/kecil dan menormalisasi variasi
umum seperti snake_case, camelCase, tanda hubung, atau spasi. Daftar ini adalah
minimum dan harus diperluas saat model domain tersedia.

PDF/file biner tidak dimasukkan ke payload audit sama sekali. Jika aktivitas
file perlu diaudit, simpan hanya metadata aman seperti ID dokumen, nama logis,
ukuran, jenis konten, dan checksum yang telah disetujui; jangan simpan bytes,
Base64, signed URL, cookie, atau header Authorization.

## Pseudocode framework-netral

```text
SENSITIVE_KEYS = {
  "password",
  "passwordconfirmation",
  "accesstoken",
  "refreshtoken",
  "authorization",
  "cookie",
  "session",
  "apikey",
  "secret",
  "privatekey",
  "token"
}

function normalizeKey(key):
  return lowercase(removeCharactersOtherThanLettersAndDigits(key))

function sanitizeAuditPayload(payload):
  if payload is null:
    return null

  if payload is binary or payload represents uploaded file content:
    return "[REDACTED]"

  if payload is array:
    sanitizedArray = []
    for each item in payload:
      sanitizedArray.append(sanitizeAuditPayload(item))
    return sanitizedArray

  if payload is object:
    sanitizedObject = {}
    for each (key, value) in payload:
      normalizedKey = normalizeKey(key)
      if normalizedKey is in SENSITIVE_KEYS:
        sanitizedObject[key] = "[REDACTED]"
      else:
        sanitizedObject[key] = sanitizeAuditPayload(value)
    return sanitizedObject

  return payload
```

Pencocokan harus berdasarkan key, bukan mencari pola pada nilai biasa. Sanitizer
harus menghasilkan salinan baru agar payload bisnis tidak berubah. Uji unit
wajib mencakup object/array bersarang, variasi penamaan, null, dan file.

## Tanggung jawab integrasi

Backend wajib menjalankan sanitizer pada `oldValues` dan `newValues` tepat
sebelum insert audit. Request body mentah dan header lengkap tidak boleh dipakai
sebagai snapshot. Review berkala diperlukan ketika field atau integrasi baru
ditambahkan. Contoh hasil tersanitasi tersedia pada
[`examples/sensitive-data-redaction-audit.json`](examples/sensitive-data-redaction-audit.json).
