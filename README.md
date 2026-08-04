# Chess-Opening-Analysis
SQL data analysis of ~20K Lichess games taken on Kaggle to find the highest-performing chess openings by rating bracket.
# Chess Opening Win-Rate Analysis

SQL data analysis of ~20,000 rated Lichess games to identify the highest-performing chess openings by player rating bracket, separately for White and Black.

! Overview

This project answers the question: which chess opening performs best at a given rating level? Using a public dataset of Lichess games, the data was cleaned, filtered, and aggregated in MySQL to calculate each opening's average performance score across five rating brackets, separately for White and Black.

**A.** Initial data screening & analysis
! Overview
In this first part, data was downloaded from kaggle, cleansed before having the average win rates computed.

! Data Source

[Chess Game Dataset (Lichess) — Kaggle](https://www.kaggle.com/datasets/datasnaek/chess?resource=download)

! Methodology

- Filtering: Restricted to rated games only, and to rapid time control (8–25 min base time) to exclude bullet/blitz (blunder-prone, fast time pressure) and classical (small sample size) games.
- Deduplication: Removed full-row duplicate entries introduced during data import.
- Scoring: Games are scored using standard chess convention — win = 1, draw = 0.5, loss = 0.
- Rating brackets: 800–1199, 1200–1599, 1600–1799, 1800–1999, 2000+
- Perspective split: Games are analyzed separately for White and Black, since the same opening performs differently depending on which side plays it.
- Sample size threshold: Openings with fewer than 20 games in a given bracket are excluded, as smaller samples produce unreliable win-rate estimates.

Full SQL pipeline: [`chessanalysisqueriesA.sql`](./chessanalysisqueriesA.sql)

! Key Findings

Top opening by rating bracket — White
FORMAT: [RATING-BUCKET] Opening_name: number-of-games - winrate
[800–1199] Scandinavian Defense: 45 - 46.67% 
[1200–1599] French Defense: Advance Variation #3: 20 - 75.00% 
[1600–1799] Scandinavian Defense: Mieses-Kotroc Variation: 35 - 77.14% 
[1800–1999]Scandinavian Defense: Mieses-Kotroc Variation: 21 - 71.43% 

Top opening by rating bracket — Black
FORMAT: [RATING-BUCKET] Opening_name: number-of-games - winrate
[800–1199] Scandinavian Defense: 40 - 45.00%
[1200–1599] Van't Kruijs Opening: 105 - 70.95%
[1600–1799] Van't Kruijs Opening: 31 - 75.81%
[1800–1999] Sicilian Defense: Old Sicilian: 31 - 74.19%

Full results: [`white_winrate_sorted.csv`](./white_winrate_sorted.csv), [`black_winrate_sorted.csv`](./black_winrate_sorted.csv)

! Tools

MySQL Workbench, SQL (CASE expressions, aggregate functions, GROUP BY/HAVING), Claude AI (Data cleaning, schema design, and all SQL queries were written independently. Final output files were sorted and formatted with Claude's assistance.)

! Second Reference
The queries are explained in this file: https://docs.google.com/document/d/1FNSdlg1CY0cUO4g3m7-KVtIktGQdBTZDR7c6qhpo2IA/edit?tab=t.0

! Limitations

- The 2000+ bracket had too few games with any single opening to meet the 20-game sample threshold, so no reliable "top opening" could be determined for that bracket.
- Some openings show high average scores from relatively small samples (e.g., 20–30 games), which should be interpreted with appropriate caution rather than as definitive rankings.

**B.** Further analysis.

! Overview
This part addresses some of the limitations in part A by computing the standard deviation values and running the binomial significance test.

### Standard Deviation
For each opening/bracket combination, the sample standard deviation of the score (`won`, valued 1, 0.5, or 0) was computed directly in SQL using `STDDEV_SAMP()`, alongside the existing average, to get a sense of how much individual games vary around that average before testing significance.

**Result:** 
- Across every opening (White and Black combined), standard deviation values fall between roughly 0.40 and 0.51 — close to the maximum possible spread for a variable that only takes values of 0, 0.5, or 1. This means individual games are close to unpredictable.
- This high per-game variability is exactly why a small-sample average can't be trusted at face value — a 75% score over 20 games could easily be the product of this underlying randomness rather than a real advantage. This motivates the binomial significance test below, which formally checks whether each opening's *average* score across all its games is still far enough from a 50/50 baseline to be unlikely by chance, despite the noise at the individual-game level.
- Full results in Binomial Test Results section.

### Binomial Test
To test whether each opening's average score is meaningfully different from a 50/50 baseline, a binomial test was run on every opening/bracket row using Python's `scipy.stats.binomtest`. The null hypothesis for each test: the opening has no real advantage (a true win rate of 50%), and any observed deviation is due to random chance given the sample size.

**Setup:**
- `white_winrate_v2` and `black_winrate_v2` were exported from MySQL Workbench to CSV.
- `scipy` was installed into the project's virtual environment (`pip install scipy`, run via PyCharm's interpreter settings).
- Each CSV was read using Python's built-in `csv.DictReader`, which parses each row into a dictionary keyed by column name.

**For each opening/bracket row:**
1. The average score percentage and game count were converted from text to numerical values.
2. An approximate "win-equivalent" count was reconstructed as `avg_score / 100 × games_played`.
3. `scipy.stats.binomtest(wins_equivalent, games_played, 0.5)` was run to compute a p-value.
4. Results with p < 0.05 were flagged as statistically significant — meaning the observed score is unlikely to have occurred by chance if the opening were truly a 50/50 proposition.

**A known limitation of this approach:** because games can end in a draw (score 0.5), the "win-equivalent" count used in the binomial test is an approximation, not an exact win/loss tally — the binomial test technically assumes a clean binary outcomeper trial. This is a simplification worth noting. Because draws (score 0.5) pull outcomes toward the middle rather than the extremes, this approximation likely makes the test slightly conservative — it may under-detect real patterns (undercounts) rather than produce false positives (overcounts).

### Results

Of the 100 White opening/bracket combinations meeting the 20-game sample threshold, 12 (12.0%) showed a statistically significant deviation from a 50% baseline (p < 0.05). For Black, 13 of 96 (13.5%) were significant. 
The remaining results — while still the highest-scoring within their bracket in some cases — should be interpreted with caution, as their sample size is not large enough to rule out random variation.

Some notable significant results include:

- **Van't Kruijs Opening** was significant for both colors in multiple brackets, and in opposite directions — Black scores well against it (70.95% at 1200-1599, p < 0.0001), while White scores poorly with it (34.29% at 1200-1599, 18.87% at 800-1199), consistent with it being an objectively weak opening choice for White.
- **Scandinavian Defense: Mieses-Kotroc Variation** was significant for White at 1600-1799 (77.14%, p = 0.0019), suggesting White holds a real advantage against this response at that rating level.
- **Sicilian Defense: Old Sicilian** and **Sicilian Defense: Bowdler Attack** were significant for Black at 1800-1999 (74.19% and 73.53%, respectively), suggesting these lines perform reliably well for Black players at that level, not just by chance.

Full results, including computed standard deviation values, p-values and significance flags for every opening/bracket combination: [`white_significance_results_formatted.csv`](./white_significance_results_formatted.csv), [`black_significance_results_formatted.csv`](./black_significance_results_formatted.csv)

! Tools:
MySQL Workbench, SQL (STDDEV_SAMP), Python (PyCharm), scipy (binomtest), Claude AI (Standard deviation computation and binomial significance testing methodology were designed and implemented independently. Claude assisted with result formatting and README documentation.)

Full SQL & Python pipeline: [`chessanalysisqueriesB`](./chessanalysisqueriesB)


