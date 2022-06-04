-- Создание шести представлений (по одному на каждую таблицу)
CREATE OR REPLACE VIEW de.analysis.orderitems AS
SELECT * FROM de.production.orderitems;

CREATE OR REPLACE VIEW de.analysis.orders AS
SELECT * FROM de.production.orders;

CREATE OR REPLACE VIEW de.analysis.orderstatuses AS
SELECT * FROM de.production.orderstatuses;

CREATE OR REPLACE VIEW de.analysis.orderstatuslog AS
SELECT * FROM de.production.orderstatuslog;

CREATE OR REPLACE VIEW de.analysis.products AS
SELECT * FROM de.production.products;

CREATE OR REPLACE VIEW de.analysis.users AS
SELECT * FROM de.production.users;
