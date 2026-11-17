# Basketly: Where Does the Money Go?

A PostgreSQL case study on a fictional grocery delivery app. I played the data analyst: audit messy data, build the metrics, and answer three questions from the CEO.

**Tools:** PostgreSQL 18, pgAdmin 4. SQL only (CTEs, window functions, subqueries, indexes, views).

## The company

Basketly delivers groceries in three cities (Riverton, Lakeside, Hillcrest). Data covers Jan 2025 to Jun 2026: 75,404 orders, 10 tables.

The CEO asked:
1. Where does the money go?
2. Why do customers leave?
3. Is anyone abusing our promotions?

## Headline answers

| Question | Answer |
|---|---|
| Where does the money go? | Basketly loses money: **-81,119.82** on 4,058,887.12 revenue. **57.2%** of orders lose money. Goods cost is 83.7% of revenue, rider payout 14.4%, payment fees 2.5%, refunds 1.5%. |
| Which orders lose most? | Small baskets (under 30: **-5.50** per order), late-night orders (22:00 to 01:59: **-5.18** per order, 38% of the total loss), and Hillcrest (**-3.33** per order, long distances of 6.5 km on average). Orders over 100 earn **+9.71**. |
| Why do customers leave? | Late first deliveries. Customers whose first order was late reordered within 30 days **56.0%** of the time, against **68.6%** when on time. Lakeside had a rider shortage from Sep 2025 to Jan 2026 (late rate **47.8%** against 11.0% normally). Lakeside customers who joined in those months reordered **54.6%** against 69.8%. |
| Promo abuse? | Real but small. **580** suspect accounts (178 on shared devices, 402 on shared emails) cost about 12,867 in discounts, 12% of the WELCOME50 bill. The bigger problem is the WELCOME50 design itself: **-19.91** profit per order, about -96,000 in total, more than the company's whole loss. |
| Who is profitable? | Only the "Champions" customer segment (2,559 customers, +16,485). "At risk" customers lose **-43,613**. |

## Recommendations

1. Redesign WELCOME50 (minimum basket, smaller discount).
2. Add a minimum order size or delivery fee for small baskets.
3. Review late-night rider pay and Hillcrest delivery distance.
4. Keep enough riders per city (the Lakeside shortage cost about 250 customers per the first-order analysis).
5. Block repeat devices and emails at signup.
6. Win back "At risk" customers before they become "Lost".

## Method

### Phase 1 to 2: load and audit
Loaded 10 CSV files into raw tables, then audited each table with the same 3 steps: count, look, logic checks. Rule: **raw tables are never changed.** Bad rows are **flagged, not deleted**, in `*_final` tables (every `_final` table has a primary key).

Examples of problems found and flagged: 149 deliveries with delivery time before pickup time, 98 repeat refunds (517.13), 9 refunds for missing orders (86.10), 45 order lines with deleted products, orders with totals that do not match their items, promo codes used outside their dates, 1 rider who left before joining.

### Phase 3: business metrics
Revenue = delivered orders with a successful payment (72,052 orders, 4,058,887.12; matched to the payments table). Monthly orders grew from 632 (Jan 2025) to 7,694 (Jun 2026). Riverton earns 53% of revenue, Lakeside 32%, Hillcrest 15%.

### Phase 4: profit per order (the join trap)
Joining orders to order items multiplies rows (387,924 extra rows) and would inflate every amount. Fix: sum items per order in a subquery first, then join one row per order. Profit = revenue - goods cost - rider payout - payment fee - refunds (first refund only).

### Phase 5: cohort retention
Customers grouped by first-order month, then % ordering again 1, 3 and 6 months later. Month-1 retention is about 50 to 60%, month-6 about 10 to 15%.

### Phase 6: RFM segmentation
Recency, frequency and monetary scores (1 to 5, cut with percentiles) turned into 6 segments. Only Champions make money.

### Phase 7: delivery and churn
Late-delivery rate by month and city, riders working per month, and first-order reorder rate. This isolated the Lakeside shortage.

### Phase 8: promo-abuse investigation
Grouped accounts by device and email. Normal devices have 1 account; 18 devices have 6 to 16 accounts each (178 accounts). Labeled as "suspect", not proven fraud (some shared emails may be duplicate sign-ups).

### Phase 9: production touches
- 6 indexes on join columns. Test query: **23.9 ms to 0.16 ms** (about 150x faster), checked with `EXPLAIN ANALYZE`.
- 4 reusable views: `v_monthly_revenue`, `v_city_profit`, `v_segment_profit`, `v_promo_abuse_cost`.
- No foreign keys on purpose: flagged orphan rows are kept for audit and a foreign key would reject them.

## Limits (what this analysis does not claim)

- Profit is **contribution profit**: no rent, salaries or marketing. Real profit is lower.
- Product cost is one current value per product, not history.
- Cohort and lateness effects show association, not proven cause.
- Promo-abuse accounts are suspects, based on shared device or email only.

## Repository

```
basketly/
  data/          10 CSV files + data dictionary
  sql/           scripts in phase order
  README.md
```

## Skills shown

Data cleaning and auditing, joins and the fan-out trap, CTEs, window functions, cohort analysis, RFM, root-cause analysis, fraud-pattern detection, indexing and `EXPLAIN ANALYZE`, views.
