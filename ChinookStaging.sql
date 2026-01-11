-- If staging db exists, drop it.
USE master
IF EXISTS (SELECT * FROM SYSDATABASES WHERE NAME='ChinookStaging')
BEGIN
	ALTER DATABASE ChinookStaging 
	SET SINGLE_USER 
	WITH ROLLBACK IMMEDIATE;
		DROP DATABASE ChinookStaging
END

-- Create staging db

USE Chinook;
CREATE DATABASE ChinookStaging;

-- Create staging db tables

-- Employees

SELECT EmployeeId, LastName, FirstName, Title
INTO ChinookStaging.dbo.Employees
FROM Employee;

SELECT * FROM ChinookStaging.dbo.Employees;

-- Customers

SELECT CustomerId, FirstName, LastName, Company, Address, City, State, Country, PostalCode, SupportRepId
INTO ChinookStaging.dbo.Customers
FROM Customer;

SELECT * FROM ChinookStaging.dbo.Customers;

-- Tracks

SELECT t.TrackId, t.Name AS TrackName, al.Title AS AlbumTitle, g.Name AS GenreName, t.Composer, a.Name AS ArtistName, m.Name AS MediaTypeName
INTO ChinookStaging.dbo.Tracks
FROM Track t
JOIN Album al
	ON al.AlbumId = t.AlbumId
JOIN Genre g
	ON g.GenreId = t.GenreId
JOIN Artist a
	ON al.ArtistId = a.ArtistId
JOIN MediaType m
	ON m.MediaTypeId = t.MediaTypeId;

SELECT * FROM ChinookStaging.dbo.Tracks
ORDER BY TrackId;

-- Sales

SELECT t.TrackId, i.InvoiceId, e.EmployeeId, i.CustomerId, i.InvoiceDate, t.UnitPrice, il.Quantity
INTO ChinookStaging.dbo.Sales
FROM Track t
LEFT JOIN InvoiceLine il
	ON t.TrackId = il.TrackId
LEFT JOIN Invoice i
	ON il.InvoiceId = i.InvoiceId
LEFT JOIN Customer c
	ON i.CustomerId = c.CustomerId
LEFT JOIN Employee e
	ON e.EmployeeId = c.SupportRepId
ORDER BY TrackId;