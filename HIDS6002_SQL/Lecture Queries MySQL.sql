use synthea;


		/*MySQL Compatible*/
		
		
		
		/*The Select Statement*/
		SELECT
			'Hello World' AS txt
			, CONCAT(p.LAST, ', ', p.FIRST) AS FullName
			, (SELECT DESCRIPTION FROM observations o WHERE o.PATIENT = p.Id
					ORDER BY `DATE` DESC LIMIT 1) AS LastObservDescr
			, (SELECT `VALUE` FROM observations o WHERE o.PATIENT = p.Id
					ORDER BY `DATE` DESC LIMIT 1) AS LastObservValue
			, CASE
					WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) >= 65 THEN 'Senior'
					WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) >= 18 THEN 'Adult'
					ELSE 'Child'
				END AS AgeGroup
			, p.COUNTY
			, p.ZIP
			, LAG(p.LAST)  OVER (PARTITION BY p.COUNTY ORDER BY p.LAST) AS PrevLast
			, LEAD(p.LAST) OVER (PARTITION BY p.COUNTY ORDER BY p.LAST) AS NextLast			
			, ROW_NUMBER() OVER (PARTITION BY p.COUNTY ORDER BY p.LAST) AS rowNum
		FROM
			patients p
		ORDER BY
			COUNTY
			, rowNum;



		/*identify the conditions and their codes*/
		select distinct
			DESCRIPTION
			, CODE
		from
			conditions
		where
			CODE IN (59621000, 429007001, 55822004, 196416002)
		order by
			DESCRIPTION;




		/*identify the conditions and their codes*/
		select distinct
			DESCRIPTION
			, CODE
		from
			conditions
		where
			lower(DESCRIPTION) LIKE '%hyper%'
		order by
			DESCRIPTION






		/*Find the patients with HTN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			join conditions c on p.Id = c.PATIENT
		where
			c.CODE = 59621000;
			
			

		/*Not Suggested*/
		/*Find the patients with HTN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			join conditions c on p.Id = c.PATIENT
		where
			c.DESCRIPTION = 'Hypertension'
			/*c.DESCRIPTION = 'HTN'*/
			/*c.DESCRIPTION = 'hypertension'*/;



			
		/*Find the patients with HTN with Multiple Conditions*/
		SELECT
			p.Id
			, p.LAST
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.`START`
			, c.CODE
		FROM
			patients p
			JOIN conditions c ON p.Id = c.PATIENT
				AND c.`START` <= DATE_SUB(CURDATE(), INTERVAL 25 YEAR)
		WHERE
			c.CODE = 59621000;



		/*Using Order BY*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			join conditions c on p.Id = c.PATIENT
		where
			c.CODE = 59621000
		ORDER BY
			p.CITY DESC
			, p.ZIP;




		/*INNER JOIN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			JOIN conditions c
				ON p.Id = c.PATIENT
		WHERE 
			c.CODE = 59621000;
			
			

		/*INNER JOIN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			JOIN conditions c
				ON p.Id = c.PATIENT
					AND c.CODE = 59621000;
	
	
		/*INNER JOIN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			JOIN (SELECT *
					FROM Conditions c2
					WHERE c2.CODE = 59621000) c
				ON p.Id = c.PATIENT;
			



		/*Gettgin a Row Count*/
		Select count(iD) AS Count FROM patients;

		/*LEFT JOIN*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			LEFT JOIN conditions c 
					ON p.Id = c.PATIENT
						AND CODE = 59621000;


		/*LEFT JOIN (Filter in WHERE)*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
			, c.CODE
		from
			patients p
			LEFT JOIN conditions c
				ON p.Id = c.PATIENT
		WHERE 
			c.CODE = 59621000;
	
		

		/*NOT EXISTS*/
		Select
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
		from
			patients p
		WHERE 
			NOT EXISTS(
				SELECT 1
				FROM conditions
				WHERE
					conditions.CODE = 59621000
					and conditions.PATIENT = p.Id);
			
			
			
			
		/*Booleans, and BETWEEN*/
		SELECT
			p.Id
			, p.Last
			, p.SSN
			, p.CITY
			, p.ZIP
		FROM
			patients p
		WHERE 
			EXISTS(
				SELECT 1
				FROM conditions
				WHERE
					conditions.CODE = 59621000
					and conditions.PATIENT = p.Id)
			AND
				(
					p.ZIP BETWEEN 1000 AND 1250
					OR p.ZIP > 2000 AND p.ZIP < 2500
				)
		ORDER BY
			p.ZIP ;




		/*Where are they with zip (Waltham twice)*/
		Select
			p.CITY
			, p.ZIP
			, count(p.First) TheCount
		from
			patients p
			join conditions c on p.Id = c.PATIENT
		where
			c.CODE = 59621000
		Group By
			p.CITY
			, p.ZIP
		Order by
			City
			, ZIP;




		/*Where are they by city*/
		Select
			p.CITY
			, SUM(p.ZIP) TheSumZip
			, AVG(p.ZIP) TheAVGZip
			, COUNT(p.ZIP) TheCount
		from
			patients p
			join conditions c on p.Id = c.PATIENT
		where
			c.CODE = 59621000
		Group By
			p.CITY
		HAVING
			count(p.Zip) >= 3
		Order by
			TheCount DESC;



		/*of the patients with htn how many*/
		/*had an encounter where the sbp > 150*/
		/*evaluate observations table*/
		select distinct
			o.DESCRIPTION
			, o.CODE
		from 
			observations o
		order by
			o.DESCRIPTION;



		/*wrong way to find all patients with sbp > 150*/
		Select
			p.Id , p.LAST , e.START , e.ENCOUNTERCLASS , e.DESCRIPTION
			, o.DATE , o.DESCRIPTION SBP , o.VALUE
		from
			patients p
			join encounters e on p.Id = e.PATIENT
			join observations o on p.Id = o.PATIENT
		where
			EXISTS (
				Select 1
				from
					conditions c
				where
					c.PATIENT = p.Id
					and c.CODE = 59621000)
			and o.CODE = '8480-6'
			and VALUE > '150';


		


		/*MySQL Compatible*/
		/*Better way to find patients if SBP > 150*/
		DROP TEMPORARY TABLE IF EXISTS pdata;

		CREATE TEMPORARY TABLE pdata AS
		SELECT
			p.Id, p.LAST,
			e.START_DT AS `START`, e.ENCOUNTERCLASS, e.DESCRIPTION
			, o.DATE_DT AS `DATE`, o.DESCRIPTION AS SBP, o.`VALUE`
		FROM
			patients p
			JOIN (
				SELECT *, STR_TO_DATE(REPLACE(REPLACE(`START`, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS START_DT
				FROM encounters
			) e ON p.Id = e.PATIENT
			JOIN (
				SELECT *, STR_TO_DATE(REPLACE(REPLACE(`DATE`, 'T', ' '), 'Z', ''), '%Y-%m-%d %H:%i:%s') AS DATE_DT
				FROM observations
			) o ON p.Id = o.PATIENT
		WHERE
			EXISTS (
				SELECT 1
				FROM conditions c
				WHERE c.PATIENT = p.Id AND c.CODE = 59621000
			)
			AND o.CODE = '8480-6'
			AND o.`VALUE` REGEXP '^[+-]?[0-9]*\\.?[0-9]+$'
			AND CAST(o.`VALUE` AS DECIMAL(10,2)) > 150
			AND o.DATE_DT BETWEEN DATE_SUB(e.START_DT, INTERVAL 1 DAY) AND DATE_ADD(e.START_DT, INTERVAL 1 DAY);

		SELECT * FROM pdata
		ORDER BY LAST, Id, `DATE`;



	



/*Now the correct way to find patients if SBP > 150*/
DROP TEMPORARY TABLE IF EXISTS pdata;

CREATE TEMPORARY TABLE pdata AS
SELECT
    p.Id, p.LAST, e.`START`, e.ENCOUNTERCLASS, e.DESCRIPTION
    , o.`DATE`, o.DESCRIPTION AS SBP, o.`VALUE`
FROM
    patients p
    JOIN encounters e ON e.PATIENT = p.Id
    JOIN observations o ON o.ENCOUNTER = e.Id
WHERE
    EXISTS (
        SELECT 1
        FROM conditions c
        WHERE c.PATIENT = p.Id AND c.CODE = 59621000
    )
    AND o.CODE = '8480-6'
    AND o.`VALUE` REGEXP '^[+-]?[0-9]*\\.?[0-9]+$'
    AND CAST(o.`VALUE` AS DECIMAL(10,2)) > 150;

SELECT * FROM pdata
ORDER BY LAST, Id, `DATE`;


/*Just the patients Id that have severe HTN*/
SELECT DISTINCT pdata.Id, pdata.LAST
FROM pdata
ORDER BY LAST;




/*where are all the patients with severe HTN*/
SELECT
    p.CITY
    , COUNT(p.First) AS TheCount
FROM
    patients p
WHERE
    p.Id IN (SELECT pdata.Id FROM pdata)
GROUP BY
    p.CITY
ORDER BY
    TheCount DESC;





/*MySQL Compatible*/
/*severe hypertensives taking and not taking antihypertensives, NO filter*/
DROP TEMPORARY TABLE IF EXISTS Rx;

CREATE TEMPORARY TABLE Rx (
    Code BIGINT,
    Description VARCHAR(50)
);

INSERT INTO Rx (Code, Description)
VALUES
    (866414, 'metoprolol'), (999967, 'amlodipine/hctz')
    , (197361, 'amlodipine'), (833036, 'captopril')
    , (897718, 'verapamil');

SELECT DISTINCT
    p.Id, p.LAST, m.DESCRIPTION
FROM
    pdata p
    LEFT JOIN (
        SELECT m2.PATIENT, m2.DESCRIPTION
        FROM medications m2
            JOIN Rx ON m2.CODE = Rx.Code
    ) m ON p.Id = m.PATIENT
ORDER BY
    Id;




/*MySQL Compatible*/
/*severe hypertensives NOT taking antihypertensives*/
DROP TEMPORARY TABLE IF EXISTS Rx;

CREATE TEMPORARY TABLE Rx (
    Code BIGINT,
    Description VARCHAR(50)
);

INSERT INTO Rx (Code, Description)
VALUES
    (866414, 'metoprolol'), (999967, 'amlodipine/hctz')
    , (197361, 'amlodipine'), (833036, 'captopril')
    , (897718, 'verapamil');

SELECT DISTINCT
    p.Id, p.LAST, m.DESCRIPTION
FROM
    pdata p
    LEFT JOIN (
        SELECT m2.PATIENT, m2.DESCRIPTION
        FROM medications m2
            JOIN Rx ON m2.CODE = Rx.Code
    ) m ON p.Id = m.PATIENT
WHERE
    m.DESCRIPTION IS NULL
ORDER BY
    Id;






		---Using String Functions
		Select
			'Supercalifragilisticexpialidocious'
			, LEN('     Supercalifragilisticexpialidocious     ') TheLEN
			, LEN(TRIM('     Supercalifragilisticexpialidocious     ')) TheTrimmedLEN
			, LEFT(TRIM('     Supercalifragilisticexpialidocious     ') , 5) TheLeft
			, SUBSTRING(TRIM('     Supercalifragilisticexpialidocious     ') , 6 , 9) TheSUBSTRING
			, CHARINDEX('cali', TRIM('     Supercalifragilisticexpialidocious     ')) TheCHARINDEX
			, PATINDEX('%cali%', TRIM('     Supercalifragilisticexpialidocious     ')) ThePATINDEX
			, LOWER(TRIM('     Supercalifragilisticexpialidocious     ')) TheLOWER



------hash function for DataWarehouse lecture

SELECT
	p.Id,
	-- Hashed name (not salted)
	CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
		CAST(
			LEFT(p.Last, CASE WHEN LEN(p.Last) > 3 THEN LEN(p.Last) - 3 ELSE 0 END)
			+ ', ' +
			LEFT(p.First, CASE WHEN LEN(p.First) > 3 THEN LEN(p.First) - 3 ELSE 0 END)
			AS NVARCHAR(100))
	), 2) AS HashedName,
	-- Birthdate shifted ±30 days (consistent per patient)
	DATEADD(DAY, CHECKSUM(p.Id) % 61 - 30, p.BIRTHDATE) AS ShiftedBirthdate,
	-- SSN hashed with salt
	CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
		CAST(p.SSN + '|my_static_salt_123' AS NVARCHAR(100))
	), 2) AS HashedSSN_Salted,
	-- Driver’s license hashed (not salted)
	CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
		CAST(p.DRIVERS AS NVARCHAR(100))
	), 2) AS HashedDrivers,
    e.Id AS Encntr,
	-- ProcDtTm shifted ±30 days (consistent per patient)
	DATEADD(DAY, CHECKSUM(p.Id) % 61 - 30, e.START) AS ShiftedProcDtTm,
	e.DESCRIPTION AS [Proc]
FROM
	patients p
	JOIN encounters e ON p.Id = e.PATIENT;
