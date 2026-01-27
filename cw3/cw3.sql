-- 1 Utwórz widok v_wysokie_pensje, dla tabeli employees
-- który pokaże wszystkich pracowników zarabiających więcej niż 6000.

CREATE VIEW v_wysokie_pensje AS
SELECT * FROM employees
WHERE salary > 6000;

-- 2. Zmień definicję widoku v_wysokie_pensje aby 
-- pokazywał tylko pracowników zarabiających powyżej 12000.

CREATE OR REPLACE VIEW v_wysokie_pensje AS
SELECT * FROM employees
WHERE salary < 12000;

-- 3. Usuń widok v_wysokie_pensje.

DROP VIEW v_wysokie_pensje;

-- 4. Stwórz widok dla tabeli employees zawierający:
-- employee_id, last_name, first_name, dla
-- pracowników z departamentu o nazwie Finance.

CREATE VIEW v_employees_finances AS
SELECT
    employee_id,
    last_name,
    first_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Finance';

-- 5. Stwórz widok dla tabeli employees zawierający: 
-- employee_id, last_name, first_name, salary, job_id, email, hire_date
-- dla pracowników mających zarobki pomiędzy 5000 a 12000.

CREATE VIEW v_employees_salary AS
SELECT
    employee_id,
    last_name,
    first_name,
    salary,
    job_id,
    email,
    hire_date
FROM employees
WHERE salary BETWEEN 5000 AND 12000;

-- 6. Poprzez utworzone widoki sprawdź czy możesz:
--  a. dodać nowego pracownika

INSERT INTO v_employees_salary (
    employee_id,
    last_name,
    first_name,
    salary,
    job_id,
    email,
    hire_date
) VALUES (
    210,
    'Szymański',
    'Mateusz',
    3000,
    'IT_PROG',
    'MSZYMANSKI@wp.pl',
    SYSDATE
);


--  b. edytować pracownika

UPDATE v_employees_salary
SET salary = 12000
WHERE employee_id = 210;

--  c. usunąć pracownika

DELETE FROM v_employees_salary
WHERE employee_id = 210;

-- 7. Stwórz widok, który dla każdego działu który
-- zatrudnia przynajmniej 4 pracowników wyświetli: 
-- identyfikator działu, nazwę działu, 
-- liczbę pracowników w dziale, średnią pensja w dziale
-- i najwyższa pensja w dziale.

CREATE VIEW v_departments_stats AS
SELECT
    d.department_id AS "ID działu",
    d.department_name AS "Nazwa działu",
    COUNT(e.employee_id) AS "Liczba pracowników",
    ROUND(AVG(e.salary), 2) AS "Średnia pensja",
    MAX(e.salary) AS "Najwyższa pensja"
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) >= 4
ORDER BY d.department_id;


--  a. Sprawdź czy możesz dodać dane do tego widoku.

INSERT INTO v_departments_stats (
    "ID działu",
    "Nazwa działu",
    "Liczba pracowników",
    "Średnia pensja",
    "Najwyższa pensja"
) VALUES (
    280,
    'Tester',
    5,
    5000,
    10000
);

-- Nie mogę, ponieważ łączy więcej niż jedną tabelę a także widok ma 
-- GROUP BY oraz HAVING co blokuje możliwość wstawiania.

-- 8. Stwórz analogiczny widok zadania 3 z dodaniem warunku ‘WITH CHECK OPTION’

CREATE VIEW v_wysokie_pensje AS
SELECT * FROM employees
WHERE salary > 6000
WITH CHECK OPTION;

--  a. Sprawdź czy możesz:
--      i. dodać pracownika z zarobkami pomiędzy 5000 a 12000.

INSERT INTO v_wysokie_pensje (
    employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    job_id,
    salary
) VALUES (
    999,
    'Jan',
    'Kowalski',
    'JKOWALSKI@company.com',
    SYSDATE,
    'IT_PROG',
    5500
);

-- SQL Error: ORA-01402: 
-- naruszenie klauzuli WHERE dla perspektywy z WITH CHECK OPTION

--      ii. dodać pracownika z zarobkami powyżej 12000.

INSERT INTO v_wysokie_pensje (
    employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    job_id,
    salary
) VALUES (
    420,
    'Jan',
    'Kowalski',
    'JKOWALSKI@company.com',
    SYSDATE,
    'IT_PROG',
    12010
);

-- 9. Utwórz widok zmaterializowany v_managerowie, 
-- który pokaże tylko menedżerów wraz z nazwami ich działów.

CREATE MATERIALIZED VIEW v_managerowie AS
SELECT
    e.employee_id AS "ID menedżera",
    e.first_name AS "Imię",
    e.last_name AS "Nazwisko",
    e.email AS "Email",
    e.job_id AS "Stanowisko",
    d.department_id AS "ID działu",
    d.department_name AS "Nazwa działu"
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.employee_id IN (
    SELECT DISTINCT manager_id
    FROM employees
    WHERE manager_id IS NOT NULL
)
ORDER BY e.last_name, e.first_name;

-- 10. Stwórz widok v_najlepiej_oplacani, 
-- który zawiera tylko 10 najlepiej opłacanych pracowników.

CREATE VIEW v_najlepiej_oplacani AS
SELECT *
FROM (
    SELECT
        employee_id AS "ID pracownika",
        first_name AS "Imię",
        last_name AS "Nazwisko",
        salary AS "Wynagrodzienie",
        job_id AS "Stanowisko",
        department_id AS "Departament"
    FROM employees
    ORDER BY salary DESC
)
WHERE ROWNUM <= 10;