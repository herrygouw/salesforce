USE [Autoparts]
GO
/****** Object:  Trigger [dbo].[HostingSync_M01]    Script Date: 11/21/2020 5:03:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[HostingSync_M01] 
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