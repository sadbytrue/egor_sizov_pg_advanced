SELECT * FROM phones WHERE id = (SELECT * FROM random_between(1,2000000));
SELECT * FROM goods WHERE id = (SELECT * FROM random_between(1,100000));
SELECT * FROM uoms WHERE id = (SELECT * FROM random_between(1,10000));

SELECT * FROM customers WHERE id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM suppliers WHERE id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM customers WHERE phone_id = (SELECT * FROM random_between(1,2000000));
SELECT * FROM suppliers WHERE phone_id = (SELECT * FROM random_between(1,2000000));

SELECT * FROM contracts WHERE id = (SELECT * FROM random_between(1,10000000));
SELECT * FROM contracts WHERE supplier_id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM contracts WHERE customer_id = (SELECT * FROM random_between(1,1000000));
SELECT * FROM contracts WHERE good_id = (SELECT * FROM random_between(1,100000));
SELECT * FROM contracts WHERE uom_id = (SELECT * FROM random_between(1,10000));


UPDATE phones SET value = random_between(100000000,999999999) WHERE id = (SELECT * FROM random_between(1,2000000));
UPDATE goods SET name = random_string(10) WHERE id = (SELECT * FROM random_between(1,100000));
UPDATE uoms SET name = random_string(5) WHERE id = (SELECT * FROM random_between(1,10000));

UPDATE customers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,2000000)
WHERE id = (SELECT * FROM random_between(1,1000000));
UPDATE suppliers SET 
name = random_string(10),
surname = random_string(10),
phone_id = random_between(1,2000000)
WHERE id = (SELECT * FROM random_between(1,1000000));

UPDATE contracts SET
supplier_id=random_between(1,1000000),
customer_id=random_between(1,1000000),
good_id=random_between(1,100000),
quantity=random_between(1,1000000)::numeric/1000::numeric,
uom_id=random_between(1,10000)
WHERE id = (SELECT * FROM random_between(1,10000000));