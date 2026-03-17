INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120131,3,1,1,43,-9150113,'20120131 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120229,3,1,1,43,-9580598,'20120229 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120331,3,1,1,43,-8560068,'20120331 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120430,3,1,1,43,-8800352,'20120430 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120531,3,1,1,43,-7771024,'20120531 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20120630,3,1,1,43,-6910367,'20120630 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20110731,3,1,1,43,-4428989,'20110731 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20110831,3,1,1,43,-9748669,'20110831 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20110930,3,1,1,43,-4466185,'20110930 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20111031,3,1,1,43,-5566584,'20111031 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20111130,3,1,1,43,-4399617,'20111130 ')
INSERT INTO FactFinance (DateKey, OrganizationKey, DepartmentGroupKey, ScenarioKey, AccountKey, Amount, Date) VALUES (20111231,3,1,1,43,-10387811,'20111231 ')


select MAX(financeKey) from FactFinance 

--(No column name)
--40407

--40419


delete  From FactFinance where FinanceKey > 40191



