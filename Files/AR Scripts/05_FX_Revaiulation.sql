/* =========================
   DROP + CREATE TABLE
   ========================= */

DROP TABLE IF EXISTS FXRevaluation;

CREATE TABLE FXRevaluation
(
    EntryID INT IDENTITY(1,1)
  , InvoiceID INT
  , TransactionDate DATE
  , TransactionType VARCHAR(20)   -- REVAL / REVERSAL
  , CurrencyCode CHAR(3)
  , OpenLocal DECIMAL(18,2)
  , FXRate_Invoice DECIMAL(18,6)
  , FXRate_Current DECIMAL(18,6)
  , UnrealisedEUR DECIMAL(18,2)
);


/* =========================
   INSERT REVALUATION (MONTH-END)
   ========================= */

;WITH MonthEnd AS
(
    SELECT DISTINCT EOMONTH(InvoiceDate) AS RevalDate
    FROM Invoice
)
, Paid AS
(
    SELECT
        pa.InvoiceID
      , p.PaymentDate
      , SUM(pa.AppliedLocal) AS PaidLocal
    FROM PaymentAllocation pa
    JOIN Payment p
        ON p.PaymentID = pa.PaymentID
    GROUP BY
        pa.InvoiceID
      , p.PaymentDate
)
, OpenBal AS
(
    SELECT
        i.InvoiceID
      , i.CurrencyCode
      , i.FXRate AS FXRate_Invoice
      , m.RevalDate
      , i.AmountLocal
        - ISNULL(SUM(CASE 
            WHEN p.PaymentDate <= m.RevalDate THEN p.PaidLocal 
            ELSE 0 END), 0) AS OpenLocal
    FROM Invoice i
    CROSS JOIN MonthEnd m
    LEFT JOIN Paid p
        ON i.InvoiceID = p.InvoiceID
    WHERE i.InvoiceDate <= m.RevalDate
    GROUP BY
        i.InvoiceID
      , i.CurrencyCode
      , i.FXRate
      , i.AmountLocal
      , m.RevalDate
)

INSERT INTO FXRevaluation
(
    InvoiceID
  , TransactionDate
  , TransactionType
  , CurrencyCode
  , OpenLocal
  , FXRate_Invoice
  , FXRate_Current
  , UnrealisedEUR
)
SELECT
    o.InvoiceID
  , o.RevalDate
  , 'REVAL'
  , o.CurrencyCode
  , o.OpenLocal
  , o.FXRate_Invoice
  , fx.EURRate
  , (o.OpenLocal * fx.EURRate)
    - (o.OpenLocal * o.FXRate_Invoice)
FROM OpenBal o
JOIN FXRate fx
    ON fx.RateDate = o.RevalDate
   AND fx.CurrencyCode = o.CurrencyCode
WHERE o.OpenLocal > 0;



/* =========================
   INSERT REVERSAL (NEXT DAY)
   ========================= */

INSERT INTO FXRevaluation
(
    InvoiceID
  , TransactionDate
  , TransactionType
  , CurrencyCode
  , OpenLocal
  , FXRate_Invoice
  , FXRate_Current
  , UnrealisedEUR
)
SELECT
    InvoiceID
  , DATEADD(DAY, 1, TransactionDate)
  , 'REVERSAL'
  , CurrencyCode
  , OpenLocal
  , FXRate_Invoice
  , FXRate_Current
  , -UnrealisedEUR
FROM FXRevaluation
WHERE TransactionType = 'REVAL';


