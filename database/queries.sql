-- Check Database
USE movie_db;
SHOW TABLES;

SHOW COLUMNS FROM film_company;
SHOW COLUMNS FROM film_country;
SHOW COLUMNS FROM film_info;
SHOW COLUMNS FROM films;
SHOW COLUMNS FROM finance;
SHOW COLUMNS FROM genre;
SHOW COLUMNS FROM genre_film;
SHOW COLUMNS FROM production_company;
SHOW COLUMNS FROM production_country;
SHOW COLUMNS FROM ratings;

-- Core queries
-- 1. Budget Efficiency: Do higher budgets guarantee higher profits, and which genres give the best ROI?
-- Goal: Compare profitability across budget tiers (Low/Medium/Avergage/High/High-end) and genres.
-- Categorizing movies into budget tiers
-- Query 1: Basic ROI calculation with budget tiers
SELECT 
    fl.imdb_id,
    fl.film_title,
    fc.budget,
    fc.revenue,
    (fc.revenue - fc.budget) / fc.budget AS ROI,
    (fc.revenue - fc.budget) AS profit,
  CASE
            WHEN fc.budget < 1e6 THEN 'Low Budget'				-- ($0-1M)
            WHEN fc.budget < 10e6 THEN 'Medium Budget'			-- ($1M-10M)
            WHEN fc.budget < 50e6 THEN 'Average Movie Budget'	-- ($10M-50M)
            WHEN fc.budget < 100e6 THEN 'High Budget'			-- ($50M-100M)
            ELSE 'High-end Budget'									-- (>$100M)
        END AS budget_tier    
FROM 
    films fl
JOIN 
    finance fc ON fl.imdb_id = fc.imdb_id
WHERE 
    fc.budget > 0 AND fc.revenue > 0
ORDER BY 
    fc.budget DESC;    
    ;  -- Avoid division by zero

-- =================
-- Genres:
-- =================

-- 1a. Number of movies per genre
SELECT 
    g.genre_name,
    COUNT(gf.imdb_id) AS movie_count
FROM genre_film gf
JOIN genre g ON gf.genre_id = g.genre_id
GROUP BY g.genre_name
ORDER BY movie_count DESC;

-- 1b. Movies by number of genres
SELECT 
    genre_count,
    COUNT(imdb_id) AS movie_count
FROM (
    SELECT 
        imdb_id,
        COUNT(genre_id) AS genre_count
    FROM genre_film
    GROUP BY imdb_id
) AS sub
GROUP BY genre_count
ORDER BY genre_count;

-- 1.c ROI Metrics by Genre
		-- # 1. Get raw ROI data by genre
		-- # 2. Better to use Pandas tools to analyse metrics
SELECT 
        g.genre_name,
        (fc.revenue - fc.budget)/fc.budget AS roi
    FROM films f
    JOIN finance fc ON f.imdb_id = fc.imdb_id
    JOIN genre_film gf ON f.imdb_id = gf.imdb_id
    JOIN genre g ON gf.genre_id = g.genre_id
    WHERE fc.budget > 0 AND fc.revenue > 0;

-- Query 2: ROI with genres
WITH MovieROI AS (
    SELECT 
        fl.imdb_id,
        fl.film_title,
        fc.budget,
        fc.revenue,
        (fc.revenue - fc.budget) / fc.budget AS ROI
    FROM 
        films fl
    JOIN 
        finance fc ON fl.imdb_id = fc.imdb_id
    WHERE 
        fc.budget > 0 AND fc.revenue > 0
)
SELECT 
    mr.*,
    g.genre_name
FROM 
    MovieROI mr
JOIN 
    genre_film gf ON mr.imdb_id = gf.imdb_id
JOIN 
    genre g ON gf.genre_id = g.genre_id;

-- 2. Audience Reception: Do highly-rated movies earn more, and does this vary by genre?
-- Goal: Link IMDb ratings to profitability
-- Key Metrics: Average profit per rating range (e.g., 6-7, 7-8).
-- Correlation between IMDb ratings and profit
SELECT CASE 
           WHEN r.avg_rating >= 8 THEN 'Excellent (8+)'
           WHEN avg_rating >= 7 THEN 'Good (7-8)'
		   WHEN avg_rating >= 6 THEN 'Average (6-7)'
		   ELSE 'Poor (<6)'
		END AS rating_category,
        COUNT(*) AS movie_count,
        ROUND(AVG(fi.revenue - fi.budget)/1e6, 2) AS avg_profit_millions,
        -- Standard ROI calculation
        ROUND(AVG((fi.revenue - fi.budget)/NULLIF(fi.budget, 0)), 2) AS avg_roi,
    -- Additional metric for context
    ROUND(AVG(fi.revenue/NULLIF(fi.budget, 0)), 2) AS revenue_multiplier
FROM ratings r
JOIN finance fi ON r.imdb_id = fi.imdb_id
WHERE r.avg_rating IS NOT NULL
GROUP BY rating_category
ORDER BY avg_roi DESC;

-- Relationship between ratings and profitability by genre
SELECT 
    g.genre_name,
    COUNT(*) AS movie_count,
    ROUND(AVG(r.avg_rating), 1) AS avg_rating,
    ROUND(AVG(fi.revenue - fi.budget)/1e6, 2) AS avg_profit_millions,
    -- Standard ROI calculation (revenue - budget)/budget
    ROUND(AVG((fi.revenue - fi.budget)/NULLIF(fi.budget, 0)), 2) AS avg_roi
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
JOIN ratings r ON gf.imdb_id = r.imdb_id
JOIN finance fi ON gf.imdb_id = fi.imdb_id
GROUP BY g.genre_name
HAVING COUNT(*) >= 10  -- Only genres with sufficient data
ORDER BY avg_roi DESC;

-- 3.Temporal Trends: How have movie budgets and revenues changed over time?
-- Goal: Track decade-by-decade trends.
-- Key Metrics: Average movie budgets & ROI by Decade
-- Basic decade-level aggreagtes
SELECT 
    CONCAT(FLOOR(YEAR(f.release_date)/10)*10, 's') AS decade,
    COUNT(*) AS movie_count,
    ROUND(AVG(fi.budget)/1e6, 2) AS avg_budget_millions,
    ROUND(AVG(fi.revenue)/1e6, 2) AS avg_revenue_millions,
    -- Standard ROI calculation
    ROUND(AVG((fi.revenue - fi.budget)/NULLIF(fi.budget, 0)), 2) AS avg_roi,
    -- Total investment vs return
    ROUND(SUM(fi.revenue)/NULLIF(SUM(fi.budget), 0), 2) AS aggregate_roi
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
WHERE f.release_date IS NOT NULL
GROUP BY decade
ORDER BY decade;

-- Number of movies per decade and movie economics' trends (detailed decade analysis)
SELECT 
    CONCAT(FLOOR(YEAR(f.release_date)/10)*10, 's') AS decade,
    COUNT(*) AS movie_count,
    -- Only movies with valid budgets > 0
    SUM(CASE WHEN fi.budget > 0 THEN 1 ELSE 0 END) AS movies_with_budget_data,
    ROUND(AVG(CASE WHEN fi.budget > 0 THEN fi.budget END)/1e6, 2) AS avg_budget_millions,
    ROUND(AVG(CASE WHEN fi.budget > 0 THEN fi.revenue END)/1e6, 2) AS avg_revenue_millions,
    ROUND(
        AVG(CASE 
            WHEN fi.budget > 0 AND fi.revenue IS NOT NULL 
            THEN (fi.revenue - fi.budget)/fi.budget 
        END),
    2) AS avg_roi
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
WHERE f.release_date IS NOT NULL
GROUP BY decade
ORDER BY decade;

-- Total movie budget and total revenue across decades (total investment vs total return)
SELECT 
	  CONCAT(FLOOR(YEAR(f.release_date)/10)*10, 's') AS decade,
	  COUNT(*) AS movie_count,
	  ROUND(SUM(fi.budget)/1e6, 2) AS total_budget_millions,
	  ROUND(SUM(fi.revenue)/1e6, 2) AS total_revenue_millions
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
WHERE f.release_date IS NOT NULL
GROUP BY decade
ORDER BY decade;

-- Change in budgets and revenue per decade
WITH decade_stats AS (
    SELECT 
        FLOOR(YEAR(f.release_date) / 10) * 10 AS decade_start,
        FLOOR(YEAR(f.release_date) / 10) * 10 + 9 AS decade_end,
        CONCAT(FLOOR(YEAR(f.release_date) / 10) * 10, '-', 
               FLOOR(YEAR(f.release_date) / 10) * 10 + 9) AS decade,
        AVG(fi.budget) AS avg_budget,
        AVG(fi.revenue) AS avg_revenue,
        COUNT(*) AS movie_count
    FROM films f
    JOIN finance fi ON f.imdb_id = fi.imdb_id
    WHERE fi.budget > 0 AND fi.revenue > 0
    GROUP BY 
        FLOOR(YEAR(f.release_date) / 10) * 10,
        FLOOR(YEAR(f.release_date) / 10) * 10 + 9,
        CONCAT(FLOOR(YEAR(f.release_date) / 10) * 10, '-', 
               FLOOR(YEAR(f.release_date) / 10) * 10 + 9)
    HAVING COUNT(*) > 10
),

decade_comparison AS (
    SELECT 
        current.decade_start,
        current.decade_end,
        current.decade,
        current.avg_budget,
        current.avg_revenue,
        current.movie_count,
        previous.avg_budget AS prev_avg_budget,
        previous.avg_revenue AS prev_avg_revenue,
        previous.decade AS prev_decade
    FROM decade_stats current
    LEFT JOIN decade_stats previous ON current.decade_start = previous.decade_start + 10
)

SELECT 
    decade,
    decade_start,
    decade_end,
    movie_count,
    avg_budget,
    avg_revenue,
    prev_decade,
    prev_avg_budget,
    prev_avg_revenue,
    ROUND((avg_budget - prev_avg_budget) / NULLIF(prev_avg_budget, 0) * 100, 2) AS budget_pct_change,
    ROUND((avg_revenue - prev_avg_revenue) / NULLIF(prev_avg_revenue, 0) * 100, 2) AS revenue_pct_change
FROM decade_comparison
WHERE prev_decade IS NOT NULL
ORDER BY decade_start;

  
