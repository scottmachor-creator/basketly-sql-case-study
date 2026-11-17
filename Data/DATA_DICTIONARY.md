# Basketly dataset: data dictionary

Basketly is a fictional grocery delivery app. All people, addresses, phone numbers and devices are invented.
Period covered: 1 Jan 2025 to 30 Jun 2026. Cities: Riverton, Lakeside (both launched Jan 2025), Hillcrest (launched Jul 2025).
Money is in a single currency, 2 decimal places.

The data was exported "as is" from production. Expect quality problems. Finding them is part of the job.

## customers.csv
| column | meaning |
|---|---|
| customer_id | Customer identifier |
| full_name | Name on the account |
| email | Login email |
| phone | Phone number, as typed by the customer |
| device_id | ID of the phone/browser the account was created on |
| signup_date | Date the account was created |
| city | Home city chosen at signup |
| acquisition_channel | How the customer found Basketly: organic, paid_social, search_ads, referral, influencer |
| referred_by_customer_id | If referred, the customer_id of the referrer |

## addresses.csv
| column | meaning |
|---|---|
| address_id | Address identifier |
| customer_id | Owner of the address |
| street | Street line, as typed by the customer |
| city | City of the address |
| postal_code | Postal code |
| is_default | Customer's default delivery address |

## products.csv
| column | meaning |
|---|---|
| product_id | Product identifier |
| product_name | Name |
| category | Product category |
| unit_price | **Current** selling price (as of 30 Jun 2026) |
| unit_cost | Standard cost Basketly pays the supplier per unit |
| is_active | Still on sale |

## promotions.csv
| column | meaning |
|---|---|
| promo_code | Code the customer enters |
| description | What the promo gives |
| discount_type | percent, fixed, or free_delivery |
| discount_value | Percent or fixed amount off |
| min_order_value | Minimum basket subtotal for the code to apply |
| max_discount | Cap on the discount (blank = no cap) |
| start_date, end_date | Validity window (inclusive) |
| new_customers_only | Only valid on a customer's first order |

## riders.csv
| column | meaning |
|---|---|
| rider_id | Rider identifier |
| rider_name | Name |
| city | City the rider works in |
| vehicle_type | bicycle, scooter, motorbike, car |
| employment_type | contractor or full_time |
| joined_date | First day working |
| left_date | Last day working (blank = still active) |

## orders.csv
| column | meaning |
|---|---|
| order_id | Order identifier |
| customer_id | Who ordered |
| address_id | Delivery address |
| city | City the order was delivered in |
| order_ts | When the order was placed (local time) |
| status | delivered or cancelled |
| promo_code | Promo code used (blank = none) |
| subtotal | Value of items before discount |
| discount_amount | Promo discount |
| delivery_fee | Delivery fee charged (2.99; free on subtotal of 35+ or with a free-delivery promo) |
| total_amount | What the customer paid: subtotal - discount_amount + delivery_fee |
| platform | android, ios, web |

## order_items.csv
| column | meaning |
|---|---|
| order_item_id | Line identifier |
| order_id | Order the line belongs to |
| product_id | Product |
| quantity | Units ordered |
| unit_price | Price per unit **at the time of the order** |

## payments.csv
One row per payment **attempt**.
| column | meaning |
|---|---|
| payment_id | Attempt identifier |
| order_id | Order being paid |
| payment_method | card, wallet, cash |
| amount | Amount attempted |
| status | success, failed, refunded (refunded = order cancelled after payment) |
| processed_at | Time of the attempt |
| processing_fee | Fee Basketly paid the payment provider for this attempt |

## deliveries.csv
| column | meaning |
|---|---|
| delivery_id | Delivery identifier |
| order_id | Order delivered |
| rider_id | Rider assigned (blank if none was assigned) |
| distance_km | Distance from store to customer |
| promised_at | Delivery time promised to the customer |
| picked_up_at | When the rider collected the order |
| delivered_at | When the order reached the customer |
| rider_payout | What Basketly paid the rider for this delivery |

## refunds.csv
| column | meaning |
|---|---|
| refund_id | Refund identifier |
| order_id | Order refunded |
| refund_ts | When the refund was issued |
| reason | spoiled, missing_item, damaged, wrong_item, late_delivery |
| amount | Amount refunded to the customer |
