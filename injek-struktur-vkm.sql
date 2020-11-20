USE Autoparts
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE M01
ADD PushSuccess bit,
PushDateTime datetime

GO


CREATE TABLE [dbo].[M01_hosting_log](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[M0101] [nvarchar](50) NOT NULL,
	[TriggerDateTime] [datetime] NOT NULL,
	[FlagHosting] [nvarchar](1) NOT NULL,
	[Delay] [int] NULL,
 CONSTRAINT [PK_M01_hosting_log] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO



CREATE TRIGGER [dbo].[HostingSync_M01] 
   ON  [dbo].[M01]
   AFTER INSERT,DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @iRef nvarchar(50)
	DECLARE @dRef nvarchar(50)

	SET @iRef = (SELECT M0101 FROM inserted i)
	SET @dRef = (SELECT M0101 FROM deleted d)

	DECLARE @iPushSuccess bit = 1 
	DECLARE @dPushSuccess bit = 1

	SET @iPushSuccess = (SELECT PushSuccess FROM inserted i)
	SET @dPushSuccess = (SELECT PushSuccess FROM deleted d)


		IF @iRef IS NOT NULL
			BEGIN

				DECLARE @iRec int = 0

					SET @iRec = (SELECT TOP 1 id FROM [M01_hosting_log] WHERE M0101 = @iRef AND FlagHosting = 'D' AND PushSuccess is NULL AND datediff(ms,TriggerDateTime,GETDATE()) < 10 ORDER BY id DESC)

					IF @iRec > 0
						UPDATE [M01_hosting_log] SET Delay = datediff(ms,TriggerDateTime,GETDATE()), FlagHosting = 'U' WHERE id = @iRec
					ELSE
						INSERT [dbo].[M01_hosting_log] (M0101, TriggerDateTime, FlagHosting) SELECT @iRef, GETDATE(), 'I'

					UPDATE M01 SET PushSuccess = 0 WHERE M0101 = @iRef
			END

		IF @dRef IS NOT NULL
			INSERT [dbo].[M01_hosting_log] (M0101, TriggerDateTime, FlagHosting) SELECT @dRef, GETDATE(), 'D'


END
GO

ALTER TABLE [dbo].[M01] ENABLE TRIGGER [HostingSync_M01]
GO


