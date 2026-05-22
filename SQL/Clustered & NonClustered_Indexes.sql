-- Learning Indexes.

-- Clustered and Non-Clustered Indexes.

USE LA_Crime_DB;

-- Turn on Measurement Tools.

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Creating Index
CREATE NONCLUSTERED INDEX idx_LA_Crime_DB_part_1_2 ON dbo.LA_Crime (part_1_2);

SELECT *
FROM dbo.LA_Crime
WHERE part_1_2 = 'Normal';

SELECT DISTINCT part_1_2
FROM dbo.LA_Crime;

-- Key Learning 
/*
Low_Selectivity_Column:
A column with very few distinct values is called Low Selectivity Column.

High Selectivity Column:
A column that returns very few rows for a specific value is called a high selectivity column.

“Indexes are not effective on columns with low selectivity (few distinct values). In such cases,
SQL Server prefers a table scan because using an index would require many key lookups,
making it more expensive.”
*/


-- Running Without Index
SELECT *
FROM dbo.LA_Crime
WHERE dr_no = 151816385;

-- Logical reads mean how many pages sql server reads.
/*
Logical reads --> 37296
CPU Time --> 125 ms
Elapsed Time --> 162 ms
Table Scan
*/

-- Running With Index
CREATE NONCLUSTERED INDEX idx_LA_Crime_dr_no ON LA_Crime (dr_no);

SELECT *
FROM dbo.LA_Crime
WHERE dr_no = 151816385;

/*
Logical reads --> 4
CPU Time --> 0ms
Elapsed Time --> 43ms
Index Seek
*/

-- Conclusion:
/*
We tested indexing on LA_Crime (1M+ rows) and observed that nonclustered index
on a low selectivity column (part_1_2 with only “Normal” and “Serious”) did not improve performance,
as SQL Server still used a table scan with high logical reads.
However, when we created a nonclustered index on a high selectivity column (dr_no),
performance improved significantly with Index Seek, very low logical reads,
and reduced execution time. This shows that indexes are effective only on high selectivity columns
where they reduce data scanning and improve query performance.
*/

-- Without Index
SELECT * 
FROM dbo.LA_Crime
WHERE area_name = 'Newton';

/*
logical reads 37296
CPU time = 235 ms
elapsed time = 900 ms.
*/

-- With Index
CREATE NONCLUSTERED INDEX idx_LA_Crime_area_name ON LA_Crime (area_name);

SELECT *
FROM dbo.LA_Crime
WHERE area_name = 'Newton';

/*
logical reads 37296
CPU time = 250 ms
elapsed time = 897 ms.
*/

--Conclusion:
/*
Even after creating a nonclustered index on area_name,
SQL Server still used a table scan because the query returned a large number of rows.
In such cases, the cost of using the index plus key lookups is higher than scanning the entire table,
so the optimizer ignores the index.
*/

/*
LEFT PREFIX RULE:
A composite index can only be used from LEFT to RIGHT order.
SQL Server cannot use the index efficiently
if the query does not include the leftmost column(s) of the index.
*/

-- Droping the Index:
DROP INDEX idx_LA_Crime_area_name ON LA_Crime;
DROP INDEX idx_LA_Crime_DB_part_1_2 ON LA_Crime;

-- Without Index
SELECT area_name,part_1_2
FROM dbo.LA_Crime
WHERE area_name = 'Newton'
AND part_1_2 = 'Normal';

/*
logical reads 37296
CPU time = 172 ms
elapsed time = 242 ms.
Table Scan
*/

-- With Index

-- Create Composite Index.
CREATE NONCLUSTERED INDEX idx_LA_Crime_area_part ON LA_Crime (area_name,part_1_2);

SELECT area_name,part_1_2
FROM dbo.LA_Crime
WHERE area_name = 'Newton'
AND part_1_2 = 'Normal';

/*
logical reads 107
CPU time = 15 ms
elapsed time = 178 ms.
Index Seek
*/

/*
Composite indexes work efficiently when queries match the leftmost column(s)
and significantly reduce the number of rows being scanned,
resulting in lower logical reads and faster execution using Index Seek instead of Table Scan.
*/

-- Not Following the Left Prefix Rule:

SELECT area_name,part_1_2
FROM dbo.LA_Crime
WHERE part_1_2 = 'Normal';

/*
logical reads 6728
CPU time = 250 ms
elapsed time = 3129 ms.
Index Scan
*/

/*
Even if the leftmost column of a composite index is not used,
SQL Server can still use the index in the form of an Index Scan.
However, it cannot perform an Index Seek because the left prefix rule is not satisfied.
*/

-- Key Learning:
/*
SQL Server does not always use Index Seek even if an index exists.
It uses a cost-based optimizer that compares Index Seek, Index Scan, and Table Scan,
and chooses the cheapest operation based on estimated rows,
key lookup cost, and data distribution statistics.
*/