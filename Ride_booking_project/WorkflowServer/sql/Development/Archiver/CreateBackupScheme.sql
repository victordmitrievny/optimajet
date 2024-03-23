BEGIN TRANSACTION

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[SCHEMATA]
        WHERE [SCHEMA_NAME] = N'backup'
    )
    BEGIN
        EXEC ('create schema [backup];');
    END


IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessScheme'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessScheme (
                                               [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessScheme PRIMARY KEY
            ,[Scheme] NTEXT NOT NULL
            ,[DefiningParameters] NTEXT NOT NULL
            ,[DefiningParametersHash] NVARCHAR(24) NOT NULL
            ,[SchemeCode] NVARCHAR(256) NOT NULL
            ,[IsObsolete] BIT DEFAULT 0 NOT NULL
            ,[RootSchemeCode] NVARCHAR(256)
            ,[RootSchemeId] UNIQUEIDENTIFIER
            ,[AllowedActivities] NVARCHAR(max)
            ,[StartingTransition] NVARCHAR(max)
        )

        CREATE INDEX IX_SchemeCode_Hash_IsObsolete ON [backup].WorkflowProcessScheme (
                                                                             SchemeCode
            ,DefiningParametersHash
            ,IsObsolete
            )

        PRINT 'WorkflowProcessScheme CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessInstance'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessInstance (
                                                 [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessInstance PRIMARY KEY
            ,[StateName] NVARCHAR(max)
            ,[ActivityName] NVARCHAR(max) NOT NULL
            ,[SchemeId] UNIQUEIDENTIFIER
            ,[PreviousState] NVARCHAR(max)
            ,[PreviousStateForDirect] NVARCHAR(max)
            ,[PreviousStateForReverse] NVARCHAR(max)
            ,[PreviousActivity] NVARCHAR(max)
            ,[PreviousActivityForDirect] NVARCHAR(max)
            ,[PreviousActivityForReverse] NVARCHAR(max)
            ,[ParentProcessId] UNIQUEIDENTIFIER
            ,[RootProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[IsDeterminingParametersChanged] BIT DEFAULT 0 NOT NULL
            ,[TenantId] NVARCHAR(1024)
            ,[StartingTransition] NVARCHAR(max)
            ,[SubprocessName] NVARCHAR(max)
            ,[CreationDate] datetime NOT NULL CONSTRAINT DF_WorkflowProcessInstance_CreationDate DEFAULT getdate()
            ,[LastTransitionDate] datetime NULL
        )

        CREATE INDEX IX_RootProcessId ON [backup].WorkflowProcessInstance (RootProcessId)

        PRINT 'WorkflowProcessInstance CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessInstancePersistence'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessInstancePersistence (
                                                            [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessInstancePersistence PRIMARY KEY NONCLUSTERED
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[ParameterName] NVARCHAR(max) NOT NULL
            ,[Value] NVARCHAR(max) NOT NULL
        )

        CREATE CLUSTERED INDEX IX_ProcessId_Clustered ON [backup].WorkflowProcessInstancePersistence (ProcessId)

        PRINT 'WorkflowProcessInstancePersistence CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessTransitionHistory'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessTransitionHistory (
                                                          [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessTransitionHistory PRIMARY KEY NONCLUSTERED
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[ExecutorIdentityId] NVARCHAR(256)
            ,[ActorIdentityId] NVARCHAR(256)
            ,[ExecutorName] NVARCHAR(256)
            ,[ActorName] NVARCHAR(256)
            ,[FromActivityName] NVARCHAR(max) NOT NULL
            ,[ToActivityName] NVARCHAR(max) NOT NULL
            ,[ToStateName] NVARCHAR(max)
            ,[TransitionTime] DATETIME NOT NULL
            ,[TransitionClassifier] NVARCHAR(max) NOT NULL
            ,[IsFinalised] BIT NOT NULL
            ,[FromStateName] NVARCHAR(max)
            ,[TriggerName] NVARCHAR(max)
            ,[StartTransitionTime] DATETIME
            ,[TransitionDuration] BIGINT
        )

        CREATE CLUSTERED INDEX IX_ProcessId_Clustered ON [backup].WorkflowProcessTransitionHistory (ProcessId)

        CREATE INDEX IX_ExecutorIdentityId ON [backup].WorkflowProcessTransitionHistory (ExecutorIdentityId)

        PRINT 'WorkflowProcessTransitionHistory CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessInstanceStatus'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessInstanceStatus (
                                                       [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessInstanceStatus PRIMARY KEY
            ,[Status] TINYINT NOT NULL
            ,[Lock] UNIQUEIDENTIFIER NOT NULL
            ,[RuntimeId] nvarchar(450) NOT NULL
            ,[SetTime] datetime NOT NULL
        )

        CREATE NONCLUSTERED INDEX [IX_WorkflowProcessInstanceStatus_Status] ON [backup].[WorkflowProcessInstanceStatus]
            (
             [Status] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];


        CREATE NONCLUSTERED INDEX [IX_WorkflowProcessInstanceStatus_Status_Runtime] ON [backup].[WorkflowProcessInstanceStatus]
            (
             [Status] ASC,
             [RuntimeId] ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];


        PRINT 'WorkflowProcessInstanceStatus CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT *
        FROM [INFORMATION_SCHEMA].[ROUTINES]
        WHERE [SPECIFIC_NAME] = N'spWorkflowProcessResetRunningStatus'
          AND [SPECIFIC_SCHEMA] = N'backup'
    )
    BEGIN
        EXECUTE (
            'CREATE PROCEDURE [backup].[spWorkflowProcessResetRunningStatus]
    AS
    BEGIN
        UPDATE [WorkflowProcessInstanceStatus] SET [WorkflowProcessInstanceStatus].[Status] = 2 WHERE [WorkflowProcessInstanceStatus].[Status] = 1
    END'
            )

        PRINT 'spWorkflowProcessResetRunningStatus CREATE PROCEDURE'
    END

IF NOT EXISTS (
        SELECT *
        FROM [INFORMATION_SCHEMA].[ROUTINES]
        WHERE [SPECIFIC_NAME] = N'DropUnusedWorkflowProcessScheme'
          AND [SPECIFIC_SCHEMA] = N'backup'
    )
    BEGIN
        EXECUTE (
            'CREATE PROCEDURE [backup].[DropUnusedWorkflowProcessScheme]
    AS
    BEGIN
        DELETE wps FROM WorkflowProcessScheme AS wps 
            WHERE wps.IsObsolete = 1 
                AND NOT EXISTS (SELECT * FROM WorkflowProcessInstance wpi WHERE wpi.SchemeId = wps.Id )

        RETURN (SELECT COUNT(*) 
            FROM WorkflowProcessInstance wpi LEFT OUTER JOIN WorkflowProcessScheme wps ON wpi.SchemeId = wps.Id 
            WHERE wps.Id IS NULL)
    END'
            )

        PRINT 'DropUnusedWorkflowProcessScheme CREATE PROCEDURE'
    END


IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowScheme'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowScheme (
                                        [Code] NVARCHAR(256) NOT NULL CONSTRAINT PK_WorkflowScheme PRIMARY KEY,
                                        [Scheme] NVARCHAR(max) NOT NULL,
                                        [CanBeInlined] [bit] NOT NULL DEFAULT(0),
                                        [InlinedSchemes] [nvarchar](max) NULL,
                                        [Tags] [nvarchar](max) NULL,
        )

        PRINT 'WorkflowScheme CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowInbox'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowInbox (
                                       [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowInbox PRIMARY KEY NONCLUSTERED
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[IdentityId] NVARCHAR(256) NOT NULL
            ,[AddingDate] DATETIME NOT NULL DEFAULT GETDATE()
            ,[AvailableCommands] NVARCHAR(max) NOT NULL DEFAULT ''
        )

        CREATE CLUSTERED INDEX IX_IdentityId_Clustered ON [backup].WorkflowInbox (IdentityId)

        CREATE INDEX IX_ProcessId ON [backup].WorkflowInbox (ProcessId)

        PRINT 'WorkflowInbox CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT *
        FROM [INFORMATION_SCHEMA].[ROUTINES]
        WHERE [SPECIFIC_NAME] = N'DropWorkflowInbox'
          AND [SPECIFIC_SCHEMA] = N'backup'
    )
    BEGIN
        EXECUTE (
            'CREATE PROCEDURE [backup].[DropWorkflowInbox]
        @processId uniqueidentifier
    AS
    BEGIN
        BEGIN TRAN
        DELETE FROM dbo.WorkflowInbox WHERE ProcessId = @processId
        COMMIT TRAN
    END'
            )

        PRINT 'DropWorkflowInbox CREATE PROCEDURE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessTimer'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessTimer (
                                              [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessTimer PRIMARY KEY NONCLUSTERED
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[RootProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[Name] NVARCHAR(max) NOT NULL
            ,[NextExecutionDateTime] DATETIME NOT NULL
            ,[Ignore] BIT NOT NULL
        )

        CREATE CLUSTERED INDEX IX_NextExecutionDateTime_Clustered ON [backup].WorkflowProcessTimer (NextExecutionDateTime)
        CREATE INDEX IX_ProcessId ON [backup].WorkflowProcessTimer (ProcessId)

        PRINT 'WorkflowProcessTimer CREATE TABLE'
    END


IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowProcessAssignment'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowProcessAssignment (
                                                   [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowProcessAssignment PRIMARY KEY NONCLUSTERED
            ,[AssignmentCode] NVARCHAR(2048) NOT NULL
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[Name] NVARCHAR(max) NOT NULL
            ,[Description] NVARCHAR(max)
            ,[StatusState] NVARCHAR(max) NOT NULL
            ,[DateCreation] DATETIME NOT NULL
            ,[DateStart] DATETIME
            ,[DateFinish] DATETIME
            ,[DeadlineToStart] DATETIME
            ,[DeadlineToComplete] DATETIME
            ,[Executor] NVARCHAR(256) NOT NULL
            ,[Observers] NVARCHAR(max)
            ,[Tags] NVARCHAR(max)
            ,[IsActive] BIT NOT NULL
            ,[IsDeleted] BIT NOT NULL
        )

        CREATE INDEX IX_Assignment_ProcessId ON [backup].WorkflowProcessAssignment (ProcessId)
        CREATE INDEX IX_Assignment_AssignmentCode ON [backup].WorkflowProcessAssignment (AssignmentCode)
        CREATE INDEX IX_Assignment_Executor ON [backup].WorkflowProcessAssignment (Executor)
        CREATE INDEX IX_Assignment_ProcessId_Executor ON [backup].WorkflowProcessAssignment (ProcessId, Executor)

        PRINT 'WorkflowProcessAssignment CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowGlobalParameter'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowGlobalParameter (
                                                 [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowGlobalParameter PRIMARY KEY NONCLUSTERED
            ,[Type] NVARCHAR(306) NOT NULL
            ,[Name] NVARCHAR(128) NOT NULL
            ,[Value] NVARCHAR(max) NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IX_Type_Name_Clustered ON [backup].WorkflowGlobalParameter (
                                                                                         Type
            ,Name
            )

        PRINT 'WorkflowGlobalParameter CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowRuntime'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowRuntime (
                                         [RuntimeId] nvarchar(450) NOT NULL CONSTRAINT PK_WorkflowRuntime PRIMARY KEY
            ,[Lock] UNIQUEIDENTIFIER NOT NULL
            ,[Status] TINYINT NOT NULL
            ,[RestorerId] nvarchar(450)
            ,[NextTimerTime] datetime
            ,[NextServiceTimerTime] datetime
            ,[LastAliveSignal] datetime
        )

        PRINT 'WorkflowRuntime CREATE TABLE'

        EXEC('INSERT INTO [backup].WorkflowRuntime  (RuntimeId,Lock,Status)  VALUES (''00000000-0000-0000-0000-000000000000'', NEWID(),100)');
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowSync'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].WorkflowSync (
                                               [Name] nvarchar(450) NOT NULL CONSTRAINT PK_WorkflowSync PRIMARY KEY
            ,[Lock] UNIQUEIDENTIFIER NOT NULL
        )

        INSERT INTO [backup].[WorkflowSync]
        ([Name]
        ,[Lock])
        VALUES
            ('Timer',
             NEWID());

        INSERT INTO [backup].[WorkflowSync]
        ([Name]
        ,[Lock])
        VALUES
            ('ServiceTimer',
             NEWID());

        PRINT 'WorkflowSync CREATE TABLE'
    END

IF NOT EXISTS (
        SELECT 1
        FROM [INFORMATION_SCHEMA].[TABLES]
        WHERE [TABLE_NAME] = N'WorkflowApprovalHistory'
          AND [TABLE_SCHEMA] = N'backup'
    )
    BEGIN
        CREATE TABLE [backup].[WorkflowApprovalHistory](
                                                        [Id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_WorkflowApprovalHistory PRIMARY KEY NONCLUSTERED
            ,[ProcessId] UNIQUEIDENTIFIER NOT NULL
            ,[IdentityId] NVARCHAR(256) NULL
            ,[AllowedTo] NVARCHAR(max) NULL
            ,[TransitionTime] DateTime NULL
            ,[Sort] BIGINT NULL
            ,[InitialState] NVARCHAR(1024) NOT NULL
            ,[DestinationState] NVARCHAR(1024) NOT NULL
            ,[TriggerName] NVARCHAR(1024) NULL
            ,[Commentary] NVARCHAR(max) NULL
        )

        CREATE CLUSTERED INDEX IX_ProcessId_Clustered ON [backup].WorkflowApprovalHistory (ProcessId)
        CREATE NONCLUSTERED INDEX IX_IdentityId ON [backup].WorkflowApprovalHistory (IdentityId)
        PRINT 'WorkflowApprovalHistory CREATE TABLE'
    END



COMMIT TRANSACTION