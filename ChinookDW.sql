-- If staging db exists, drop it.

USE master
GO
IF EXISTS (SELECT * FROM SYSDATABASES WHERE NAME='ChinookDW')
BEGIN
	ALTER DATABASE ChinookDW
	SET SINGLE_USER 
	WITH ROLLBACK IMMEDIATE;
		DROP DATABASE ChinookDW
END
GO
-- Create Data Warehouse db

CREATE DATABASE ChinookDW;
GO
USE ChinookDW;
GO

-- Create DW db tables

CREATE TABLE DimEmployee (
	EmployeeKey INT IDENTITY(1,1) NOT NULL,
	EmployeeID INT NOT NULL,
	EmployeeFirstName VARCHAR(40) NOT NULL,
	EmployeeLastName VARCHAR(40) NOT NULL,
	EmployeeTitle VARCHAR(40) NOT NULL,
	EmployeeReportsTo INT,
	--EmployeeIsCurrent INT DEFAULT 1 NOT NULL,
	EmployeeHireDate DATE NOT NULL,
	--EmployeeContractEndDate DATE DEFAULT NULL,
	--EmployeeRowChangeReason VARCHAR(200) DEFAULT NULL,
	CONSTRAINT PK_EmployeeKey PRIMARY KEY CLUSTERED (EmployeeKey)
);

CREATE TABLE DimCustomer (
	CustomerKey INT IDENTITY(1,1) NOT NULL,
	CustomerID INT NOT NULL,
	CompanyName NVARCHAR(50),
	CustomerFirstName NVARCHAR(40) NOT NULL,
	CustomerLastName NVARCHAR(40) NOT NULL,
	CustomerAddress VARCHAR(40) NOT NULL,
	CustomerCountry VARCHAR(15) NOT NULL,
	CustomerState VARCHAR(15),
	CustomerCity VARCHAR(20) NOT NULL,
	CustomerPostalCode VARCHAR(10),
	CustomerSupportRepID INT NOT NULL,
	CONSTRAINT PK_CustomerKey PRIMARY KEY CLUSTERED (CustomerKey)
);

CREATE TABLE DimTrack (
	TrackKey INT IDENTITY(1,1) NOT NULL, 
	TrackID INT NOT NULL,
	TrackName VARCHAR(200) NOT NULL,
	AlbumTitle VARCHAR(200) NOT NULL, 
	GenreName VARCHAR(30) NOT NULL,  
	TrackComposer VARCHAR(200),
	ArtistName VARCHAR(100) NOT NULL, 
	MediaTypeName VARCHAR(40) NOT NULL, 
	CONSTRAINT PK_TrackKey PRIMARY KEY CLUSTERED (TrackKey)
);

CREATE TABLE FactSales (
	TrackKey INT NOT NULL,
	CustomerKey INT NOT NULL,
	EmployeeKey INT NOT NULL,
	InvoiceDateKey INT NOT NULL,
	InvoiceDate DATE,
	InvoiceID INT NOT NULL,
	UnitPrice NUMERIC(10,2) NOT NULL,
	Quantity INT NOT NULL,
	RevenuePerTrack FLOAT NOT NULL
);

DECLARE @StartDate DATE = '1947-01-01'		-- Covers employee birth dates from 1947
DECLARE @EndDate DATE = '2027-12-31'   -- Cover past + future

-- Drop table if exists
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL
    DROP TABLE dbo.DimDate;

/**********************************************************************************/

CREATE TABLE dbo.DimDate (	
	DateKey INT PRIMARY KEY, 
	[Date] DATE,
	FullDateUK CHAR(10),				-- Date in dd-MM-yyyy format
	FullDateUSA CHAR(10),				-- Date in MM-dd-yyyy format
	DayOfMonth VARCHAR(2),				-- Field will hold day number of Month
	DayName VARCHAR(9),					-- Contains name of the day, Sunday, Monday 
	DayOfWeekUSA CHAR(1),				-- First Day Sunday=1 and Saturday=7
	DayOfWeekInMonth VARCHAR(2),		-- 1st Monday or 2nd Monday in Month
	DayOfWeekInYear VARCHAR(2),
	DayOfQuarter VARCHAR(3),
	DayOfYear VARCHAR(3),
	WeekOfMonth VARCHAR(1),				-- Week Number of Month 
	WeekOfQuarter VARCHAR(2),			-- Week Number of the Quarter
	WeekOfYear VARCHAR(2),				-- Week Number of the Year
	[Month] VARCHAR(2),					-- Number of the Month 1 to 12
	MonthName VARCHAR(9),				-- January, February etc
	MonthOfQuarter VARCHAR(2),			-- Month Number belongs to Quarter
	Quarter CHAR(1),
	QuarterName VARCHAR(9),				-- First,Second..
	[Year] CHAR(4),						-- Year value of Date stored in Row
	YearName CHAR(7),					-- CY 2012,CY 2013
	MonthYear CHAR(10),					-- Jan-2013,Feb-2013
	MMYYYY CHAR(6),
	FirstDayOfMonth DATE,
	LastDayOfMonth DATE,
	FirstDayOfQuarter DATE,
	LastDayOfQuarter DATE,
	FirstDayOfYear DATE,
	LastDayOfYear DATE,
	IsHolidayUSA BIT,					-- Flag 1=National Holiday, 0-No National Holiday
	IsHolidayUK BIT,					-- Flag 1=National Holiday, 0-No National Holiday
	IsWeekday BIT,						-- 0=Week End ,1=Week Day
	HolidayUSA VARCHAR(50),				-- Name of Holiday in US
	HolidayUK VARCHAR(50),				-- Name of Holiday in US
);

/***********************	Insert Data to DimDate		*******************************/

--Temporary Variables To Hold the Values During Processing of Each Date of Year
DECLARE
	@DayOfWeekInMonth INT,
	@DayOfWeekInYear INT,
	@DayOfQuarter INT,
	@WeekOfMonth INT,
	@CurrentYear INT,
	@CurrentMonth INT,
	@CurrentQuarter INT

/*Table Data type to store the day of week count for the month and year*/
DECLARE @DayOfWeek TABLE (DOW INT, MonthCount INT, QuarterCount INT, YearCount INT)

INSERT INTO @DayOfWeek VALUES (1, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (2, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (3, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (4, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (5, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (6, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (7, 0, 0, 0)

--Extract and assign part of Values from Current Date to Variable

DECLARE @CurrentDate AS DATETIME = @StartDate
SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

/********************************************************************************************/
--Proceed only if Start Date(Current date ) is less than End date you specified above

WHILE @CurrentDate <= @EndDate
BEGIN
 
/*Begin day of week logic*/

         /*Check for Change in Month of the Current date if Month changed then 
          Change variable value*/
	IF @CurrentMonth != DATEPART(MM, @CurrentDate) 
	BEGIN
		UPDATE @DayOfWeek
		SET MonthCount = 0
		SET @CurrentMonth = DATEPART(MM, @CurrentDate)
	END

        /* Check for Change in Quarter of the Current date if Quarter changed then change 
         Variable value*/

	IF @CurrentQuarter != DATEPART(QQ, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET QuarterCount = 0
		SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)
	END
       
        /* Check for Change in Year of the Current date if Year changed then change 
         Variable value*/
	

	IF @CurrentYear != DATEPART(YY, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET YearCount = 0
		SET @CurrentYear = DATEPART(YY, @CurrentDate)
	END
	
        -- Set values in table data type created above from variables 

	UPDATE @DayOfWeek
	SET 
		MonthCount = MonthCount + 1,
		QuarterCount = QuarterCount + 1,
		YearCount = YearCount + 1
	WHERE DOW = DATEPART(DW, @CurrentDate)

	SELECT
		@DayOfWeekInMonth = MonthCount,
		@DayOfQuarter = QuarterCount,
		@DayOfWeekInYear = YearCount
	FROM @DayOfWeek
	WHERE DOW = DATEPART(DW, @CurrentDate)
	
/*End day of week logic*/


/* Populate Your Dimension Table with values*/
	
	INSERT INTO [dbo].[DimDate]
	SELECT
		
		CONVERT (char(8),@CurrentDate,112) as DateKey,
		@CurrentDate AS Date,
		CONVERT (char(10),@CurrentDate,103) as FullDateUK,
		CONVERT (char(10),@CurrentDate,101) as FullDateUSA,
		DATEPART(DD, @CurrentDate) AS DayOfMonth,
		
		DATENAME(DW, @CurrentDate) AS DayName,
		DATEPART(DW, @CurrentDate) AS DayOfWeekUSA,

		
		@DayOfWeekInMonth AS DayOfWeekInMonth,
		@DayOfWeekInYear AS DayOfWeekInYear,
		@DayOfQuarter AS DayOfQuarter,
		DATEPART(DY, @CurrentDate) AS DayOfYear,
		DATEPART(WW, @CurrentDate) + 1 - DATEPART(WW, CONVERT(VARCHAR, DATEPART(MM, @CurrentDate)) + '/1/' + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate))) AS WeekOfMonth,
		(DATEDIFF(DD, DATEADD(QQ, DATEDIFF(QQ, 0, @CurrentDate), 0), @CurrentDate) / 7) + 1 AS WeekOfQuarter,
		DATEPART(WW, @CurrentDate) AS WeekOfYear,
		DATEPART(MM, @CurrentDate) AS Month,
		DATENAME(MM, @CurrentDate) AS MonthName,
		CASE
			WHEN DATEPART(MM, @CurrentDate) IN (1, 4, 7, 10) THEN 1
			WHEN DATEPART(MM, @CurrentDate) IN (2, 5, 8, 11) THEN 2
			WHEN DATEPART(MM, @CurrentDate) IN (3, 6, 9, 12) THEN 3
			END AS MonthOfQuarter,
		DATEPART(QQ, @CurrentDate) AS Quarter,
		CASE DATEPART(QQ, @CurrentDate)
			WHEN 1 THEN 'First'
			WHEN 2 THEN 'Second'
			WHEN 3 THEN 'Third'
			WHEN 4 THEN 'Fourth'
			END AS QuarterName,
		DATEPART(YEAR, @CurrentDate) AS Year,
		'CY ' + CONVERT(VARCHAR, DATEPART(YEAR, @CurrentDate)) AS YearName,
		LEFT(DATENAME(MM, @CurrentDate), 3) + '-' + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate)) AS MonthYear,
		RIGHT('0' + CONVERT(VARCHAR, DATEPART(MM, @CurrentDate)),2) + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate)) AS MMYYYY,
		CONVERT(DATETIME, CONVERT(DATE, DATEADD(DD, - (DATEPART(DD, @CurrentDate) - 1), @CurrentDate))) AS FirstDayOfMonth,
		CONVERT(DATETIME, CONVERT(DATE, DATEADD(DD, - (DATEPART(DD, (DATEADD(MM, 1, @CurrentDate)))), DATEADD(MM, 1, @CurrentDate)))) AS LastDayOfMonth,
		DATEADD(QQ, DATEDIFF(QQ, 0, @CurrentDate), 0) AS FirstDayOfQuarter,
		DATEADD(QQ, DATEDIFF(QQ, -1, @CurrentDate), -1) AS LastDayOfQuarter,
		CONVERT(DATETIME, '01/01/' + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate))) AS FirstDayOfYear,
		CONVERT(DATETIME, '12/31/' + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate))) AS LastDayOfYear,
		NULL AS IsHolidayUSA,
		CASE DATEPART(DW, @CurrentDate)
			WHEN 1 THEN 0
			WHEN 2 THEN 1
			WHEN 3 THEN 1
			WHEN 4 THEN 1
			WHEN 5 THEN 1
			WHEN 6 THEN 1
			WHEN 7 THEN 0
			END AS IsWeekday,
		NULL AS HolidayUSA, Null, Null

	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END



/*Add HOLIDAYS UK*/
	
-- Good Friday  April 18 
	UPDATE [dbo].[DimDate]
		SET HolidayUK = 'Good Friday'
	WHERE [Month] = 4 AND [DayOfMonth]  = 18
-- Easter Monday  April 21 
	UPDATE [dbo].[DimDate]
		SET HolidayUK = 'Easter Monday'
	WHERE [Month] = 4 AND [DayOfMonth]  = 21
-- Boxing Day  December 26  	
    UPDATE [dbo].[DimDate]
		SET HolidayUK = 'Boxing Day'
	WHERE [Month] = 12 AND [DayOfMonth]  = 26	
--CHRISTMAS
	UPDATE [dbo].[DimDate]
		SET HolidayUK = 'Christmas Day'
	WHERE [Month] = 12 AND [DayOfMonth]  = 25
--New Years Day
	UPDATE [dbo].[DimDate]
		SET HolidayUK  = 'New Year''s Day'
	WHERE [Month] = 1 AND [DayOfMonth] = 1
	
	UPDATE [dbo].[DimDate] 
	SET IsHolidayUK = CASE WHEN HolidayUK IS NULL THEN 0 WHEN HolidayUK IS NOT NULL THEN 1 END 


	/*Add HOLIDAYS USA*/

	/*CHRISTMAS*/
	UPDATE [dbo].[DimDate]
		SET HolidayUSA = 'Christmas Day'
		
	WHERE [Month] = 12 AND [DayOfMonth]  = 25

	/*New Years Day*/
	UPDATE [dbo].[DimDate]
		SET HolidayUSA = 'New Year''s Day'
	WHERE [Month] = 1 AND [DayOfMonth] = 1
	
	UPDATE [dbo].[DimDate]
		SET IsHolidayUSA = CASE WHEN HolidayUSA  IS NULL THEN 0 WHEN HolidayUSA  IS NOT NULL THEN 1 END

SELECT * FROM ChinookDW.dbo.DimDate;


/*******************************************************************************************************************************************************/


-----------------------------------------------


 --FactSales Foreign Keys
alter table [ChinookDW].[dbo].FactSales
	add constraint FactSales_DimCustomer_CustomerKey_fk
		foreign key (CustomerKey) references [ChinookDW].[dbo].DimCustomer (CustomerKey);

alter table [ChinookDW].[dbo].FactSales
	add constraint FactSales_DimEmployee_EmployeeKey_fk
		foreign key (EmployeeKey) references [ChinookDW].[dbo].DimEmployee (EmployeeKey);

alter table [ChinookDW].[dbo].FactSales
	add constraint FactSales_DimTrack_TrackKey_fk
		foreign key (TrackKey) references [ChinookDW].[dbo].DimTrack (TrackKey);
	
alter table [ChinookDW].[dbo].FactSales
	add constraint FactSales_DimDate_Date_Dim_id_fk
		foreign key (InvoiceDateKey) references [ChinookDW].[dbo].[DimDate] (DateKey);



-- 3. inserts data from Staging to the DW

-- Insert the Data from Employees to DimEmployee

Insert into [ChinookDW].[dbo].[DimEmployee] (
	[EmployeeID], 
	[EmployeeFirstName], 
	[EmployeeLastName], 
	[EmployeeTitle], 
	[EmployeeReportsTo], 
	[EmployeeHireDate])

Select 
	[EmployeeID], 
	[FirstName], 
	[LastName], 
	[Title], 
	[ReportsTo], 
	[HireDate]
from [ChinookStaging].[dbo].[Employees];

 

-- Insert the Data from Customers to DimCustomer

INSERT INTO [ChinookDW].[dbo].[DimCustomer] (
    CustomerId, 
    CompanyName, 
    [CustomerFirstName], 
    [CustomerLastName], 
    [CustomerAddress], 
    [CustomerCountry], 
    [CustomerState], 
    [CustomerCity], 
    [CustomerPostalCode], 
    [CustomerSupportRepId])

SELECT 
    [CustomerId], 
    ISNULL([Company], 'N/A'),
    [FirstName], 
    [LastName], 
    ISNULL([Address], 'N/A'),
    [Country], 
    ISNULL([State], 'N/A'),
    [City],
    ISNULL([PostalCode], 'N/A'),
    [SupportRepId]
FROM [ChinookStaging].[dbo].[Customers];



-- Insert the Data from Tracks to DimTrack

Insert into [ChinookDW].[dbo].[DimTrack] (
	TrackID, 
	TrackName, 
	AlbumTitle, 
	GenreName, 
	TrackComposer, 
	ArtistName, 
	MediaTypeName)

(Select 
	TrackId, 
	TrackName, 
	AlbumTitle, 
	GenreName, 
	Composer, 
	ArtistName, 
	MediaTypeName   
from [ChinookStaging].[dbo].[Tracks]);


alter table [ChinookDW].[dbo].FactSales alter column InvoiceDateKey int null;




-- Insert the Data from Sales to FactSales

insert into [ChinookDW].[dbo].FactSales (
	TrackKey, 
	CustomerKey, 
	EmployeeKey, 
	InvoiceDateKey, 
	InvoiceDate, 
	InvoiceID, 
	UnitPrice, 
	Quantity, 
	RevenuePerTrack)

(select
	t.TrackKey, 
	c.customerkey, 
	e.employeekey,
    dorder.[DateKey] as InvoiceDatakey,
	s.InvoiceDate,
    s.InvoiceId, 
	s.UnitPrice,
	s.quantity,
    s.LineTotal
from [ChinookStaging].[dbo].sales s
join [ChinookDW].[dbo].DimCustomer c
on s.[CustomerID] = c.CustomerID
join [ChinookDW].[dbo].DimEmployee e
on s.EmployeeId = e.EmployeeID
join [ChinookDW].[dbo].DimTrack t
on s.TrackId = t.TrackID
join  [ChinookDW].[dbo].[DimDate] dorder 
on s.[InvoiceDate] = dorder.[Date]   

);

SELECT * FROM ChinookDW.dbo.DimCustomer;
SELECT * FROM ChinookDW.dbo.DimDate;
SELECT * FROM ChinookDW.dbo.DimEmployee;
SELECT * FROM ChinookDW.dbo.DimTrack;
SELECT * FROM ChinookDW.dbo.FactSales;
