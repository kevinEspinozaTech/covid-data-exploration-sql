@echo off
rem Loads deaths.tsv and vaccinations.tsv (created by prepare_owid_tables.py) into SQL Server.
rem Uses Windows authentication against the local default instance.
cd /d "%~dp0"
bcp "[Portfolio Project 1].dbo.['covid-data-deaths$']" in deaths.tsv -S localhost -T -u -c -C 65001 -t "\t" -r 0x0a
bcp "[Portfolio Project 1].dbo.['covid-data-vaccinations$']" in vaccinations.tsv -S localhost -T -u -c -C 65001 -t "\t" -r 0x0a
