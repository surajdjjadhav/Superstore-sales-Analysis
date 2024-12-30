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