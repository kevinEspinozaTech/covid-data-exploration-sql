-- Creates the database and the two tables expected by SQLProject1.sql.
-- Numeric columns are FLOAT, as an Excel import would create them.
IF DB_ID('Portfolio Project 1') IS NULL CREATE DATABASE [Portfolio Project 1];
GO
USE [Portfolio Project 1];
GO
DROP TABLE IF EXISTS dbo.['covid-data-deaths$'];
DROP TABLE IF EXISTS dbo.['covid-data-vaccinations$'];
CREATE TABLE dbo.['covid-data-deaths$'] (
    iso_code nvarchar(255), continent nvarchar(255), location nvarchar(255), date datetime,
    population float, total_cases float, new_cases float, total_deaths float, new_deaths float);
CREATE TABLE dbo.['covid-data-vaccinations$'] (
    iso_code nvarchar(255), continent nvarchar(255), location nvarchar(255), date datetime,
    new_vaccinations float);
GO
