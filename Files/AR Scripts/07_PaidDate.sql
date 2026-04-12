UPDATE i
SET PaidDate =
    CASE
        -- Fully settled via payment and/or credit
        WHEN s.PaidLocal + s.CreditedLocal >= s.AmountLocal
            THEN 
                CASE 
                    WHEN s.LastPaymentDate IS NOT NULL 
                         AND s.LastCreditDate IS NOT NULL
                        THEN 
                            CASE 
                                WHEN s.LastPaymentDate > s.LastCreditDate 
                                    THEN s.LastPaymentDate
                                ELSE s.LastCreditDate
                            END
                    ELSE COALESCE(s.LastPaymentDate, s.LastCreditDate)
                END

        -- Written off
        WHEN s.WriteOffDate IS NOT NULL
            THEN s.WriteOffDate

        -- Otherwise still open
        ELSE NULL
    END
FROM Invoice i
JOIN
(
    SELECT
        i.InvoiceID
      , i.AmountLocal

      , SUM(ISNULL(pa.AppliedLocal,0)) AS PaidLocal
      , SUM(ISNULL(c.AmountLocal,0)) AS CreditedLocal

      , MAX(p.PaymentDate) AS LastPaymentDate
      , MAX(c.CreditDate) AS LastCreditDate
      , MAX(b.WriteOffDate) AS WriteOffDate

    FROM Invoice i

    LEFT JOIN PaymentAllocation pa 
        ON pa.InvoiceID = i.InvoiceID

    LEFT JOIN Payment p 
        ON p.PaymentID = pa.PaymentID

    LEFT JOIN CreditNote c 
        ON c.InvoiceID = i.InvoiceID

    LEFT JOIN BadDebt b 
        ON b.InvoiceID = i.InvoiceID

    GROUP BY
        i.InvoiceID
      , i.AmountLocal

) s
    ON s.InvoiceID = i.InvoiceID;