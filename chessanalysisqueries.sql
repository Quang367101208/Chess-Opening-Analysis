-- Chess Opening Win-Rate Analysis — SQL Data Analysis Project

-- I. Initial Data Cleaning
-- (Picking necessary columns & narrowing down to rated = 'TRUE' games)

-- Data was downloaded from:
-- https://www.kaggle.com/datasets/datasnaek/chess?resource=download

-- Afterwards, the downloaded file was uploaded onto MySQL Workbench using the table data import wizard. Before uploading, a new schema was created specifically for this project, named "chessgames." The unfiltered data was imported into this schema under the table name "games."

-- The following query selects the necessary columns and filters to rated = 'TRUE' games only:

USE chessgames;

CREATE TABLE rated_true AS
SELECT id, rated, turns, victory_status, winner, increment_code, 
       white_rating, black_rating, opening_eco, opening_name, opening_ply 
FROM games
WHERE rated = 'TRUE';

-- During primary key setup, duplicate rows were discovered (likely introduced during the import process). These were removed using SELECT DISTINCT, after which the id column could be reliably set as the primary key:

CREATE TABLE rated_true1 AS
SELECT DISTINCT * FROM rated_true;

-- The id column was then converted from TEXT to VARCHAR(20) and set as the primary key (TEXT columns cannot be indexed as a primary key without a defined length).
-- Next, games were restricted to rapid time control (8-25 minutes base time). This excludes bullet and blitz games, where fast time pressure leads to more blunder-driven results rather than results reflecting genuine opening performance, and excludes classical games, which have a much smaller sample size on the platform. 
-- A new table, rated_true2, was created for this purpose.

USE chessgames;
CREATE TABLE rated_true2 AS
SELECT *,
  CAST(SUBSTRING_INDEX(increment_code, '+', 1) AS UNSIGNED) AS base_minutes
FROM rated_true1
WHERE CAST(SUBSTRING_INDEX(increment_code, '+', 1) AS UNSIGNED) BETWEEN 8 AND 25;


-- II. Splitting into White and Black Perspective Tables

-- Each game is split into separate White and Black perspective tables, since opening performance is measured differently depending on which side plays it. Games are scored using standard chess convention (win = 1, draw = 0.5, loss = 0) rather than binary win/loss, since draws carry meaningful information about an opening's solidity that a binary win-rate would discard. Players are also grouped into rating brackets: 800-1199, 1200-1599, 1600-1799, 1800-1999, and 2000+.

USE chessgames;
CREATE TABLE white_games AS
SELECT
  id,
  white_rating AS player_rating,
  opening_eco,
  opening_name,
  opening_ply,
  CASE
    WHEN winner = 'white' THEN 1
    WHEN winner = 'draw' THEN 0.5
    ELSE 0
  END AS won,
  CASE
    WHEN white_rating BETWEEN 800 AND 1199 THEN '800-1199'
    WHEN white_rating BETWEEN 1200 AND 1599 THEN '1200-1599'
    WHEN white_rating BETWEEN 1600 AND 1799 THEN '1600-1799'
    WHEN white_rating BETWEEN 1800 AND 1999 THEN '1800-1999'
    ELSE '2000+'
  END AS rating_bucket
FROM rated_true2;

CREATE TABLE black_games AS
SELECT
  id,
  black_rating AS player_rating,
  opening_eco,
  opening_name,
  opening_ply,
  CASE
    WHEN winner = 'black' THEN 1
    WHEN winner = 'draw' THEN 0.5
    ELSE 0
  END AS won,
  CASE
    WHEN black_rating BETWEEN 800 AND 1199 THEN '800-1199'
    WHEN black_rating BETWEEN 1200 AND 1599 THEN '1200-1599'
    WHEN black_rating BETWEEN 1600 AND 1799 THEN '1600-1799'
    WHEN black_rating BETWEEN 1800 AND 1999 THEN '1800-1999'
    ELSE '2000+'
  END AS rating_bucket
FROM rated_true2;


-- III. Win Rate Aggregation Per Opening Per Rating Bracket

-- Games are grouped by rating bracket and opening name (full opening name, including named variations, e.g. "Sicilian Defense: Najdorf Variation" is treated as distinct from "Sicilian Defense: Alapin Variation"), and the average score is computed per group. 
-- Openings with fewer than 20 recorded games within a given rating bracket are excluded, as smaller samples produce unreliable win-rate estimates.

USE chessgames;
CREATE TABLE white_winrate AS
SELECT
  rating_bucket,
  opening_name,
  COUNT(*) AS games_played,
  AVG(won) * 100 AS avg_scorepercent
FROM white_games
GROUP BY rating_bucket, opening_name
HAVING COUNT(*) >= 20;

CREATE TABLE black_winrate AS
SELECT
  rating_bucket,
  opening_name,
  COUNT(*) AS games_played,
  AVG(won) * 100 AS avg_scorepercent
FROM black_games
GROUP BY rating_bucket, opening_name
HAVING COUNT(*) >= 20;


-- IV. Display-Formatted Versions

-- Finally, to make the results human-readable, the average score is rounded to 2 decimal places and formatted with a % symbol:

USE chessgames;
CREATE TABLE white_winrate_display AS
SELECT
  rating_bucket,
  opening_name,
  games_played,
  CONCAT(ROUND(avg_scorepercent, 2), '%') AS avg_scorepercent_display
FROM white_winrate;

CREATE TABLE black_winrate_display AS
SELECT
  rating_bucket,
  opening_name,
  games_played,
  CONCAT(ROUND(avg_scorepercent, 2), '%') AS avg_scorepercent_display
FROM black_winrate;

-- The final tables were exported using the SQL Table Export Wizard and sorted by rating bracket and descending win rate for presentation.