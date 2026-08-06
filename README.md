# GBE Sales & Customer Analytics Dashboard

Capstone project: end-to-end BI analytics for a fictitious global electronics
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
| Products | ProductKey | Primary key to identify products |
| Products | Product Name | Product name |
| Products | Brand | Product brand |
| Products | Color | Product color |
| Products | Unit Cost USD | Cost to produce the product in USD |
| Products | Unit Price USD | Product list price in USD |
| Products | Subcategory | Product subcategory name |
| Products | Category | Product category name |
| Stores | StoreKey | Primary key to identify stores (0 = Online) |
| Stores | Country | Store country |
| Stores | State | Store state |
| Stores | Square Meters | Store footprint in square meters |
| Stores | Open Date | Store open date |
| Exchange Rates | Date | Date |
| Exchange Rates | Currency | Currency code |
| Exchange Rates | Exchange | Exchange rate compared to USD |

---

## Executive Summary & Recommendation

| Strategic Theme | Business Issue | Recommendation |
|---|---|---|
| **Seasonality & Channel Mix** | Order volume, revenue and profit show a sharp, recurring dip every April and a spike every Nov–Dec across all 6 years — the pattern holds at the overall level and repeats within every category/subcategory, so it's a platform-wide demand cycle, not a category quirk. Online's revenue share has grown steadily from ~17% (2016) to ~28% (2021), and Online AOV now tracks almost identically with Offline AOV. | Build inventory and marketing calendars around the Nov–Dec peak and the April trough (targeted promotions to smooth the trough). Continue shifting investment toward Online — the AOV gap with Offline has closed, so channel economics no longer justify prioritizing Offline. |
| **Customer Retention & Segmentation** | RFM segmentation surfaces distinct, actionable groups (Champions, Loyal, At Risk, Cant Lose Them, About to Sleep, etc.) with very different value profiles. Quarterly cohort retention appears to "recover" strongly around 2018–2019 and collapse in 2020–2021 — but this pattern lines up almost exactly with the company's overall order-volume boom/bust cycle, meaning raw retention rate is confounded by platform-wide growth, not pure cohort loyalty. | Target win-back and loyalty offers specifically at *At Risk* / *Cant Lose Them* (high monetary value, declining recency) rather than broad campaigns. Before using cohort retention to judge a loyalty initiative, normalize it against total platform order volume for that period so growth-cycle effects aren't mistaken for improved retention. |
| **Product Portfolio Optimization** | The Computers category (led by Desktops) alone drives ~45% of company profit/revenue by 2021 — a concentration risk. The long tail ("Others") still accounts for ~50% of overall subcategory revenue but is fragmented across many small subcategories. Profit margin is stable (~58–62%) across most subcategories except Refrigerators, which dropped to ~52% in 2021. | Reduce dependency on Desktops by actively growing 2–3 secondary subcategories (e.g., Televisions, Projectors & Screens) that already show healthy margin and consistent YoY growth. Investigate the Refrigerators margin drop before it recurs. Use bundling/cross-sell (e.g., pairing high-AOV appliances with accessories) to lift AOV in the long tail. |
| **Delivery & Operational Excellence** | Average online delivery lead time improved substantially, from ~8 days (2016) to ~4 days (2020–2021), and has converged close to the overall benchmark line. A few countries and a mid-2018 period still spike above benchmark. | Formalize a ~4-day SLA target based on the current benchmark. Set up ongoing monitoring to flag any country/category that drifts above benchmark, and review the 2018 spike as a root-cause case study to prevent recurrence. |

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

## Repository Structure
