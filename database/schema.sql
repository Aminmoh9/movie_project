-- Create Database
CREATE DATABASE movie_db;
USE movie_db;

-- Genre Table
CREATE TABLE genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(255) NOT NULL UNIQUE
);

-- Films Table
CREATE TABLE films (
    imdb_id VARCHAR(20) PRIMARY KEY,
    film_title VARCHAR(255) NOT NULL,
    release_date DATE NOT NULL
);

-- Finance Table
CREATE TABLE finance (
    finance_id INT AUTO_INCREMENT PRIMARY KEY,
    imdb_id VARCHAR(20),
    budget DECIMAL(15,2) NOT NULL,
    revenue DECIMAL(15,2) NOT NULL,
    UNIQUE (imdb_id),  -- Ensure one rating per film
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE
);

-- Ratings Table (Fixed primary key issue)
CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY, 
    imdb_id VARCHAR(20),
    avg_rating FLOAT NOT NULL,
    vote_count INT NOT NULL,
    UNIQUE (imdb_id),  -- Ensure one rating per film
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE
);

-- Junction Table for Many-to-Many Relationship Between Films and Genres
CREATE TABLE genre_film (
    imdb_id VARCHAR(20),
    genre_id INT,
    PRIMARY KEY (imdb_id, genre_id),
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id) ON DELETE CASCADE
);

-- Film_Info Table (Additional metadata for films)
CREATE TABLE film_info (
    imdb_id VARCHAR(20) PRIMARY KEY,
    id_kaggle VARCHAR(50) UNIQUE,  -- Optional ID from Kaggle dataset
    runtime INT,  -- Runtime in minutes
    original_language VARCHAR(10),
    overview TEXT,
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE
);

-- Production Company Table (Stores production company details)
CREATE TABLE production_company (
    company_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL UNIQUE
);

-- Film_Company Table (Many-to-Many relationship between films and production companies)
CREATE TABLE film_company (
    imdb_id VARCHAR(20),
    company_id INT,
    PRIMARY KEY (imdb_id, company_id),
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES production_company(company_id) ON DELETE CASCADE
);

-- Production Countries Table (Stores country details)
CREATE TABLE production_country (
    country_code VARCHAR(10) PRIMARY KEY,
    country_name VARCHAR(255) NOT NULL UNIQUE
);

-- Film_Country Table (Fixed foreign key issue with auto-increment ID)
CREATE TABLE film_country (
    id INT AUTO_INCREMENT PRIMARY KEY,
    imdb_id VARCHAR(20),
    country_code VARCHAR(10),
    UNIQUE (imdb_id, country_code), -- Ensuring uniqueness
    FOREIGN KEY (imdb_id) REFERENCES films(imdb_id) ON DELETE CASCADE,
    FOREIGN KEY (country_code) REFERENCES production_country(country_code) ON DELETE CASCADE
);
