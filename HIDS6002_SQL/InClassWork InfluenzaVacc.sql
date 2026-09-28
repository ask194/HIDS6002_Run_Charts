use synthea;

/*Examine the Immunization Table*/
SELECT * FROM immunizations order by DATE DESC;



/*Get aggregate counts of the types of immunzations*/
SELECT
	DESCRIPTION
	, COUNT(*) AS n
FROM
	immunizations
GROUP BY
	DESCRIPTION
ORDER BY
	n DESC;


/*Patients that have or have not received at least one influenza vaccination*/
SELECT
	p.Id
	, p.LAST
FROM
	patients p
WHERE
	/*NOT*/
	EXISTS (SELECT 1
		FROM
		immunizations i
		WHERE
		i.DESCRIPTION LIKE '%Influenza%' 
		AND i.PATIENT = p.Id );




/*Get a complete immunization record by patient*/
SELECT
	p.Id
	, p.LAST
	, p.FIRST
	, CASE
		WHEN i.PATIENT IS NOT NULL THEN 'Immunized'
		ELSE 'Never immunized' END AS flu_status
	, i.DATE
	, i.PATIENT
FROM
	patients p
LEFT JOIN immunizations i
	ON p.Id = i.PATIENT
	AND i.DESCRIPTION LIKE '%Influenza%'
ORDER BY
	flu_status DESC
	, p.LAST
	, p.FIRST
	, p.Id
	, i.DATE;




/*Flu vaccine since at least 2020-01-01*/
SELECT
	p.Id
	, p.LAST
	, CASE
		WHEN MAX(i.DATE) > '2020-01-01' THEN 'Recently Immunized'
		ELSE 'Not Recently immunized' END AS flu_status
	, MAX(i.DATE) AS last_flu_shot_date
FROM
	patients p
		LEFT JOIN immunizations i
			ON p.Id = i.PATIENT
			AND i.DESCRIPTION LIKE '%Influenza%'
GROUP BY
	p.Id
	, p.LAST
ORDER BY
	last_flu_shot_date
	, flu_status
	, p.Id;




/*Another Solution*/
Select
	b.id
	, b.LAST
	, (case	
		when b.DESCRIPTION is null then 'Not Recently Immunized'
		else 'Recently Immunized'
		END) AS flu_status
	, b.DATE
FROM
	(select
		p.id
		, p.last
		, p.FIRST
		, i.DESCRIPTION
		, i.DATE
		, ROW_NUMBER() over (Partition By p.id order by i.Date DESC) rownum
	from
		patients p
		left join immunizations i
			on p.Id = i.PATIENT
			and lower(i.description) like '%influ%'
			and i.DATE > '2020-01-01'
			ORDER BY p.id
			) b
WHERE
	b.rownum = 1
ORDER BY
	b.DATE
	, flu_status
	, b.Id
