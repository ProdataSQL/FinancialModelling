CREATE TABLE [dbo].[Time] (

	[TimeID] int NOT NULL, 
	[TimeBKey] varchar(8) NOT NULL, 
	[HourNumber] int NOT NULL, 
	[MinuteNumber] int NOT NULL, 
	[SecondNumber] int NOT NULL, 
	[TimeInSecond] int NOT NULL, 
	[HourlyBucket] varchar(15) NOT NULL, 
	[DayTimeBucketGroupKey] int NOT NULL, 
	[DayTimeBucket] varchar(100) NOT NULL
);