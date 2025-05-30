 
/****** Object:  StoredProcedure [dbo].[sp_AssignModulePermissionsThreshold]    Script Date: 5/27/2025 9:01:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Mark Lusala Mudoga>
-- Create date: <Create Date,27th May 2025,>
-- Description:	<Description,Opens up the system to all users,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_AssignModuleThresholdPermissionsBranch]
	-- Add the parameters for the stored procedure here 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
-------------------------------------------------------------------------------------------------
--  Module Access Assignment
-------------------------------------------------------------------------------------------------
--select * from [VanguardFinancialsDB_AuthStore].DBO.aspnet_Roles
--select * from [dbo].[vfin_ModuleNavigationItems]
--select * from [dbo].[vfin_ModuleNavigationItemsInRoles]  

DECLARE @RoleNameModuleAssignment NVARCHAR(256)
DECLARE @ModuleNavigationItemId UNIQUEIDENTIFIER
DECLARE @NewId UNIQUEIDENTIFIER

-- Cursor to loop through Role Names
DECLARE RoleCursor CURSOR FOR
SELECT RoleName FROM [VanguardFinancialsDB_AuthStore].dbo.aspnet_Roles

-- Open Role cursor
OPEN RoleCursor
FETCH NEXT FROM RoleCursor INTO @RoleNameModuleAssignment

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Ensure RoleName is valid
    IF @RoleNameModuleAssignment IS NOT NULL
    BEGIN
        -- Cursor for all ModuleNavigationItems
        DECLARE ModuleItemCursor CURSOR FOR
        SELECT Id FROM [dbo].[vfin_ModuleNavigationItems]

        OPEN ModuleItemCursor
        FETCH NEXT FROM ModuleItemCursor INTO @ModuleNavigationItemId

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Avoid duplicate entries
            IF NOT EXISTS (
                SELECT 1 
                FROM [dbo].[vfin_ModuleNavigationItemsInRoles]
                WHERE ModuleNavigationItemId = @ModuleNavigationItemId
                  AND RoleName = @RoleNameModuleAssignment
            )
            BEGIN
                SET @NewId = NEWID()

                INSERT INTO [dbo].[vfin_ModuleNavigationItemsInRoles] (
                    Id,
                    ModuleNavigationItemId,
                    RoleName,
                    CreatedBy,
                    CreatedDate
                )
                VALUES (
                    @NewId,
                    @ModuleNavigationItemId,
                    @RoleNameModuleAssignment,
                    '___SYS___',
                    GETDATE()
                )
            END

            FETCH NEXT FROM ModuleItemCursor INTO @ModuleNavigationItemId
        END

        CLOSE ModuleItemCursor
        DEALLOCATE ModuleItemCursor
    END

    FETCH NEXT FROM RoleCursor INTO @RoleNameModuleAssignment
END

CLOSE RoleCursor
DEALLOCATE RoleCursor

-------------------------------------------------------------------------------------------------
--  System Permission Assignment
-------------------------------------------------------------------------------------------------
--select Value,Description from [dbo].[vfin_Enumerations] where [Key] = 'SystemPermissionType'
--SELECT * FROM [VanguardFinancialsDB_AuthStore].DBO.aspnet_Roles
--select * from [dbo].[vfin_SystemPermissionTypesInRoles]
  
DECLARE @RoleNameSystemPermissionAssignment NVARCHAR(256) 
DECLARE @SystemPermissionType INT
DECLARE @NewIdSystemPermissionAssignment UNIQUEIDENTIFIER

-- Cursor to loop through Role Names
DECLARE RoleCursor CURSOR FOR
SELECT RoleName FROM [VanguardFinancialsDB_AuthStore].dbo.aspnet_Roles

-- Open the Role cursor
OPEN RoleCursor
FETCH NEXT FROM RoleCursor INTO @RoleNameSystemPermissionAssignment

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Get RoleId for current RoleName
    SELECT @RoleNameSystemPermissionAssignment = RoleName
    FROM [VanguardFinancialsDB_AuthStore].dbo.aspnet_Roles
    WHERE RoleName = @RoleNameSystemPermissionAssignment

    -- Ensure role exists before proceeding
    IF @RoleNameSystemPermissionAssignment IS NOT NULL
    BEGIN
        -- Cursor for SystemPermissionType values
        DECLARE PermissionCursor CURSOR FOR
        SELECT [Value] FROM [dbo].[vfin_Enumerations]
        WHERE [Key] = 'SystemPermissionType'

        OPEN PermissionCursor
        FETCH NEXT FROM PermissionCursor INTO @SystemPermissionType

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the combination already exists to avoid duplicates
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[vfin_SystemPermissionTypesInRoles]
                WHERE RoleName = @RoleNameSystemPermissionAssignment AND SystemPermissionType = @SystemPermissionType
            )
            BEGIN
                SET @NewIdSystemPermissionAssignment = NEWID()

                INSERT INTO [dbo].[vfin_SystemPermissionTypesInRoles] (
                    Id,
                    SystemPermissionType,
                    RoleName, 
                    CreatedBy,
                    CreatedDate
                )
                VALUES (
                    @NewIdSystemPermissionAssignment,
                    @SystemPermissionType,
                    @RoleNameSystemPermissionAssignment, 
                    '___SYS___',
                    GETDATE()
                )
            END

            FETCH NEXT FROM PermissionCursor INTO @SystemPermissionType
        END

        CLOSE PermissionCursor
        DEALLOCATE PermissionCursor
    END

    FETCH NEXT FROM RoleCursor INTO @RoleNameSystemPermissionAssignment
END

CLOSE RoleCursor
DEALLOCATE RoleCursor


-------------------------------------------------------------------------------------------------
--  Designation Threshold Assignment
-------------------------------------------------------------------------------------------------
--select * from vfin_Designations
--select * from vfin_Enumerations  where [Key] = 'systemtransactioncode' and len(Description)>1
--select * from vfin_TransactionThresholds

DECLARE @DesignationId UNIQUEIDENTIFIER
DECLARE @SystemTransactionCode INT
DECLARE @NewIdDesignation UNIQUEIDENTIFIER

-- Cursor to loop through all DesignationIds
DECLARE DesignationCursor CURSOR FOR
SELECT Id FROM [dbo].[vfin_Designations]

OPEN DesignationCursor
FETCH NEXT FROM DesignationCursor INTO @DesignationId

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @DesignationId IS NOT NULL
    BEGIN
        -- Cursor for valid SystemTransactionCodes
        DECLARE TransactionCodeCursor CURSOR FOR
        SELECT [Value] 
        FROM [dbo].[vfin_Enumerations] 
        WHERE [Key] = 'systemtransactioncode' AND LEN(Description) > 1

        OPEN TransactionCodeCursor
        FETCH NEXT FROM TransactionCodeCursor INTO @SystemTransactionCode

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Avoid inserting duplicate entries
            IF NOT EXISTS (
                SELECT 1 
                FROM [dbo].[vfin_TransactionThresholds]
                WHERE DesignationId = @DesignationId
                  AND Type = @SystemTransactionCode
            )
            BEGIN
                SET @NewIdDesignation = NEWID()

                INSERT INTO [dbo].[vfin_TransactionThresholds] (
                    Id,
                    DesignationId,
                    Type,
                    Threshold,
                    CreatedBy,
                    CreatedDate
                )
                VALUES (
                    @NewIdDesignation,
                    @DesignationId,
                    @SystemTransactionCode,
                    200000000,
                    '___SYS___',
                    GETDATE()
                )
            END

            FETCH NEXT FROM TransactionCodeCursor INTO @SystemTransactionCode
        END

        CLOSE TransactionCodeCursor
        DEALLOCATE TransactionCodeCursor
    END

    FETCH NEXT FROM DesignationCursor INTO @DesignationId
END

CLOSE DesignationCursor
DEALLOCATE DesignationCursor

-------------------------------------------------------------------------------------------------
--  Employee Authorization Assignment
-------------------------------------------------------------------------------------------------
--select * from vfin_Branches
--select * from vfin_Employees
--select * from [dbo].[vfin_EmployeesInBranches]

DECLARE @EmployeeId UNIQUEIDENTIFIER
DECLARE @BranchId UNIQUEIDENTIFIER
DECLARE @NewIdEmployeeInBranches UNIQUEIDENTIFIER

-- Cursor to loop through all Employees
DECLARE EmployeeCursor CURSOR FOR
SELECT Id FROM [dbo].[vfin_Employees]

OPEN EmployeeCursor
FETCH NEXT FROM EmployeeCursor INTO @EmployeeId

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @EmployeeId IS NOT NULL
    BEGIN
        -- Cursor for all Branches
        DECLARE BranchCursor CURSOR FOR
        SELECT Id FROM [dbo].[vfin_Branches]

        OPEN BranchCursor
        FETCH NEXT FROM BranchCursor INTO @BranchId

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Prevent duplicate entries
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[vfin_EmployeesInBranches]
                WHERE EmployeeId = @EmployeeId AND BranchId = @BranchId
            )
            BEGIN
                SET @NewIdEmployeeInBranches = NEWID()

                INSERT INTO [dbo].[vfin_EmployeesInBranches] (
                    Id,
                    EmployeeId,
                    BranchId,
                    CreatedBy,
                    CreatedDate
                )
                VALUES (
                    @NewIdEmployeeInBranches,
                    @EmployeeId,
                    @BranchId,
                    '___SYS___',
                    GETDATE()
                )
            END

            FETCH NEXT FROM BranchCursor INTO @BranchId
        END

        CLOSE BranchCursor
        DEALLOCATE BranchCursor
    END

    FETCH NEXT FROM EmployeeCursor INTO @EmployeeId
END

CLOSE EmployeeCursor
DEALLOCATE EmployeeCursor

-------------------------------------------------------------------------------------------------
--  Branch Authorization Assignment
-------------------------------------------------------------------------------------------------
--select Value,Description from [dbo].[vfin_Enumerations] where [Key] = 'SystemPermissionType'
--select * from vfin_Branches 
--select * from vfin_SystemPermissionTypesInBranches

DECLARE @BranchIdPermitted UNIQUEIDENTIFIER
DECLARE @SystemPermissionTypePermitted INT
DECLARE @NewIdPermittedBranches UNIQUEIDENTIFIER

-- Cursor to loop through all Branches
DECLARE BranchCursor CURSOR FOR
SELECT Id FROM [dbo].[vfin_Branches]

OPEN BranchCursor
FETCH NEXT FROM BranchCursor INTO @BranchIdPermitted

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @BranchIdPermitted IS NOT NULL
    BEGIN
        -- Cursor for SystemPermissionType values
        DECLARE PermissionCursor CURSOR FOR
        SELECT [Value] FROM [dbo].[vfin_Enumerations]
        WHERE [Key] = 'SystemPermissionType'

        OPEN PermissionCursor
        FETCH NEXT FROM PermissionCursor INTO @SystemPermissionTypePermitted

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Avoid duplicates
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[vfin_SystemPermissionTypesInBranches]
                WHERE BranchId = @BranchIdPermitted AND SystemPermissionType = @SystemPermissionTypePermitted
            )
            BEGIN
                SET @NewIdPermittedBranches = NEWID()

                INSERT INTO [dbo].[vfin_SystemPermissionTypesInBranches] (
                    Id,
                    BranchId,
                    SystemPermissionType,
                    CreatedBy,
                    CreatedDate
                )
                VALUES (
                    @NewIdPermittedBranches,
                    @BranchIdPermitted,
                    @SystemPermissionTypePermitted,
                    '___SYS___',
                    GETDATE()
                )
            END

            FETCH NEXT FROM PermissionCursor INTO @SystemPermissionTypePermitted
        END

        CLOSE PermissionCursor
        DEALLOCATE PermissionCursor
    END

    FETCH NEXT FROM BranchCursor INTO @BranchIdPermitted
END

CLOSE BranchCursor
DEALLOCATE BranchCursor

-------------------------------------------------------------------------------------------------
--  Lock user sessions after 24 hours of inactivity
-------------------------------------------------------------------------------------------------

UPDATE vfin_Employees SET InactivityTimeout = 1440 , EnforceSystemInitializationLockTime = 1 , TimeDuration_StartTime = '02:00:00.0000000', TimeDuration_EndTime = '23:59:59.0000000'

END

 