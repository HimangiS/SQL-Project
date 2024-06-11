CREATE TABLE IPL_Ball (
    ID INT,
    inning INT,
    over INT,
    ball INT,
    batsman VARCHAR(255),
    non_striker VARCHAR(255),
    bowler VARCHAR(255),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket BOOLEAN,
    dismissal_kind VARCHAR(255),
    player_dismissed VARCHAR(255),
    fielder VARCHAR(255),
    extras_type VARCHAR(255),
    batting_team VARCHAR(255),
    bowling_team VARCHAR(255)
);

select * from IPL_ball;

CREATE TABLE IPL_Matches (
    ID INT,
    city VARCHAR(255),
    date DATE,
    player_of_match VARCHAR(255),
    venue VARCHAR(255),
    neutral_venue BOOLEAN,
    team1 VARCHAR(255),
    team2 VARCHAR(255),
    toss_winner VARCHAR(255),
    toss_decision VARCHAR(255),
    winner VARCHAR(255),
    result VARCHAR(255),
    result_margin VARCHAR(255),
    eliminator VARCHAR(255),
    method VARCHAR(255),
    umpire1 VARCHAR(255),
    umpire2 VARCHAR(255)
);

select * from IPL_matches;

COPY IPL_ball
FROM 'C:\Program Files\PostgreSQL\16\data\data copy\IPL_ball.csv'
DELIMITER ',' CSV HEADER;


SET datestyle = 'ISO, DMY';  -- Set datestyle to 'Day, Month, Year'
COPY IPL_matches
FROM 'C:\Program Files\PostgreSQL\16\data\data copy\IPL_matches.csv'
DELIMITER ',' CSV HEADER;

RESET datestyle;  -- Reset datestyle to default


/*Q1 -- Your first priority is to get 2-3 players with high S.R who have faced at least 500 balls.And to do that you have to make a list of 10 players you want to bid in the auction so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player*/

/*Q1*/

SELECT batsman, 
       SUM(batsman_runs) AS total_runs,
       COUNT(*) AS balls_faced,
       SUM(batsman_runs) * 1.0 / COUNT(*) AS strike_rate
FROM ipl_ball
GROUP BY batsman
HAVING COUNT(*) >= 500
ORDER BY strike_rate DESC
LIMIT 10;

/*answer - here are 2-3 players with high strike rates who have faced at least 500 balls:

1. AD Russell: Strike Rate = 1.719954649
2. SP Narine: Strike Rate = 1.556719023
3. HH Pandya: Strike Rate = 1.503901895 */



/*Q2 --- */

-- Step 1: Filter players who have played more than 2 IPL seasons
WITH PlayerSeasons AS (
    SELECT 
        batsman,
        COUNT(DISTINCT ID) AS num_seasons
    FROM 
        IPL_Ball
    GROUP BY 
        batsman
    HAVING 
        COUNT(DISTINCT ID) > 2
),
-- Step 2: Calculate batting average for each player
PlayerBattingAverage AS (
    SELECT 
        pb.batsman,
        SUM(pb.batsman_runs) * 1.0 / COUNT(*) AS batting_average
    FROM 
        IPL_Ball pb
    JOIN 
        PlayerSeasons ps ON pb.batsman = ps.batsman
    GROUP BY 
        pb.batsman
)
-- Step 3: Select top 2-3 players with highest batting average
SELECT 
    batsman,
    batting_average
FROM 
    PlayerBattingAverage
ORDER BY 
    batting_average DESC
LIMIT 10;


/*answer - 3 players with good averages who have played more than 2 IPL seasons from the provided list of 10 players, you can consider the following players:
Umar Gul: Batting Average = 2.0526315789473684
Shahid Afridi: Batting Average = 1.7608695652173913
AD Russell: Batting Average = 1.7199546485260771*/



/*Q3-------*/

-- Step 1: Filter players who have played more than 2 IPL seasons
WITH PlayerSeasons AS (
    SELECT 
        batsman,
        COUNT(DISTINCT ID) AS num_seasons
    FROM 
        IPL_Ball
    GROUP BY 
        batsman
    HAVING 
        COUNT(DISTINCT ID) > 2
),
-- Step 2: Calculate total runs scored in boundaries for each player
PlayerBoundaryRuns AS (
    SELECT 
        batsman,
        SUM(CASE WHEN batsman_runs = 4 OR batsman_runs = 6 THEN batsman_runs ELSE 0 END) AS boundary_runs
    FROM 
        IPL_Ball
    WHERE 
        batsman_runs = 4 OR batsman_runs = 6
    GROUP BY 
        batsman
)
-- Step 3: Select top 2-3 players with highest boundary runs
SELECT 
    pb.batsman,
    pb.boundary_runs
FROM 
    PlayerBoundaryRuns pb
JOIN 
    PlayerSeasons ps ON pb.batsman = ps.batsman
ORDER BY 
    pb.boundary_runs DESC
LIMIT 10;

/*answer -  the top 3 hard-hitting players who have scored the most runs in boundaries and have played more than 2 IPL seasons are:

1. CH Gayle - 3630
2. V Kohli - 3228
3. DA Warner - 3210*/



/*Q4-------*/

WITH BowlerStats AS (
    SELECT 
        bowler,
        COUNT(*) AS balls_bowled,
        SUM(total_runs) AS total_runs_conceded
    FROM 
        IPL_Ball
    WHERE 
        is_wicket = '0' 
    GROUP BY 
        bowler
    HAVING 
        COUNT(*) >= 500  
),
BowlerEconomy AS (
    SELECT 
        bs.bowler,
        bs.balls_bowled,
        bs.total_runs_conceded,
        (bs.total_runs_conceded / bs.balls_bowled) * 6.0 AS economy_rate
    FROM 
        BowlerStats bs
)
SELECT 
    be.bowler,
    be.economy_rate
FROM 
    BowlerEconomy be
ORDER BY 
    be.economy_rate ASC
LIMIT 10; 

OR

WITH BowlerStats AS (
    SELECT 
        bowler,
        COUNT(*) AS balls_bowled,
        SUM(total_runs) AS total_runs_conceded
    FROM 
        IPL_Ball
    WHERE 
        is_wicket = '0' 
    GROUP BY 
        bowler
    HAVING 
        COUNT(*) >= 500  
),
BowlerEconomy AS (
    SELECT 
        bs.bowler,
        bs.balls_bowled,
        bs.total_runs_conceded,
        CASE
            WHEN bs.balls_bowled = 0 THEN NULL
            ELSE (bs.total_runs_conceded / bs.balls_bowled) * 6.0
        END AS economy_rate
    FROM 
        BowlerStats bs
)
SELECT 
    be.bowler,
    be.balls_bowled,
    be.total_runs_conceded,
    be.economy_rate
FROM 
    BowlerEconomy be
WHERE
    be.economy_rate IS NOT NULL
ORDER BY 
    be.economy_rate ASC
LIMIT 10;



/*Q5------*/

WITH BowlerStats AS (
    SELECT 
        bowler,
        COUNT(*) AS balls_bowled,
        SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END) AS total_wickets
    FROM 
        IPL_Ball
    GROUP BY 
        bowler
    HAVING 
        COUNT(*) >= 500  ),
BowlerStrikeRate AS (
    SELECT 
        bs.bowler,
        bs.balls_bowled,
        bs.total_wickets,
        (bs.balls_bowled / NULLIF(bs.total_wickets, 0)) AS strike_rate
    FROM 
        BowlerStats bs
)
SELECT 
    bsr.bowler,
    bsr.strike_rate
FROM 
    BowlerStrikeRate bsr
ORDER BY 
    bsr.strike_rate ASC
LIMIT 10; 



/*Q6------*/

WITH AllRounderStats AS (
    SELECT 
        batsman,
        bowler,
        COUNT(DISTINCT CASE WHEN extra_runs = 0 THEN ID END) AS balls_faced,
        COUNT(DISTINCT CASE WHEN is_wicket = '1' THEN ID END) AS wickets_taken
    FROM 
        IPL_Ball
    GROUP BY 
        batsman, bowler
    HAVING 
        COUNT(DISTINCT CASE WHEN extra_runs = 0 THEN ID END) >= 500 
        AND COUNT(DISTINCT CASE WHEN is_wicket = '0' THEN ID END) >= 300 
),
AllRounderPerformance AS (
    SELECT 
        ar.batsman,
        ar.bowler,
        ar.balls_faced,
        ar.wickets_taken,
        (ar.balls_faced / NULLIF(ar.wickets_taken, 0)) AS batting_strike_rate,
        (ar.balls_faced / NULLIF(ar.wickets_taken, 0)) AS bowling_strike_rate
    FROM 
        AllRounderStats ar
)
SELECT 
    arp.batsman,
    arp.bowler,
    arp.batting_strike_rate,
    arp.bowling_strike_rate
FROM 
    AllRounderPerformance arp
ORDER BY 
    arp.batting_strike_rate DESC,
    arp.bowling_strike_rate DESC
LIMIT 3;  -- Selecting top 2-3 all-rounders with the best batting and bowling strike rate



/*additional qts*/

/*Q1*/
SELECT COUNT(DISTINCT city) AS num_cities
FROM IPL_Matches;



/*Q2*/
CREATE TABLE deliveries_v02 AS
SELECT *,
    CASE
        WHEN total_runs >= 4 THEN 'boundary'
        WHEN total_runs = 0 THEN 'dot'
        ELSE 'other'
    END AS ball_result
FROM ipl_ball;

select * from deliveries_v02

/*Q3*/
SELECT 
    ball_result,
    COUNT(*) AS total_count
FROM 
    deliveries_v02
WHERE 
    ball_result IN ('boundary', 'dot')
GROUP BY 
    ball_result;
	
	
/*Q4*/
SELECT 
    batting_team,
    COUNT(*) AS total_boundaries
FROM 
    deliveries_v02
WHERE 
    ball_result = 'boundary'
GROUP BY 
    batting_team
ORDER BY 
    total_boundaries DESC;


/*Q5*/
SELECT 
    bowling_team,
    COUNT(*) AS total_dot_balls
FROM 
    deliveries_v02
WHERE 
    ball_result = 'dot'
GROUP BY 
    bowling_team
ORDER BY 
    total_dot_balls DESC;


/Q6*/
SELECT 
    dismissal_kind,
    COUNT(*) AS total_dismissals
FROM 
    deliveries_v02
WHERE 
    dismissal_kind IS NOT NULL
    AND dismissal_kind != 'NA'
GROUP BY 
    dismissal_kind;


/*Q7*/
SELECT 
    bowler,
    SUM(extra_runs) AS total_extra_runs
FROM 
    deliveries_v02
GROUP BY 
    bowler
ORDER BY 
    total_extra_runs DESC
LIMIT 5;


/*Q8*/

CREATE TABLE deliveries_v03 AS
SELECT dv.*, im.venue, im.date AS match_date
FROM deliveries_v02 dv
JOIN ipl_matches im ON dv.id = im.id;

select * from deliveries_v03;

/*Q9*/

SELECT im.venue, SUM(dv.total_runs) AS total_runs_scored
FROM ipl_matches im
JOIN deliveries_v02 dv ON im.id = dv.id
GROUP BY im.venue
ORDER BY total_runs_scored DESC;


/*Q10*/

SELECT EXTRACT(YEAR FROM im.date) AS year,
       SUM(dv.total_runs) AS total_runs_scored
FROM ipl_matches im
JOIN deliveries_v02 dv ON im.id = dv.id
WHERE im.venue = 'Eden Gardens'
GROUP BY year
ORDER BY total_runs_scored DESC;



/*TEST QUESTIONS*/
/*Q24*/

SELECT batsman, SUM(batsman_runs) AS total_runs
FROM ipl_ball
GROUP BY batsman
HAVING SUM(batsman_runs) > 0 AND
       SUM(batsman_runs) > 150 * (SUM(ball)/100) -- Check for strike rate above 150
ORDER BY total_runs DESC
LIMIT 1;






/*creating visualizations*/

COPY (
    SELECT batsman, 
           SUM(batsman_runs) AS total_runs,
           COUNT(*) AS balls_faced,
           SUM(batsman_runs) * 1.0 / COUNT(*) AS strike_rate
    FROM ipl_ball
    GROUP BY batsman
    HAVING COUNT(*) >= 500
    ORDER BY strike_rate DESC
    LIMIT 10
) TO 'C:\DS\SQL\Project\My Project/top_batsmen.csv' WITH CSV HEADER;



SELECT 
    batsman,
    SUM(CASE WHEN batsman_runs = 4 THEN 4 WHEN batsman_runs = 6 THEN 6 ELSE 0 END) AS total_boundary_runs
FROM 
    IPL_Ball
GROUP BY 
    batsman
ORDER BY 
    total_boundary_runs DESC
LIMIT 10;


SELECT ball_result, COUNT(*) AS count
FROM deliveries_v02
GROUP BY ball_result;



SELECT batting_team, SUM(CASE WHEN ball_result = 'boundary' THEN 1 ELSE 0 END) AS total_boundaries
FROM deliveries_v02
GROUP BY batting_team;


WITH BowlerWickets AS (
    SELECT 
        bowler,
        COUNT(*) AS total_wickets
    FROM 
        IPL_Ball
    WHERE 
        is_wicket = TRUE
    GROUP BY 
        bowler
    ORDER BY 
        total_wickets DESC
    LIMIT 10
)
SELECT 
    bowler,
    total_wickets
FROM 
    BowlerWickets;



SELECT 
    city,
    COUNT(*) AS matches_count
FROM 
    IPL_Matches
GROUP BY 
    city;
