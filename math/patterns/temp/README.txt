Second batch of 3-particle finds: 156 patterns the first sweep missed
(it skipped about two thirds of the starts it should have tried; fixed
and re-run). All verified in bobo.html, none duplicate the Zoo or batch 1.

NewFinds/ uses the same folder names as batch 1, so it merges straight into
patterns/NewFinds; names already used in batch 1 get the next letter
(e.g. orbiter_p376_b). Run update-manifest.sh afterwards.
  Orbiters_new      13  quarter-turn orbiters (p15100 is about 24,700 across)
  HalfTurn_large    34  half-turn travellers, span >= 100
  HalfTurn_small    15  half-turn travellers, span < 100
  Osc3_asymmetric   65  oscillators with no symmetry
  Osc3_symmetric    29  mirror-symmetric oscillators

In 11 files the particles trade places, so the Zoo badge shows 3x the lap.
orbiter_p15100 is longer than the Zoo thumbnail's 5000-tick limit, so its
card shows only the opening of the run.
