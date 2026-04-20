-- Data Cleaning


SELECT *
FROM layoffs;

-- 1. Reomve Duplicates
-- 2. Stanardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns


-- Create Staging Table
CREATE TABLE layoffs_staging
LIKE layoffs;


SELECT *
FROM layoffs_staging;

-- Copy Original Data into Staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- ___________________________________________________________

-- Identify Duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off,percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;


-- Detect Full Duplicate Records (CTE)
WITH duplicates_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off,percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Create Clean Table to Add row_num Column
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Identify Duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Insert Data with Row Numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off,percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete Duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- The New Table without Duplicates
SELECT *
FROM layoffs_staging2;

-- _______________________________________________________
-- Standardizing data

-- Clean Company Names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize Industry Values
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Clean Country Names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';

-- Convert Date Format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- _______________________________________________________
-- Handling Missing Values

-- Identify Missing Data
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Convert Empty Strings to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill Missing Industry Using Same Company Data
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Remove Incomplete Rows
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- _______________________________________
-- THE FINAL CLEANED DATA
SELECT *
FROM layoffs_staging2;

-- Drop Helper Column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

