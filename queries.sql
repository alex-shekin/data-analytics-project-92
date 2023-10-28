/* Подсчет количества покупателей */
select count(customer_id) as customers_count from customers; /* Подсчет количества ID покупателей 
из таблицы customers при помоши функции count и присваивание имени столбцу при помощи as */


/* Отчет о 10 лучших продавцов */
/*Общее табличное выражение для ID продавца и связки фамилия + имя */
with name_table as (
	select employee_id, concat(employees.first_name, ' ', employees.last_name) as name
	from employees
	),
/* Общее табличное выражение для ID продавца и количсетва сделок*/
	operations_table as (
	select sales_person_id, count(sales_person_id) as operations
	from sales
	group by sales_person_id
	),
/* общее табличное вырадение для суммарной выручки */
	income_table as (
	select sales_person_id, sum(p.price * s.quantity) as income
	from products as p
		inner join sales as s
		on p.product_id = s.product_id
	group by sales_person_id
	)
select n.name, o.operations, round(i.income, 0) as income -- сборка в одну таблицу основного запроса и округление
from name_table as n
	left join operations_table as o
	on n.employee_id = o.sales_person_id
	left join income_table as i
	on n.employee_id = i.sales_person_id
	order by i.income desc nulls last limit 10 -- сортировка по убыванию и вывод топ-10 с учетом NULL
	
/* Отчет о продавцах с наименьшей средней выручкой */
/*Общее табличное выражение для ID продавца и связки фамилия + имя */
with name_table as (
	select employee_id, concat(employees.first_name, ' ', employees.last_name) as name
	from employees
	),
/* общее табличное вырадение для нахождения среднего по сделке для ID продавца */
	average_income_table as (
	select distinct (s.sales_person_id), 
		   avg(s.quantity * p.price) over (partition by sales_person_id) as average_income
	from sales as s
		inner join products as p
		on s.product_id = p.product_id
	)
select n.name, round(a.average_income, 0) as average_income
from sales as s
	left join name_table as n
	on s.sales_person_id = n.employee_id
	left join average_income_table as a
	on s.sales_person_id = a.sales_person_id
where a.average_income < (
	select avg(quantity * price)
	from sales as s
	join products as p
	on s.product_id = p.product_id
	 )
group by n.name, average_income
order by average_income asc; 

/* Отчет о выручке по дням неделям */
/* Общее табличное выражение для ID дня недели и выручки по дням недели для каждого продавца */
	with income_table as (
	select 
	   concat(e.first_name, ' ', e.last_name) as name,
	   extract (isodow from s.sale_date) as weekday_num,
	   sum (s.quantity * p.price) over (partition by extract (isodow from s.sale_date), e.employee_id) as income
	from sales as s
	join employees as e
	on s.sales_person_id = e.employee_id
	join products as p
	on s.product_id = p.product_id
	order by weekday_num, name
	),
	day_of_week as (
	select 
		extract (isodow from s.sale_date) as weekday_num,
		to_char (s.sale_date, 'day') as weekday_text
	from sales as s
	group by weekday_num, weekday_text
	)
select distinct on (i.weekday_num, name) name, weekday_text as weekday , round(income, 0) as income -- вывод уникальных значений уже отсортированных данных
from income_table as i
join day_of_week as d
on i.weekday_num = d.weekday_num;