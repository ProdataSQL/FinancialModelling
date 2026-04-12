DROP TABLE IF EXISTS Payment;

CREATE TABLE Payment
(
    PaymentID INT IDENTITY(1,1)
  , PaymentNo VARCHAR(30)
  , PaymentDate DATE
  , CurrencyCode CHAR(3)
  , AmountLocal DECIMAL(18,2)
  , FXRate DECIMAL(18,6)
  , AmountEUR AS (AmountLocal * FXRate)
);

DROP TABLE IF EXISTS PaymentAllocation;
CREATE TABLE PaymentAllocation
(
    PaymentID INT
  , InvoiceID INT
  , AppliedLocal DECIMAL(18,2)
  , AppliedEUR_InvoiceRate DECIMAL(18,2)
  , AppliedEUR_PaymentRate DECIMAL(18,2)
  , FXGainLoss AS (AppliedEUR_PaymentRate - AppliedEUR_InvoiceRate)
);


TRUNCATE TABLE PaymentAllocation;
TRUNCATE TABLE Payment;

IF OBJECT_ID('tempdb..#PaymentStage') IS NOT NULL
	DROP TABLE #PaymentStage;

IF OBJECT_ID('tempdb..#PaymentMap') IS NOT NULL
	DROP TABLE #PaymentMap;

CREATE TABLE #PaymentStage
(
	InvoiceID INT NOT NULL
  , PaymentDate DATE NOT NULL
  , CurrencyCode CHAR(3) NOT NULL
  , AmountLocal DECIMAL(18,2) NOT NULL
  , FXRate DECIMAL(18,6) NOT NULL
);

CREATE TABLE #PaymentMap
(
	PaymentID INT NOT NULL
  , InvoiceID INT NOT NULL
);

WITH PaymentBase AS
(
	SELECT
		i.InvoiceID
	  , i.DueDate
	  , i.CurrencyCode
	  , i.AmountLocal
	  , i.FXRate
	  , r.Rnd
	  , CASE
			WHEN r.Rnd < 65 THEN 'FULL'
			WHEN r.Rnd < 90 THEN 'PARTIAL'
			ELSE 'NONE'
		END AS PayType
	  , CAST((ABS(CHECKSUM(NEWID())) % 50) / 100.0 AS DECIMAL(18,4)) AS PartialPct
	  , 5 + ABS(CHECKSUM(NEWID())) % 90 AS DelayDays
	  , CAST((ABS(CHECKSUM(NEWID())) % 10) / 100.0 AS DECIMAL(18,4)) AS FXVar
	FROM Invoice i
	CROSS APPLY
	(
		SELECT ABS(CHECKSUM(NEWID())) % 100 AS Rnd
	) r
)
INSERT INTO #PaymentStage
(
	InvoiceID
  , PaymentDate
  , CurrencyCode
  , AmountLocal
  , FXRate
)
SELECT
	pb.InvoiceID
  , DATEADD(DAY, pb.DelayDays, pb.DueDate)
  , pb.CurrencyCode
  , CASE
		WHEN pb.PayType = 'FULL' THEN pb.AmountLocal
		WHEN pb.PayType = 'PARTIAL' THEN CAST(pb.AmountLocal * (0.30 + pb.PartialPct) AS DECIMAL(18,2))
	END
  , CASE pb.CurrencyCode
		WHEN 'EUR' THEN CAST(1.000000 AS DECIMAL(18,6))
		WHEN 'USD' THEN CAST(0.88 + pb.FXVar AS DECIMAL(18,6))
		WHEN 'GBP' THEN CAST(1.15 + pb.FXVar AS DECIMAL(18,6))
		WHEN 'JPY' THEN CAST(0.006 + (pb.FXVar / 10.0) AS DECIMAL(18,6))
		WHEN 'CAD' THEN CAST(0.70 + pb.FXVar AS DECIMAL(18,6))
		ELSE CAST(pb.FXRate AS DECIMAL(18,6))
	END
FROM PaymentBase pb
WHERE pb.PayType <> 'NONE';

MERGE Payment AS tgt
USING
(
	SELECT
		ps.InvoiceID
	  , ps.PaymentDate
	  , ps.CurrencyCode
	  , ps.AmountLocal
	  , ps.FXRate
	FROM #PaymentStage ps
) AS src
ON 1 = 0
WHEN NOT MATCHED THEN
	INSERT
	(
		PaymentDate
	  , CurrencyCode
	  , AmountLocal
	  , FXRate
	)
	VALUES
	(
		src.PaymentDate
	  , src.CurrencyCode
	  , src.AmountLocal
	  , src.FXRate
	)
OUTPUT
	inserted.PaymentID
  , src.InvoiceID
INTO #PaymentMap
(
	PaymentID
  , InvoiceID
);

INSERT INTO PaymentAllocation
(
	PaymentID
  , InvoiceID
  , AppliedLocal
  , AppliedEUR_InvoiceRate
  , AppliedEUR_PaymentRate
)
SELECT
	pm.PaymentID
  , pm.InvoiceID
  , CASE
		WHEN p.AmountLocal >= i.AmountLocal THEN i.AmountLocal
		ELSE p.AmountLocal
	END
  , CASE
		WHEN p.AmountLocal >= i.AmountLocal THEN CAST(i.AmountLocal * i.FXRate AS DECIMAL(18,2))
		ELSE CAST(p.AmountLocal * i.FXRate AS DECIMAL(18,2))
	END
  , CASE
		WHEN p.AmountLocal >= i.AmountLocal THEN CAST(i.AmountLocal * p.FXRate AS DECIMAL(18,2))
		ELSE CAST(p.AmountLocal * p.FXRate AS DECIMAL(18,2))
	END
FROM #PaymentMap pm
JOIN Payment p
	ON p.PaymentID = pm.PaymentID
JOIN Invoice i
	ON i.InvoiceID = pm.InvoiceID;

SELECT
	COUNT(*) AS TotalInvoices
  , SUM(CASE WHEN OpenAmt = 0 THEN 1 ELSE 0 END) AS FullyPaid
  , SUM(CASE WHEN OpenAmt > 0 AND OpenAmt < Amount THEN 1 ELSE 0 END) AS Partial
  , SUM(CASE WHEN OpenAmt = Amount THEN 1 ELSE 0 END) AS Unpaid
FROM
(
	SELECT
		i.InvoiceID
	  , i.AmountLocal AS Amount
	  , CAST(i.AmountLocal - ISNULL(SUM(pa.AppliedLocal), 0) AS DECIMAL(18,2)) AS OpenAmt
	FROM Invoice i
	LEFT JOIN PaymentAllocation pa
		ON pa.InvoiceID = i.InvoiceID
	GROUP BY
		i.InvoiceID
	  , i.AmountLocal
) x;

