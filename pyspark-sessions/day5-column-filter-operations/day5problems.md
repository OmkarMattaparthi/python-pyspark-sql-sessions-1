# Day 5 - Practice Problems

**Topics:** Column selection, new column creation, type casting, filtering (AND / OR / NOT / isin / between / like / null)

Use the orders dataset from `data/orders.csv`. Load it with the defined schema before attempting problems.

---

## Section A — Column Selection

**Problem 1**  
Select only `order_id`, `customer_name`, and `total_amount` where `total_amount = quantity * unit_price`.  
Do this in two ways:
- Using `col()` with `.alias()`
- Using `selectExpr`

**Problem 2**  
Store the column names `["order_id", "city", "category", "status"]` in a Python list and use it in `df.select()`.

**Problem 3**  
Select all columns except `is_returned` and `order_date`. Use `drop()`.

**Problem 4**  
Using `selectExpr`, create:
- `order_id`
- `total_amount = quantity * unit_price`
- `city_upper = upper(city)`
- `month_num = month(order_date)`

---

## Section B — Creating New Columns

**Problem 5**  
Add a column `total_amount` = `quantity * unit_price`. Show `order_id`, `product`, `quantity`, `unit_price`, `total_amount`.

**Problem 6**  
Add a column `tax_18pct` = 18% of `total_amount`, rounded to 2 decimal places.  
Then add `net_payable` = `total_amount + tax_18pct`.  
Chain both `withColumn` calls.

**Problem 7**  
Add a column `order_label` by concatenating `product` and `city` with ` (` and `)` like:  
`"Laptop (Mumbai)"`.  
Hint: use `concat()` or `concat_ws()`.

**Problem 8**  
Extract `order_month` and `order_year` from `order_date`. Show only orders from February 2024.

**Problem 9**  
Add a column `value_segment`:
- `"Premium"` if `unit_price >= 30000`
- `"Standard"` if `unit_price >= 5000`
- `"Budget"` otherwise

Show `order_id`, `product`, `unit_price`, `value_segment`.

**Problem 10**  
Add a column `status_code`:
- `1` for `"delivered"`
- `2` for `"shipped"`
- `3` for `"cancelled"`
- `0` for anything else

---

## Section C — Type Casting

**Problem 11**  
Cast `unit_price` (Double) to Integer. What happens to decimal values?  
Show `unit_price` and `unit_price_int` side by side.

**Problem 12**  
Cast `is_returned` (Boolean) to Integer. Show `is_returned` and `returned_int`.  
What are the values you see?

**Problem 13**  
Cast `quantity` to Double and then back to Integer. Do you get the same values?

**Problem 14**  
Try casting `status` (String) to Integer. What do you see in the result column?  
Why does this happen?

**Problem 15**  
Cast `order_date` (Date) to String. Show `order_date` and `order_date_str`.  
What format is the resulting string?

---

## Section D — Filtering

**Problem 16 — Single condition**  
1. Filter orders where `status == "shipped"`. How many rows?
2. Filter orders where `unit_price > 40000`.
3. Filter orders where `is_returned == True`.

**Problem 17 — AND (&)**  
1. Filter orders where `category == "Electronics"` AND `status == "delivered"`.
2. Filter orders where `city == "Mumbai"` AND `quantity > 1`.
3. Filter orders where `unit_price > 5000` AND `status != "cancelled"`.

**Problem 18 — OR (|)**  
1. Filter orders where `status == "cancelled"` OR `is_returned == True`.
2. Filter orders from `"Chennai"` OR `"Hyderabad"`.
3. Filter orders where `category == "Furniture"` OR `unit_price > 50000`.

**Problem 19 — NOT (~)**  
1. Filter orders that are NOT in `"cancelled"` status.
2. Filter orders where `is_returned` is NOT True.

**Problem 20 — Combining AND + OR**  
1. Find `"delivered"` orders from the `"Electronics"` OR `"Furniture"` category.
2. Find orders from `"Delhi"` with `unit_price > 3000` AND status is NOT `"cancelled"`.

**Problem 21 — isin**  
1. Filter orders where city is one of: `Mumbai`, `Delhi`, `Bangalore`.
2. Filter orders where category is NOT in: `Grocery`, `Clothing`.

**Problem 22 — between**  
1. Filter orders where `unit_price` is between `2000` and `15000` (inclusive).
2. Filter orders where `quantity` is between `2` and `5`.

**Problem 23 — like**  
1. Find customers whose name starts with `"S"`.
2. Find products that contain `"one"`.
3. Find customers whose city ends with `"i"` (hint: `"%i"`).

**Problem 24 — isNull / isNotNull**  
Add a `discount` column:
- `NULL` for `Grocery` orders
- 5% of `unit_price` for all others

Then:
1. Filter rows where `discount` is NULL.
2. Filter rows where `discount` is NOT NULL and `discount > 2000`.

---

## Bonus — Chain it all together

Write a single chain that:
1. Reads the orders CSV
2. Adds `total_amount = quantity * unit_price`
3. Adds `order_tier` (High/Mid/Low based on total_amount)
4. Filters only `"delivered"` orders that are NOT returned
5. Selects `order_id`, `customer_name`, `city`, `product`, `total_amount`, `order_tier`
6. Orders by `total_amount` descending
7. Shows the result

How many rows does the final result have? Which order has the highest total amount?
