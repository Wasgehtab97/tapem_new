-- ─── gym_deals ───────────────────────────────────────────────────────────────
-- Each row is a branded deal/partnership scoped to a specific gym.
-- Per-gym scoping enables revenue attribution and split tracking per gym.

CREATE TABLE public.gym_deals (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id                UUID        NOT NULL REFERENCES public.tenant_gyms(id) ON DELETE CASCADE,
  brand_name            TEXT        NOT NULL,
  tagline               TEXT        NOT NULL DEFAULT '',
  description           TEXT        NOT NULL DEFAULT '',
  logo_url              TEXT,
  banner_gradient_start TEXT        NOT NULL DEFAULT '#12121A',
  banner_gradient_end   TEXT        NOT NULL DEFAULT '#0A0A0F',
  affiliate_url         TEXT        NOT NULL,
  discount_code         TEXT,
  discount_label        TEXT,
  category              TEXT        NOT NULL DEFAULT 'supplements'
                          CHECK (category IN (
                            'supplements', 'clothing', 'food', 'equipment', 'wellness'
                          )),
  is_active             BOOLEAN     NOT NULL DEFAULT TRUE,
  sort_order            INTEGER     NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX gym_deals_gym_active_sort_idx
  ON public.gym_deals (gym_id, is_active, sort_order);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.gym_deals ENABLE ROW LEVEL SECURITY;

-- Active gym members can read deals for their gym.
CREATE POLICY "gym_members_read_active_deals"
  ON public.gym_deals
  FOR SELECT
  TO authenticated
  USING (
    is_active = TRUE
    AND EXISTS (
      SELECT 1 FROM public.memberships m
      WHERE m.gym_id  = gym_deals.gym_id
        AND m.user_id = auth.uid()
        AND m.is_active = TRUE
    )
  );

-- ─── Grants ──────────────────────────────────────────────────────────────────
GRANT ALL    ON public.gym_deals TO service_role;
GRANT SELECT ON public.gym_deals TO authenticated;

-- ─── Demo seed: 3 brands × all existing gyms ─────────────────────────────────
-- Same brands per gym so the feature works everywhere on launch.
-- Revenue is tracked by gym_id, so duplicate brand rows are intentional.
INSERT INTO public.gym_deals (
  gym_id,
  brand_name, tagline, description,
  banner_gradient_start, banner_gradient_end,
  affiliate_url, discount_code, discount_label,
  category, sort_order
)
SELECT
  g.id,
  b.brand_name,
  b.tagline,
  b.description,
  b.gradient_start,
  b.gradient_end,
  b.affiliate_url,
  b.discount_code,
  b.discount_label,
  b.category,
  b.sort_order
FROM public.tenant_gyms g
CROSS JOIN (
  VALUES
    (
      'ESN',
      'Premium Supplements für echte Athleten',
      'Europas führende Supplement-Marke. Proteine, Kreatin, Aminosäuren und mehr – alles für deine optimale Performance.',
      '#0D1B2A', '#071018',
      'https://www.esn.com',
      'TAPEM10', '10% RABATT',
      'supplements', 0
    ),
    (
      'PrepMyMeal',
      'Meal Prep. Einfach. Lecker. Gesund.',
      'Frisch zubereitete Fitness-Mahlzeiten direkt zu dir nach Hause – perfekt auf deine Makros abgestimmt.',
      '#0D2A1A', '#071510',
      'https://www.prepmymeal.de',
      'TAPEM', 'GRATIS VERSAND',
      'food', 1
    ),
    (
      'YoungLA',
      'Built in the Gym. Worn in the Streets.',
      'Premium Gym-Kleidung für den modernen Athleten. Designed für maximale Performance und Style.',
      '#1A0D2A', '#100718',
      'https://www.youngla.com',
      'TAPEM15', '15% RABATT',
      'clothing', 2
    )
) AS b (
  brand_name, tagline, description,
  gradient_start, gradient_end,
  affiliate_url, discount_code, discount_label,
  category, sort_order
);
