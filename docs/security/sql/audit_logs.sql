-- Skema referensi PostgreSQL untuk audit trail data prestasi KONI Aceh.
-- File ini tidak terikat framework/migration tool karena backend belum tersedia.

BEGIN;

CREATE TABLE public.audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    actor_id        BIGINT NULL,
    action          VARCHAR(16) NOT NULL,
    entity_type     VARCHAR(100) NOT NULL,
    entity_id       BIGINT NOT NULL,
    old_values      JSONB NULL,
    new_values      JSONB NULL,
    changed_fields  JSONB NULL,
    ip_address      INET NULL,
    user_agent      TEXT NULL,
    request_id      UUID NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT audit_logs_action_check
        CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'ARCHIVE')),
    CONSTRAINT audit_logs_entity_type_not_blank
        CHECK (BTRIM(entity_type) <> ''),
    CONSTRAINT audit_logs_old_values_object
        CHECK (old_values IS NULL OR JSONB_TYPEOF(old_values) = 'object'),
    CONSTRAINT audit_logs_new_values_object
        CHECK (new_values IS NULL OR JSONB_TYPEOF(new_values) = 'object'),
    CONSTRAINT audit_logs_changed_fields_array
        CHECK (changed_fields IS NULL OR JSONB_TYPEOF(changed_fields) = 'array')
);

CREATE INDEX audit_logs_entity_idx
    ON public.audit_logs (entity_type, entity_id);
CREATE INDEX audit_logs_actor_id_idx
    ON public.audit_logs (actor_id);
CREATE INDEX audit_logs_action_idx
    ON public.audit_logs (action);
CREATE INDEX audit_logs_created_at_idx
    ON public.audit_logs (created_at DESC);
CREATE INDEX audit_logs_request_id_idx
    ON public.audit_logs (request_id)
    WHERE request_id IS NOT NULL;

COMMENT ON TABLE public.audit_logs IS
    'Catatan append-only perubahan data untuk akuntabilitas dan keterlacakan aktivitas sistem.';
COMMENT ON COLUMN public.audit_logs.id IS
    'Identitas unik audit log yang dibuat PostgreSQL.';
COMMENT ON COLUMN public.audit_logs.actor_id IS
    'Identitas pengguna/pelaku; nullable untuk proses sistem atau saat identitas tidak tersedia. Tidak memakai foreign key sampai model autentikasi tersedia.';
COMMENT ON COLUMN public.audit_logs.action IS
    'Aksi yang diizinkan: CREATE, UPDATE, DELETE, atau ARCHIVE.';
COMMENT ON COLUMN public.audit_logs.entity_type IS
    'Nama tipe entitas domain yang berubah, misalnya prestasi.';
COMMENT ON COLUMN public.audit_logs.entity_id IS
    'Identitas numerik entitas yang berubah.';
COMMENT ON COLUMN public.audit_logs.old_values IS
    'Snapshot objek JSON sebelum perubahan; null untuk CREATE.';
COMMENT ON COLUMN public.audit_logs.new_values IS
    'Snapshot objek JSON sesudah perubahan; null untuk DELETE.';
COMMENT ON COLUMN public.audit_logs.changed_fields IS
    'Array JSON nama field tingkat atas yang berubah.';
COMMENT ON COLUMN public.audit_logs.ip_address IS
    'Alamat IP client yang telah ditentukan menggunakan konfigurasi trusted proxy.';
COMMENT ON COLUMN public.audit_logs.user_agent IS
    'User-Agent request; panjangnya perlu dibatasi pada lapisan aplikasi.';
COMMENT ON COLUMN public.audit_logs.request_id IS
    'UUID korelasi untuk menelusuri seluruh aktivitas dari satu request.';
COMMENT ON COLUMN public.audit_logs.created_at IS
    'Waktu pencatatan menurut server database, termasuk zona waktu.';

CREATE OR REPLACE FUNCTION public.prevent_audit_log_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
    RAISE EXCEPTION
        'audit_logs bersifat append-only; operasi % tidak diizinkan',
        TG_OP
        USING ERRCODE = '42501';
END;
$$;

COMMENT ON FUNCTION public.prevent_audit_log_mutation() IS
    'Menolak perubahan dan penghapusan terhadap baris audit_logs.';

CREATE TRIGGER audit_logs_prevent_update
BEFORE UPDATE ON public.audit_logs
FOR EACH ROW
EXECUTE FUNCTION public.prevent_audit_log_mutation();

CREATE TRIGGER audit_logs_prevent_delete
BEFORE DELETE ON public.audit_logs
FOR EACH ROW
EXECUTE FUNCTION public.prevent_audit_log_mutation();

-- TRUNCATE tidak menjalankan trigger per baris, sehingga perlu dilindungi
-- secara eksplisit agar tidak menjadi jalan pintas untuk mengosongkan log.
CREATE TRIGGER audit_logs_prevent_truncate
BEFORE TRUNCATE ON public.audit_logs
FOR EACH STATEMENT
EXECUTE FUNCTION public.prevent_audit_log_mutation();

-- Contoh hardening hak akses produksi. Jangan jalankan sebelum nama role final:
--
-- REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.audit_logs FROM koni_app;
-- REVOKE USAGE, SELECT ON SEQUENCE public.audit_logs_id_seq FROM koni_app;
-- GRANT INSERT ON public.audit_logs TO koni_app;
-- GRANT USAGE, SELECT ON SEQUENCE public.audit_logs_id_seq TO koni_app;
-- GRANT SELECT ON public.audit_logs TO koni_audit_reader;
--
-- Role aplikasi idealnya hanya dapat INSERT dan tidak dapat UPDATE/DELETE.
-- Hak SELECT diberikan hanya kepada role pembaca audit yang berwenang.

COMMIT;
