-- Employee Management Database Project
-- Database: EmployeeManagmentDB
-- SQL Server

-- Create the Employee Management Database
CREATE DATABASE EmployeeManagmentDB

-- Select the database
USE EmployeeManagmentDB

-- Create Departments table
CREATE TABLE Departments 
(
   DepartmentID INT PRIMARY KEY,
   DepartmentName VARCHAR(50) NOT NULL UNIQUE,
   DeptLocation VARCHAR(50)
 )

-- Create JobRoles table  
 CREATE TABLE JobRoles
 (
    JobRoleID INT PRIMARY KEY,
    JobTitle VARCHAR(50) NOT NULL,
    MinSalary DECIMAL(10,2),
    MaxSalary DECIMAL(10,2),
    
    CHECK (
      MinSalary >= 0 
        AND MaxSalary > MinSalary
        )
)

-- Create Employees table with foreign key relationships
CREATE TABLE Employees
(
   EmployeeID INT PRIMARY KEY,
   FirstName VARCHAR(50) NOT NULL,
   LastName VARCHAR(50),
   Email VARCHAR(100) NOT NULL UNIQUE,
   HireDate DATE,
   Salary DECIMAL(10,2),
   DepartmentID INT NOT NULL,
   JobRoleID INT NOT NULL,
   ManagerID INT NULL,
  
   FOREIGN KEY (DepartmentID) 
       REFERENCES Departments(DepartmentID),

   FOREIGN KEY (JobRoleID)
       REFERENCES JobRoles(JobRoleID),

   FOREIGN KEY (ManagerID)
      REFERENCES Employees(EmployeeID) 
 )

--Data Analysis & Business Problems with SQL Solutions
-- 1. Display employees earning more than 60,000.

SELECT 
  EmployeeID,
  FirstName,
  Salary
FROM Employees
WHERE Salary > 60000

-- 2. Display employee details with department and job title.

SELECT
  E.FirstName,
  E.Salary,
  D.DepartmentName,
  J.JobTitle
FROM Employees E
INNER JOIN Departments D ON
    (E.DepartmentID = D.DepartmentID) 
JOIN JobRoles J ON 
    (E.JobRoleID = J.JobRoleID)

-- 3. Display employees earning more than 60,00,000 sorted by salary.

SELECT
  E.FirstName,
  E.Salary,
  D.DepartmentName,
  J.JobTitle
FROM Employees E
JOIN Departments D 
  ON E.DepartmentID = D.DepartmentID
JOIN JobRoles J
  ON E.JobRoleID = J.JobRoleID
WHERE E.Salary > 6000000
ORDER BY E.Salary DESC

-- 4. Find employees earning above their department's average salary.
SELECT * FROM Employees

SELECT
  E.FirstName,
  E.Salary,
  E.DepartmentID
FROM Employees E
WHERE E.Salary > (
   SELECT 
     AVG(E2.Salary)
    FROM Employees E2
    WHERE E2.DepartmentID = E.DepartmentID
    )

-- 5. Rank employees by salary within each department.
SELECT 
  FirstName,
  Salary,
  DepartmentID,
  DENSE_RANK() OVER(
     PARTITION BY DepartmentID
     ORDER BY Salary DESC
    ) AS SalaryRank
FROM Employees

-- 6. Find the top two salary ranks in each department.
WITH EmployeeRank AS(
    SELECT 
      FirstName,
      Salary,
      DepartmentID,
      DENSE_RANK() OVER(
         PARTITION BY DepartmentID
         ORDER BY Salary DESC
        ) AS SalaryRank
    FROM Employees
 )
 SELECT  
   FirstName,
   Salary,
   DepartmentID,
   SalaryRank
FROM EmployeeRank
WHERE SalaryRank <= 2
ORDER BY DepartmentID, Salary DESC

-- 7. Find the highest-paid employees in each department.
WITH EmployeesRank AS (
  SELECT
     FirstName,
     Salary,
     DepartmentID,
     DENSE_RANK() OVER(
         PARTITION BY DepartmentID
         ORDER BY Salary DESC
     ) AS SalaryRank
 FROM Employees
)
SELECT 
  FirstName,
  Salary,
  DepartmentID,
  SalaryRank
FROM EmployeesRank
WHERE SalaryRank = 1
ORDER BY DepartmentID, Salary DESC


-- 8. Find departments with an average salary above 600000.
SELECT 
  D.DepartmentID,
  D.DepartmentName,
  AVG(E.Salary) AS avg_salary
FROM Departments D
JOIN Employees E
   ON D.DepartmentID = E.DepartmentID
GROUP BY D.DepartmentID, D.DepartmentName
HAVING AVG(E.Salary) > 600000
   
-- 9. Find employees earning more than their managers
SELECT
  E.FirstName + ' ' + E.LastName AS EmployeeName,
  E.Salary AS EmployeeSalary,
  M.FirstName + ' ' + M.LastName AS ManagerName,
  M.Salary AS ManagerSalary
FROM Employees M
INNER JOIN Employees E
   ON E.ManagerID = M.EmployeeID
WHERE E.Salary > M.Salary

-- 10. Find employees who do not have a manager.
SELECT 
   EmployeeID,
   FirstName,
   Salary,
   ManagerID
FROM Employees
WHERE ManagerID IS NULL

-- 11. Find departments without employees.
SELECT
   D.DepartmentID,
   D.DepartmentName
FROM Departments D
WHERE NOT EXISTS(
    SELECT 1
    FROM Employees E
    WHERE E.DepartmentID = D.DepartmentID
    )

--Alternate Method
SELECT 
   D.DepartmentID,
   D.DepartmentName
FROM Departments D
LEFT JOIN Employees E
   ON D.DepartmentID = E.DepartmentID
WHERE E.EmployeeID IS  NULL

-- 12. Create a view for employee details.
CREATE VIEW dbo.vw_EmployeeDetails
AS
SELECT 
  E.EmployeeID,
  E.FirstName,
  E.LastName,
  E.Email,
  E.HireDate,
  E.Salary,
  D.DepartmentName,
  J.JobTitle,
  E.ManagerID
FROM Employees E
INNER JOIN Departments D
  ON E.DepartmentID = D.DepartmentID
INNER JOIN JobRoles J
  ON E.JobRoleID = J.JobRoleID

SELECT * FROM vw_employeeDetails

-- 13. Create a stored procedure to retrieve employees by department.
ALTER PROCEDURE dbo.GetEmployeesByDepartment
@DepartmentID INT
AS
BEGIN 
  SELECT
    EmployeeID,
    FirstName,
    LastName,
    Salary
  FROM Employees
  WHERE DepartmentID = @DepartmentID
  ORDER BY Salary DESC
END

EXEC dbo.GetEmployeesByDepartment @DepartmentID = 60

-- 14. Add a minimum salary filter to the stored procedure.
 ALTER PROCEDURE dbo.GetEmployeesByDepartment
 @DepartmentID INT,
 @MinSalary DECIMAL(10,2)
 AS
 BEGIN
   SELECT
     EmployeeID,
     FirstName,
     Salary
   FROM Employees
   WHERE DepartmentID = @DepartmentID
     AND Salary > @MinSalary
    ORDER BY Salary DESC
 END

 EXEC dbo.GetEmployeesByDepartment 
    @DepartmentId = 1,
    @MinSalary=  700000

-- 15. Make the minimum salary parameter optional.
ALTER PROCEDURE dbo.GetEmployeesByDepartment
@DepartmentID INT,
@MinSalary DECIMAL(10,2) = NULL
AS
BEGIN
  SELECT
    EmployeeID,
    FirstName,
    Salary
  FROM Employees
  WHERE (DepartmentID = @DepartmentID)
     AND 
     (@MinSalary IS NULL OR Salary > @MinSalary)
  ORDER BY Salary DESC
END

EXEC dbo.GetEmployeesByDepartment 
   @DepartmentID = 1


-- 16. Make department and minimum salary filters optional.
ALTER PROCEDURE dbo.GetEmployeesByDepartment
@DepartmentId INT = NULL,
@MinSalary DECIMAL(10,2) = NULL
AS
BEGIN
  SELECT 
    FirstName,
    LastName,
    DepartmentID,
    Salary
  FROM Employees
  WHERE 
     (@DepartmentID IS NULL OR DepartmentID = @DepartmentID) 
       AND 
     (@Minsalary IS NULL OR Salary >= @MinSalary)
  ORDER BY Salary DESC
END

EXEC dbo.GetEmployeesByDepartment 
  @DepartmentID = 1,
  @MinSalary = 300000
    

EXEC dbo.GetEmployeesByDepartment 

EXEC dbo.GetEmployeesByDepartment 
  @DepartmentID = 1


EXEC dbo.GetEmployeesByDepartment 
  @MinSalary = 300000


-- 17. Display the total matching employee count.
ALTER PROCEDURE GetTotalEmployeesByDepartment
@DepartmentID INT = NULL,
@MinSalary DECIMAL(10,2)  = NULL
AS
BEGIN
  SELECT
     FirstName,
     LastName,
     DepartmentId,
     Salary,
     COUNT(*) OVER(
        PARTITION BY DepartmentID
      ) AS TotalMatchingEmployees
      FROM Employees
      WHERE 
         (@DepartmentID IS NULL OR DepartmentID = @DepartmentID)
            AND
          (@MinSalary IS NULL OR Salary >= @MinSalary)
 END


EXEC dbo.GetTotalEmployeesByDepartment 
  @DepartmentID = 1,
  @MinSalary = 300000
    

EXEC dbo.GetTotalEmployeesByDepartment

EXEC dbo.GetTotalEmployeesByDepartment 
  @DepartmentID = 1


EXEC dbo.GetTotalEmployeesByDepartment 
  @MinSalary = 300000

-- 18. Update the procedure using COUNT() OVER().
CREATE PROCEDURE GetTotalEmployeeS
@DepartmentID INT = NULL,
@MinSalary DECIMAL(10,2)  = NULL
AS
BEGIN
  SELECT
     FirstName,
     LastName,
     DepartmentId,
     Salary,
    COUNT(*) OVER() AS TotalMatchingEmployees
      FROM Employees
      WHERE
        (@DepartmentID IS NULL OR DepartmentID = @DepartmentID)
            AND
          (@MinSalary IS NULL OR Salary > @MinSalary)
      ORDER BY Salary DESC
 END

 EXEC GetTotalEmployeeS
   @DepartmentID = 1,
    @Minsalary = 600000


-- 19. Find the highest-paid employee in each department.

WITH EmployeeRank AS( 
   SELECT 
     FirstName,
     LastName,
     DepartmentID,
     Salary,
     DENSE_RANK() OVER (
       PARTITION BY DepartmentID
       ORDER BY Salary DESC
       ) AS HighestSalary
    FROM Employees
  )
SELECT * 
FROM EmployeeRank 
WHERE HighestSalary <=1

-- 20. Find departments with an average salary above the company average.

 SELECT
   DepartmentID,
   AVG(Salary) AS AverageDepartmentSalary
 FROM Employees
 GROUP BY DepartmentID
 HAVING AVG(Salary) > (SELECT AVG(Salary) FROM Employees)

-- 21. Find employees earning above their department average.
   
 SELECT
   E.EmployeeID,
   E.FirstName,
   E.DepartmentID,
   E.Salary
 FROM Employees E
 WHERE E.Salary > (
    SELECT
      AVG(E2.Salary)
      FROM Employees E2
      WHERE E2.DepartmentID = E.DepartmentID
      )
    
-- 22. Find the second-highest distinct salary in each department.
WITH EmployeeRank AS (
  SELECT 
    EmployeeID,
    FirstName,
    DepartmentID,
    Salary,
    DENSE_RANK() OVER(
       PARTITION BY DepartmentID 
       ORDER BY Salary DESC
     ) AS EmpRank
 FROM Employees
 )
 SELECT 
    EmployeeID,
    FirstName,
    DepartmentID,
    Salary
 FROM EmployeeRank 
 WHERE EmpRank = 2

 -- 23. Find employees earning more than their managers
 SELECT
   E.EmployeeID,
   E.FirstName,
   E.Salary,
   M.FirstName AS ManagerName,
   M.Salary AS ManagerSalary
FROM Employees E
JOIN Employees M
   ON E.ManagerID = M.EmployeeID
WHERE E.Salary > M.Salary

-- 24. Find departments without employees.
SELECT 
  D.DepartmentID,
  D.DepartmentName
FROM Departments D
LEFT JOIN Employees E
  ON  D.DepartmentID = E.DepartmentID 
WHERE E.DepartmentID IS NULL
   
-- 25. Find duplicate salaries within each department.
SELECT 
  DepartmentID,
  Salary,
  COUNT(*) AS EmployeeCount
FROM Employees
GROUP BY DepartmentID,
      Salary
 HAVING Count(*) >= 2
   
-- 26. Find employees hired in the last 12 months.
SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate >= DATEADD(MONTH,-12,GETDATE())

-- 27. Count employees hired in each year.
SELECT
  YEAR(HireDate) AS HireYear,
  COUNT(*) AS TotaEmployees
FROM Employees
GROUP BY YEAR(HireDate)
ORDER BY YEAR(HireDate) DESC

-- 28. Count employees hired in each month.
SELECT 
  YEAR(HireDate) AS HireYear,
  MONTH(HireDate) AS HireMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
GROUP BY YEAR(HireDate),
       MONTH(HireDate)

-- 29. Find employees hired on weekends.
SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE DATENAME(WEEKDAY, HireDate) = 'Saturday'
OR DATENAME(WEEKDAY, HireDate) = 'Sunday'


-- 30. Find employees hired in May, regardless of year.
SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE MONTH(HireDate) = 5

-- 31. Find employees hired in May 2025.
SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE YEAR(HireDate) = 2025
   AND MONTH(HireDate) = 5

-- 32. Find employees hired between January and March 2025.
SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE YEAR(HireDate) = 2025 AND
   MONTH(HireDate) BETWEEN 1 AND 3 

-- 33. Find employees hired in the last six months.
SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
 WHERE HireDate >= DATEADD(MONTH, -6, GETDATE())

-- 34. Find employees with more than five years of service.
SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate <= DATEADD(YEAR, -5, GETDATE())

-- 35. Find employees hired in the current year.
SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate BETWEEN '2026-01-01' AND GETDATE()
  
-- 36. Find employees hired in the previous year.
SELECT
   EmployeeID,
   FirstName,
   HireDate
FROM Employees
WHERE HireDate >= '2025-01-01' AND 
      HireDate <= '2025-12-31'

-- 37. Categorize employees by hiring quarter
SELECT
   EmployeeID,
   FirstName,
   HireDate,
   CASE DATEPART(QUARTER, HireDate) 
     WHEN 1 THEN 'Q1' 
     WHEN 2 THEN'Q2'
     WHEN 3 THEN 'Q3'
     WHEN 4 THEN 'Q4'
    END AS HiringQuarter
FROM Employees  
WHERE YEAR(HireDate) = 2025

-- 38. Count employees hired in each quarter of 2025.
SELECT 
  CASE DATEPART(QUARTER, HireDate)
     WHEN 1 THEN 'Q1'
     WHEN 2 THEN 'Q2'
     WHEN 3 THEN 'Q3'
     WHEN 4 THEN 'Q4'
  END AS HiringQuarter,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) =2025
GROUP BY DATEPART(QUARTER, HireDate)

-- 39. Find the busiest hiring quarter in 2025.
SELECT
  CASE DATEPART(QUARTER, HireDate) 
     WHEN 1 THEN 'Q1'
     WHEN 2 THEN 'Q2'
     WHEN 3 THEN 'Q3'
     WHEN 4 THEN 'Q4'
     END AS HiringQuarter,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY DATEPART(QUARTER, HireDate)
ORDER BY COUNT(*) DESC
   
-- 40. Calculate the hiring percentage for each quarter.
SELECT 
  CASE DATEPART(QUARTER, HireDate) 
     WHEN 1 THEN 'Q1'
     WHEN 2 THEN 'Q2'
     WHEN 3 THEN 'Q3'
     WHEN 4 THEN 'Q4'
  END AS HiringQuarter,

  COUNT(*) AS TotalEmployees,

  CAST( 
     COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
      AS DECIMAL(5,2)
      ) AS HiringPercentage
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY DATEPART(QUARTER, HireDate)
ORDER BY DATEPART(QUARTER, HireDate) 

-- 41. Calculate the monthly hiring running total.
SELECT
  MONTH(HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees,
  SUM(COUNT(*)) OVER(
    ORDER BY MONTH(HireDate)
    ) AS RunningTotal
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY MONTH(HireDate)

-- 42. Find the busiest hiring month in 2025.
SELECT TOP 1
  MONTH(HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY MONTH(HireDate)
ORDER BY COUNT(*) DESC

-- 43. Display monthly hiring counts with month names.
SELECT
  CASE MONTH(HireDate)
     WHEN 1 THEN 'January'
     WHEN 2 THEN 'February'
     WHEN 3 THEN 'March'
     WHEN 4 THEN 'April'
     WHEN 5 THEN 'May'
     WHEN 6 THEN 'June'
     WHEN 7 THEN 'July'
     WHEN 8 THEN 'August'
     WHEN 9 THEN 'September'
     WHEN 10 THEN 'October'
     WHEN 11 THEN 'November'
     WHEN 12 THEN 'December'
  END AS HiringMonth,
 COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY MONTH(HireDate)
ORDER BY MONTH(HireDate)

--Alternate Method

SELECT
  DATENAME(MONTH,HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY DATENAME(MONTH, HireDate), MONTH(HireDate)
ORDER BY MONTH(HireDate)
   
-- 44. Find months with no new employees in 2025.
WITH Months AS
(
    SELECT 1 AS MonthNumber, 'January' AS HiringMonth
    UNION ALL SELECT 2, 'February'
    UNION ALL SELECT 3, 'March'
    UNION ALL SELECT 4, 'April'
    UNION ALL SELECT 5, 'May'
    UNION ALL SELECT 6, 'June'
    UNION ALL SELECT 7, 'July'
    UNION ALL SELECT 8, 'August'
    UNION ALL SELECT 9, 'September'
    UNION ALL SELECT 10, 'October'
    UNION ALL SELECT 11, 'November'
    UNION ALL SELECT 12, 'December'
)
SELECT
    M.HiringMonth,
    COUNT(E.EmployeeID) AS TotalEmployees
FROM Months M
LEFT JOIN Employees E
    ON M.MonthNumber = MONTH(E.HireDate)
    AND YEAR(E.HireDate) = 2025
GROUP BY M.MonthNumber, M.HiringMonth
ORDER BY M.MonthNumber;

-- 45. Generate a complete monthly hiring report for 2025.
WITH Months AS
(
    SELECT 1 AS MonthNumber, 'January' AS HiringMonth
    UNION ALL SELECT 2, 'February'
    UNION ALL SELECT 3, 'March'
    UNION ALL SELECT 4, 'April'
    UNION ALL SELECT 5, 'May'
    UNION ALL SELECT 6, 'June'
    UNION ALL SELECT 7, 'July'
    UNION ALL SELECT 8, 'August'
    UNION ALL SELECT 9, 'September'
    UNION ALL SELECT 10, 'October'
    UNION ALL SELECT 11, 'November'
    UNION ALL SELECT 12, 'December'
),
MonthlyHiring AS
(
    SELECT
        M.MonthNumber,
        M.HiringMonth,
        COUNT(E.EmployeeID) AS TotalEmployees
    FROM Months M
    LEFT JOIN Employees E
        ON M.MonthNumber = MONTH(E.HireDate)
        AND YEAR(E.HireDate) = 2025
    GROUP BY M.MonthNumber, M.HiringMonth
)
SELECT
    HiringMonth,
    TotalEmployees,

    SUM(TotalEmployees) OVER(
        ORDER BY MonthNumber
    ) AS RunningTotal,

    CAST(
        TotalEmployees * 100.0 /
        NULLIF(SUM(TotalEmployees) OVER(), 0)
        AS DECIMAL(5,2)
    ) AS HiringPercentage

FROM MonthlyHiring
ORDER BY MonthNumber;

