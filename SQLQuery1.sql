use AdventureWorks2019
go 
select DB_NAME() AS Database_Name,
		sc.name AS Schema_Name,
		o.name AS Table_Name,
		i.name AS Index_Name,
		i.type_desc AS Index_Type

FROM sys.indexes i
	INNER JOIN sys.objects o ON i.object_id = o.object_id
	INNER JOIN sys.schemas sc ON o.schema_id = sc.schema_id

WHERE i.name IS NOT NULL
		AND o.type = 'U'

		ORDER BY o.name,
				i.type;

---crear un index no agrupado 
--CREATE INDEX nombreindice ON  schema.tabl (columna) [asc/desc]

CREATE NONCLUSTERED INDEX IX_SalesPerson_SalesQuota_SalesYTD ON Sales.SalesPerson(SalesQuota, SalesYTD)


CREATE TABLE Bookstore2
(ISBN_NO VARCHAR(15) NOT NULL PRIMARY KEY,
SHORT_DESC VARCHAR (100),
AUTHOR VARCHAR(40),
PUBLISHER VARCHAR(40),
PRICE FLOAT,
INDEX IX_SHORTDESC_PUBISHER(SHORT_DESC, PUBLISHER)
);