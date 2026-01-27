-- 1. Stwórz ranking pracowników oparty na wysokości pensji 
--    Jeśli dwie osoby mają tę samą pensję, powinny otrzymać ten sam numer.

SELECT
    first_name AS "Imię",
    last_name AS "Nazwisko",
    salary AS "Pensja",
    department_id AS "ID departamentu",
    DENSE_RANK() OVER (ORDER BY salary DESC) AS "Ranking"
FROM employees
ORDER BY department_id, last_name;

-- 2. Dodaj kolumnę, która pokazuje całkowitą sumę pensji wszystkich pracowników,
-- ale bez grupowania ich.

SELECT
    first_name AS "Imię",
    last_name AS "Nazwisko",
    salary AS "Pensja",
    department_id AS "ID departamentu",
    DENSE_RANK() OVER (ORDER BY salary DESC) AS "Ranking",
    SUM(salary) OVER () AS "Całkowita suma pensji"
FROM employees
ORDER BY salary DESC;

-- 3. Dla każdego pracownika wypisz: nazwisko, nazwę produktu, 
-- skumulowaną wartość sprzedaży dla pracownika, 
-- ranking wartości sprzedaży względem wszystkich zamówień.

SELECT
    e.last_name AS "Nazwisko",
    p.product_name AS "Nazwa produktu",
    sum(s.price) OVER (
        PARTITION BY s.employee_id
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Skumulowana wartość sprzedaży",
    DENSE_RANK() OVER (
        ORDER BY s.price DESC
    ) AS "Ranking wartości sprzedaży"
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
ORDER BY "Ranking wartości sprzedaży";

-- 4. Dla każdego wiersza z tabeli sales wypisać nazwisko pracownika, 
-- nazwę produktu, cenę produktu, 
-- liczbę transakcji dla danego produktu tego dnia, sumę zapłaconą danego dnia
-- za produkt, poprzednią cenę oraz kolejną cenę danego produktu.

SELECT
    e.last_name AS "Nazwisko",
    p.product_name AS "Nazwa produktu",
    s.price AS "Cena produktu",
    s.sale_date AS "Data sprzedaży",
    COUNT(*) OVER (
        PARTITION BY s.product_id, TRUNC(s.sale_date)
    ) AS "Liczba transakcji produktu danego dnia",
    SUM(s.price) OVER (
        PARTITION BY s.product_id, TRUNC(s.sale_date)
    ) AS "Suma zapłacona za produkt danego dnia",
    LAG(s.price) OVER (
        PARTITION BY s.product_id
        ORDER BY s.sale_date
    ) AS "Poprzednia cena produktu",
    LEAD(s.price) OVER (
        PARTITION BY s.product_id
        ORDER BY s.sale_date
    ) AS "Kolejna cena produktu"
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
ORDER BY p.product_name, s.sale_date;

-- 5. Dla każdego wiersza wypisać nazwę produktu, cenę produktu, sumę całkowitą
-- zapłaconą w danym miesiącu oraz sumę rosnącą zapłaconą w danym miesiącu za
-- konkretny produkt.

SELECT
    p.product_name AS "Nazwa produktu",
    s.price AS "Cena produktu",
    SUM(s.price) OVER (
        PARTITION BY s.product_id, 
            EXTRACT(YEAR FROM s.sale_date), 
            EXTRACT(MONTH FROM s.sale_date)
    ) AS "Suma całkowita w miesiącu",
    SUM(s.price) OVER (
        PARTITION BY s.product_id,
            EXTRACT(YEAR FROM s.sale_date),
            EXTRACT(MONTH FROM s.sale_date)
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Suma rosnąca w miesiącu"
FROM sales s
JOIN products p ON s.product_id = p.product_id
ORDER BY p.product_name, s.sale_date;

-- 6. Wypisać obok siebie cenę produktu z roku 2022 i roku 2023 z tego samego
-- dnia oraz dodatkowo różnicę pomiędzy cenami tych produktów oraz 
-- dodatkowo nazwę produktu i jego kategorię.

SELECT
    p.product_name AS "Nazwa produktu",
    p.product_category AS "Kategoria",
    s2022.price AS "Cena 2022",
    s2023.price AS "Cena 2023",
    COALESCE(s2023.price, 0) - COALESCE(s2022.price, 0) AS "Różnica cen"
FROM products p
LEFT JOIN sales s2022 ON p.product_id = s2022.product_id
    AND EXTRACT(YEAR FROM s2022.sale_date) = 2022
LEFT JOIN sales s2023 ON p.product_id = s2023.product_id
    AND EXTRACT(YEAR FROM s2023.sale_date) = 2023
    AND EXTRACT(MONTH FROM s2022.sale_date) = EXTRACT(MONTH FROM s2023.sale_date)
    AND EXTRACT(DAY FROM s2022.sale_date) = EXTRACT(DAY FROM s2023.sale_date)
WHERE s2022.price IS NOT NULL AND s2023.price IS NOT NULL;

-- 7. Dla każdego wiersza wypisać nazwę kategorii produktu, nazwę produktu, 
-- jego cenę, minimalną cenę w danej kategorii, 
-- maksymalną cenę w danej kategorii, różnicę między maksymalną a minimalną ceną.

SELECT
    p.product_category AS "Nazwa kategorii",
    p.product_name AS "Nazwa produktu",
    s.price AS "Cena produktu",
    MIN(s.price) OVER (
        PARTITION BY p.product_category
    ) AS "Minimalna cena w kategorii",
    MAX(s.price) OVER (
        PARTITION BY p.product_category
        ) AS "Maksymalna cena w kategorii",
    MAX(s.price) OVER (
        PARTITION BY p.product_category
        ) - MIN(s.price) OVER (
            PARTITION BY p.product_category
            ) AS "Różnica cen w kategorii"
FROM sales s
JOIN products p ON s.product_id = p.product_id
ORDER BY p.product_category, s.price;

-- 8. Dla każdego wiersza wypisz nazwę produktu i średnią kroczącą ceny 
-- (biorącą pod uwagę poprzednią, bieżącą i następną cenę) 
-- tego produktu według kolejnych dat.

SELECT
    p.product_name AS "Nazwa produktu",
    s.sale_date AS "Data sprzedaży",
    s.price AS "Cena",
    ROUND(AVG(s.price) OVER (
        PARTITION BY s.product_id
        ORDER BY s.sale_date
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS "Średnia krocząca"
FROM sales s
JOIN products p ON s.product_id = p.product_id
ORDER BY p.product_name, s.sale_date;

-- 9. Dla każdego wiersza nazwę produktu, kategorię oraz 
-- ranking cen wewnątrz kategorii, ponumerowane wiersze wewnątrz kategorii 
-- w zależności od ceny oraz ranking gęsty (dense) cen wewnątrz kategorii.

SELECT
    p.product_name AS "Nazwa produktu",
    p.product_category AS "Kategoria",
    s.price AS "Cena",
    RANK() OVER (
        PARTITION BY p.product_category
        ORDER BY s.price DESC
    ) AS "Ranking cen",
    ROW_NUMBER() OVER (
        PARTITION BY p.product_category
        ORDER BY s.price DESC, p.product_name
    ) AS "Numer wiersza w kategorii",
    DENSE_RANK() OVER (
        PARTITION BY p.product_category
        ORDER BY s.price DESC
    ) AS "Ranking gęsty"
FROM sales s
JOIN products p ON s.product_id = p.product_id
ORDER BY p.product_category, s.price DESC;

-- 10. Dla każdego wiersza tabeli sales nazwisko pracownika, nazwa produktu, 
-- wartość rosnąca jego sprzedaży według dat (cena produktu * ilość) dla danego
-- pracownika oraz ranking wartości sprzedaży dla kolejnych wierszy globalnie 
-- według wartości zamówienia.

SELECT
    e.last_name AS "Nazwisko pracownika",
    p.product_name AS "Nazwa produktu",
    s.sale_date AS "Data sprzedaży",
    s.quantity AS "Ilość",
    s.price AS "Cena",
    (s.quantity * s.price) AS "Wartość sprzedaży",
    SUM(s.quantity * s.price) OVER (
        PARTITION BY s.employee_id
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Rosnąca wartość sprzedaży pracownika",
    RANK() OVER (
        ORDER BY (s.quantity * s.price) DESC
    ) AS "Ranking wartości sprzedaży"
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
ORDER BY s.sale_date;

-- 11. Nie używając funkcji okienkowych wyświetl: Imiona i nazwiska pracowników 
-- oraz ich stanowisko, którzy uczestniczyli w sprzedaży.

SELECT DISTINCT
    e.first_name AS "Imię",
    e.last_name AS "Nazwisko",
    e.job_id AS "Stanowisko"
FROM employees e
JOIN sales s ON e.employee_id = s.employee_id
ORDER BY e.last_name, e.first_name;