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

Full SQL pipeline: [`chessanalysisqueries.sql`](./chessanalysisqueries.sql)

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
This part addresses some of the limitations in part A by computing the standard deviation value & running the binomial test. 
