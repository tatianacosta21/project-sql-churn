# 🧠 Project Mind Map - Customer Segmentation & Churn Detection

A one-page overview of how everything in this project connects, from the environment it runs in down to the SQL concepts each stage teaches.

## Mermaid Flowchart

```mermaid
flowchart TD
    classDef env fill:#e0f2fe,stroke:#0284c7,color:#0c4a6e,font-weight:bold
    classDef db fill:#fef3c7,stroke:#d97706,color:#78350f,font-weight:bold
    classDef pipeline fill:#dcfce7,stroke:#16a34a,color:#14532d,font-weight:bold
    classDef docs fill:#f3e8ff,stroke:#9333ea,color:#581c87,font-weight:bold

    A["🐳 Docker + PostgreSQL"]:::env --> B["🛠️ DBeaver"]:::env
    B --> C["📐 Stage 1<br/>Schema"]:::db
    C --> D["🌱 Stage 2<br/>Seed Data"]:::db
    D --> E["🔍 Stage 3<br/>Exploration"]:::pipeline
    E --> F["📊 Stage 4<br/>RFM"]:::pipeline
    F --> G["🏷️ Stage 5<br/>Segmentation"]:::pipeline
    G --> H["⏳ Stage 6<br/>Churn Detection"]:::pipeline
    H --> I["🧩 Stage 7<br/>Final View"]:::pipeline
    I --> J["📄 README +<br/>EXERCISES"]:::docs
    I --> K["🐙 GitHub Repo"]:::docs
```

##  Mermaid Mindmap

```mermaid
mindmap
  root((SQL Project<br/>Customer Segmentation<br/>and Churn Detection))
    Environment
      Docker container pg-churn
      DBeaver SQL client
      Git and GitHub
    Database
      customers table
      orders table
      Constraints PK FK CHECK
    Seed Data
      Active customers
      At risk customers
      Lost customers
      New customers
    Analysis Pipeline
      Stage 3 Exploration
      Stage 4 RFM metrics
      Stage 5 NTILE segmentation
      Stage 6 LAG churn detection
      Stage 7 Final VIEW
    SQL Concepts
      CTEs
      Window functions
      Aggregate functions
      CASE logic
      Views
    Documentation
      README file
      Exercises worksheet
      This diagram file
```

## Text version (ASCII tree)

```
Customer Segmentation & Churn Detection (SQL Project)
│
├── 🐳 Environment
│   ├── Docker (PostgreSQL container: pg-churn)
│   ├── DBeaver (SQL client)
│   └── Git + GitHub (private repo, English commits)
│
├── 🗄️ Database (customers / orders)
│   ├── Stage 1 - Schema
│   │   ├── customers (id, name, email, signup_date)
│   │   └── orders (id, customer_id → FK, order_date, amount CHECK > 0)
│   │
│   └── Stage 2 - Seed Data
│       ├── generate_series + CROSS JOIN (no manual INSERTs)
│       └── 4 behavioural groups
│           ├── Active (ids 1-5) → frequent, recent orders
│           ├── At risk (ids 6-10) → used to order, went quiet ~70 days
│           ├── Lost (ids 11-15) → silent for 180+ days
│           └── New (ids 16-20) → recent signup, few orders
│
├── 🔍 Analysis Pipeline
│   ├── Stage 3 - Exploration
│   │   ├── Total volume & revenue
│   │   ├── Revenue per customer (LEFT JOIN)
│   │   └── Days since last order
│   │
│   ├── Stage 4 - RFM
│   │   ├── Recency → CURRENT_DATE - MAX(order_date)
│   │   ├── Frequency → COUNT(orders)
│   │   └── Monetary → SUM(amount)
│   │
│   ├── Stage 5 - Segmentation
│   │   ├── NTILE(5) scores each of R, F, M (1 = worst, 5 = best)
│   │   └── CASE combines scores → Champion / Loyal / At risk / Lost / New
│   │
│   ├── Stage 6 - Churn Detection
│   │   ├── LAG + PARTITION BY → each customer's average order cycle
│   │   └── overdue_ratio → Active / At risk / Likely churned
│   │
│   └── Stage 7 - Final View
│       └── vw_customer_rfm_churn (CREATE OR REPLACE VIEW)
│           combines Stages 4-6 into one queryable object
│
├── 🧩 SQL Concepts Practiced
│   ├── Constraints → PRIMARY KEY, FOREIGN KEY, CHECK, NOT NULL
│   ├── CTEs → WITH ... AS (...)
│   ├── Window functions → NTILE, LAG
│   ├── Aggregate functions → COUNT, SUM, AVG, MIN, MAX
│   ├── Business logic → CASE WHEN ... THEN ... ELSE ... END
│   └── Reusability → VIEW
│
└── 📄 Documentation
    ├── README.md → overview, setup, SQL glossary, skills demonstrated
    ├── EXERCISES.md → guided worksheet, one challenge + solution per stage
    ├── MINDMAP.md → this file
    └── 01-07 *.sql → one fully-commented script per stage
```

**How to read it:** each stage builds directly on the one before it - Stage 5 reuses the RFM numbers from Stage 4, Stage 7 reuses the logic from Stages 4, 5 *and* 6. Nothing is duplicated by accident; every later CTE exists because an earlier stage already proved the underlying query works.