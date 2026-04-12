DROP TABLE IF EXISTS ARTransaction;

CREATE TABLE ARTransaction
(
    ARTransactionID INT IDENTITY(1,1)
  , InvoiceID INT
  , CustomerID INT
  , DocumentNo varchar(50)
  , PostedDate DATE
  , TransactionType VARCHAR(30)
  , PostedType VARCHAR(10)
  , CurrencyCode CHAR(3)

  , AmountLocal DECIMAL(18,2)      -- real transaction currency
  , FXRate      DECIMAL(18,6)      -- rate used to derive EUR
  , AmountEUR   DECIMAL(18,2)      -- stored reporting value
  , CONSTRAINT PK_ARTransaction PRIMARY KEY (ARTransactionID)
);



-- 1. Invoice
INSERT INTO ARTransaction
SELECT
    i.InvoiceID
  , i.CustomerID
  , i.InvoiceNo
  , i.InvoiceDate
  , 'INVOICE'
  , 'AR'
  , i.CurrencyCode
  , i.AmountLocal
  , i.FXRate
  , i.AmountLocal * i.FXRate
FROM Invoice i;

--2/ payments and Allocation
INSERT INTO ARTransaction
SELECT
    i.InvoiceID
  , i.CustomerID
  , p.PaymentNo
  , p.PaymentDate
  , 'PAYMENT'
  , 'AR'
  , p.CurrencyCode
  , -pa.AppliedLocal
  , p.FXRate
  , -pa.AppliedLocal * p.FXRate   -- 🔥 CRITICAL FIX (payment rate)
FROM PaymentAllocation pa
JOIN Payment p ON p.PaymentID = pa.PaymentID
JOIN Invoice i ON i.InvoiceID = pa.InvoiceID;

--Credit Notes 
INSERT INTO ARTransaction
SELECT
    c.InvoiceID
  , i.CustomerID
  , 'CR-' + convert (varchar, c.InvoiceID)
  , c.CreditDate
  , 'CREDIT_NOTE'
  , 'AR'
  , i.CurrencyCode
  , -c.AmountLocal
  , c.FXRate
  , -c.AmountLocal * c.FXRate
FROM CreditNote c
JOIN Invoice i ON i.InvoiceID = c.InvoiceID;

--Bad Debt

INSERT INTO ARTransaction
SELECT
    b.InvoiceID
  , i.CustomerID
  , 'JNBD-' + convert (varchar,b.InvoiceID)
  , b.WriteOffDate
  , 'BAD_DEBT'
  , 'AR'
  , i.CurrencyCode
  , -b.AmountLocal
  , b.FXRate
  , -b.AmountLocal * b.FXRate  
FROM BadDebt b
JOIN Invoice i ON i.InvoiceID = b.InvoiceID;


--FX 
INSERT INTO ARTransaction
SELECT
    r.InvoiceID
  , i.CustomerID
   , 'JNFXR1-' + convert (varchar,r.InvoiceID)
  , r.TransactionDate
  , 'FX_REVAL'
  , 'AR'
  , r.CurrencyCode
  , null
  , null
  , r.UnrealisedEUR
FROM FXRevaluation r
JOIN Invoice i ON i.InvoiceID = r.InvoiceID
WHERE r.TransactionType = 'REVAL';

INSERT INTO ARTransaction
SELECT
    r.InvoiceID
  , i.CustomerID
   , 'JNFXR2-' + convert (varchar,r.InvoiceID)
  , r.TransactionDate
  , 'FX_REVERSAL'
  , 'AR'
  , r.CurrencyCode
  , null
  , null
  , - r.UnrealisedEUR
FROM FXRevaluation r
JOIN Invoice i ON i.InvoiceID = r.InvoiceID
WHERE r.TransactionType = 'REVERSAL';


--Realised FX Gains 
INSERT INTO ARTransaction
SELECT
    i.InvoiceID
  , i.CustomerID
  , 'JNFX-' + convert (varchar,i.InvoiceID)
  , p.PaymentDate
  , 'FX_REALISED'
  , 'AR'
  , p.CurrencyCode
  , null
  , null                                         -- already EUR value
  , pa.AppliedLocal * (p.FXRate - i.FXRate)   -- FX difference
FROM PaymentAllocation pa
JOIN Payment p ON p.PaymentID = pa.PaymentID
JOIN Invoice i ON i.InvoiceID = pa.InvoiceID
WHERE ABS(p.FXRate - i.FXRate) > 0.000001;