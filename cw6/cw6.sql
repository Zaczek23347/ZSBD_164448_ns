SET SERVEROUTPUT ON

-- ===============
-- Stwórz funkcje:
-- ===============
-- 1. Zwracającą nazwę pracy dla podanego parametru id, dodaj wyjątek, 
-- jeśli taka praca nie istnieje.

CREATE OR REPLACE FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
RETURN JOBS.JOB_TITLE%TYPE
IS
    v_title JOBS.JOB_TITLE%TYPE;
BEGIN
    SELECT job_title
      INTO v_title
      FROM jobs
     WHERE job_id = p_job_id;

    RETURN v_title;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Brak pracy o id = ' || p_job_id);
END;
/

SELECT get_job_name('IT_PROG') AS job_title FROM dual;

-- 2. Zwracającą roczne zarobki (wynagrodzenie 12-to miesięczne plus premia jako
-- wynagrodzenie * commission_pct) dla pracownika o podanym id

CREATE OR REPLACE FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
RETURN NUMBER
IS
    v_salary         EMPLOYEES.SALARY%TYPE;
    v_commission_pct EMPLOYEES.COMMISSION_PCT%TYPE;
BEGIN
    SELECT salary, NVL(commission_pct, 0)
      INTO v_salary, v_commission_pct
      FROM employees
     WHERE employee_id = p_emp_id;

    RETURN v_salary * 12 + v_salary * v_commission_pct;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Brak pracownika o id = ' || p_emp_id);
END;
/

SELECT get_annual_earnings(100) AS annual_pay FROM dual;

-- 3. Biorącą w nawias numer kierunkowy z numeru telefonu podanego jako varchar

CREATE OR REPLACE FUNCTION wrap_area_code(p_phone IN VARCHAR2)
RETURN VARCHAR2
IS
    v_area   VARCHAR2(20);
    v_rest   VARCHAR2(50);
BEGIN
    v_area := REGEXP_SUBSTR(p_phone, '^[^-. ]+');
    v_rest := REGEXP_SUBSTR(p_phone, '[-. ].*');
    IF v_area IS NULL THEN
        RETURN p_phone; 
    END IF;

    RETURN '(' || v_area || ')' || NVL(v_rest, '');
END;
/

SELECT wrap_area_code('22-123-4567') AS phone_fmt FROM dual;

-- 4. Dla podanego w parametrze ciągu znaków zmieniającą pierwszą i 
-- ostatnią literę na wielką – pozostałe na małe.

CREATE OR REPLACE FUNCTION capitalize_edges(p_text IN VARCHAR2)
RETURN VARCHAR2
IS
    v_len PLS_INTEGER := LENGTH(p_text);
BEGIN
    IF v_len = 0 THEN
        RETURN p_text;
    ELSIF v_len = 1 THEN
        RETURN UPPER(p_text);
    ELSE
        RETURN UPPER(SUBSTR(p_text, 1, 1))
               || LOWER(SUBSTR(p_text, 2, v_len - 2))
               || UPPER(SUBSTR(p_text, -1, 1));
    END IF;
END;
/

SELECT capitalize_edges('pRzyKLad') AS fixed_text FROM dual;

-- 5. Dla podanego peselu - przerabiającą pesel na datę urodzenia w 
-- formacie ‘yyyy-mm-dd'

CREATE OR REPLACE FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
RETURN VARCHAR2
IS
    v_pesel  VARCHAR2(11) := p_pesel;
    v_year   NUMBER;
    v_month  NUMBER;
    v_day    NUMBER;
    v_cent   NUMBER := 1900;
    v_date   DATE;
BEGIN
    IF LENGTH(v_pesel) != 11 OR NOT REGEXP_LIKE(v_pesel, '^\d{11}$') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nieprawidłowy PESEL: ' || p_pesel);
    END IF;

    v_year  := TO_NUMBER(SUBSTR(v_pesel, 1, 2));
    v_month := TO_NUMBER(SUBSTR(v_pesel, 3, 2));
    v_day   := TO_NUMBER(SUBSTR(v_pesel, 5, 2));

    IF v_month BETWEEN 1 AND 12 THEN
        v_cent := 1900;
    ELSIF v_month BETWEEN 21 AND 32 THEN
        v_cent := 2000; v_month := v_month - 20;
    ELSIF v_month BETWEEN 41 AND 52 THEN
        v_cent := 2100; v_month := v_month - 40;
    ELSIF v_month BETWEEN 61 AND 72 THEN
        v_cent := 2200; v_month := v_month - 60;
    ELSIF v_month BETWEEN 81 AND 92 THEN
        v_cent := 1800; v_month := v_month - 80;
    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Nieprawidłowy miesiąc w PESEL: ' || p_pesel);
    END IF;

    v_date := TO_DATE(TO_CHAR(v_cent + v_year) || LPAD(v_month, 2, '0') || LPAD(v_day, 2, '0'),
                      'YYYYMMDD');

    RETURN TO_CHAR(v_date, 'YYYY-MM-DD');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20000 AND -20999 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20005, 'Błąd PESEL: ' || SQLERRM);
        END IF;
END;
/

SELECT pesel_to_birthdate('02211312345') AS birth_date FROM dual;

-- 6. Zwracającą liczbę pracowników oraz liczbę departamentów które znajdują się
-- w kraju podanym jako parametr (nazwa kraju). 
-- W przypadku braku kraju - odpowiedni wyjątek

CREATE OR REPLACE FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
RETURN VARCHAR2
IS
    v_country_id COUNTRIES.COUNTRY_ID%TYPE;
    v_emp_cnt    NUMBER;
    v_dept_cnt   NUMBER;
BEGIN
    SELECT country_id
      INTO v_country_id
      FROM countries
     WHERE UPPER(country_name) = UPPER(p_country_name);

    SELECT COUNT(DISTINCT d.department_id)
      INTO v_dept_cnt
      FROM departments d
      JOIN locations l ON l.location_id = d.location_id
     WHERE l.country_id = v_country_id;

    SELECT COUNT(e.employee_id)
      INTO v_emp_cnt
      FROM employees e
      JOIN departments d ON d.department_id = e.department_id
      JOIN locations l   ON l.location_id = d.location_id
     WHERE l.country_id = v_country_id;

    RETURN 'Pracownicy: ' || v_emp_cnt || ', Departamenty: ' || v_dept_cnt;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nie znaleziono kraju: ' || p_country_name);
END;
/

SELECT country_counts('Canada') AS summary FROM dual;

-- ===============
-- Stworzyć następujące wyzwalacze:
-- ===============
-- 1. Stworzyć tabelę archiwum_departamentów (id, nazwa, data_zamknięcia,
-- ostatni_manager jako imię i nazwisko). 
-- Po usunięciu departamentu dodać odpowiedni rekord do tej tabeli

CREATE TABLE archiwum_departamentow (
    id               NUMBER PRIMARY KEY,
    nazwa            VARCHAR2(100),
    data_zamkniecia  DATE,
    ostatni_manager  VARCHAR2(200)
);

CREATE OR REPLACE TRIGGER trg_arch_departments
BEFORE DELETE ON departments
FOR EACH ROW
DECLARE
    v_manager_name VARCHAR2(200);
BEGIN
    BEGIN
        SELECT NVL(first_name, '') || ' ' || NVL(last_name, '')
          INTO v_manager_name
          FROM employees
         WHERE employee_id = :OLD.manager_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_manager_name := 'brak';
    END;

    INSERT INTO archiwum_departamentow (id, nazwa, data_zamkniecia, ostatni_manager)
    VALUES (
        :OLD.department_id,
        :OLD.department_name,
        SYSDATE,
        v_manager_name
    );
END;
/

DELETE FROM departments WHERE department_id = 290;
SELECT * FROM archiwum_departamentow ORDER BY id DESC;

-- 2. W razie UPDATE i INSERT na tabeli employees, sprawdzić czy zarobki 
-- łapią się w widełkach 2000 - 26000. Jeśli nie łapią się - zabronić dodania. 
-- Dodać tabelę złodziej(id, USER, czas_zmiany), której będą wrzucane logi,
-- jeśli będzie próba dodania, bądź zmiany wynagrodzenia poza widełki

CREATE TABLE zlodziej (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usr         VARCHAR2(128),
    czas_zmiany TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_employees_salary_guard
BEFORE INSERT OR UPDATE OF salary ON employees
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_user VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
BEGIN
    IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
        INSERT INTO zlodziej (usr, czas_zmiany)
        VALUES ( v_user, SYSTIMESTAMP);
        COMMIT; -- tylko dla autonomicznej transakcji
        RAISE_APPLICATION_ERROR(-20020,
            'Wynagrodzenie poza widełkami 2000-26000: ' || :NEW.salary);
    END IF;
END;
/

UPDATE employees SET salary = 50000 WHERE employee_id = 103;
SELECT * FROM zlodziej ORDER BY id DESC;

-- 3. Stworzyć sekwencję i wyzwalacz, który będzie odpowiadał za 
-- auto_increment w tabeli employees.

CREATE SEQUENCE employees_seq START WITH 1000 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_employees_autoinc
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF :NEW.employee_id IS NULL THEN
        :NEW.employee_id := employees_seq.NEXTVAL;
    END IF;
END;
/

INSERT INTO employees (first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES ('Jan', 'Nowak', 'JAN.NOWAK', SYSDATE, 'IT_PROG', 5000, 60);

-- 4. Stworzyć wyzwalacz, który zabroni dowolnej operacji na tabeli JOD_GRADES 
-- (INSERT, UPDATE, DELETE)

--==============================================================================
-- UWAGA! TESTUJ OD TEGO MOMENTU
--==============================================================================

CREATE OR REPLACE TRIGGER trg_job_grades_lock
BEFORE INSERT OR UPDATE OR DELETE ON job_grades
BEGIN
    RAISE_APPLICATION_ERROR(-20030, 'Operacje na JOB_GRADES są zabronione.');
END;
/

DELETE FROM job_grades WHERE grade = 'A';

-- 5. Stworzyć wyzwalacz, który przy próbie zmiany max i min salary w 
-- tabeli jobs zostawia stare wartości.

CREATE OR REPLACE TRIGGER trg_jobs_keep_salaries
BEFORE UPDATE OF min_salary, max_salary ON jobs
FOR EACH ROW
BEGIN
    :NEW.min_salary := :OLD.min_salary;
    :NEW.max_salary := :OLD.max_salary;
END;
/

UPDATE jobs SET min_salary = min_salary + 100 WHERE job_id = 'IT_PROG';

-- ===============
-- Stworzyć paczki:
-- ===============
-- 1.  Składającą się ze stworzonych procedur i funkcji

CREATE OR REPLACE PACKAGE hr_utils_pkg AS
    FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
        RETURN JOBS.JOB_TITLE%TYPE;

    FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
        RETURN NUMBER;

    FUNCTION wrap_area_code(p_phone IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION capitalize_edges(p_text IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
        RETURN VARCHAR2;
END hr_utils_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_utils_pkg AS

    FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
        RETURN JOBS.JOB_TITLE%TYPE
    IS
        v_title JOBS.JOB_TITLE%TYPE;
    BEGIN
        SELECT job_title
          INTO v_title
          FROM jobs
         WHERE job_id = p_job_id;
    
        RETURN v_title;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Brak pracy o id = ' || p_job_id);
    END;
    
    FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
        RETURN NUMBER
    IS
        v_salary         EMPLOYEES.SALARY%TYPE;
        v_commission_pct EMPLOYEES.COMMISSION_PCT%TYPE;
    BEGIN
        SELECT salary, NVL(commission_pct, 0)
          INTO v_salary, v_commission_pct
          FROM employees
         WHERE employee_id = p_emp_id;
    
        RETURN v_salary * 12 + v_salary * v_commission_pct;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Brak pracownika o id = ' || p_emp_id);
    END;
    
    FUNCTION wrap_area_code(p_phone IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_area   VARCHAR2(20);
        v_rest   VARCHAR2(50);
    BEGIN
        v_area := REGEXP_SUBSTR(p_phone, '^[^-. ]+');
        v_rest := REGEXP_SUBSTR(p_phone, '[-. ].*');
        IF v_area IS NULL THEN
            RETURN p_phone; 
        END IF;
    
        RETURN '(' || v_area || ')' || NVL(v_rest, '');
    END;
    
    FUNCTION capitalize_edges(p_text IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_len PLS_INTEGER := LENGTH(p_text);
    BEGIN
        IF v_len = 0 THEN
            RETURN p_text;
        ELSIF v_len = 1 THEN
            RETURN UPPER(p_text);
        ELSE
            RETURN UPPER(SUBSTR(p_text, 1, 1))
                   || LOWER(SUBSTR(p_text, 2, v_len - 2))
                   || UPPER(SUBSTR(p_text, -1, 1));
        END IF;
    END;
    
    FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_pesel  VARCHAR2(11) := p_pesel;
        v_year   NUMBER;
        v_month  NUMBER;
        v_day    NUMBER;
        v_cent   NUMBER := 1900;
        v_date   DATE;
    BEGIN
        IF LENGTH(v_pesel) != 11 OR NOT REGEXP_LIKE(v_pesel, '^\d{11}$') THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nieprawidłowy PESEL: ' || p_pesel);
        END IF;
    
        v_year  := TO_NUMBER(SUBSTR(v_pesel, 1, 2));
        v_month := TO_NUMBER(SUBSTR(v_pesel, 3, 2));
        v_day   := TO_NUMBER(SUBSTR(v_pesel, 5, 2));
    
        IF v_month BETWEEN 1 AND 12 THEN
            v_cent := 1900;
        ELSIF v_month BETWEEN 21 AND 32 THEN
            v_cent := 2000; v_month := v_month - 20;
        ELSIF v_month BETWEEN 41 AND 52 THEN
            v_cent := 2100; v_month := v_month - 40;
        ELSIF v_month BETWEEN 61 AND 72 THEN
            v_cent := 2200; v_month := v_month - 60;
        ELSIF v_month BETWEEN 81 AND 92 THEN
            v_cent := 1800; v_month := v_month - 80;
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'Nieprawidłowy miesiąc w PESEL: ' || p_pesel);
        END IF;
    
        v_date := TO_DATE(TO_CHAR(v_cent + v_year) || LPAD(v_month, 2, '0') || LPAD(v_day, 2, '0'),
                          'YYYYMMDD');
    
        RETURN TO_CHAR(v_date, 'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20000 AND -20999 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20005, 'Błąd PESEL: ' || SQLERRM);
            END IF;
    END;
    
    FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
        RETURN VARCHAR2
    IS
        v_country_id COUNTRIES.COUNTRY_ID%TYPE;
        v_emp_cnt    NUMBER;
        v_dept_cnt   NUMBER;
    BEGIN
        SELECT country_id
          INTO v_country_id
          FROM countries
         WHERE UPPER(country_name) = UPPER(p_country_name);
    
        SELECT COUNT(DISTINCT d.department_id)
          INTO v_dept_cnt
          FROM departments d
          JOIN locations l ON l.location_id = d.location_id
         WHERE l.country_id = v_country_id;
    
        SELECT COUNT(e.employee_id)
          INTO v_emp_cnt
          FROM employees e
          JOIN departments d ON d.department_id = e.department_id
          JOIN locations l   ON l.location_id = d.location_id
         WHERE l.country_id = v_country_id;
    
        RETURN 'Pracownicy: ' || v_emp_cnt || ', Departamenty: ' || v_dept_cnt;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Nie znaleziono kraju: ' || p_country_name);
    END;
END hr_utils_pkg;
/

SELECT hr_utils_pkg.get_job_name('IT_PROG') FROM dual;
SELECT hr_utils_pkg.get_annual_earnings(100) FROM dual;
SELECT hr_utils_pkg.pesel_to_birthdate('02211312345') FROM dual;

-- 2. Stworzyć paczkę z procedurami i funkcjami do obsługi tabeli 
-- REGIONS (CRUD), gdzie odczyt z różnymi parametrami

CREATE SEQUENCE regions_seq START WITH 100 INCREMENT BY 1;

CREATE OR REPLACE PACKAGE regions_api_pkg AS
    PROCEDURE create_region(
        p_region_name IN REGIONS.REGION_NAME%TYPE,
        p_region_id   IN REGIONS.REGION_ID%TYPE DEFAULT NULL);

    PROCEDURE update_region(
        p_region_id   IN REGIONS.REGION_ID%TYPE,
        p_region_name IN REGIONS.REGION_NAME%TYPE);

    PROCEDURE delete_region(
        p_region_id IN REGIONS.REGION_ID%TYPE);

    FUNCTION get_region_by_id(
        p_region_id IN REGIONS.REGION_ID%TYPE)
        RETURN REGIONS%ROWTYPE;

    FUNCTION get_region_by_name(
        p_region_name IN REGIONS.REGION_NAME%TYPE)
        RETURN REGIONS%ROWTYPE;

    PROCEDURE list_regions(
        p_region_id     IN REGIONS.REGION_ID%TYPE   DEFAULT NULL,
        p_name_like     IN VARCHAR2                 DEFAULT NULL,
        p_result        OUT SYS_REFCURSOR);
END regions_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY regions_api_pkg AS

    PROCEDURE create_region(
        p_region_name IN REGIONS.REGION_NAME%TYPE,
        p_region_id   IN REGIONS.REGION_ID%TYPE DEFAULT NULL) IS
        v_region_id REGIONS.REGION_ID%TYPE;
    BEGIN
        v_region_id := COALESCE(p_region_id, regions_seq.NEXTVAL);
        INSERT INTO regions (region_id, region_name)
        VALUES (v_region_id, p_region_name);
    END create_region;

    PROCEDURE update_region(
        p_region_id   IN REGIONS.REGION_ID%TYPE,
        p_region_name IN REGIONS.REGION_NAME%TYPE) IS
    BEGIN
        UPDATE regions
           SET region_name = p_region_name
         WHERE region_id = p_region_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'Region nie istnieje: ' || p_region_id);
        END IF;
    END update_region;

    PROCEDURE delete_region(
        p_region_id IN REGIONS.REGION_ID%TYPE) IS
    BEGIN
        DELETE FROM regions
         WHERE region_id = p_region_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'Region nie istnieje: ' || p_region_id);
        END IF;
    END delete_region;

    FUNCTION get_region_by_id(
        p_region_id IN REGIONS.REGION_ID%TYPE)
        RETURN REGIONS%ROWTYPE
    IS
        v_row REGIONS%ROWTYPE;
    BEGIN
        SELECT *
          INTO v_row
          FROM regions
         WHERE region_id = p_region_id;
        RETURN v_row;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20053, 'Region nie istnieje: ' || p_region_id);
    END get_region_by_id;

    FUNCTION get_region_by_name(
        p_region_name IN REGIONS.REGION_NAME%TYPE)
        RETURN REGIONS%ROWTYPE
    IS
        v_row REGIONS%ROWTYPE;
    BEGIN
        SELECT *
          INTO v_row
          FROM regions
         WHERE UPPER(region_name) = UPPER(p_region_name);
        RETURN v_row;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20054, 'Region nie istnieje: ' || p_region_name);
    END get_region_by_name;

    PROCEDURE list_regions(
        p_region_id     IN REGIONS.REGION_ID%TYPE   DEFAULT NULL,
        p_name_like     IN VARCHAR2                 DEFAULT NULL,
        p_result        OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_result FOR
            SELECT r.*
              FROM regions r
             WHERE (p_region_id IS NULL OR r.region_id = p_region_id)
               AND (p_name_like IS NULL OR UPPER(r.region_name) LIKE UPPER('%' || p_name_like || '%'))
             ORDER BY r.region_id;
    END list_regions;

END regions_api_pkg;
/

BEGIN
    regions_api_pkg.create_region(p_region_name => 'Antarctica');
    regions_api_pkg.create_region(p_region_id => 10, p_region_name => 'Europe');
    regions_api_pkg.update_region(10, 'EU');
    regions_api_pkg.delete_region(10);
END;
/