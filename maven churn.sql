-- Why are customers leaving Maven Telecom?

-- Total Number of customers
SELECT
COUNT(DISTINCT Customer_ID) AS customer_count
FROM
dbo.churn2

-- check for duplicates in customer ID
SELECT Customer_ID,
COUNT( Customer_ID )as count
FROM dbo.churn2
GROUP BY Customer_ID
HAVING count(Customer_ID) > 1;


-- DEEP DIVE ANALYSIS

-- How much revenue did maven lose to churned customers?
SELECT Customer_Status, 
COUNT(Customer_ID) AS customer_count,
ROUND((SUM(Total_Revenue) * 100.0) / SUM(SUM(Total_Revenue)) OVER(), 1) AS Revenue_Percentage 
FROM dbo.churn
GROUP BY Customer_Status; 

-- Typical tenure for new customers?
SELECT 
    Customer_Status, 
    CASE 
        WHEN Tenure_in_Months <= 10 THEN '1 Month'
        WHEN Tenure_in_Months <= 6 THEN '1-6 Months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '1-2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    COUNT(Customer_ID) AS tenure_count
FROM dbo.churn
WHERE Customer_Status = 'Joined' 
GROUP BY 
    Customer_Status,
    CASE 
        WHEN Tenure_in_Months <= 1 THEN '1 Month'
        WHEN Tenure_in_Months <= 6 THEN '1-6 Months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '1-2 Years'
        ELSE '> 2 Years'
    END;

-- How much revenue has maven lost?
 SELECT 
  Customer_Status, 
  CEILING(SUM(Total_Revenue)) AS Revenue,     -- ceiling is used to Round up the figures
  ROUND((SUM(Total_Revenue) * 100.0) / SUM(SUM(Total_Revenue)) OVER(), 1) AS Revenue_Percentage
FROM 
  dbo.churn
GROUP BY 
  Customer_Status;


-- Which cities have the higest churn rates?
SELECT
    TOP 4 City,
    COUNT(Customer_ID) AS Churned,
    CEILING(COUNT(CASE WHEN Customer_Status = 'Churned' THEN Customer_ID ELSE NULL END) * 100.0 / COUNT(Customer_ID)) AS Churn_Rate
FROM
    dbo.churn2
GROUP BY
    City
HAVING
    COUNT(Customer_ID)  > 30
AND
    COUNT(CASE WHEN Customer_Status = 'Churned' THEN Customer_ID ELSE NULL END) > 0
ORDER BY
    Churn_Rate DESC;
    


-- why did churners leave and how much did it cost?
SELECT 
  Churn_Category,  
  ROUND(SUM(Total_Revenue),0)AS Churned_Rev,
  CEILING((COUNT(Customer_ID) * 100.0) / SUM(COUNT(Customer_ID)) OVER()) AS Churn_Percentage
FROM 
  dbo.churn
WHERE 
    Customer_Status = 'Churned'
GROUP BY 
  Churn_Category
ORDER BY 
  Churn_Percentage DESC;


-- What service did churned customers use?
SELECT 
    Internet_Type,
    COUNT(Customer_ID) AS Churned,
    ROUND((COUNT(Customer_ID) * 100.0) / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.churn
WHERE 
    Churn_Category = 'Competitor' 
AND 
    Customer_Status = 'Churned'
GROUP BY 
    Internet_Type
ORDER BY 
    Churned DESC;

-- What contract were churners on?
SELECT 
    Contract,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.churn
WHERE
    Customer_Status = 'Churned'
GROUP BY
    Contract
ORDER BY 
    Churned DESC;

-- Did churners have premium tech support?
SELECT 
    Premium_Tech_Support,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS Churn_Percentage
FROM
    dbo.churn
WHERE 
    Customer_Status = 'Churned'
GROUP BY Premium_Tech_Support
ORDER BY Churned DESC;


-- What Internet service were churners on?
SELECT
    Internet_Type,
    COUNT(Customer_ID) AS Churned,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    dbo.churn
WHERE 
    Customer_Status = 'Churned'
GROUP BY
Internet_Type
ORDER BY 
Churned DESC;


-- Typical tenure for churners
SELECT
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    COUNT(Customer_ID) AS Churned,
    CEILING(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER()) AS Churn_Percentage
FROM
dbo.churn2
WHERE
Customer_Status = 'Churned'
GROUP BY
    CASE 
        WHEN Tenure_in_Months <= 6 THEN '6 months'
        WHEN Tenure_in_Months <= 12 THEN '1 Year'
        WHEN Tenure_in_Months <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END
ORDER BY
Churned DESC;


-- Are high value customers at risk?

SELECT 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,
    COUNT(Customer_ID) AS num_customers,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(),1) AS cust_percentage,
    num_conditions  
FROM 
    (
    SELECT 
        Customer_ID,
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END)+
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Premium_Tech_Support = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Internet_Type = 'Fiber Optic' THEN 1 ELSE 0 END) AS num_conditions
    FROM 
        dbo.churn2
    WHERE 
        Monthly_Charge > 70.05 
        AND Customer_Status = 'Stayed'
        AND Number_of_Referrals > 0
        AND Tenure_in_Months > 9
    GROUP BY 
        Customer_ID
    HAVING 
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Premium_Tech_Support = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Internet_Type = 'Fiber Optic' THEN 1 ELSE 0 END) >= 1
    ) AS subquery
GROUP BY 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END, num_conditions; 


-- why did customer's churn exactly?
SELECT TOP 10
    Churn_Reason,
    Churn_Category,
    ROUND(COUNT(Customer_ID) *100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS churn_perc
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY 
Churn_Reason,
Churn_Category
ORDER BY churn_perc DESC;


-- What offers were churners on?
SELECT  
    Offer,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY
Offer
ORDER BY 
churn_percentage DESC;


-- HOW old were churners?
SELECT  
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END AS Age,
    ROUND(COUNT(Customer_ID) * 100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END
ORDER BY
Churn_Percentage DESC;

-- What gender were churners?
SELECT
    Gender,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY
    Gender
ORDER BY
Churn_Percentage DESC;

-- Did churners have dependents
SELECT
    CASE
        WHEN Number_of_Dependents > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS Dependents,
    ROUND(COUNT(Customer_ID) *100 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage

FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY 
CASE
        WHEN Number_of_Dependents > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END
ORDER BY Churn_Percentage DESC;

-- Were churners married
SELECT
    Married,
    ROUND(COUNT(Customer_ID) *100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY
    Married
ORDER BY
Churn_Percentage DESC;


-- Do churners have phone lines
SELECT
    Phone_Service,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    Phone_Service


-- Do churners have internet service
SELECT
    Internet_Service,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    Internet_Service


-- Did they give referrals
SELECT
    CASE
        WHEN Number_of_Referrals > 0 THEN 'Yes'
        ELSE 'No'
    END AS Referrals,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churned
FROM
    dbo.churn2
WHERE
    Customer_Status = 'Churned'
GROUP BY 
    CASE
        WHEN Number_of_Referrals > 0 THEN 'Yes'
        ELSE 'No'
    END;


-- What Internet Type did 'Competitor' churners have?
SELECT
    Internet_Type,
    Churn_Category,
    ROUND(COUNT(Customer_ID) * 100.0 / SUM(COUNT(Customer_ID)) OVER(), 1) AS Churn_Percentage
FROM
    dbo.churn2
WHERE 
    Customer_Status = 'Churned'
    AND Churn_Category = 'Competitor'
GROUP BY
Internet_Type,
Churn_Category
ORDER BY Churn_Percentage DESC;



















