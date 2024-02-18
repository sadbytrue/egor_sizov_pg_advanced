SELECT
contracts.id,
customers.name AS customer_name,
customers.surname AS customer_surname,
customers_phones.value AS customer_phone,
suppliers.name AS supplier_name,
suppliers.surname AS supplier_surname,
suppliers_phones.value AS supplier_phone,
goods.name AS good_name,
contracts.quantity,
uoms.name AS uom_name
FROM contracts
LEFT JOIN customers ON contracts.customer_id=customers.id
LEFT JOIN suppliers ON contracts.customer_id=suppliers.id
LEFT JOIN phones customers_phones ON customers.phone_id=customers_phones.id
LEFT JOIN phones suppliers_phones ON suppliers.phone_id=suppliers_phones.id
LEFT JOIN goods ON contracts.good_id=goods.id
LEFT JOIN uoms ON contracts.uom_id=uoms.id;

SELECT 
supplier_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY supplier_id;

SELECT 
customer_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY customer_id;

SELECT 
good_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY good_id;

SELECT 
uom_id,
AVG(quantity) AS avg_quantity,
COUNT(supplier_id) AS number_of_contracts,
SUM(quantity) AS sum_quantity
FROM contracts GROUP BY uom_id;