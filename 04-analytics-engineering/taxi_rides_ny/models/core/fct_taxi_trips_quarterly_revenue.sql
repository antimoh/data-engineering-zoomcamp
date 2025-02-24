WITH quarterly_revenue AS (
    SELECT
        DATE_TRUNC(pickup_datetime, QUARTER) AS quarter,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(QUARTER FROM pickup_datetime) AS quarter_number,
        service_type,
        SUM(total_amount) AS total_revenue
    FROM {{ ref('fact_trips') }}
    GROUP BY 1, 2, 3, 4
),

quarterly_revenue_with_yoy AS (
    SELECT
        quarter,
        year,
        quarter_number,
        service_type,
        total_revenue,
        LAG(total_revenue) OVER (PARTITION BY service_type, quarter_number ORDER BY year) AS previous_year_revenue,
        CASE
            WHEN LAG(total_revenue) OVER (PARTITION BY service_type, quarter_number ORDER BY year) = 0 THEN NULL
            ELSE (total_revenue - LAG(total_revenue) OVER (PARTITION BY service_type, quarter_number ORDER BY year)) / LAG(total_revenue) OVER (PARTITION BY service_type, quarter_number ORDER BY year) * 100
        END AS yoy_growth
    FROM quarterly_revenue
)

SELECT
    quarter,
    year,
    quarter_number,
    service_type,
    total_revenue,
    previous_year_revenue,
    yoy_growth
FROM quarterly_revenue_with_yoy
ORDER BY service_type, quarter, year