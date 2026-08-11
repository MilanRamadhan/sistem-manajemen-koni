-- Pengujian manual aman untuk PostgreSQL.
-- Prasyarat: docs/security/sql/audit_logs.sql sudah diterapkan.
-- Seluruh data uji dibungkus transaksi dan dihapus kembali melalui ROLLBACK.
-- File ini belum dijalankan bila tidak ada koneksi PostgreSQL yang tersedia.

BEGIN;

-- 1. Expected: satu audit CREATE berhasil dibuat.
INSERT INTO public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    changed_fields,
    ip_address,
    user_agent,
    request_id
) VALUES (
    7,
    'CREATE',
    'prestasi',
    15001,
    NULL,
    '{"id":15001,"atlet_id":42,"medali":"Perak"}'::JSONB,
    '["id","atlet_id","medali"]'::JSONB,
    '192.0.2.10'::INET,
    'audit-manual-test/1.0',
    '00000000-0000-4000-8000-000000000101'::UUID
);

-- 2. Expected: satu audit UPDATE dari Perak menjadi Emas berhasil dibuat.
INSERT INTO public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    changed_fields,
    ip_address,
    user_agent,
    request_id
) VALUES (
    7,
    'UPDATE',
    'prestasi',
    15001,
    '{"id":15001,"atlet_id":42,"medali":"Perak"}'::JSONB,
    '{"id":15001,"atlet_id":42,"medali":"Emas"}'::JSONB,
    '["medali"]'::JSONB,
    '192.0.2.10'::INET,
    'audit-manual-test/1.0',
    '00000000-0000-4000-8000-000000000102'::UUID
);

-- 3. Expected: dua baris tampil; baris UPDATE tampil lebih dahulu.
SELECT
    id,
    actor_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    changed_fields,
    ip_address,
    user_agent,
    request_id,
    created_at
FROM public.audit_logs
WHERE request_id IN (
    '00000000-0000-4000-8000-000000000101'::UUID,
    '00000000-0000-4000-8000-000000000102'::UUID
)
ORDER BY created_at DESC, id DESC;

-- 4. Expected: trigger menolak UPDATE dengan SQLSTATE 42501.
-- Exception ditangkap agar langkah berikutnya tetap dapat dijalankan.
DO $$
BEGIN
    UPDATE public.audit_logs
    SET action = 'DELETE'
    WHERE request_id = '00000000-0000-4000-8000-000000000102'::UUID;

    RAISE EXCEPTION 'TEST GAGAL: UPDATE audit log tidak ditolak';
EXCEPTION
    WHEN SQLSTATE '42501' THEN
        RAISE NOTICE 'EXPECTED: UPDATE audit log ditolak: %', SQLERRM;
END;
$$;

-- 5. Expected: trigger menolak DELETE dengan SQLSTATE 42501.
DO $$
BEGIN
    DELETE FROM public.audit_logs
    WHERE request_id = '00000000-0000-4000-8000-000000000102'::UUID;

    RAISE EXCEPTION 'TEST GAGAL: DELETE audit log tidak ditolak';
EXCEPTION
    WHEN SQLSTATE '42501' THEN
        RAISE NOTICE 'EXPECTED: DELETE audit log ditolak: %', SQLERRM;
END;
$$;

-- 6. Expected: data uji tidak tersimpan permanen.
ROLLBACK;
