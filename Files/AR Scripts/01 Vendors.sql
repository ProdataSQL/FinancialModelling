
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer
(
    CustomerID INT IDENTITY(1,1)
  , CUstomerName VARCHAR(100)
  , Country VARCHAR(50)
  , CurrencyCode CHAR(3)
);

INSERT INTO Customer
(
    CUstomerName
  , Country
  , CurrencyCode
)
VALUES
('SqlBits Ltd',        'UK',      'GBP'),
('Contoso Retail Group',       'USA',     'USD'),
('Fabrikam Manufacturing',     'Germany', 'EUR'),
('Northwind Traders',          'France',  'EUR'),
('Tailspin Toys',              'USA',     'USD'),
('Wingtip Logistics',          'Ireland', 'EUR'),
('ACME Corporation',           'USA',     'USD'),
('Globex Corporation',         'Canada',  'CAD'),
('Initech Solutions',          'UK',      'GBP'),
('Umbrella Corporation',       'Japan',   'JPY');

GO
DROP TABLE IF EXISTS CustomerProfile;
CREATE TABLE CustomerProfile
(
    CustomerID INT
  , AvgDaysToPay INT
  , StdDevDays INT
  , PartialRate DECIMAL(5,4)
  , NonPayRate DECIMAL(5,4)
);

INSERT INTO CustomerProfile
(
    CustomerID
  , AvgDaysToPay
  , StdDevDays
  , PartialRate
  , NonPayRate
)
VALUES
(1, 20, 8,  0.00, 0.01), -- excellent
(2, 25, 10, 0.00, 0.01),
(3, 35, 15, 0.02, 0.02), -- normal
(4, 38, 18, 0.02, 0.03),
(5, 40, 18, 0.02, 0.03),
(6, 50, 22, 0.05, 0.05), -- slow
(7, 60, 25, 0.05, 0.06),
(8, 80, 30, 0.08, 0.10), -- risky
(9, 90, 35, 0.09, 0.12),
(10,45, 20, 0.10, 0.04);

GO
DROP TABLE IF EXISTS FXRate;
CREATE TABLE FXRate
(
    RateDate DATE
  , CurrencyCode CHAR(3)
  , EURRate DECIMAL(18,6)
);

WITH D AS (
    SELECT TOP 500 DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), GETDATE()) d
    FROM sys.objects
)
INSERT INTO FXRate
SELECT
    d
  , v.CurrencyCode
  , CASE v.CurrencyCode
        WHEN 'EUR' THEN 1
        WHEN 'USD' THEN 0.90 + (RAND(CHECKSUM(NEWID())) * 0.05)
        WHEN 'GBP' THEN 1.15 + (RAND(CHECKSUM(NEWID())) * 0.05)
        WHEN 'JPY' THEN 0.006 + (RAND(CHECKSUM(NEWID())) * 0.001)
        WHEN 'CAD' THEN 0.70 + (RAND(CHECKSUM(NEWID())) * 0.05)
    END
FROM D
CROSS JOIN (SELECT DISTINCT CurrencyCode FROM Customer) v;

GO

