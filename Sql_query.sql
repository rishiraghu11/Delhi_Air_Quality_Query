CREATE DATABASE Delhi_Air_Quality;

DROP TABLE IF EXISTS delhi_air_quality;

CREATE TABLE delhi_air_quality (
    id SERIAL PRIMARY KEY,
    date_day SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    holidays_count SMALLINT NOT NULL,
    day_of_week SMALLINT NOT NULL,
    pm25 NUMERIC(10,2) NOT NULL,
    pm10 NUMERIC(10,2) NOT NULL,
    no2 NUMERIC(10,2) NOT NULL,
    so2 NUMERIC(10,2) NOT NULL,
    co NUMERIC(10,2) NOT NULL,
    ozone NUMERIC(10,2) NOT NULL,
    aqi INT NOT NULL
);

COPY public.delhi_air_quality(
    date_day, month, year, holidays_count, day_of_week,
    pm25, pm10, no2, so2, co, ozone, aqi
)
FROM 'C:/Users/Acer Nitro 5/Desktop/Delhi_Air_Quality_Dataset.csv'
WITH (
    FORMAT csv,
    DELIMITER ';',
    HEADER true
);

SELECT * FROM delhi_air_quality;

--1. Average AQI (Overall)

SELECT ROUND(AVG(AQI), 2) AS avg_aqi
FROM delhi_air_quality;

--2. Worst AQI Day

SELECT date_day, month, year, aqi
FROM delhi_air_quality
ORDER BY aqi DESC
LIMIT 1;

--3. Count of Hazardous Days (AQI > 300)

SELECT COUNT(*) AS hazardous_days
FROM delhi_air_quality
WHERE AQI > 300;

--4. Average Pollutant Levels
SELECT 
    ROUND(AVG(PM25), 2) AS avg_pm25,
    ROUND(AVG(PM10), 2) AS avg_pm10,
    ROUND(AVG(NO2), 2) AS avg_no2,
    ROUND(AVG(SO2), 2) AS avg_so2,
    ROUND(AVG(CO), 2) AS avg_co,
    ROUND(AVG(Ozone), 2) AS avg_ozone
FROM delhi_air_quality;

--5. Holidays vs Non-Holidays AQI
SELECT 
    CASE WHEN Holidays_Count > 0 THEN 'Holiday' ELSE 'Non-Holiday' END AS day_type,
    ROUND(AVG(AQI), 2) AS avg_aqi
FROM delhi_air_quality
GROUP BY day_type;

-- Stations Table
CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100),
    location VARCHAR(100)
);

-- Pollutants Table
CREATE TABLE pollutants (
    pollutant_id SERIAL PRIMARY KEY,
    pollutant_name VARCHAR(50),
    description TEXT
);

-- Weather Table
CREATE TABLE weather (
    weather_id SERIAL PRIMARY KEY,
    full_date DATE,
    temperature DECIMAL(5,2),
    humidity DECIMAL(5,2),
    wind_speed DECIMAL(5,2)
);

-- Holidays Table
CREATE TABLE holidays (
    holiday_id SERIAL PRIMARY KEY,
    full_date DATE,
    holiday_name VARCHAR(100)
);


-- Stations
INSERT INTO stations (station_name, location) VALUES
('Anand Vihar', 'East Delhi'),
('RK Puram', 'South Delhi'),
('Punjabi Bagh', 'West Delhi'),
('ITO', 'Central Delhi');

-- Pollutants
INSERT INTO pollutants (pollutant_name, description) VALUES
('PM2.5', 'Particulate matter less than 2.5 microns'),
('PM10', 'Particulate matter less than 10 microns'),
('NO2', 'Nitrogen Dioxide'),
('SO2', 'Sulphur Dioxide'),
('CO', 'Carbon Monoxide'),
('Ozone', 'Ground-level ozone');

-- Weather
INSERT INTO weather (full_date, temperature, humidity, wind_speed) VALUES
('2021-01-01', 14.5, 60.2, 2.3),
('2021-01-02', 15.0, 58.1, 2.5),
('2021-01-03', 13.8, 65.0, 2.1),
('2021-01-04', 14.2, 63.5, 1.9);

-- Holidays
INSERT INTO holidays (full_date, holiday_name) VALUES
('2021-01-01', 'New Year'),
('2021-01-26', 'Republic Day'),
('2021-03-29', 'Holi'),
('2021-08-15', 'Independence Day');

SELECT * FROM Stations;
SELECT * FROM pollutants;
SELECT * FROM weather;
SELECT * FROM holidays;

--Joins realted queries

--6. Average AQI on Holidays
SELECT 
    h.holiday_name, 
    ROUND(AVG(a.aqi), 2) AS avg_aqi
FROM delhi_air_quality a
JOIN holidays h
    ON MAKE_DATE(a.year, a.month, a.date_day) = h.full_date
GROUP BY h.holiday_name
ORDER BY avg_aqi DESC;

--7. Weather Impact: AQI vs Temperature
--Compare daily AQI with average temperature.

SELECT 
    w.full_date,
    ROUND(AVG(a.aqi), 2) AS avg_aqi,
    ROUND(AVG(w.temperature), 2) AS avg_temperature
FROM delhi_air_quality a
JOIN weather w
    ON MAKE_DATE(a.year, a.month, a.date_day) = w.full_date
GROUP BY w.full_date
ORDER BY w.full_date;


INSERT INTO weather_info (full_date, temperature, humidity, wind_speed) VALUES
('2021-01-01', 15.2, 45.6, 3.5),
('2021-01-02', 14.8, 50.2, 2.8),
('2021-01-03', 12.5, 48.0, 4.1),
('2021-01-04', 13.9, 55.3, 3.2);

SELECT * FROM weather_info;

--8. Weather Conditions During Worst AQI Day
--Find the weather details on the most polluted day.

WITH worst_day AS (
    SELECT 
        MAKE_DATE(year, month, date_day) AS full_date,
        aqi
    FROM delhi_air_quality
    ORDER BY aqi DESC
    LIMIT 1
)
SELECT 
    w.full_date,
    w.temperature,
    w.humidity,
    w.wind_speed,
    a.aqi
FROM worst_day wd
JOIN weather w
    ON wd.full_date = w.full_date
JOIN delhi_air_quality a
    ON w.full_date = MAKE_DATE(a.year, a.month, a.date_day)
ORDER BY a.aqi DESC
LIMIT 1;

--9. Correlation Between Wind Speed & AQI

SELECT 
    CORR(a.aqi, w.wind_speed) AS corr_wind_aqi
FROM delhi_air_quality a
JOIN weather w
    ON MAKE_DATE(a.year, a.month, a.date_day) = w.full_date;
Purpose: Correlation coefficient (-1 = strong negative, +1 = strong positive).

--10. Monthly AQI % Change

SELECT Year, Month,
       ROUND(AVG(AQI), 2) AS avg_aqi,
       ROUND(
         (AVG(AQI) - LAG(AVG(AQI)) OVER (ORDER BY Year, Month)) 
         / LAG(AVG(AQI)) OVER (ORDER BY Year, Month) * 100, 2
       ) AS pct_change
FROM delhi_air_quality
GROUP BY Year, Month
ORDER BY Year, Month;

--11. 7-Day Rolling Average AQI

SELECT date_day, Month, Year, AQI,
       ROUND(AVG(AQI) OVER (ORDER BY Year, Month, date_day ROWS 6 PRECEDING), 2) 
	   AS rolling_avg_7
FROM delhi_air_quality;

--12. Pollution Spike Detection (Mean + 2×StdDev)

WITH stats AS (
    SELECT AVG(AQI) AS mean_aqi, STDDEV(AQI) AS stddev_aqi
    FROM delhi_air_quality
)
SELECT d.date_day, d.Month, d.Year, d.AQI
FROM delhi_air_quality d
JOIN stats s
  ON d.AQI > (s.mean_aqi + 2 * s.stddev_aqi)
ORDER BY d.AQI DESC;

--13. Longest Consecutive Hazardous Streak (AQI > 300)

WITH flagged AS (
    SELECT 
        date_day,
        month,
        year,
        aqi,
        CASE WHEN aqi > 300 THEN 1 ELSE 0 END AS is_high
    FROM delhi_air_quality
),
grouped AS (
    SELECT *,
           SUM(CASE WHEN is_high = 0 THEN 1 ELSE 0 END) 
           OVER (ORDER BY year, month, date_day) AS grp
    FROM flagged
),
streaks AS (
    SELECT grp, COUNT(*) AS streak_length
    FROM grouped
    WHERE is_high = 1
    GROUP BY grp
)
SELECT MAX(streak_length) AS longest_streak
FROM streaks;


--14. Primary Pollutant by Month

SELECT Year, Month,
       CASE
         WHEN AVG(PM25) >= GREATEST(AVG(PM10), AVG(NO2), AVG(SO2), AVG(CO), AVG(Ozone)) THEN 'PM2.5'
         WHEN AVG(PM10) >= GREATEST(AVG(PM25), AVG(NO2), AVG(SO2), AVG(CO), AVG(Ozone)) THEN 'PM10'
         WHEN AVG(NO2) >= GREATEST(AVG(PM25), AVG(PM10), AVG(SO2), AVG(CO), AVG(Ozone)) THEN 'NO2'
         WHEN AVG(SO2) >= GREATEST(AVG(PM25), AVG(PM10), AVG(NO2), AVG(CO), AVG(Ozone)) THEN 'SO2'
         WHEN AVG(CO) >= GREATEST(AVG(PM25), AVG(PM10), AVG(NO2), AVG(SO2), AVG(Ozone)) THEN 'CO'
         ELSE 'Ozone'
       END AS primary_pollutant
FROM delhi_air_quality
GROUP BY Year, Month
ORDER BY Year, Month;

--15. Turn raw AQI into categories dynamically.

SELECT 
    date_day,
    aqi,
    CASE 
        WHEN aqi <= 50 THEN 'Good'
        WHEN aqi <= 100 THEN 'Moderate'
        WHEN aqi <= 200 THEN 'Poor'
        WHEN aqi <= 300 THEN 'Very Poor'
        ELSE 'Severe'
    END AS aqi_category
FROM delhi_air_quality;

--16. Find the worst month for each year.

SELECT DISTINCT year, month, aqi
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY year ORDER BY aqi DESC) AS rank_in_year
    FROM delhi_air_quality
) t
WHERE rank_in_year = 1;

SELECT 
    date_day,
    aqi,
    RANK() OVER (ORDER BY aqi DESC) AS worst_rank,
    LAG(aqi) OVER (ORDER BY date_day) AS prev_day_aqi,
    aqi - LAG(aqi) OVER (ORDER BY date_day) AS day_to_day_change
FROM delhi_air_quality;

--17. Shows how pollution changes for the same day each year.

SELECT 
    month,
    date_day,
    year,
    aqi,
    aqi - LAG(aqi) OVER (PARTITION BY month, date_day ORDER BY year) AS yoy_change
FROM delhi_air_quality;

--18. Find AQI thresholds percentile per year.

SELECT
    year,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY aqi) AS aqi_90th_percentile
FROM delhi_air_quality
GROUP BY year
ORDER BY year;

