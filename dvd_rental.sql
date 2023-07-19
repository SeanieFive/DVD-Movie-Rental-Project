----Create Tables---- This works
----Create Detailed Table----
-- This creates an empty detailed table to be used
-- for the detailed section of the business report
DROP TABLE IF EXISTS detailed;
CREATE TABLE detailed (
	rental_id integer,
	rental_date timestamp,
	staff_id integer,
	store_id integer,
	address_id integer,
	address varchar (50),
	city_id integer,
	city varchar (50)
);

-- This will display the empty detailed table
SELECT * FROM detailed;

----Create Summary Table----
-- This creates an empty summary table to be used
-- for the summary section of the business report
DROP TABLE IF EXISTS summary;
CREATE TABLE summary (
	store_location varchar (100),
	total_rentals integer
);

-- This will display the empty summary table
SELECT * FROM summary;


--------------------------------------------------------------


----Insert Data into the Detailed Table---- This works
-- This will load the data from the rental, staff, store,
-- address, and city tables into the detailed table

INSERT INTO detailed (
	rental_id,
	rental_date,
	staff_id,
	store_id,
	address_id,
	address,
	city_id,
	city
)
	
SELECT
	rental.rental_id, rental.rental_date,
	staff.staff_id,
	store.store_id,
	address.address_id, address.address,
	city.city_id, city.city

FROM rental
INNER JOIN staff ON rental.staff_id = staff.staff_id
INNER JOIN store ON staff.store_id = store.store_id
INNER JOIN address ON store.address_id = address.address_id
INNER JOIN city ON address.city_id = city.city_id
;

-- This will display the filled detailed table
SELECT * FROM detailed;


--------------------------------------------------------------


-- CONCAT FUNCTION -- This works
-- This will input the address and city fields through a
-- concatenating function to create a single field

CREATE OR REPLACE FUNCTION create_store_location(address varchar (50), city varchar (50))
	RETURNS varchar (100)
	LANGUAGE plpgsql
AS
$$
DECLARE store_location varchar (100);
BEGIN
	SELECT CONCAT_WS(‘, ‘, address, city) INTO store_location;
	RETURN store_location;
END;
$$

--------------------------------------------------------------


-- This tests the function with the city and address
-- fields from the detailed table

SELECT DISTINCT create_store_location(address, city) FROM detailed


--------------------------------------------------------------


----Insert Data into the Summary Table---- This works
-- This will run the concat function on city and address
-- fields, count total rentals, and group by store location

INSERT INTO summary (
	store_location,
	total_rentals
)
SELECT create_store_location(address, city) AS store_location, COUNT (create_store_location(address, city)) AS total_rentals FROM detailed
GROUP BY store_location;

SELECT * FROM summary;


--------------------------------------------------------------


-- CREATE TRIGGER FUNCTION -- This works
-- This creates the trigger function for
-- updating the summary table
CREATE FUNCTION update_summary()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS $$
BEGIN
	-- Removes any previous data from summary table
	DELETE FROM summary;
	INSERT INTO summary (
		store_location,
		total_rentals
	)
	
	-- This will use the create_store_location function to
	-- create the store_location field in the summary table	
	SELECT create_store_location(address, city) AS store_location, COUNT	(create_store_location(address, city)) AS total_rentals FROM detailed
	GROUP BY store_location
	ORDER BY total_rentals DESC;
RETURN NEW;
END;
$$


--------------------------------------------------------------


-- CREATE TRIGGER EVENT FUNCTION -- This works
-- This event trigger will call the update_summary() trigger
-- function whenever data is inserted into the detailed table
CREATE TRIGGER update_summary_trigger
AFTER INSERT ON detailed
FOR EACH STATEMENT
EXECUTE PROCEDURE update_summary();


--------------------------------------------------------------


-- CREATE STORED PROCEDURES -- This works
-- This will create the procedures that will
-- refresh the detailed table which will then
-- trigger the update_summary_trigger to update
-- the summary table

CREATE OR REPLACE PROCEDURE tables_refresh()
LANGUAGE PLPGSQL
AS $$

BEGIN
	-- This clears all data from the detailed table
	
	DELETE FROM detailed;

	----Insert Data into the Detailed Table----
	-- This will load the data from the rental, staff, store,
	-- address, and city tables into the detailed table

	INSERT INTO detailed (
		rental_id,
		rental_date,
		staff_id,
		store_id,
		address_id,
		address,
		city_id,
		city
	)
	
	SELECT
		rental.rental_id, rental.rental_date,
		staff.staff_id,
		store.store_id,
		address.address_id, address.address,
		city.city_id, city.city

	FROM rental
	INNER JOIN staff ON rental.staff_id = staff.staff_id
	INNER JOIN store ON staff.store_id = store.store_id
	INNER JOIN address ON store.address_id = address.address_id
	INNER JOIN city ON address.city_id = city.city_id
	;
END;
$$

-- This runs the stored procedure -- 
-- This should be executed 6 months after a new store
-- location is opened to evaluate new rental data

CALL tables_refresh();
