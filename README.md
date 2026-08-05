# GBE Sales & Customer Analytics Dashboard

Capstone project: end-to-end BI analytics for a fictitious global electronics
retailer (GBE) — from SQL Server data modeling to an interactive Power BI
dashboard, covering sales performance, customer segmentation, and delivery
operations.

## Business Questions

**Topic 1 — Sales Performance, Seasonal Trend & Channel Analysis**
- Seasonal trends in order volume / revenue / profit, overall vs. by category/location
- Key drivers of revenue/order volume/profit growth (product, category, brand, location)
- Online vs. In-Store channel performance

**Topic 2 — Customer Analysis & Segmentation**
- Customer segmentation based on demographics, spending & purchase behavior (RFM)
- Cohort retention analysis
- Recommendations for tailored customer strategies

**Topic 3 — Online Delivery & Operation Optimization**
- Average delivery lead time and trend over time
- Delivery performance benchmarking by location/product
- Recommendations to optimize delivery experience

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

```
├── sql/
│   └── GBE_PowerBI_Views.sql      # All SQL Server views (data model + analysis)
├── screenshots/                    # Dashboard page screenshots
└── README.md
```

## Dashboard Pages

1. **Overview** — KPI summary, revenue trend, category/channel/country breakdown
2. **Sales** — Seasonal trend, YoY growth drivers, channel comparison
3. **Customer** — RFM segmentation, demographics, cohort retention heatmap
4. **Delivery** — Delivery lead time trend, benchmark comparison by country/category

