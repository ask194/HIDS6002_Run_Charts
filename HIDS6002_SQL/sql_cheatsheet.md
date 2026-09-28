# SQL Syntax Reference (MariaDB)

## 1. A note on comments

In MariaDB, a `--` comment must be followed by **at least one space** (or
the end of the line) to be recognized as a comment at all. 

```sql
SELECT 5 --3;     -- returns 8  (parsed as 5 - -3, NOT a comment!)
SELECT 5 -- 3;    -- returns 5  (correctly a comment)
```

Always put a space after `--`. This is not a style preference — it's the
difference between a comment and a silent arithmetic error.

---

## 2. Basic SELECT

```sql
SELECT column_a, column_b
FROM table_a
WHERE category = 'x'
ORDER BY column_a;

SELECT DISTINCT category FROM table_a;   -- unique values only

SELECT * FROM table_a LIMIT 100;          -- a quick peek at a big table
```

**`SELECT *` is for exploring, not for final queries.** It's the right
tool the first time you look at an unfamiliar table; a finished query
should name its columns explicitly, so it doesn't silently change shape
if the table gains a column later.

---

## 3. Filtering

```sql
WHERE category = 'x'                      -- equals
WHERE category != 'x'                     -- not equals
WHERE value > 100                         -- comparison
WHERE category IN ('x', 'y')              -- matches any of several values
WHERE category LIKE '%text%'              -- contains "text" anywhere
WHERE lower(category) LIKE '%text%'       -- case-insensitive contains
WHERE value BETWEEN 75 AND 150            -- inclusive range
WHERE category IS NULL                    -- missing value
WHERE category IS NOT NULL                -- present value
WHERE category = 'x' AND value > 100      -- multiple conditions = AND
WHERE category = 'x' OR category = 'y'    -- either condition
```

**`= NULL` never matches anything** `NULL` means "unknown," and
nothing is known to equal an unknown. Always use `IS NULL` /
`IS NOT NULL` for missing values, never `= NULL`.

---

## 4. Joining tables

```sql
SELECT a.id, a.category, b.value
FROM table_a a
JOIN table_b b ON a.id = b.id;

SELECT a.id, a.category, b.value
FROM table_a a
LEFT JOIN table_b b ON a.id = b.id
                        AND b.key_col = 'k1';
```

- **`JOIN`** (inner join) keeps only rows that matched in *both* tables:
  a row in `table_a` with no match in `table_b` disappears entirely.
- **`LEFT JOIN`** keeps every row of `table_a`, whether or not it found a
  match in `table_b`. Where there's no match, `table_b`'s columns come
  back `NULL`, which lets you ask "which rows had no match?" afterward 
  with `WHERE some_column IS NULL`.
- **Where you put an extra condition changes what it does.** A condition
  in the `ON` clause narrows *what counts as a match* (every row of
  `table_a` is still kept, just matched more narrowly). The same
  condition in the `WHERE` clause instead throws away non-matching rows
  entirely. A `LEFT JOIN`, putting a filter on the *right* table in
  `WHERE` turns it back into something that behaves like an
  inner join. If you want a left join to stay a left join, keep the
  filter on the joined table inside `ON`.

**A row count can multiply unexpectedly after a join.** If `table_b` has
more than one matching row for a given `table_a` row, that `table_a` row
comes back once *per match* — always sanity-check row counts before and
after a join if you're not sure the join key is unique on both sides.

---

## 5. EXISTS — a different kind of filter

```sql
SELECT a.id
FROM table_a a
WHERE EXISTS (
    SELECT 1 FROM table_b b
    WHERE b.id = a.id AND b.key_col = 'k1'
);
```

`EXISTS` answers a yes/no question about each row of the outer query. It
never actually returns columns from the inner query (the `SELECT 1` is
just a convention; nothing about the `1` matters). This makes it useful
for "does this patient/record have at least one matching row," 
**without** multiplying the outer row if there happen to be
several matches.

**The trade-off:** because `EXISTS` only checks *whether* a match exists,
any columns you actually want *from* the matched row have to come from
somewhere else — a separate `JOIN`, not the `EXISTS` subquery itself.
Reach for `EXISTS` when you're filtering ("only rows that have a match"),
and a `JOIN` when you need to pull real column values across.

---

## 6. Aggregation

```sql
SELECT category, COUNT(*) AS n
FROM table_a
GROUP BY category
ORDER BY n DESC;

SELECT id, SUM(value) AS total
FROM table_b
GROUP BY id
HAVING COUNT(*) > 1;          -- filters groups, applied AFTER grouping
```

**`WHERE` vs. `HAVING`:** `WHERE` filters individual rows *before*
grouping happens; `HAVING` filters whole groups *after* aggregation. A
condition on an aggregate function (`COUNT(*)`, `SUM(...)`) has to go in
`HAVING`. `WHERE COUNT(*) > 1` is not valid SQL, because `WHERE` runs
before `COUNT(*)` has been computed at all.

---

## 7. CASE WHEN — a conditional column

```sql
SELECT
    id,
    value,
    CASE WHEN value > 150 THEN 'high' ELSE 'normal' END AS flag
FROM table_b;
```

Reads top to bottom, first match wins — you can chain multiple
`WHEN ... THEN` clauses before the final `ELSE`. A common pattern for
turning a join's match/no-match result into a readable label:

```sql
CASE WHEN b.id IS NOT NULL THEN 'matched' ELSE 'unmatched' END
```

---

## 8. Type conversion and dates

```sql
CAST(value AS float)                          -- text -> number
CAST(value AS int)

DATE_FORMAT(date_col, '%Y-%m-01')             -- snap any date to the 1st of its month
DATE_FORMAT(date_col, '%Y-%m-%d')             -- reformat a date/datetime as plain YYYY-MM-DD
```

**A column can look numeric and still be stored as text.** Comparing a
text column to a number directly (`WHERE value > 150`, when `value` is
`VARCHAR`) can silently produce wrong results depending on how the
database decides to compare them. `CAST(... AS float)` first makes the
comparison unambiguous.

**`DATE_FORMAT()` returns a string, not a date.** `DATE_FORMAT(date_col,
'%Y-%m-01')` is great for `GROUP BY` (it collapses every day in a month
down to one shared value), but the result comes back as text — if you
need it back as a real date column afterward (e.g., once the query
results land in R), it needs to be converted there, not assumed to
already be one.

---

## 9. Temporary tables

```sql
DROP TABLE IF EXISTS tmp_table;

CREATE TEMPORARY TABLE tmp_table (
    id VARCHAR(36),
    flag VARCHAR(20)
);

INSERT INTO tmp_table (id, flag)
SELECT id, 'seen'
FROM table_a
WHERE category = 'x';

SELECT * FROM tmp_table;
```

Useful when a result is going to be reused by more than one later query,
or when a multi-step calculation is easier to read broken into stages.
**A temporary table only exists for the current connection/session** — it
disappears when that connection closes, and it's invisible to any other
connection in the meantime. `DROP TABLE IF EXISTS` before creating one is
defensive: it means re-running your script from the top doesn't
error out on a table that's already there from last time.

---

## 10. Running SQL from R

```r
library(DBI)
library(RMariaDB)

# a query that returns rows -> data.frame
result <- dbGetQuery(con, "SELECT * FROM table_a WHERE category = 'x'")

# a statement with no rows to return (DROP / CREATE / INSERT / UPDATE)
dbExecute(con, "DROP TABLE IF EXISTS tmp_table")
dbExecute(con, "CREATE TEMPORARY TABLE tmp_table (id VARCHAR(36))")
```

**`dbGetQuery()` is for `SELECT`; `dbExecute()` is for everything else.**

---

## Quick lookup

| I want to... | Syntax |
|---|---|
| Unique values only | `SELECT DISTINCT ...` |
| Match any of several values | `WHERE x IN (...)` |
| Partial text match | `WHERE x LIKE '%text%'` |
| Inclusive range | `WHERE x BETWEEN a AND b` |
| Check for missing values | `WHERE x IS NULL` / `IS NOT NULL` |
| Keep only matched rows | `JOIN` |
| Keep all rows, matched or not | `LEFT JOIN` |
| Filter to "has at least one match" without duplicating rows | `WHERE EXISTS (...)` |
| Count / sum per group | `GROUP BY` + `COUNT(*)` / `SUM(...)` |
| Filter on a group's aggregate value | `HAVING` (not `WHERE`) |
| Conditional label/flag | `CASE WHEN ... THEN ... ELSE ... END` |
| Text to number | `CAST(x AS float)` |
| Snap a date to the start of its month | `DATE_FORMAT(x, '%Y-%m-01')` |
| Reusable intermediate result | `CREATE TEMPORARY TABLE` |
| Run a SELECT from R | `dbGetQuery(con, "...")` |
| Run DDL/DML from R | `dbExecute(con, "...")` |
