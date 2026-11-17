-- Basketly case study: analysis tables, indexes and views (PostgreSQL 18)
-- Run after the *_final tables exist (see 01_load_and_clean.sql).

-- ============================================================
-- Phase 2: flagged final tables (examples with exact logic)
-- ============================================================

-- Refunds: flag refunds for missing orders and repeat refunds (keep first only)
CREATE TABLE refunds_final AS
SELECT r.*,
       (o.order_id IS NULL) AS order_missing,
       (ROW_NUMBER() OVER (PARTITION BY r.order_id ORDER BY r.refund_ts, r.refund_id) > 1) AS repeat_refund
FROM refunds r
LEFT JOIN orders_final o ON o.order_id = r.order_id;

-- Riders: flag riders whose left_date is before joined_date
CREATE TABLE riders_final AS
SELECT *, COALESCE(left_date < joined_date, FALSE) AS date_error
FROM riders;

-- ============================================================
-- Phase 4: profit per delivered order
-- Items are summed per order BEFORE joining, to avoid the fan-out trap.
-- ============================================================
CREATE TABLE order_profit AS
SELECT *, revenue - goods_cost - rider_payout - payment_fee - refunds AS profit
FROM (
    SELECT o.order_id, o.city, o.order_ts, o.total_amount AS revenue,
           COALESCE(i.goods_cost, 0)    AS goods_cost,
           COALESCE(d.rider_payout, 0)  AS rider_payout,
           COALESCE(p.processing_fee,0) AS payment_fee,
           COALESCE(r.refund_amount, 0) AS refunds
    FROM orders_final o
    LEFT JOIN (SELECT oi.order_id, SUM(oi.quantity * pr.unit_cost) AS goods_cost
               FROM order_items_final oi
               JOIN products_final pr ON pr.product_id = oi.product_id
               GROUP BY oi.order_id) i ON i.order_id = o.order_id
    LEFT JOIN deliveries_final d ON d.order_id = o.order_id
    LEFT JOIN payments p ON p.order_id = o.order_id AND p.status = 'success'
    LEFT JOIN (SELECT order_id, SUM(amount) AS refund_amount
               FROM refunds_final
               WHERE NOT repeat_refund
               GROUP BY order_id) r ON r.order_id = o.order_id
    WHERE o.status = 'delivered'
) t;

-- ============================================================
-- Phase 5: customer activity by month (base for cohort retention)
-- ============================================================
CREATE TABLE customer_activity AS
SELECT DISTINCT customer_id, DATE_TRUNC('month', order_ts)::date AS active_month
FROM orders_final
WHERE status = 'delivered';

-- ============================================================
-- Phase 6: RFM base (recency measured from 2026-06-30)
-- ============================================================
CREATE TABLE rfm_base AS
SELECT customer_id,
       DATE '2026-06-30' - MAX(order_ts)::date AS recency_days,
       COUNT(*)                                AS frequency,
       SUM(total_amount)                       AS monetary
FROM orders_final
WHERE status = 'delivered'
GROUP BY customer_id;

-- ============================================================
-- Phase 8: promo-abuse suspect accounts (WELCOME50)
-- ============================================================
CREATE TABLE promo_abuse_accounts AS
WITH w AS (
    SELECT DISTINCT c.customer_id, c.email, c.device_id
    FROM customers_final c
    JOIN orders_final o ON o.customer_id = c.customer_id
    WHERE o.promo_code = 'WELCOME50'
),
ring_devices AS (
    SELECT device_id FROM customers_final
    WHERE device_id IS NOT NULL
    GROUP BY device_id HAVING COUNT(*) >= 6
),
shared_emails AS (
    SELECT email FROM w GROUP BY email HAVING COUNT(*) >= 2
)
SELECT customer_id,
       CASE WHEN device_id IN (SELECT device_id FROM ring_devices)
            THEN 'device_ring' ELSE 'shared_email' END AS reason
FROM w
WHERE device_id IN (SELECT device_id FROM ring_devices)
   OR email IN (SELECT email FROM shared_emails);

-- ============================================================
-- Phase 9: indexes on join and filter columns
-- Test: EXPLAIN ANALYZE on orders_final WHERE customer_id = 100254
--       Seq Scan 23.9 ms -> Index Scan 0.16 ms
-- ============================================================
CREATE INDEX idx_orders_final_customer_id   ON orders_final (customer_id);
CREATE INDEX idx_order_items_final_order_id ON order_items_final (order_id);
CREATE INDEX idx_deliveries_final_order_id  ON deliveries_final (order_id);
CREATE INDEX idx_payments_order_id          ON payments (order_id);
CREATE INDEX idx_refunds_final_order_id     ON refunds_final (order_id);
CREATE INDEX idx_customers_final_device_id  ON customers_final (device_id);

-- ============================================================
-- Phase 9: reusable views
-- ============================================================
CREATE VIEW v_monthly_revenue AS
SELECT DATE_TRUNC('month', order_ts)::date AS month,
       COUNT(*)                            AS orders,
       SUM(total_amount)                   AS revenue,
       ROUND(AVG(total_amount), 2)         AS avg_order_value
FROM orders_final
WHERE status = 'delivered'
GROUP BY 1;

CREATE VIEW v_city_profit AS
SELECT city,
       COUNT(*)                       AS orders,
       ROUND(SUM(revenue), 2)         AS revenue,
       ROUND(SUM(profit), 2)          AS profit,
       ROUND(AVG(profit), 2)          AS profit_per_order,
       ROUND(100.0 * COUNT(*) FILTER (WHERE profit < 0) / COUNT(*), 1) AS pct_losing
FROM order_profit
GROUP BY city;

CREATE VIEW v_segment_profit AS
SELECT s.segment,
       COUNT(DISTINCT s.customer_id)  AS customers,
       COUNT(*)                       AS orders,
       ROUND(SUM(p.revenue), 2)       AS revenue,
       ROUND(SUM(p.profit), 2)        AS profit,
       ROUND(AVG(p.profit), 2)        AS profit_per_order
FROM rfm_segments s
JOIN orders_final o ON o.customer_id = s.customer_id
JOIN order_profit p ON p.order_id = o.order_id
GROUP BY s.segment;

CREATE VIEW v_promo_abuse_cost AS
SELECT a.reason,
       COUNT(DISTINCT a.customer_id) AS accounts,
       COUNT(*)                      AS welcome50_orders,
       ROUND(SUM(p.profit), 2)       AS profit
FROM promo_abuse_accounts a
JOIN orders_final o ON o.customer_id = a.customer_id
                   AND o.promo_code = 'WELCOME50'
JOIN order_profit p ON p.order_id = o.order_id
GROUP BY a.reason;
