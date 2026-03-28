-- Migration 00053: RLS policies for nutrition tables

-- Enable RLS on all nutrition tables
ALTER TABLE nutrition_goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_goal_defaults      ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_logs               ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_year_summaries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_recipes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_weight_logs        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_weight_year_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_weight_meta        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_products           ENABLE ROW LEVEL SECURITY;

-- ── Owner-only policies for user-scoped tables ────────────────────────────────
-- nutrition_goals
CREATE POLICY "owner_goals" ON nutrition_goals
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_goal_defaults
CREATE POLICY "owner_goal_defaults" ON nutrition_goal_defaults
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_logs
CREATE POLICY "owner_logs" ON nutrition_logs
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_year_summaries
CREATE POLICY "owner_year_summaries" ON nutrition_year_summaries
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_recipes
CREATE POLICY "owner_recipes" ON nutrition_recipes
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_weight_logs
CREATE POLICY "owner_weight_logs" ON nutrition_weight_logs
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_weight_year_summaries
CREATE POLICY "owner_weight_year_summaries" ON nutrition_weight_year_summaries
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- nutrition_weight_meta
CREATE POLICY "owner_weight_meta" ON nutrition_weight_meta
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── nutrition_products: all authenticated users can read, authenticated can write ──
CREATE POLICY "products_read_authenticated" ON nutrition_products
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "products_write_authenticated" ON nutrition_products
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "products_update_authenticated" ON nutrition_products
  FOR UPDATE USING (auth.role() = 'authenticated')
             WITH CHECK (auth.role() = 'authenticated');

-- ── Grant service_role explicit access (needed for edge functions) ────────────
GRANT ALL ON nutrition_goals                  TO service_role;
GRANT ALL ON nutrition_goal_defaults          TO service_role;
GRANT ALL ON nutrition_logs                   TO service_role;
GRANT ALL ON nutrition_year_summaries         TO service_role;
GRANT ALL ON nutrition_recipes                TO service_role;
GRANT ALL ON nutrition_weight_logs            TO service_role;
GRANT ALL ON nutrition_weight_year_summaries  TO service_role;
GRANT ALL ON nutrition_weight_meta            TO service_role;
GRANT ALL ON nutrition_products               TO service_role;

-- ── Grant authenticated users RPC access ────────────────────────────────────
GRANT EXECUTE ON FUNCTION nutrition_upsert_year_day   TO authenticated;
GRANT EXECUTE ON FUNCTION nutrition_upsert_weight_day TO authenticated;
