
# DATA CLEANING

ALTER TABLE CREDIT_CARD 
CHANGE COLUMN `ï»¿Client_Num`  CLIENT_NUM INT ;

ALTER TABLE CC_ADD 
CHANGE COLUMN `ï»¿Client_Num`  CLIENT_NUM INT ;

ALTER TABLE CUST_ADD
CHANGE COLUMN `ï»¿Client_Num`  CLIENT_NUM INT ;





# Q1: Write a query to retrieve the total number of customers (CLIENT_NUM) grouped by GENDER and MARITAL_STATUS.

SELECT GENDER , MARITAL_STATUS ,  COUNT(CLIENT_NUM) AS TOTAL_CLIENTS 
 FROM CUSTOMER
 GROUP BY GENDER  , MARITAL_STATUS
 ORDER BY TOTAL_CLIENTS DESC;
 
 
# Question 2 : Calculate the total Annual_Fees and average Credit_Limit for each Card_Category

SELECT CARD_CATEGORY , SUM(ANNUAL_FEES) AS TOTAL_FEE , 
ROUND(AVG(CREDIT_LIMIT),2) AS AVERAGE_CREDIT_LIMIT
FROM CREDIT_CARD
GROUP BY CARD_CATEGORY;
 
 
 
# 3 Find customers with an Avg_Utilization_Ratio greater than 0.5 and list their CLIENT_NUM and Credit_Limit.

SELECT CLIENT_NUM  , CREDIT_LIMIT , AVG_UTILIZATION_RATIO  
FROM CREDIT_CARD
WHERE AVG_UTILIZATION_RATIO  >  0.5
ORDER BY AVG_UTILIZATION_RATIO DESC ;
  





# MEDIUM LEVEL QUERY QUESTIONS


# 4 Question: Find the top 5 customers with the highest Total_Trans_Amt in each quarter

SELECT * FROM 
(SELECT CARD_CATEGORY , CLIENT_NUM , QTR ,  SUM(TOTAL_TRANS_AMT)AS TOTAL_TRANSACTION,
ROW_NUMBER() OVER (PARTITION BY QTR ORDER BY  SUM(TOTAL_TRANS_AMT) DESC ) AS RN
  FROM CREDIT_CARD
GROUP BY CLIENT_NUM , CARD_CATEGORY ,  QTR) RANKING
WHERE RN <= 5;
 
 
 
# QUESTION 5: Identify customers whose CUSTOMER_SATISFACTION_SCORE is below 3 and whose income is below the average income of all customers

select CLIENT_NUM from customer 
WHERE CUSTOMER_SATISFACTION_SCORE < 3 AND INCOME < (SELECT AVG(INCOME) FROM CUSTOMER) ;



# QUESTION 6 :Calculate the rolling average of Avg_Utilization_Ratio over the past 3 weeks for each customer

SELECT 
    CLIENT_NUM, 
    Week_Start_Date, 
    AVG(Avg_Utilization_Ratio) 
        OVER (PARTITION BY CLIENT_NUM ORDER BY Week_Start_Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Rolling_Avg_Utilization
FROM CREDIT_CARD;


 
/* Q 7 : "Identify customers who have low credit card utilization (below 30%), have at least one delinquent account, 
		and have activated their credit card in the last 30 days  and find average credit limit for this customers .*/
        
WITH Activated_Customers AS (
    SELECT 
        CLIENT_NUM, 
        Avg_Utilization_Ratio, 
        Credit_Limit
    FROM CREDIT_CARD
    WHERE Activation_30_Days = 'Yes' 
      AND Avg_Utilization_Ratio < 0.3 
      AND Delinquent_Acc > 0
)
SELECT 
    round(AVG(Credit_Limit) ,2 )AS Avg_Credit_Limit
FROM Activated_Customers;




# Q8 :- Identify customers with significant transaction amounts who also have delinquent accounts.

WITH Ranked_Customers AS (
    SELECT 
        CLIENT_NUM, 
        Total_Trans_Amt, 
        PERCENT_RANK() OVER (ORDER BY Total_Trans_Amt DESC) AS Percent_Rank_
    FROM CREDIT_CARD
)
SELECT 
    CLIENT_NUM, 
    Total_Trans_Amt
FROM Ranked_Customers
WHERE Percent_Rank_ >= 0.9 AND CLIENT_NUM IN (
    SELECT CLIENT_NUM FROM CREDIT_CARD WHERE Delinquent_Acc > 0
);





# Q9  calculate the total interest earned by customers whose acquisition cost is above the median value
 
WITH RANKING AS (
    SELECT 
        CLIENT_NUM,
        CUSTOMER_ACQ_COST,
        DENSE_RANK() OVER (ORDER BY CUSTOMER_ACQ_COST DESC, CLIENT_NUM DESC) AS DESC_,
        DENSE_RANK() OVER (ORDER BY CUSTOMER_ACQ_COST ASC, CLIENT_NUM ASC) AS ASC_
    FROM CREDIT_CARD
),
MedianCost AS (
    SELECT 
        CAST(AVG(CUSTOMER_ACQ_COST) AS SIGNED) AS MEDIAN
    FROM RANKING
    WHERE DESC_ = ASC_ OR ASC_ + 1 = DESC_ OR ASC_ - 1 = ASC_
)
SELECT 
    CLIENT_NUM, 
    SUM(Interest_Earned) AS TOTAL_INTEREST
FROM CREDIT_CARD 
WHERE CUSTOMER_ACQ_COST > (SELECT MEDIAN FROM MedianCost)
GROUP BY CLIENT_NUM
;





# Q10 Identify the percentage of delinquent accounts in each quarter

WITH Delinquent_Accounts AS (
    SELECT 
        Qtr, 
        COUNT(Delinquent_Acc) AS Total_Delinquent_Acc
    FROM CREDIT_CARD
    WHERE Delinquent_Acc > 0
    GROUP BY Qtr
),
Total_Accounts AS (
    SELECT 
        Qtr, 
        COUNT(*) AS Total_Acc
    FROM CREDIT_CARD
    GROUP BY Qtr
)
SELECT 
    D.Qtr, 
    D.Total_Delinquent_Acc, 
    ROUND((D.Total_Delinquent_Acc * 100.0 / T.Total_Acc), 2)  AS Delinquent_Percentage
FROM Delinquent_Accounts D
JOIN Total_Accounts T ON D.Qtr = T.Qtr;




# Question 11 : For each Card_Category, calculate the delinquency rate (number of delinquent accounts divided by total accounts). 

SELECT CARD_CATEGORY  , 
COUNT(DELINQUENT_ACC)  * 100 / (SELECT COUNT(*) FROM CREDIT_CARD)  AS DELIQUENT_PEERCENTAGE
FROM CREDIT_CARD
WHERE DELINQUENT_ACC > 0 
GROUP BY CARD_CATEGORY ;






/*Q12 . "Identify customers who have a high credit limit but low transaction volume, 
and calculate the total interest earned for this segment. */


WITH High_Limit_Low_Volume AS (
    SELECT 
        CLIENT_NUM, 
        CREDIT_LIMIT, 
        SUM(Total_Trans_Vol) AS Total_Trans_Vol,
        SUM(Interest_Earned) AS Total_Interest_Earned
    FROM CREDIT_CARD
    GROUP BY CLIENT_NUM, CREDIT_LIMIT
),
Overall_Avg_Volume AS (
    SELECT 
        AVG(Total_Trans_Vol) AS Overall_Avg_Trans_Vol,
        AVG(CREDIT_LIMIT) AS AVG_LIMIT
    FROM CREDIT_CARD
)
SELECT 
    H.CLIENT_NUM, 
    H.CREDIT_LIMIT, 
    H.Total_Trans_Vol, 
    H.Total_Interest_Earned,
    CASE 
        WHEN H.Total_Trans_Vol < O.Overall_Avg_Trans_Vol AND H.CREDIT_LIMIT > O.AVG_LIMIT
        THEN 'Target for Increased Spending'
        ELSE 'No Action Needed'
    END AS Marketing_Strategy
FROM High_Limit_Low_Volume H
CROSS JOIN Overall_Avg_Volume O
WHERE H.Total_Trans_Vol < O.Overall_Avg_Trans_Vol AND H.CREDIT_LIMIT > O.AVG_LIMIT;


