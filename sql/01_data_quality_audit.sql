-- Basketly case study: data quality audit (PostgreSQL 18)
--
-- Method: raw tables (addresses, customers, deliveries, order_items, orders,
-- payments, products, promotions, refunds, riders) are never modified.
-- Each table was audited in 3 steps: count, look, logic checks.
-- Bad rows are FLAGGED in *_final tables (never deleted), and every
-- *_final table has a primary key.
--
-- This query lists every flag and how many rows it marks.
-- Expected results are in the comments.

SELECT 'deliveries: delivered before pickup' AS check_name, COUNT(*) AS flagged_rows FROM deliveries_final   WHERE time_error          -- 149
UNION ALL SELECT 'addresses: customer missing',          COUNT(*) FROM addresses_final    WHERE customer_missing      -- 17
UNION ALL SELECT 'orders: customer missing',             COUNT(*) FROM orders_final       WHERE customer_missing      -- 54
UNION ALL SELECT 'orders: total does not match',         COUNT(*) FROM orders_final       WHERE total_mismatch        -- 538
UNION ALL SELECT 'orders: subtotal does not match',      COUNT(*) FROM orders_final       WHERE subtotal_mismatch     -- 643
UNION ALL SELECT 'orders: promo outside valid dates',    COUNT(*) FROM orders_final       WHERE promo_outside_dates   -- 51
UNION ALL SELECT 'order items: product missing',         COUNT(*) FROM order_items_final  WHERE product_missing       -- 45
UNION ALL SELECT 'order items: zero quantity',           COUNT(*) FROM order_items_final  WHERE zero_quantity         -- 60
UNION ALL SELECT 'refunds: order missing',               COUNT(*) FROM refunds_final      WHERE order_missing         -- 9
UNION ALL SELECT 'refunds: repeat refund',               COUNT(*) FROM refunds_final      WHERE repeat_refund         -- 98
UNION ALL SELECT 'riders: left before joined',           COUNT(*) FROM riders_final       WHERE date_error;           -- 1
