-- 1. Покажіть середню зарплату співробітників за кожен рік, до 2005 року.
SELECT  ROUND(AVG(salary)) AS avg_salary, YEAR(from_date) AS year_salary
FROM employees.salaries
WHERE YEAR(from_date) <= 2005
GROUP BY YEAR(from_date)
ORDER BY year_salary;

-- 2. Покажіть середню зарплату співробітників за кожен рік
SELECT
ROUND(AVG(salary)) AS avg_salary, YEAR(from_date) AS year_salary
FROM employees.salaries
WHERE YEAR(from_date) 
GROUP BY YEAR(from_date)
ORDER BY year_salary;

-- 3. Покажіть середню зарплату співробітників по кожному відділу. Примітка: потрібно розрахувати по поточній зарплаті, та поточному відділу співробітників
SELECT  ROUND(AVG(salary)) AS avg_salary, d.dept_no
FROM employees.salaries AS s
INNER JOIN employees.dept_emp AS d ON (s.emp_no = d.emp_no)
WHERE CURRENT_DATE BETWEEN s.from_date AND s.to_date
AND CURRENT_DATE BETWEEN d.from_date AND d.to_date
GROUP BY d.dept_no
ORDER BY avg_salary;

-- 4. Покажіть середню зарплату співробітників по кожному відділу за кожний рік
SELECT  d.dept_no,  ROUND(AVG(salary)) AS avg_salary, YEAR(s.from_date) AS year_salary
FROM employees.salaries AS s
INNER JOIN employees.dept_emp AS d ON (s.emp_no = d.emp_no)
GROUP BY d.dept_no, year_salary
ORDER BY d.dept_no, avg_salary;

-- 5 Покажіть для кожного року найбільший відділ цього року та його середню зарплату
WITH department_salaries AS (
    SELECT 
        dep.dept_no, 
        YEAR(s.from_date) AS years, 
        COUNT(s.emp_no) AS emp_count,
        ROUND(AVG(s.salary)) AS avg_salary
    FROM salaries AS s
    INNER JOIN dept_emp AS d ON s.emp_no = d.emp_no
    INNER JOIN departments AS dep ON dep.dept_no = d.dept_no
    GROUP BY dep.dept_name, YEAR(s.from_date)
),
max_departments AS (
    SELECT 
        years, 
        MAX(emp_count) AS max_emp_count 
    FROM department_salaries
    GROUP BY years
)
SELECT 
    ds.years, 
    ds.dept_no, 
    ds.emp_count,
    ds.avg_salary
    FROM department_salaries AS ds
INNER JOIN max_departments AS md 
    ON ds.years = md.years AND ds.emp_count = md.max_emp_count
ORDER BY ds.years;

-- 6. Покажіть відділи в яких зараз працює більше 15000 співробітників.
SELECT dep.dept_name AS department_name, COUNT(d_e.emp_no) AS count_employee
FROM employees.departments AS dep
INNER JOIN employees.dept_emp AS d_e ON (dep.dept_no = d_e.dept_no)
WHERE CURDATE() BETWEEN d_e.from_date AND d_e.to_date
GROUP BY d_e.dept_no
HAVING COUNT(d_e.emp_no) > 15000;
            
-- 7. Для менеджера який працює найдовше покажіть його номер, відділ, дату прийому на роботу, прізвище
SELECT ee.emp_no, t.title, d_e.dept_no, ee.hire_date, ee.last_name 
FROM employees.employees AS ee
INNER JOIN employees.dept_emp AS d_e ON (d_e.emp_no = ee.emp_no)
INNER JOIN employees.titles AS t ON (ee.emp_no = t.emp_no)
WHERE title LIKE "Manager"
AND CURDATE() BETWEEN d_e.from_date AND d_e.to_date
AND CURDATE() BETWEEN t.from_date AND t.to_date
ORDER BY ee.hire_date
LIMIT 1;

-- 8. Покажіть детальну інформацію про поточного менеджера, який найдовше виконує свої обов'язки
 WITH OldestManager AS (
    SELECT MIN(from_date) AS min_from_date
    FROM employees.dept_manager
    WHERE CURDATE() BETWEEN from_date AND to_date)
SELECT e.emp_no, dm.dept_no, e.first_name, e.last_name, e.gender, e.birth_date, e.hire_date, dm.from_date, dm.to_date
FROM employees.dept_manager AS dm
INNER JOIN employees.employees AS e ON dm.emp_no = e.emp_no
INNER JOIN OldestManager AS om ON dm.from_date = om.min_from_date
WHERE CURDATE() BETWEEN dm.from_date AND dm.to_date;

-- 9. Покажіть топ-10 діючих співробітників компанії з найбільшою різницею між їх зарплатою і середньою зарплатою в їх відділі.
WITH avg_salary_dept AS
(SELECT ed.dept_no, ROUND(AVG(s.salary)) AS avg_salary_dept
FROM employees.dept_emp AS ed
INNER JOIN employees.salaries AS s ON ed.emp_no = s.emp_no
WHERE CURDATE() BETWEEN s.from_date AND s.to_date
AND CURDATE() BETWEEN ed.from_date AND ed.to_date
GROUP BY ed.dept_no),

employee_salary AS (SELECT ee.emp_no, ee.first_name, ee.last_name, ed.dept_no, es.salary
FROM employees.employees AS ee
INNER JOIN employees.salaries AS es ON (ee.emp_no = es.emp_no)
INNER JOIN employees.dept_emp AS ed ON (es.emp_no = ed.emp_no)
WHERE CURDATE() BETWEEN es.from_date AND es.to_date 
AND CURDATE() BETWEEN ed.from_date AND ed.to_date) 

SELECT es.emp_no, es.first_name, es.last_name, d.dept_no, es.salary, avg_salary_dept,(es.salary - avg_salary_dept) AS salary_difference
FROM employee_salary AS es
INNER JOIN avg_salary_dept AS asd ON (es.dept_no = asd.dept_no)
INNER JOIN departments AS d ON (asd.dept_no = d.dept_no)
ORDER BY salary_difference DESC
LIMIT 10;

-- 7. Для кожного відділу покажіть другого по порядку менеджера. 
-- Необхідно вивести відділ, прізвище ім’я менеджера, дату прийому на роботу менеджера і дату коли він став менеджером відділу
WITH Rank_Managers AS (
    SELECT dm.emp_no, dm.dept_no, dm.from_date AS manager_from_date,
        ROW_NUMBER() OVER (PARTITION BY dm.dept_no ORDER BY dm.from_date) AS manager_rank
    FROM dept_manager AS dm)
    
SELECT dep.dept_name, concat(first_name, ' ' , last_name) AS fuul_name, ee.hire_date, rm.manager_from_date
FROM Rank_Managers  AS rm
INNER JOIN employees.employees AS ee ON (ee.emp_no = rm.emp_no)
INNER JOIN employees.departments AS dep ON (rm.dept_no = dep.dept_no)
WHERE manager_rank = 2;
