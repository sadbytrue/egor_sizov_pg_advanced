CREATE TABLE phones (
id serial PRIMARY KEY, 
value integer);

CREATE TABLE goods (
id serial PRIMARY KEY, 
name text);

CREATE TABLE uoms 
(id serial PRIMARY KEY, 
name text);

CREATE TABLE customers (
id serial PRIMARY KEY, 
name text,
surname text,
phone_id integer REFERENCES phones (id)
);

CREATE TABLE suppliers (
id serial PRIMARY KEY, 
name text,
surname text,
phone_id integer REFERENCES phones (id)
);

CREATE TABLE contracts (
id serial PRIMARY KEY, 
supplier_id integer REFERENCES suppliers (id),
customer_id integer REFERENCES customers (id),
good_id integer REFERENCES goods (id),
quantity integer,
uom_id integer REFERENCES uoms (id)
);

INSERT INTO phones (id, value)
SELECT 
generate_series,
random_between(100000000,999999999)
FROM generate_series(1,2000000);

INSERT INTO goods (id, name)
SELECT 
generate_series,
random_string(10)
FROM generate_series(1,100000);

INSERT INTO uoms (id, name)
SELECT 
generate_series,
random_string(5)
FROM generate_series(1,10000);

INSERT INTO customers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,1000000)
FROM generate_series(1,1000000);

INSERT INTO suppliers (id, name, surname, phone_id)
SELECT 
generate_series,
random_string(10),
random_string(10),
random_between(1,1000000)
FROM generate_series(1,1000000);

INSERT INTO contracts (id, supplier_id, customer_id, good_id, quantity, uom_id)
SELECT 
generate_series,
random_between(1,1000000),
random_between(1,1000000),
random_between(1,100000),
random_between(1,1000000)::numeric/1000::numeric,
random_between(1,10000)
FROM generate_series(1,10000000);