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

-- Create DW db tables

CREATE TABLE DimEmployee(
	EmployeeKey INT IDENTITY(1,1) NOT NULL,
	EmployeeID INT NOT NULL,
	FirstName VARCHAR(40) NOT NULL,
	LastName VARCHAR(40) NOT NULL,
	EmployeeTitle VARCHAR(40) NOT NULL,
	ReportsTo INT,
	IsCurrent INT DEFAULT 1 NOT NULL,
	HireDate DATE NOT NULL,
	ContractEndDate DATE DEFAULT NULL,
	RowChangeReason VARCHAR(200) DEFAULT NULL,
	CONSTRAINT PK_EmployeeKey PRIMARY KEY CLUSTERED (EmployeeKey)
);

CREATE TABLE DimCustomer (
	CustomerKey INT IDENTITY(1,1) NOT NULL,
	CustomerID INT NOT NULL,
	CompanyName VARCHAR(40),
	FirstName VARCHAR(40) NOT NULL,
	LastName VARCHAR(40) NOT NULL,
	CustomerAddress VARCHAR(40) NOT NULL,
	CustomerCountry VARCHAR(15) NOT NULL,
	CustomerRegion VARCHAR(15) DEFAULT 'N/A' NOT NULL,
	CustomerCity VARCHAR(15) NOT NULL,
	CustomerPostalCode VARCHAR(10) NOT NULL,
	CustomerSupportRepID INT NOT NULL,
	CONSTRAINT PK_CustomerKey PRIMARY KEY CLUSTERED (CustomerKey)
);

CREATE TABLE DimTrack
(
	TrackKey INT IDENTITY(1,1) NOT NULL,
	TrackID INT NOT NULL,
	TrackName VARCHAR(200) NOT NULL,
	AlbumTitle VARCHAR(200) NOT NULL,
	GenreName VARCHAR(30) NOT NULL,
	Composer VARCHAR(200),
	ArtistName VARCHAR(100) NOT NULL,
	MediaTypeName VARCHAR(40) NOT NULL,
	
	CONSTRAINT PK_TrackKey PRIMARY KEY CLUSTERED (TrackKey)
);

CREATE TABLE FactSales(
	TrackKey INT NOT NULL,
	CustomerKey INT NOT NULL,
	EmployeeKey INT NOT NULL,
	InvoiceDateKey INT NOT NULL,
	InvoiceID INT NOT NULL,
	UnitPrice NUMERIC(10,2) NOT NULL,
	Quantity INT NOT NULL,
	AmmountPerTrack FLOAT NOT NULL
);

CREATE TABLE	[dbo].[DimDate]
	(	[DateKey] INT PRIMARY KEY, 
		[Date] DATETIME,
		[FullDateUK] CHAR(10), -- Date in dd-MM-yyyy format
		[FullDateUSA] CHAR(10),-- Date in MM-dd-yyyy format
		[DayOfMonth] VARCHAR(2), -- Field will hold day number of Month
		[DayName] VARCHAR(9), -- Contains name of the day, Sunday, Monday 
		[DayOfWeekInMonth] VARCHAR(2), --1st Monday or 2nd Monday in Month
		[DayOfWeekInYear] VARCHAR(2),
		[DayOfQuarter] VARCHAR(3),
		[DayOfYear] VARCHAR(3),
		[WeekOfMonth] VARCHAR(1),-- Week Number of Month 
		[WeekOfQuarter] VARCHAR(2), --Week Number of the Quarter
		[WeekOfYear] VARCHAR(2),--Week Number of the Year
		[Month] VARCHAR(2), --Number of the Month 1 to 12
		[MonthName] VARCHAR(9),--January, February etc
		[MonthOfQuarter] VARCHAR(2),-- Month Number belongs to Quarter
		[Quarter] CHAR(1),
		[QuarterName] VARCHAR(9),--First,Second..
		[Year] CHAR(4),-- Year value of Date stored in Row
		[YearName] CHAR(7), --CY 2012,CY 2013
		[MonthYear] CHAR(10), --Jan-2013,Feb-2013
		[MMYYYY] CHAR(6),
		[FirstDayOfMonth] DATE,
		[LastDayOfMonth] DATE,
		[FirstDayOfQuarter] DATE,
		[LastDayOfQuarter] DATE,
		[FirstDayOfYear] DATE,
		[LastDayOfYear] DATE,
		[IsHolidayUSA] BIT,-- Flag 1=National Holiday, 0-No National Holiday
		[IsWeekday] BIT,-- 0=Week End ,1=Week Day
		[HolidayUSA] VARCHAR(50),--Name of Holiday in US
		
	)
;
