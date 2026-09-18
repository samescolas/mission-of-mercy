-- Link procedure 2954 (Prefab post & build up) to the Restoration treatment
-- area so it appears on the restorative checkout page.
--
-- The procedure row itself already existed with requires_tooth_number = true,
-- so the tooth-number prompt already works; only the treatment-area mapping
-- was missing, which is why it never showed up in the list.
--
-- TreatmentArea#procedures orders by code, so 2954 lands directly underneath
-- 2950 (Core buildup for crown) with no ordering work needed.
--
-- assigned is set to true rather than left NULL: ProcedureTreatmentAreaMapping
-- has an after_save hook that destroys any mapping whose assigned is falsey.
--
-- Looked up by code/name instead of hardcoded ids so this is safe to run
-- against a rebuilt database. Re-running it is a no-op.
INSERT INTO procedure_treatment_area_mappings
  (procedure_id, treatment_area_id, assigned, created_at, updated_at)
SELECT p.id, t.id, true, now(), now()
FROM   procedures p
CROSS JOIN treatment_areas t
WHERE  p.code = 2954
  AND  t.name = 'Restoration'
  AND  NOT EXISTS (
         SELECT 1 FROM procedure_treatment_area_mappings m
         WHERE m.procedure_id = p.id AND m.treatment_area_id = t.id
       );
