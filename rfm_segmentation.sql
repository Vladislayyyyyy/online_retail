-- RFM анализ
WITH rfm_base AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS last_purchase_date,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        ROUND(SUM(Revenue), 2) AS monetary
    FROM sales_clean
    GROUP BY CustomerID
),
rfm_values AS (
    SELECT
        CustomerID,
        EXTRACT(DAY FROM ((SELECT MAX(InvoiceDate) FROM sales_clean) + INTERVAL '1 day' - last_purchase_date)) AS recency,
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    SELECT
        CustomerID,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency) AS r_score,
        NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_values
),
rfm_full AS (
    SELECT
        CustomerID,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 10 THEN 'VIP'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Loyal'
            WHEN (r_score + f_score + m_score) >= 5  THEN 'Potential'
            ELSE 'At Risk'
        END AS segment
    FROM rfm_scores
),
segment_stats AS (
    SELECT
        segment,
        COUNT(*) AS customer_count,
        ROUND(AVG(recency), 1) AS avg_recency,
        ROUND(AVG(frequency), 1) AS avg_frequency,
        ROUND(AVG(monetary), 2) AS avg_monetary,
        ROUND(SUM(monetary), 2) AS total_revenue
    FROM rfm_full
    GROUP BY segment
)
SELECT
    segment,
    customer_count,
    avg_recency,
    avg_frequency,
    avg_monetary,
    total_revenue,
    ROUND(100.0 * total_revenue / SUM(total_revenue) OVER (), 2) AS revenue_share
FROM segment_stats
ORDER BY total_revenue DESC;
