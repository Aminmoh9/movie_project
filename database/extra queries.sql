USE movie_db;
-- 1. How many movies were released each year?
SELECT YEAR(release_date) AS release_year, COUNT(*) AS movie_count
FROM films
GROUP BY release_year
ORDER BY release_year;

-- 2. Which year had the most movie releases? 
SELECT YEAR(release_date) AS release_year, COUNT(*) AS movie_count
FROM films
GROUP BY release_year
ORDER BY movie_count DESC
LIMIT 1;

-- 3. Which are the top 5 most expensive movies by budget?
SELECT f.film_title, finance.budget
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
ORDER BY finance.budget DESC
LIMIT 5;

-- 4. Which movies had a loss (budget > revenue)?
SELECT f.film_title, finance.budget, finance.revenue
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
WHERE finance.budget > finance.revenue;

-- 5. What is the average IMDb rating across all movies?
SELECT AVG(avg_rating) AS avg_imdb_rating
FROM ratings;

-- 6. Which are the top 5 highest-rated movies?
SELECT f.film_title, r.avg_rating
FROM films f
JOIN ratings r ON f.imdb_id= r.imdb_id
ORDER BY r.avg_rating DESc
LIMIT 5;

-- 7. Which movies have the most votes?
SELECT f.film_title, r.vote_count
FROM films f
JOIN ratings r ON f.imdb_id=r.imdb_id
ORDER BY r.vote_count DESC
LIMIT 10;
-- 8. Which movie genre are in the database?
SELECT DISTINCT genre_name
FROM genre;
-- 9. Which genre appears the most in films?
SELECT g.genre_name, COUNT(*) AS genre_count
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
GROUP BY g.genre_name
ORDER BY genre_count DESC
LIMIT 1;

-- 10. Do big-budget movies tend to have higher IMDb ratings?
SELECT CASE
           WHEN budget > (SELECT AVG(budget) FROM finance) THEN 'High Budget'
           ELSE 'Low Budget'
		END AS budget_category,
        AVG(r.avg_rating) AS avg_imdb_rating
FROM finance fi
JOIN ratings r on fi.imdb_id = r.imdb_id
GROUP BY budget_category;
        
-- 11. Which movies had the highest profit margins?
SELECT f.film_title, ((fi.revenue - fi.budget) / fi.revenue) * 100  AS profit_margin
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
ORDER BY profit_margin DESC
LIMIT 5;

-- 12. Which genres have the highest average IMDb ratings?
SELECT g.genre_name, AVG(r.avg_rating) AS avg_rating
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
JOIN ratings r ON gf.imdb_id = r.imdb_id
GROUP BY g.genre_name
ORDER BY avg_rating DESC;

-- 13. Which are the highest-grossing movies per genre?
SELECT g.genre_name, f.film_title, MAX(fi.revenue) AS max_revenue
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
JOIN finance fi ON gf.imdb_id = fi.imdb_id
JOIN films f ON gf.imdb_id = f.imdb_id
GROUP BY g.genre_name, f.film_title
ORDER BY max_revenue DESC
LIMIT 20;

-- 14. Do movies with more votes tend to have higher IMDb ratings?
SELECT CASE 
           WHEN vote_count > (SELECT AVG(vote_count) FROM ratings) THEN 'High Votes'
           ELSE 'Low Votes' 
       END AS Vote_Category,
       AVG(avg_rating) AS avg_imdb_rating
FROM ratings
GROUP BY Vote_Category;

-- 15. Find the top 3 highest-rated movies for each genre.
WITH ranked_movies AS (
    SELECT 
        g.genre_name, 
        f.film_title, 
        r.avg_rating,
        ROW_NUMBER() OVER (PARTITION BY g.genre_name ORDER BY r.avg_rating DESC) as movie_rank
    FROM genre g
    JOIN genre_film gf ON g.genre_id = gf.genre_id
    JOIN ratings r ON gf.imdb_id = r.imdb_id
    JOIN films f ON gf.imdb_id = f.imdb_id
    WHERE r.avg_rating IS NOT NULL
)
SELECT genre_name, film_title, avg_rating
FROM ranked_movies
WHERE movie_rank <= 3
ORDER BY genre_name, avg_rating DESC;

-- 16. Identify movies where the budget was above the average budget of their genre.
SELECT f.film_title, g.genre_name, fi.budget
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
JOIN genre_film gf ON f.imdb_id= gf.imdb_id
JOIN genre g ON gf.genre_id = g.genre_id
WHERE fi.budget > (SELECT AVG(fi.budget) FROM finance fi);

-- 17. Determine the percentage of movies that made a profit per decade.
SELECT FLOOR(YEAR(f.release_date)/10)*10 AS decade,
       COUNT(CASE WHEN fi.revenue > fi.budget THEN 1 END) * 100.0 / COUNT(*) AS profit_percentage
FROM films f
JOIN finance fi ON f.imdb_id = fi.imdb_id
GROUP BY decade;

-- 18. Find the most profitable genre based on total revenue.
SELECT g.genre_name, SUM(fi.revenue) AS total_revenue
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
JOIN finance fi ON gf.imdb_id = fi.imdb_id
GROUP BY g.genre_name
ORDER BY total_revenue DESC
LIMIT 1;

-- 19. Retrieve the top 10 highest-rated movies, sorted in descending order.
SELECT f.film_title, r.avg_rating
FROM films f
JOIN ratings r ON f.imdb_id = r.imdb_id
ORDER BY r.avg_rating DESC
LIMIT 10;

-- 20. Find the top 10 most profitable movies based on ROI.
SELECT f.film_title, ((finance.revenue - finance.budget) / finance.budget) * 100 AS ROI
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
ORDER BY ROI DESC
LIMIT 10;

-- 21. List the top 10 movies with the highest budgets.
SELECT f.film_title, finance.budget
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
ORDER BY finance.budget DESC
LIMIT 10;

-- 22. Identify the most profitable movie per genre, sorted by ROI.
SELECT g.genre_name, f.film_title, ((finance.revenue - finance.budget) / finance.budget) * 100 AS ROI
FROM genre g
JOIN genre_film gf ON g.genre_id = gf.genre_id
JOIN finance ON gf.imdb_id = finance.imdb_id
JOIN films f ON gf.imdb_id = f.imdb_id
ORDER BY g.genre_name, ROI DESC
LIMIT 1;

-- 23. Retrieve the 5 most recent movies that earned over $500 million.
SELECT f.film_title, finance.revenue, f.release_date
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
WHERE finance.revenue > 500000000
ORDER BY f.release_date DESC
LIMIT 5;
-- 24. Categorize movies into Low, Medium, and High budget categories based on their budget.
SELECT f.film_title, 
       CASE 
           WHEN finance.budget < 10e6 THEN 'Low'
           WHEN finance.budget BETWEEN 10e6 AND 50e6 THEN 'Medium'
           ELSE 'High'
       END AS budget_category
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id;

-- 25. Create a column labeling movies as "Blockbuster" if revenue > 500M, "Successful" if 100M-500M, "Moderate" if 10M-100M, "Indie" if <10M.
SELECT f.film_title, 
       CASE 
           WHEN finance.revenue > 50e7 THEN 'Blockbuster'
           WHEN finance.revenue BETWEEN 10e7 AND 50e7 THEN 'Successful'
           WHEN finance.revenue BETWEEN 10e6 AND 10e7 THEN 'Moderate'
           ELSE 'Indie'
       END AS movie_category
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id;

-- 26. Find the percentage of movies in each budget category that earned a profit.
SELECT budget_category, 
       COUNT(CASE WHEN finance.revenue > finance.budget THEN 1 END) * 100.0 / COUNT(*) AS profit_percentage
FROM (
    SELECT f.film_title, finance.revenue, finance.budget,
           CASE 
               WHEN finance.budget < 10000000 THEN 'Low'
               WHEN finance.budget BETWEEN 10000000 AND 50000000 THEN 'Medium'
               ELSE 'High'
           END AS budget_category
    FROM films f
    JOIN finance ON f.imdb_id = finance.imdb_id
) AS budget_data
GROUP BY budget_category;
-- 27. Retrieve movies where the budget was above the average budget of their release year.
SELECT f.film_title, f.release_date, finance.budget
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
WHERE finance.budget > (
    SELECT AVG(finance.budget)
    FROM finance
    JOIN films f2 ON finance.imdb_id = f2.imdb_id
    WHERE YEAR(f2.release_date) = YEAR(f.release_date)
);

-- 28. Identify the top 5 most profitable movies per genre using a subquery.
SELECT g.genre_name, f.film_title, ranked_movies.profit
FROM (
    SELECT gf.genre_id, f.imdb_id, (fi.revenue - fi.budget) AS profit,
           RANK() OVER (PARTITION BY gf.genre_id ORDER BY (fi.revenue - fi.budget) DESC) AS movie_rank
    FROM genre_film gf
    JOIN films f ON gf.imdb_id = f.imdb_id
    JOIN finance fi ON f.imdb_id = fi.imdb_id
) ranked_movies
JOIN films f ON ranked_movies.imdb_id = f.imdb_id
JOIN genre g ON ranked_movies.genre_id = g.genre_id
WHERE ranked_movies.movie_rank <= 5
ORDER BY g.genre_name, ranked_movies.profit DESC;


-- 29. Find the highest-budget movie per decade.
SELECT decade, film_title, budget
FROM (
    SELECT f.film_title, finance.budget,
           FLOOR(YEAR(f.release_date) / 10) * 10 AS decade,
           RANK() OVER (PARTITION BY FLOOR(YEAR(f.release_date) / 10) * 10 ORDER BY finance.budget DESC) AS movie_rank
    FROM films f
    JOIN finance ON f.imdb_id = finance.imdb_id
) ranked_movies
WHERE movie_rank = 1;

-- 30. Calculate the average, max, min, and standard deviation of movie budgets.
SELECT 
    AVG(finance.budget) AS avg_budget,
    MAX(finance.budget) AS max_budget,
    MIN(finance.budget) AS min_budget,
    STDDEV(finance.budget) AS stddev_budget
FROM finance;

-- 31. Find the highest-rated movie and lowest-rated movie per decade.
SELECT 
    decade, 
    film_title, 
    avg_rating, 
    CASE 
        WHEN high_rank = 1 THEN 'Highest Rated' 
        WHEN low_rank = 1 THEN 'Lowest Rated' 
    END AS rating_type
FROM (
    SELECT 
        f.film_title, 
        r.avg_rating, 
        FLOOR(YEAR(f.release_date) / 10) * 10 AS decade,
        RANK() OVER (PARTITION BY FLOOR(YEAR(f.release_date) / 10) * 10 ORDER BY r.avg_rating DESC) AS high_rank,
        RANK() OVER (PARTITION BY FLOOR(YEAR(f.release_date) / 10) * 10 ORDER BY r.avg_rating ASC) AS low_rank
    FROM films f
    JOIN ratings r ON f.imdb_id = r.imdb_id
) ranked_movies
WHERE high_rank = 1 OR low_rank = 1
ORDER BY decade, rating_type DESC;

-- 32. Determine the decade with the highest average revenue.
SELECT FLOOR(YEAR(f.release_date) / 10) * 10 AS decade, AVG(finance.revenue) AS avg_revenue
FROM films f
JOIN finance ON f.imdb_id = finance.imdb_id
GROUP BY decade
ORDER BY avg_revenue DESC
LIMIT 1;

-- 33. Find the year with the highest and lowest standard deviation in movie budgets.
WITH budget_stddev_by_year AS (
    SELECT 
        YEAR(f.release_date) AS year, 
        STDDEV(finance.budget) AS stddev_budget,
        COUNT(*) AS movie_count
    FROM films f
    JOIN finance ON f.imdb_id = finance.imdb_id
    WHERE finance.budget IS NOT NULL
    GROUP BY year
    HAVING COUNT(*) > 5  
)

SELECT 
    year,
    stddev_budget,
    movie_count,
    CASE 
        WHEN stddev_budget = (SELECT MAX(stddev_budget) FROM budget_stddev_by_year) THEN 'Highest Variation'
        WHEN stddev_budget = (SELECT MIN(stddev_budget) FROM budget_stddev_by_year) THEN 'Lowest Variation'
    END AS variation_type
FROM budget_stddev_by_year
WHERE stddev_budget = (SELECT MAX(stddev_budget) FROM budget_stddev_by_year)
   OR stddev_budget = (SELECT MIN(stddev_budget) FROM budget_stddev_by_year)
ORDER BY stddev_budget DESC;

-- 34. Find the top 3 most profitable movies for each genre using GROUP BY and ORDER BY.
WITH genre_profits AS (
    SELECT 
        g.genre_name,
        f.film_title,
        (finance.revenue - finance.budget) AS profit,
        AVG(finance.revenue - finance.budget) OVER (PARTITION BY g.genre_id) AS avg_genre_profit,
        RANK() OVER (PARTITION BY g.genre_id ORDER BY (finance.revenue - finance.budget) DESC) AS profit_rank
    FROM films f
    JOIN finance ON f.imdb_id = finance.imdb_id
    JOIN genre_film gf ON f.imdb_id = gf.imdb_id
    JOIN genre g ON gf.genre_id = g.genre_id
    WHERE finance.revenue IS NOT NULL 
      AND finance.budget IS NOT NULL
    GROUP BY g.genre_id, g.genre_name, f.imdb_id, f.film_title, finance.revenue, finance.budget
)

SELECT 
    genre_name,
    film_title,
    profit,
    ROUND(avg_genre_profit, 2) AS avg_genre_profit
FROM genre_profits
WHERE profit_rank <= 3
ORDER BY genre_name, profit_rank;

-- 35. Identify movies that are rated highly (above 8.0) and also financially successful (ROI > 100%).
SELECT 
    f.film_title, 
    r.avg_rating,
    finance.budget,
    finance.revenue,
    ((finance.revenue - finance.budget) / finance.budget) * 100 AS roi_percentage
FROM films f
JOIN ratings r ON f.imdb_id = r.imdb_id
JOIN finance ON f.imdb_id = finance.imdb_id
WHERE r.avg_rating > 8.0 
  AND finance.budget > 0  -- Avoid division by zero
  AND ((finance.revenue - finance.budget) / finance.budget) > 1  -- ROI > 100%
ORDER BY roi_percentage DESC;

-- 36. Determine whether higher budgets correlate with higher IMDb ratings.
SELECT 
    CASE 
        WHEN finance.budget > (SELECT AVG(budget) FROM finance) THEN 'High Budget'
        ELSE 'Low Budget'
    END AS budget_category,
    AVG(r.avg_rating) AS avg_rating
FROM films f
JOIN ratings r ON f.imdb_id = r.imdb_id
JOIN finance ON f.imdb_id = finance.imdb_id
GROUP BY budget_category;

-- 37. Find the average IMDb rating of movies that were both high-budget and high-profit.
WITH budget_stats AS (
    SELECT 
        AVG(budget) AS avg_budget,
        STDDEV(budget) AS stddev_budget
    FROM finance
    WHERE budget > 0  
)
SELECT 
    ROUND(AVG(r.avg_rating), 2) AS avg_rating_high_budget_high_profit,
    COUNT(*) AS movie_count
FROM films f
JOIN ratings r ON f.imdb_id = r.imdb_id
JOIN finance ON f.imdb_id = finance.imdb_id
CROSS JOIN budget_stats bs
WHERE finance.budget > bs.avg_budget  
AND finance.revenue > 2 * finance.budget  
AND finance.budget IS NOT NULL
AND finance.revenue IS NOT NULL;