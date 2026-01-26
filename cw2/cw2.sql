-- I. Usuń wszystkie tabele ze swojej bazy

DROP TABLE countries CASCADE CONSTRAINTS;
DROP TABLE departments CASCADE CONSTRAINTS;
DROP TABLE employees CASCADE CONSTRAINTS;
DROP TABLE job_history CASCADE CONSTRAINTS;
DROP TABLE jobs CASCADE CONSTRAINTS;
DROP TABLE locations CASCADE CONSTRAINTS;

-- II. Przekopiuj wszystkie tabele wraz z danymi od użytkownika HR.
-- Poustawiaj klucze główne i obce

-- Kopiowanie tabel z danymi od użytkownika HR.

CREATE TABLE countries AS SELECT * FROM hr.countries;
CREATE TABLE departments AS SELECT * FROM hr.departments;
CREATE TABLE employees AS SELECT * FROM hr.employees;
CREATE TABLE job_grades AS SELECT * FROM hr.job_grades;
CREATE TABLE job_history AS SELECT * FROM hr.job_history;
CREATE TABLE jobs AS SELECT * FROM hr.jobs;
CREATE TABLE locations AS SELECT * FROM hr.locations;
CREATE TABLE products AS SELECT * FROM hr.products;
CREATE TABLE regions AS SELECT * FROM hr.regions;
CREATE TABLE sales AS SELECT * FROM hr.sales;

-- Tworzenie kluczy głównych

ALTER TABLE countries ADD CONSTRAINT pk_countries PRIMARY KEY (country_id);
ALTER TABLE departments ADD CONSTRAINT pk_departments PRIMARY KEY (department_id);
ALTER TABLE employees ADD CONSTRAINT pk_employees PRIMARY KEY (employee_id);
ALTER TABLE job_grades ADD CONSTRAINT pk_job_grades PRIMARY KEY (grade);
ALTER TABLE job_history ADD CONSTRAINT pk_job_history PRIMARY KEY (employee_id, start_date);
ALTER TABLE jobs ADD CONSTRAINT pk_jobs PRIMARY KEY (job_id);
ALTER TABLE locations ADD CONSTRAINT pk_locations PRIMARY KEY (location_id);
ALTER TABLE products ADD CONSTRAINT pk_products PRIMARY KEY (product_id);
ALTER TABLE regions ADD CONSTRAINT pk_regions PRIMARY KEY (region_id);
ALTER TABLE sales ADD CONSTRAINT pk_sales PRIMARY KEY (sale_id);

-- Tworzenie kluczy obcych

ALTER TABLE countries
ADD CONSTRAINT fk_countries_regions
FOREIGN KEY (region_id) REFERENCES regions(region_id);

ALTER TABLE departments
ADD CONSTRAINT fk_departments_locations
FOREIGN KEY (location_id) REFERENCES locations(location_id);

ALTER TABLE employees
ADD CONSTRAINT fk_employee_manager
FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

ALTER TABLE employees
ADD CONSTRAINT fk_employees_departments
FOREIGN KEY (department_id) REFERENCES departments(department_id);

ALTER TABLE departments
ADD CONSTRAINT fk_department_manager
FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

ALTER TABLE employees
ADD CONSTRAINT fk_employees_jobs
FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE job_history
ADD CONSTRAINT fk_job_history_departments
FOREIGN KEY (department_id) REFERENCES departments(department_id);

ALTER TABLE job_history
ADD CONSTRAINT fk_job_history_employees
FOREIGN KEY (employee_id) REFERENCES employees(employee_id);

ALTER TABLE job_history
ADD CONSTRAINT fk_job_history_job
FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE locations
ADD CONSTRAINT fk_locations_countries
FOREIGN KEY (country_id) REFERENCES countries(country_id);

ALTER TABLE sales
ADD CONSTRAINT fk_sales_employees
FOREIGN KEY (employee_id) REFERENCES employees(employee_id);

-- III. Stwórz następujące perspektywy lub zapytania

-- 1. Z tabeli employees wypisz w jednej kolumnie nazwisko i zarobki – nazwij
-- kolumnę wynagrodzenie, dla osób z departamentów 20 i 50 z zarobkami
-- pomiędzy 2000 a 7000, uporządkuj kolumny według nazwiska

SELECT last_name || ' - ' || salary AS wynagrodzenie
FROM employees
WHERE department_id IN (20, 50)
  AND salary BETWEEN 2000 AND 7000
ORDER BY last_name;

-- 2. Z tabeli employees wyciągnąć informację data zatrudnienia, nazwisko oraz
-- kolumnę podaną przez użytkownika dla osób mających menadżera
-- zatrudnionych w roku 2005. Uporządkować według kolumny podanej przez
-- użytkownika

SELECT hire_date, last_name, &kolumna_uzytkownika 
FROM employees
WHERE manager_id IS NOT NULL
  AND EXTRACT(YEAR FROM hire_date) = 2005
ORDER BY &kolumna_sortowania;

-- 3. Wypisać imiona i nazwiska razem, zarobki oraz numer telefonu porządkując
-- dane według pierwszej kolumny malejąco a następnie drugiej rosnąco (użyć
-- numerów do porządkowania) dla osób z trzecią literą nazwiska ‘e’ oraz częścią
-- imienia podaną przez użytkownika

SELECT 
    first_name || ' ' || last_name AS "Imię i Nazwisko", 
    salary AS "Zarobki", 
    phone_number AS "Numer telefonu"
FROM employees
WHERE SUBSTR(last_name, 3, 1) = 'e'
  AND LOWER(first_name) LIKE '%&czesc_imienia%'
ORDER BY 1 DESC, 2 ASC;

-- 4. Wypisać imię i nazwisko, liczbę miesięcy przepracowanych – funkcje
-- months_between oraz round oraz kolumnę wysokość_dodatku jako (użyć CASE
-- lub DECODE):
--  ● 10% wynagrodzenia dla liczby miesięcy do 150
--  ● 20% wynagrodzenia dla liczby miesięcy od 150 do 200
--  ● 30% wynagrodzenia dla liczby miesięcy od 200
--  ● uporządkować według liczby miesięcy

SELECT
    first_name || ' ' || last_name AS "Imię i Nazwisko",
    ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS "Liczba miesięcy",
    CASE
        WHEN MONTHS_BETWEEN(SYSDATE, hire_date) < 150 THEN salary * 0.10
        WHEN MONTHS_BETWEEN(SYSDATE, hire_date) BETWEEN 150 AND 200 THEN salary * 0.20
        ELSE salary * 0.30
    END AS "Wysokość dodatku"
FROM employees
ORDER BY "Liczba miesięcy";

-- 5. Dla każdego działów w których minimalna płaca jest wyższa niż 5000 wypisz
-- sumę oraz średnią zarobków zaokrągloną do całości nazwij odpowiednio
-- kolumny

SELECT
    d.department_id AS "ID Departamentu",
    d.department_name AS "Nazwa Departamentu",
    SUM(salary) AS "Suma zarobków",
    ROUND(AVG(salary)) AS "Średnia zarobków"
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
HAVING MIN(salary) > 5000
ORDER BY d.department_id;

-- 6. Wypisać nazwisko, numer departamentu, nazwę departamentu, id pracy, dla
-- osób z pracujących Toronto

SELECT 
    e.last_name AS "Nazwisko",
    e.department_id AS "Numer departamentu",
    d.department_name AS "Nazwa departamentu",
    e.job_id AS "ID pracy"
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.city = 'Toronto';

-- 7. Dla pracowników o imieniu „Jennifer” wypisz imię i nazwisko tego pracownika
-- oraz osoby które z nim współpracują

SELECT
    jennifer.first_name || ' ' || jennifer.last_name AS "Jennifer",
    coworker.first_name || ' ' || coworker.last_name AS "Współpracownik"
FROM employees jennifer
JOIN employees coworker ON jennifer.manager_id = coworker.manager_id
WHERE jennifer.first_name = 'Jennifer'
  AND coworker.employee_id != jennifer.employee_id
ORDER BY jennifer.last_name, coworker.last_name;

-- 8. Wypisać wszystkie departamenty w których nie ma pracowników

SELECT
    d.department_id AS "ID departamentu",
    d.department_name AS "Nazwa departametnu"
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL
ORDER BY d.department_id;

-- 9. Wypisz imię i nazwisko, id pracy, nazwę departamentu, zarobki, oraz
-- odpowiedni grade dla każdego pracownika

SELECT 
    e.first_name || ' ' || e.last_name AS "Imię i Nazwisko",
    e.job_id AS "ID pracy",
    d.department_name AS "Nazwa departamentu",
    e.salary AS "Zarobki",
    jg.grade AS "Grade"
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_grades jg ON e.salary BETWEEN jg.min_salary AND jg.max_salary
ORDER BY e.last_name, e.first_name;

-- 10. Wypisz imię nazwisko oraz zarobki dla osób które zarabiają więcej niż średnia
-- wszystkich, uporządkuj malejąco według zarobków

SELECT
    first_name AS "Imię",
    last_name AS "Nazwisko",
    salary AS "Zarobki"
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
)
ORDER BY salary DESC;

-- 11. Wypisz id imię i nazwisko osób, które pracują w departamencie z osobami
-- mającymi w nazwisku „u”

SELECT
    employee_id AS "ID",
    first_name AS "Imię",
    last_name AS "Nazwisko",
    department_id AS "Departament"
FROM employees
WHERE department_id IN (
    SELECT DISTINCT department_id
    FROM employees
    WHERE LOWER(last_name) LIKE '%u%'
      AND department_id IS NOT NULL
)
ORDER BY department_id, last_name;

-- 12. Znajdź pracowników, którzy pracują dłużej niż średnia długość zatrudnienia w
-- firmie

SELECT
    employee_id AS "ID",
    first_name AS "Imię",
    last_name AS "Nazwisko",
    hire_date AS "Data zatrudnienia",
    ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS "Miesiące pracy"
FROM employees
WHERE MONTHS_BETWEEN(SYSDATE, hire_date) > (
    SELECT AVG(MONTHS_BETWEEN(SYSDATE, hire_date))
    FROM employees
)
ORDER BY "Miesiące pracy" DESC;

-- 13. Wypisz nazwę departamentu, liczbę pracowników oraz średnie wynagrodzenie
-- w każdym departamencie. Sortuj według liczby pracowników malejąco

SELECT
    d.department_name AS "Nazwa departamentu",
    COUNT(e.employee_id) AS "Liczba pracowników",
    ROUND(AVG(e.salary), 2) AS "Średnie wynagrodzenie"
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY "Liczba pracowników" DESC;

-- 14. Wypisz imiona i nazwiska pracowników, którzy zarabiają mniej niż jakikolwiek
-- pracownik w departamencie „IT”

SELECT
    first_name AS "Imię",
    last_name AS "Nazwisko",
    salary AS "Zarobki",
    department_id AS "Depratment"
FROM employees
WHERE salary < (
    SELECT MIN(salary)
    FROM employees
    WHERE department_id = (
        SELECT department_id
        FROM departments
        WHERE department_name = 'IT'
    )
)
ORDER BY salary DESC;

-- 15. Znajdź departamenty, w których pracuje co najmniej jeden pracownik
-- zarabiający więcej niż średnia pensja w całej firmie.

SELECT DISTINCT
    d.department_id AS "ID Departamentu",
    d.department_name AS "Nazwa Departamentu"
FROM departments d
JOIN employees e ON d.department_id = e.department_id
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees
)
ORDER BY d.department_id;

-- 16. Wypisz pięć najlepiej opłacanych stanowisk pracy wraz ze średnimi zarobkami.

SELECT
    job_id AS "Stanowisko",
    ROUND(AVG(salary), 2) AS "Średnie zarobki"
FROM employees
GROUP BY job_id
ORDER BY "Średnie zarobki" DESC
FETCH FIRST 5 ROWS ONLY;

-- 17. Dla każdego regionu, wypisz nazwę regionu, liczbę krajów oraz liczbę
-- pracowników, którzy tam pracują.

SELECT
    r.region_name AS "Nazwa regionu",
    COUNT(DISTINCT c.country_id) AS "Liczba krajów",
    COUNT(DISTINCT e.employee_id) AS "Liczba pracowników"
FROM regions r
LEFT JOIN countries c ON r.region_id = c.region_id
LEFT JOIN locations l ON c.country_id = l.country_id
LEFT JOIN departments d ON l.location_id = d.location_id
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;

-- 18. Podaj imiona i nazwiska pracowników, którzy zarabiają więcej niż ich
-- menedżerowie.

SELECT
    e.first_name AS "Imię pracownika",
    e.last_name AS "Nazwisko pracownika",
    e.salary AS "Zarobki pracownika",
    m.first_name AS "Imię menedżera",
    m.last_name AS "Nazwisko menedżera",
    m.salary AS "Zarobki menedżera"
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary
ORDER BY e.salary DESC;

-- 19. Policz, ilu pracowników zaczęło pracę w każdym miesiącu (bez względu na rok).

SELECT
    TO_CHAR(hire_date, 'MM') AS "Numer miesiąca",
    TO_CHAR(hire_date, 'Month') AS "Nazwa miesiąca",
    COUNT(*) AS "Liczba pracowników"
FROM employees
GROUP BY TO_CHAR(hire_date, 'MM'), TO_CHAR(hire_date, 'Month')
ORDER BY "Numer miesiąca";

-- 20. Znajdź trzy departamenty z najwyższą średnią pensją i wypisz ich nazwę oraz
-- średnie wynagrodzenie.

SELECT
    d.department_name AS "Nazwa departamentu",
    ROUND(AVG(e.salary), 2) AS "Średnie wynagrodzenie"
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY AVG(e.salary) DESC
FETCH FIRST 3 ROWS ONLY;
