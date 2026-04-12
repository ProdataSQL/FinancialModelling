DROP TABLE IF EXISTS Invoice;

CREATE TABLE Invoice
(
    InvoiceID INT IDENTITY(1,1)
  , CustomerID INT
  , InvoiceDate DATE
  , DueDate DATE
  , PaidDate DATE
  , CurrencyCode CHAR(3)
  , AmountLocal DECIMAL(18,2)
  , FXRate DECIMAL(18,6)
);

INSERT INTO Invoice
(
    CustomerID
  , InvoiceDate
  , DueDate
  , CurrencyCode
  , AmountLocal
  , FXRate
)
SELECT
    c.CustomerID

  , inv.InvoiceDate

  , DATEADD(
        DAY,
        30 + (ABS(CHECKSUM(NEWID())) % 60),   -- 30–90 day terms
        inv.InvoiceDate
    )

  , c.CurrencyCode

  , CAST(
        100 + (ABS(CHECKSUM(NEWID())) % 9000)
    AS DECIMAL(18,2))

  , CASE c.CurrencyCode
        WHEN 'EUR' THEN 1
        WHEN 'USD' THEN 0.88 + (ABS(CHECKSUM(NEWID())) % 10) / 100.0
        WHEN 'GBP' THEN 1.15 + (ABS(CHECKSUM(NEWID())) % 10) / 100.0
        WHEN 'JPY' THEN 0.006 + (ABS(CHECKSUM(NEWID())) % 5) / 1000.0
        WHEN 'CAD' THEN 0.70 + (ABS(CHECKSUM(NEWID())) % 10) / 100.0
    END

FROM Customer c

CROSS APPLY
(
    SELECT DATEADD(
        DAY,
        - (ABS(CHECKSUM(NEWID())) % 365),   -- last 12 months
        CAST(GETDATE() AS DATE)
    ) AS InvoiceDate
) inv

CROSS JOIN GENERATE_SERIES(1, 150);   -- 150 invoices per customer


