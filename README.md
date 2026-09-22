# E-Commerce Sales & Customer Analytics

An end-to-end data analytics project simulating a real-world e-commerce business, built entirely with **MySQL** and **Power BI**. The project covers the full analytics lifecycle: database design, synthetic data generation, data profiling, data cleaning, SQL-based business analysis, and interactive dashboard reporting.

## 🛠 Tools Used
- MySQL Workbench — database design, data generation, cleaning, analysis
- Power BI Desktop — data modeling, DAX, dashboard reporting

## 📁 Project Structure
SQL/ → All SQL scripts (setup, data generation, profiling, cleaning, analytics)
PowerBI/ → Power BI dashboard file (.pbix)
Data/ → Exported CSVs of the cleaned dataset
Documentation/ → Dashboard screenshots

## 🗂 Database Design
5 relational tables — `customers`, `products`, `orders`, `order_items`, `payments` — with defined primary and foreign keys, following a normalized relational structure.

## 🧪 Data Generation & Quality
Over 1,300 realistic records were generated programmatically using SQL stored procedures (no manual data entry). Raw data was intentionally seeded with real-world data-quality issues — NULL values, duplicate records, inconsistent text casing, invalid dates, and unusual prices/quantities — to simulate a real business dataset.

These issues were:
- **Audited** using a dedicated profiling script (`04_data_profiling.sql`)
- **Resolved** using a cleaning script (`05_data_cleaning.sql`) that builds a separate `clean_` table layer

Raw tables were never modified — the original messy data remains fully intact and auditable.

## 📊 SQL Analysis
21+ analytical SQL queries covering revenue, profit, customer segmentation, top products/customers, month-over-month growth, payment analysis, and more (`06_analytics.sql`).

## 📈 Power BI Dashboard
A 4-page interactive dashboard built on a star-schema data model:

1. **Executive Overview** — KPIs, monthly revenue trend, revenue by category/city
2. **Sales Analysis** — Sales trends, category/product performance, order status, payment methods, state-wise revenue
3. **Customer Analysis** — Customer segmentation, new vs repeat customers, top customers, average ratings
4. **Product & Profit Analysis** — Top/bottom products, category profitability, profit margins, quantity sold

## 🧮 Key Skills Demonstrated
- Relational schema design with primary/foreign keys
- Automated synthetic data generation using stored procedures and loops
- Data profiling and quality auditing
- Data cleaning: deduplication, NULL handling, text standardization
- SQL window functions (`LAG`, `OVER`) for month-over-month growth analysis
- Power BI data modeling (fact/dimension tables, relationships, cardinality)
- DAX measures: `CALCULATE`, `FILTER`, `DIVIDE`, `DATEADD`, `ALLEXCEPT`, `SWITCH`
- Dashboard design across multiple report pages with slicers and formatted visuals

## 📷 Dashboard Screenshots

### Executive Overview
<img width="1145" height="702" alt="01_executive_overview png" src="https://github.com/user-attachments/assets/e10f1119-c429-488f-8d1f-c91ca58eff38" />
### Sales Analysis
<img width="1156" height="697" alt="02_sales_analysis png" src="https://github.com/user-attachments/assets/e1339df0-5ae5-41e8-ba3d-cfaddab3fda9" />
### Customer Analysis
<img width="1158" height="713" alt="03_customer_analysis png" src="https://github.com/user-attachments/assets/6d320bd0-fec3-4346-92be-c41c784a77b7" />
### Product & Profit Analysis
<img width="1157" height="722" alt="04_product_profit_analysis png" src="https://github.com/user-attachments/assets/3ee7eb08-089c-4ea6-955d-692dc231088e" />
## 🚀 How to Reproduce This Project
1. Run SQL scripts `01` through `06` in order inside MySQL Workbench
2. Connect Power BI Desktop to the `ecommerce_analytics` MySQL database
3. Import the 5 `clean_` tables and open `PowerBI/Ecommerce_Sales_Analytics.pbix`
