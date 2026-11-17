CREATE DATABASE EmployeeManagmentDB

USE EmployeeManagmentDB

CREATE TABLE Departments 
(
   DepartmentID INT PRIMARY KEY,
   DepartmentName VARCHAR(50) NOT NULL UNIQUE,
   DeptLocation VARCHAR(50)
 )

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

 SELECT * FROM Sys.tables
 ORDER BY Name

 SELECT * FROM Departments

 SELECT * FROM JobRoles

/*1.Display 
    EmployeeID
    FirstName
    Salary
Only employees earning more than ₹60,000.*/

SELECT 
  EmployeeID,
  FirstName,
  Salary
FROM Employees
WHERE Salary > 60000

--2.Display each employee's first name, salary, department name, and job title.

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

--3. Display all employees earning more than ₹60,000, along with their department names and job titles. Sort the results by salary from highest to lowest.

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

--4.: Display each employee whose salary is greater than the average salary of their own department.
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

--5.Display every employee's name, salary, department ID, and salary rank within their department, with the highest salary ranked first.

SELECT 
  FirstName,
  Salary,
  DepartmentID,
  DENSE_RANK() OVER(
     PARTITION BY DepartmentID
     ORDER BY Salary DESC
    ) AS SalaryRank
FROM Employees

--6.Display the top two salary ranks within each department, including employees who tie at those ranks
     
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

--7.Display all employees who earn the maximum salary in their department, including ties.

WITH EmployeesRank AS (
  SELECT
     FirstName,
     Salary,
     DepartmentID,
     DENSE_RANK() OVER(
         PARTITION BY DepartmentID
         ORDER BY Salary
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


--8.Display DepartmentID, DepartmentName, and AverageSalary for departments where the average employee salary is greater than ₹60,000.

SELECT * FROM Departments

SELECT 
  D.DepartmentID,
  D.DepartmentName,
  AVG(E.Salary) AS avg_salary
FROM Departments D
JOIN Employees E
   ON D.DepartmentID = E.DepartmentID
GROUP BY D.DepartmentID, D.DepartmentName
HAVING AVG(E.Salary) > 600000

--9.Display the employee's name, salary, manager's name, and manager's salary — but only when the employee earns more than their manager.

SELECT
  E.FirstName + ' ' + E.LastName AS EmployeeName,
  E.Salary AS EmployeeSalary,
  M.FirstName + ' ' + M.LastName AS ManagerName,
  M.Salary AS ManagerSalary
FROM Employees M
INNER JOIN Employees E
   ON E.ManagerID = M.EmployeeID
WHERE E.Salary > M.Salary

--Method 2
SELECT 
  CONCAT(E.FirstName,' ', E.LastName) AS EmployeeName,
  E.Salary AS EmployeeSalary,
  CONCAT(M.FirstName, ' ', M.LastName) AS ManagerName,
  M.Salary AS ManagerSalary
FROM Employees E
INNER JOIN Employees M
   ON E.ManagerID = M.EmployeeID
WHERE E.Salary > M.Salary

--10. Display the EmployeeID, FirstName, and Salary of employees who don't have a manager assigned.

SELECT 
   EmployeeID,
   FirstName,
   Salary,
   ManagerID
FROM Employees
WHERE ManagerID IS NULL

--11.Display the DepartmentID and DepartmentName of departments that have no employees assigned.

SELECT
   D.DepartmentID,
   D.DepartmentName
FROM Departments D
WHERE NOT EXISTS(
    SELECT 1
    FROM Employees E
    WHERE E.DepartmentID = D.DepartmentID
    )

--method 2

SELECT 
   D.DepartmentID,
   D.DepartmentName
FROM Departments D
LEFT JOIN Employees E
   ON D.DepartmentID = E.DepartmentID
WHERE E.EmployeeID IS  NULL

--12. create a view that displays employee details along with their department and job title.

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

--13.HR should be able to enter a department ID and retrieve its employees, ordered by salary from highest to lowest.

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

--14. Now modify the procedure so that it returns employees earning more than a salary amount supplied by the user, within a specified department.

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

/*15. Requirement: If the user supplies @MinSalary, return employees earning above it. If they omit it, return all employees in the selected department.
Your task: modify the stored procedure so @MinSalary defaults to NULL and the filtering condition handles both cases. */

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


--16. HR wants to retrieve employees using an optional department ID and an optional minimum salary.

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


--17.Keep your optional filters and salary sorting, but also return the total number of employees matching the filters.

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

/*18.Your correction challenge
Make these three changes yourself:
1. Count all rows in the filtered result, not separate department groups.
2. Correct the salary comparison.
3. Restore descending salary order.*/


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


/*19. HR now wants to identify the highest-paid employee in each department.
- FirstName
- LastName
- DepartmentID
- Salary
Requirements:
1. Rank employees within each department by salary, highest first.
2. Return only employees ranked first in their department.
3. If two employees tie for the highest salary in a department, return both.*/
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

--20.Management wants to identify departments whose average employee salary is higher than the average salary across the entire company.

 SELECT
   DepartmentID,
   AVG(Salary) AS AverageDepartmentSalary
 FROM Employees
 GROUP BY DepartmentID
 HAVING AVG(Salary) > (SELECT AVG(Salary) FROM Employees)

 --21.HR wants to identify employees whose salary is higher than the average salary of their own department.
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
    
--22. HR wants the employee or employees with the second-highest distinct salary in each department. If two employees tie at that salary, return both.

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

 --23.HR wants to identify employees whose salary is higher than their direct manager's salary.

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

--24. HR wants to identify departments that currently have no employees assigned to them.

SELECT 
  D.DepartmentID,
  D.DepartmentName
FROM Departments D
LEFT JOIN Employees E
  ON  D.DepartmentID = E.DepartmentID 
WHERE E.DepartmentID IS NULL

--method 2
  SELECT 
     D.DepartmentID,
     D.DepartmentName
    FROM Departments D
    WHERE NOT EXISTS (
        SELECT 1
         FROM Employees E
         WHERE E.DepartmentID = D.DepartmentID
        )

--25.HR wants to identify salaries paid to more than one employee within the same department.

SELECT 
  DepartmentID,
  Salary,
  COUNT(*) AS EmployeeCount
FROM Employees
GROUP BY DepartmentID,
      Salary
 HAVING Count(*) >= 2


--26.HR wants a list of employees hired during the last 12 months

SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate >= DATEADD(MONTH,-12,GETDATE()) 

SELECT 
  EmployeeID,
  FirstName,
  DATEADD(MONTH, -12, GETDATE()) AS HireDate
FROM Employees

/*27.Find employees hired in each year
Business problem: HR wants to analyse employee hiring trends by year.

Return:
- HireYear
- TotalEmployees
Requirements:
1. Extract the year from HireDate.
2. Count employees hired in each year.
3. Group the results by year.
4. Sort from the most recent hiring year to the oldest.*/

SELECT
  YEAR(HireDate) AS HireYear,
  COUNT(*) AS TotaEmployees
FROM Employees
GROUP BY YEAR(HireDate)
ORDER BY YEAR(HireDate) DESC

/*28.Find the monthly hiring count
HR wants to know how many employees were hired in each month of each year.*/

SELECT 
  YEAR(HireDate) AS HireYear,
  MONTH(HireDate) AS HireMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
GROUP BY YEAR(HireDate),
       MONTH(HireDate)

--29.HR wants to identify employees whose joining date fell on a Saturday or Sunday.
SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE DATENAME(WEEKDAY, HireDate) = 'Saturday'
OR DATENAME(WEEKDAY, HireDate) = 'Sunday'


--30.HR wants to identify employees who joined during the same calendar month, regardless of the year.

SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE MONTH(HireDate) = 5

--31.HR wants to find employees hired in May 2025 only.

SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE YEAR(HireDate) = 2025
   AND MONTH(HireDate) = 5

--32.HR wants a list of employees hired between January and March 2025.

SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE YEAR(HireDate) = 2025 AND
   MONTH(HireDate) BETWEEN 1 AND 3 

--33.HR wants employees who joined within the last six months.

SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
 WHERE HireDate >= DATEADD(MONTH, -6, GETDATE())

--34. HR wants to identify employees with more than five years of service.

SELECT
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate <= DATEADD(YEAR, -5, GETDATE())

--35 Find employees hired during the current calendar year.

SELECT 
  EmployeeID,
  FirstName,
  HireDate
FROM Employees
WHERE HireDate BETWEEN '2026-01-01' AND GETDATE()
  
--36.HR wants all employees who joined during the previous calendar year.

SELECT
   EmployeeID,
   FirstName,
   HireDate
FROM Employees
WHERE HireDate >= '2025-01-01' AND 
      HireDate <= '2025-12-31'

--37.HR wants to categorize employees based on their hiring quarter for the year 2025.

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

--38.Count employees hired in each quarter of 2025

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

--39.HR wants to identify which quarter had the highest number of new employees in 2025.

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


--40.HR wants to know what percentage of all employees hired in 2025 joined in each quarter.

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

/*COUNT(*) → counts employees in each quarter.
SUM() → adds those quarterly counts.
OVER() → makes the sum available across all grouped rows without collapsing them into one row.*/

--41.HR wants to track how employee hiring increases month by month throughout 2025.

SELECT
  MONTH(HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees,
  SUM(COUNT(*)) OVER(
    ORDER BY MONTH(HireDate)
    ) AS RunningTotal
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY MONTH(HireDate)

--42.HR wants to identify the busiest hiring month in 2025.

SELECT TOP 1
  MONTH(HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY MONTH(HireDate)
ORDER BY COUNT(*) DESC

--43.HR wants a monthly hiring report with readable month names instead of numbers.

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

--Second Method

SELECT
  DATENAME(MONTH,HireDate) AS HiringMonth,
  COUNT(*) AS TotalEmployees
FROM Employees
WHERE YEAR(HireDate) = 2025
GROUP BY DATENAME(MONTH, HireDate), MONTH(HireDate)
ORDER BY MONTH(HireDate)


--44.HR wants to identify which months had no new employees hired during 2025.

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

--44.HR wants a complete monthly hiring report for 2025, including months with zero hires.

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

