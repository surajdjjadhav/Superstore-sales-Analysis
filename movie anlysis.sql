#  Question 1 : Calculate the average movie rating for each genre.

WITH AvgRatings AS (
    SELECT movieId, AVG(rating) AS avg_rating
    FROM rating 
    GROUP BY movieId
)
SELECT g.genres, AVG(ar.avg_rating) AS avg_genre_rating
FROM AvgRatings ar
JOIN movie g ON ar.movieId = g.movieId
GROUP BY g.genres
order by avg_genre_rating desc;



select movieid , title , count(*) as rating_count 
from movie group by movieid , title
order by rating_count desc ;

WITH RatingCount AS (
    SELECT movieId, COUNT(*) AS rating_count
    FROM rating
    GROUP BY movieId
)
SELECT m.movieId, m.title, rc.rating_count
FROM RatingCount rc
JOIN movie m ON rc.movieId = m.movieId
ORDER BY rc.rating_count DESC
LIMIT 5;

select count(*) rating from rating;
select count(*) movie from movie;

select * from rating;
show columns from rating

;


create  index suraj on rating(movieid);

select count(movieid) as count from rating where movieid = 300;

drop index suraj on rating;




