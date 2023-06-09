/* SQL PORTFOLIO PROJECT WITH OLYMPICS DATASET*/

--1. How many olympics games have been held?

SELECT COUNT(DISTINCT games) AS total_olympics_games
FROM olympic_history;
---------------------------------------------------------------------------------------------------------------------------------------------------------
--2.List down all Olympics games held so far.

SELECT distinct year,season,city
FROM olympic_history
ORDER BY year;
---------------------------------------------------------------------------------------------------------------------------------------------------------
--3.Mention the total no of nations who participated in each olympics game?

WITH all_countries AS
(
	SELECT region,games
	FROM olympic_history
	JOIN noc_regions ON noc_regions.noc = olympic_history.noc
	GROUP BY games, region
)
SELECT games, COUNT(region) AS participating_nations
FROM all_countries
GROUP BY games
ORDER BY games
---------------------------------------------------------------------------------------------------------------------------------------------------------
--4.Which year saw the highest and lowest no of countries participating in olympics?

WITH l_nations AS
(SELECT COUNT(DISTINCT r.region) AS lowest_nations, 
 		o.games
FROM olympic_history o
JOIN noc_regions r ON o.noc = r.noc
GROUP BY o.games
ORDER BY lowest_nations
LIMIT 1),

h_nations AS
(SELECT COUNT(DISTINCT r.region) AS highest_nations, 
 		o.games
FROM olympic_history o
JOIN noc_regions r ON o.noc = r.noc
GROUP BY o.games
ORDER BY highest_nations DESC
LIMIT 1)

SELECT l.games || ' - ' || l.lowest_nations AS  lowest_countries,
	   h.games || ' - ' || h.highest_nations AS highest_countries
FROM l_nations l, h_nations h
---------------------------------------------------------------------------------------------------------------------------------------------------------
--5.Which nation has participated in all of the olympic games?

WITH unique_games AS
(SELECT  DISTINCT o.games,
		r.region
FROM olympic_history o
JOIN noc_regions r ON r.noc = o.noc
ORDER BY r.region,o.games),

participation AS
(SELECT  *,
		ROW_NUMBER() OVER (PARTITION BY region) AS years_participated
FROM unique_games)

SELECT  region,
		MAX(years_participated) AS total_participated_games
FROM participation
WHERE years_participated = (SELECT COUNT(DISTINCT games) FROM olympic_history )
GROUP BY region
---------------------------------------------------------------------------------------------------------------------------------------------------------
--6.Identify the sport which was played in all summer olympics.

WITH t1 AS
	(SELECT DISTINCT sport,games
	 FROM olympic_history
	 WHERE season = 'Summer'
	 ORDER BY games
	),
	
	t2 AS
	(SELECT sport, COUNT(games) AS no_of_games
	 FROM t1
	 GROUP BY sport
	)
	
SELECT *
FROM t2
WHERE no_of_games = (SELECT COUNT(DISTINCT games)
			FROM olympic_history
			WHERE season = 'Summer')
---------------------------------------------------------------------------------------------------------------------------------------------------------
--7.Which Sports were just played only once in the olympics?

WITH t1 AS
	(SELECT DISTINCT sport, games
	FROM olympic_history
	ORDER BY sport),
	
	t2 AS
	(SELECT *,
			ROW_NUMBER() OVER (PARTITION BY sport) AS no_of_olympics
	FROM t1),
	
	j1 AS
	(SELECT *
	FROM t2
	WHERE no_of_olympics >=2),
	
	j2 AS
	(SELECT *
	FROM t2)

SELECT j2.sport,j2.no_of_olympics,j2.games
FROM j2
LEFT JOIN j1 ON j1.sport = j2.sport
WHERE j1.sport IS NULL
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--8.Fetch the total no of sports played in each olympic games

WITH t1 AS
	(SELECT DISTINCT games,sport
	FROM olympic_history
	ORDER BY games),
	
	t2 AS
	(SELECT *,
	 		ROW_NUMBER() OVER (PARTITION BY games) AS no_of_games
	 FROM t1
	)
	
SELECT games,MAX(no_of_games) AS total_sports
FROM t2
GROUP BY games
ORDER BY total_sports DESC
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--9.Fetch details of the oldest athletes to win a gold medal

SELECT name,sex,age,team,games,city,medal
FROM olympic_history
WHERE medal = 'Gold' AND age in (SELECT MAX(age)
								FROM olympic_history
								WHERE age !='NA' AND medal = 'Gold')
ORDER BY age DESC
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--10.Find the Ratio of male and female athletes participated in all olympic games.

WITH male AS
	(SELECT COUNT(sex) AS male_count
	FROM olympic_history WHERE sex = 'M'),
	
	female AS
	(SELECT COUNT(sex) AS female_count
	FROM olympic_history WHERE sex = 'F') 

SELECT '1 : '||(male_count::DECIMAL / female_count::DECIMAL) AS ratio
FROM male,female
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--11.Fetch the top 5 athletes who have won the most gold medals.

WITH t1 AS
	(SELECT name, team,COUNT(medal) AS no_of_gold_medals
	FROM olympic_history
	WHERE medal = 'Gold'
	GROUP BY name,team
	ORDER BY no_of_gold_medals DESC),
	
	t2 AS
	(SELECT *,
	 		DENSE_RANK() OVER (ORDER BY no_of_gold_medals DESC) AS  gold_rank
	 FROM t1
	)
	
SELECT name,team,no_of_gold_medals
FROM t2
WHERE gold_rank <=5
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

WITH t1 AS
		(SELECT name, team, COUNT(medal) AS medal_count
		FROM olympic_history
		WHERE medal IN ('Gold','Silver','Bronze')
		GROUP BY name, team
		ORDER BY medal_count DESC),
		
	t2 AS
		(SELECT *,
		 		DENSE_RANK() OVER (ORDER BY medal_count DESC) AS medal_rank
		 FROM t1
		)
SELECT name, team,medal_count
FROM t2
WHERE medal_rank <=5
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

WITH t1 AS
		(SELECT r.region, COUNT(o.medal) AS medal_count
		FROM olympic_history o
		JOIN noc_regions r ON r.noc = o.noc
		WHERE o.medal IN ('Gold','Silver','Bronze')
		GROUP BY r.region
		ORDER BY medal_count DESC),
	t2 AS
		(SELECT *,
		 		DENSE_RANK() OVER (ORDER BY medal_count DESC) AS medal_rank
		 FROM t1
		)
		
SELECT region, medal_count, medal_rank
FROM t2
WHERE medal_rank <=5
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--14.List down total gold, silver and broze medals won by each country.

WITH gold AS
		(SELECT r.region, COUNT(o.medal) AS gold_medal_count
		FROM olympic_history o
		JOIN noc_regions r ON r.noc = o.noc
		WHERE o.medal = 'Gold'
		GROUP BY r.region
		ORDER BY gold_medal_count DESC),
	
	silver AS
		(SELECT r.region, COUNT(o.medal) AS silver_medal_count
		FROM olympic_history o
		JOIN noc_regions r ON r.noc = o.noc
		WHERE o.medal = 'Silver'
		GROUP BY r.region
		ORDER BY silver_medal_count DESC),
	
	bronze AS
		(SELECT r.region, COUNT(o.medal) AS bronze_medal_count
		FROM olympic_history o
		JOIN noc_regions r ON r.noc = o.noc
		WHERE o.medal = 'Bronze'
		GROUP BY r.region
		ORDER BY bronze_medal_count DESC)
		
SELECT DISTINCT nr.region, 
		gold.gold_medal_count, 
		silver.silver_medal_count,
		bronze.bronze_medal_count
FROM noc_regions nr
JOIN gold ON gold.region = nr.region
JOIN silver ON silver.region = gold.region
JOIN bronze ON silver.region = bronze.region
ORDER BY gold.gold_medal_count DESC
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--15. In which Sport/event, India has won highest medals.

WITH t1 AS
	(SELECT sport, COUNT(medal) AS medal_count 
	FROM olympic_history
	WHERE team = 'India' AND medal NOT LIKE 'NA'
	GROUP BY sport
	ORDER BY medal_count DESC),
	
	t2 AS 
	(SELECT *,
	 		RANK() OVER (ORDER BY medal_count DESC) AS rnk
	 FROM t1
	)
	
SELECT sport, medal_count 
FROM t2
WHERE rnk = 1
---------------------------------------------------------------------------------------------------------------------------------------------------------	
--16.Which countries have never won gold medal but have won silver/bronze medals?

(SELECT r.region
FROM olympic_history o
JOIN noc_regions r ON r.noc = o.noc
GROUP BY r.region)

EXCEPT

(SELECT r.region
FROM olympic_history o
JOIN noc_regions r ON r.noc = o.noc
WHERE o.medal = 'Gold'
GROUP BY r.region)
---------------------------------------------------------------------------------------------------------------------------------------------------------	
---------------------------------------------------------------------------------------------------------------------------------------------------------	


