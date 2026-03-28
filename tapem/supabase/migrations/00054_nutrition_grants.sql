-- Migration 00054: Grant table-level access to authenticated role for nutrition tables
-- RLS policies alone are not sufficient — the role also needs GRANT on the tables.

GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_goals                 TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_goal_defaults         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_logs                  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_year_summaries        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_recipes               TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_weight_logs           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_weight_year_summaries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_weight_meta           TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON nutrition_products             TO authenticated;
