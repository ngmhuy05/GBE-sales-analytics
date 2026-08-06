# GBE Sales & Customer Analytics Dashboard

End-to-end BI analytics for a fictitious global electronics
retailer (GBE) — from SQL Server data modeling to an interactive Power BI
dashboard, covering sales performance, customer segmentation, and delivery
operations.

---

## Business Context

**Global Electronics Retailer (GBE)** is a fictitious global electronics
retailer. The dataset covers transactions, products, customers, stores, and
currency exchange rates across 6 countries (US, UK, Germany, France, Italy,
Netherlands, Australia, Canada) plus an Online channel, spanning 2016–2021.

### Goal of Project
- Analyze GBE's sales performance across seasonality, product portfolio,
  channel, and geography to identify key growth drivers and business
  opportunities.
- Segment the customer base and evaluate retention behavior to support more
  targeted engagement strategies.
- Evaluate online delivery performance to identify operational bottlenecks
  and benchmark lead time by location/category.
- Translate all of the above into actionable, profit-oriented
  recommendations.

### Big Question
GBE wants to sustain revenue and profit growth while improving customer
retention and delivery experience. **Which product/location/channel
segments are actually driving profit, which customer segments are at risk
of churning, and where is delivery underperforming — and what should GBE
do about each?**

### Metrics

| Topic | Main Metrics | Key Drivers |
|---|---|---|
| 1 — Sales Performance, Seasonal Trend & Channel | Revenue, Profit, Order Volume | Category / Subcategory / Brand mix, Location, Sales Channel (Online vs. Offline) |
| 2 — Customer Analysis & Segmentation | RFM Score, Retention Rate, Customer Count | Recency, Frequency, Monetary value, Cohort behavior |
| 3 — Online Delivery & Operation Optimization | Avg. Delivery Time (days) | Order-to-delivery lead time by Country / Category, vs. platform benchmark |

---

## Dataset Overview
**Dataset link:** Documentation Folder → Case study collection

Sales data for a fictitious global electronics retailer, including tables
containing information about transactions, products, customers, stores and
currency exchange rates. This case study aims to provide a comprehensive
understanding of the business performance of a global electronics retailer,
identify key drivers, and offer actionable recommendations for profit
optimization and customer engagement.

**Sales**

| Table | Field | Description |
|---|---|---|
| Sales | Order Number | Unique ID for each order |
| Sales | Line Item | Identifies individual products purchased as part of an order |
| Sales | Order Date | Date the order was placed |
| Sales | Delivery Date | Date the order was delivered |
| Sales | CustomerKey | Unique key identifying which customer placed the order |
| Sales | StoreKey | Unique key identifying which store processed the order |
| Sales | ProductKey | Unique key identifying which product was purchased |
| Sales | Quantity | Number of items purchased |
| Sales | Currency Code | Currency used to process the order |

**Customers**

| Table | Field | Description |
|---|---|---|
| Customers | CustomerKey | Primary key to identify customers |
| Customers | Gender | Customer gender |
| Customers | Name | Customer full name |
| Customers | City | Customer city |
| Customers | State Code | Customer state (abbreviated) |
| Customers | State | Customer state (full) |
| Customers | Zip Code | Customer zip code |
| Customers | Country | Customer country |
| Customers | Continent | Customer continent |
| Customers | Birthday | Customer date of birth |

**Products**

| Table | Field | Description |
|---|---|---|
| Products | ProductKey | Primary key to identify products |
| Products | Product Name | Product name |
| Products | Brand | Product brand |
| Products | Color | Product color |
| Products | Unit Cost USD | Cost to produce the product in USD |
| Products | Unit Price USD | Product list price in USD |
| Products | Subcategory | Product subcategory name |
| Products | Category | Product category name |

**Stores**

| Table | Field | Description |
|---|---|---|
| Stores | StoreKey | Primary key to identify stores (0 = Online) |
| Stores | Country | Store country |
| Stores | State | Store state |
| Stores | Square Meters | Store footprint in square meters |
| Stores | Open Date | Store open date |

**Exchange Rates**

| Table | Field | Description |
|---|---|---|
| Exchange Rates | Date | Date |
| Exchange Rates | Currency | Currency code |
| Exchange Rates | Exchange | Exchange rate compared to USD |

---

## Executive Summary & Recommendation

| Strategic Theme | Result / Business Issue | Recommendation |
|---|---|---|
| **Seasonality & Channel Mix** | Sales drop every April and spike every Nov–Dec, every year, across all categories. Online revenue share grew from ~17% to ~28% (2016–2021), and Online AOV is now almost equal to Offline AOV. | Plan inventory and promotions around this yearly cycle — push offers in April to fill the gap, prepare stock for Nov–Dec. Keep investing in Online; it's no longer the smaller, lower-value channel it used to be. |
| **Customer Retention** | RFM segmentation clearly separates customers by value (Champions, At Risk, Cant Lose Them, etc). Cohort retention looks like it "improves" in 2018–2019 and "drops" in 2020–2021 — but this just mirrors the company's overall sales boom and bust in those years, not real changes in loyalty. | Focus win-back offers on *At Risk* and *Cant Lose Them* customers — they still have high spend but haven't purchased recently. Don't read the retention trend at face value; adjust for overall business growth first. |
| **Product Portfolio** | Computers (mainly Desktops) alone drives ~45% of total profit — high concentration risk in one category. Refrigerators' profit margin dropped from ~60% to ~52% in 2021. | Grow 2–3 secondary categories (e.g. Televisions, Projectors & Screens) to reduce reliance on Desktops. Investigate why Refrigerators' margin dropped before it happens again. |
| **Delivery Performance** | Average delivery time improved from ~8 days (2016) to ~4 days (2020–2021), now close to benchmark. A few countries and a spike around 2018 still exceed it. | Set a ~4-day delivery SLA as the standard. Track delivery time by country/category monthly to catch and fix outliers early. |

---

## Tech Stack

- **SQL Server** — star-schema data modeling (fact + dimension views), RFM
  scoring, quarterly cohort retention analysis
- **Power BI** — data model (relationships, DAX measures), 4-page interactive
  dashboard with cross-filtering, drill-down, and conditional formatting

## Data Model

Star schema built via SQL views:

| View | Type | Description |
|---|---|---|
| `vw_Fact_Sales` | Fact | Transaction-level sales data (revenue, cost, profit, channel, delivery time) |
| `vw_Dim_Date` | Dimension | Calendar table |
| `vw_Dim_Products` | Dimension | Product catalog |
| `vw_Dim_Stores` | Dimension | Store locations |
| `vw_Dim_Customers` | Dimension | Customer demographics |
| `vw_Customer_RFM` | Analysis | RFM scores & segments per customer |
| `vw_Cohort_Retention` | Analysis | Quarterly cohort retention rates |

## Dashboard Pages (Detailed Analysis)

1. **Overview** — KPI summary, revenue trend, category/channel/country breakdown
2. **Sales** — Seasonal trend, YoY growth drivers, channel comparison
3. **Customer** — RFM segmentation, demographics, cohort retention heatmap
4. **Delivery** — Delivery lead time trend, benchmark comparison by country/category
