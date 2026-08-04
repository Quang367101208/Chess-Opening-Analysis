-- ============================================
-- Chess Opening Win-Rate Analysis
-- Part B: Standard Deviation & Binomial Significance Testing
-- ============================================

-- Part A computed the average score per opening per rating bracket, but a
-- simple average treats a 75% score from 20 games the same as a 75% score
-- from 200 games, even though the second is far more trustworthy. Part B
-- addresses this limitation in two steps: first quantifying how much
-- individual games vary (standard deviation), then formally testing
-- whether each result is distinguishable from random chance (binomial test).


-- I. Standard Deviation
-- For each opening/bracket combination, the sample standard deviation of
-- the score (won, valued 1, 0.5, or 0) is computed alongside the existing
-- average, to see how much individual games vary around that average.

USE chessgames;

CREATE TABLE white_winrate_v2 AS
SELECT
  rating_bucket,
  opening_name,
  COUNT(*) AS games_played,
  AVG(won) * 100 AS avg_scorepercent,
  STDDEV_SAMP(won) AS score_stddev
FROM white_games
GROUP BY rating_bucket, opening_name
HAVING COUNT(*) >= 20;

CREATE TABLE black_winrate_v2 AS
SELECT
  rating_bucket,
  opening_name,
  COUNT(*) AS games_played,
  AVG(won) * 100 AS avg_scorepercent,
  STDDEV_SAMP(won) AS score_stddev
FROM black_games
GROUP BY rating_bucket, opening_name
HAVING COUNT(*) >= 20;

-- Result: standard deviation values across every opening (White and Black
-- combined) fall between roughly 0.40 and 0.51 -- close to the maximum
-- possible spread for a variable that only takes values of 0, 0.5, or 1.
-- This means individual games are close to unpredictable at the
-- game-by-game level. This high per-game variability is exactly why a
-- small-sample average can't be trusted at face value, which motivates
-- the binomial significance test below.

-- These tables were exported to CSV (white_winrate_v2.csv, 
-- black_winrate_v2.csv) and brought into Python for the next step.


-- II. Binomial Significance Testing (Python)
-- To test whether each opening's average score is meaningfully different
-- from a 50/50 baseline, a binomial test is run on every opening/bracket
-- row using Python's scipy.stats.binomtest. The null hypothesis for each
-- test is that the opening has no real advantage (a true win rate of
-- 50%), and any observed deviation is due to random chance given the
-- sample size.

-- Setup:
-- - scipy was installed into the project's virtual environment via
--   PyCharm's Python Interpreter settings (Settings > Python > Interpreter
--   > + > search "scipy" > Install Package).
-- - Each CSV was read using Python's built-in csv.DictReader, which
--   parses each row into a dictionary keyed by column name.
-- - Note: the black CSV export used a semicolon delimiter rather than a
--   comma, so csv.DictReader was called with delimiter=';' for that file.

-- For each opening/bracket row:
-- 1. The average score percentage and game count are converted from text
--    to numeric values.
-- 2. An approximate "win-equivalent" count is reconstructed as
--    avg_score / 100 x games_played.
-- 3. scipy.stats.binomtest(wins_equivalent, games_played, 0.5) computes
--    a p-value.
-- 4. Results with p < 0.05 are flagged as statistically significant --
--    meaning the observed score is unlikely to have occurred by chance
--    if the opening were truly a 50/50 proposition.

/*
import csv
from scipy.stats import binomtest

with open('white_winrate_v2.csv') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

with open('white_significance_results.csv', 'w', newline='') as f:
    fieldnames = ['rating_bucket', 'opening_name', 'games_played', 'avg_scorepercent', 'score_stddev', 'p_value', 'significant']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()

    for row in rows:
        games = int(row['games_played'])
        avg_pct = float(row['avg_scorepercent'])
        wins_equiv = round(avg_pct / 100 * games)
        result = binomtest(wins_equiv, games, 0.5)
        pval = round(result.pvalue, 4)

        writer.writerow({
            'rating_bucket': row['rating_bucket'],
            'opening_name': row['opening_name'],
            'games_played': games,
            'avg_scorepercent': avg_pct,
            'score_stddev': row['score_stddev'],
            'p_value': pval,
            'significant': 'Yes' if pval < 0.05 else 'No'
        })

print("Done -- saved to white_significance_results.csv")
*/

-- The same script was re-run on black_winrate_v2.csv (with
-- delimiter=';') to produce black_significance_results.csv.

-- A known limitation of this approach: because games can end in a draw
-- (scored 0.5), the "win-equivalent" count used in the binomial test is
-- an approximation, not an exact win/loss tally -- the binomial test
-- technically assumes a clean binary outcome per trial. This is a
-- simplification worth noting rather than a perfect statistical
-- treatment.

-- Results: of the 100 White opening/bracket combinations meeting the
-- 20-game sample threshold, 12 (12.0%) showed a statistically
-- significant deviation from a 50% baseline (p < 0.05). For Black, 13 of
-- 96 (13.5%) were significant. The remaining results should be
-- interpreted with caution, as their sample size is not large enough to
-- rule out random variation.
