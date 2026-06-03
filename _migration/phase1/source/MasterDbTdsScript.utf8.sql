USE [master]
GO
/****** Object:  Database [MasterDbTds]    Script Date: 28-05-2026 21:16:40 ******/
CREATE DATABASE [MasterDbTds] ON  PRIMARY 
( NAME = N'MasterDbTds', FILENAME = N'Appdirectory\Db\MasterDbTds.mdf' , SIZE = 192512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MasterDbTds_log', FILENAME = N'Appdirectory\Db\MasterDbTds_log.ldf' , SIZE = 135104KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [MasterDbTds] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MasterDbTds].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MasterDbTds] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MasterDbTds] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MasterDbTds] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MasterDbTds] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MasterDbTds] SET ARITHABORT OFF 
GO
ALTER DATABASE [MasterDbTds] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [MasterDbTds] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [MasterDbTds] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MasterDbTds] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MasterDbTds] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MasterDbTds] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MasterDbTds] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MasterDbTds] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MasterDbTds] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MasterDbTds] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MasterDbTds] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MasterDbTds] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MasterDbTds] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MasterDbTds] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MasterDbTds] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MasterDbTds] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MasterDbTds] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MasterDbTds] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [MasterDbTds] SET  MULTI_USER 
GO
ALTER DATABASE [MasterDbTds] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MasterDbTds] SET DB_CHAINING OFF 
GO
USE [MasterDbTds]
GO
/****** Object:  Table [dbo].[ApplicationParams]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationParams](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NULL,
	[value] [nvarchar](max) NULL,
 CONSTRAINT [PK_ApplicationParams] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Assessee]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Assessee](
	[subCode] [int] IDENTITY(1,1) NOT NULL,
	[prodKey] [nvarchar](10) NOT NULL,
	[fileCode] [nvarchar](10) NULL,
	[groupCode] [int] NULL,
	[tradeName] [nvarchar](125) NOT NULL,
	[firstName] [nvarchar](25) NOT NULL,
	[middleName] [nvarchar](25) NULL,
	[lastName] [nvarchar](75) NULL,
	[fatherName] [nvarchar](125) NULL,
	[husbandName] [nvarchar](125) NULL,
	[assesseeStatus] [nvarchar](10) NOT NULL,
	[assesseeSubStatus] [nvarchar](10) NULL,
	[dob] [nvarchar](10) NULL,
	[sex] [nvarchar](1) NULL,
	[pan] [nvarchar](10) NOT NULL,
	[panStatus] [nvarchar](50) NULL,
	[tan] [nvarchar](10) NULL,
	[cin] [nvarchar](50) NULL,
	[gstNo] [nvarchar](15) NULL,
	[aadhaarNo] [nvarchar](12) NULL,
	[aadhaarEnrolment] [nvarchar](28) NULL,
	[aadhaarStatus] [nvarchar](50) NULL,
	[sebiRegNo] [nvarchar](15) NULL,
	[principalPan] [nvarchar](10) NULL,
	[citizenshipCode] [nvarchar](50) NULL,
	[citizenshipOth] [nvarchar](50) NULL,
	[residentStatus] [nvarchar](50) NULL,
	[passportNo] [nvarchar](50) NULL,
	[mobilePrimaryStdCode] [nvarchar](10) NULL,
	[mobilePrimary] [nvarchar](11) NULL,
	[mobilePrimaryBelongsTo] [nvarchar](50) NULL,
	[mobileSecondaryStdCode] [nvarchar](10) NULL,
	[mobileSecondary] [nvarchar](11) NULL,
	[mobileSecondaryBelongsTo] [nvarchar](50) NULL,
	[mobileResiStdCode] [nvarchar](50) NULL,
	[mobileResi] [nvarchar](11) NULL,
	[phoneResiStdCode] [nvarchar](5) NULL,
	[phoneResi] [nvarchar](11) NULL,
	[emailPrimary] [nvarchar](125) NULL,
	[emailPrimaryBelongsTo] [nvarchar](50) NULL,
	[emailSecondary] [nvarchar](125) NULL,
	[emailSecondaryBelongsTo] [nvarchar](50) NULL,
	[addr1] [nvarchar](50) NULL,
	[addr2] [nvarchar](50) NULL,
	[addr3] [nvarchar](50) NULL,
	[addr4] [nvarchar](50) NULL,
	[postOfcCode] [int] NULL,
	[othpostOfcName] [nvarchar](50) NULL,
	[pinCode] [int] NULL,
	[zipCode] [nvarchar](50) NULL,
	[cityCode] [int] NULL,
	[othCityName] [nvarchar](50) NULL,
	[stateCode] [int] NULL,
	[othStateName] [nvarchar](50) NULL,
	[countryCode] [int] NULL,
	[communicationAddrTo] [nvarchar](50) NULL,
	[areaCode] [nvarchar](3) NULL,
	[aoType] [nvarchar](2) NULL,
	[aoNo] [nvarchar](10) NULL,
	[rangeCode] [nvarchar](10) NULL,
	[jurisdiction] [nvarchar](50) NULL,
	[jurisdictionEmail] [nvarchar](125) NULL,
	[jurisdictionBuildingName] [nvarchar](100) NULL,
	[ward] [nvarchar](15) NULL,
	[auditCase] [bit] NOT NULL,
	[verifiedBy] [nvarchar](125) NULL,
	[referredBy] [nvarchar](125) NULL,
	[consultantId] [int] NULL,
	[startAY] [int] NULL,
	[endAY] [int] NULL,
	[userId] [nvarchar](20) NULL,
	[password] [nvarchar](max) NULL,
	[dscCommonName] [nvarchar](100) NULL,
	[dscExpiryDt] [nvarchar](50) NULL,
	[dscLinkedFlag] [nvarchar](50) NULL,
	[recgnNumAllottedByDPIIT] [nvarchar](50) NULL,
	[certificationNumber] [nvarchar](50) NULL,
	[dateOfFilingForm2] [nvarchar](10) NULL,
	[lastLogin] [nvarchar](50) NULL,
	[lastLogout] [nvarchar](50) NULL,
	[lastUpdated] [nvarchar](50) NULL,
	[profilePic] [image] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[leiNo] [nvarchar](20) NULL,
	[leiValidUpto] [nvarchar](10) NULL,
	[PRANNum] [nvarchar](20) NULL,
	[authName] [nvarchar](100) NULL,
	[authDOB] [nvarchar](10) NULL,
	[authPan] [nvarchar](10) NULL,
	[authDesignation] [nvarchar](50) NULL,
	[authAddr1] [nvarchar](75) NULL,
	[authAddr2] [nvarchar](75) NULL,
	[authAddr3] [nvarchar](75) NULL,
	[authCity] [nvarchar](75) NULL,
	[authPin] [int] NULL,
	[authState] [nvarchar](50) NULL,
	[authSex] [nvarchar](1) NULL,
	[authFname] [nvarchar](100) NULL,
	[authStdCode1] [nvarchar](5) NULL,
	[authMobile1] [nvarchar](15) NULL,
	[authStdCode2] [nvarchar](5) NULL,
	[authMobile2] [nvarchar](15) NULL,
	[authStdPh1] [nvarchar](5) NULL,
	[authPhone1] [nvarchar](10) NULL,
	[authStdPh2] [nvarchar](5) NULL,
	[authPhone2] [nvarchar](10) NULL,
	[authEmail1] [nvarchar](50) NULL,
	[authEmail2] [nvarchar](50) NULL,
	[govState] [nvarchar](50) NULL,
	[govPAO] [nvarchar](25) NULL,
	[govPAOName] [nvarchar](50) NULL,
	[govDDO] [nvarchar](25) NULL,
	[govDDONo] [nvarchar](25) NULL,
	[govMinistryName] [nvarchar](50) NULL,
	[govMinistryNameOth] [nvarchar](50) NULL,
	[govAIN] [nvarchar](25) NULL,
	[branchName] [nvarchar](50) NULL,
	[whetherInt] [bit] NULL,
	[pendingBill] [bit] NULL,
	[applicableForms] [nvarchar](50) NULL,
	[tdsCpcPwd] [nvarchar](100) NULL,
 CONSTRAINT [idx_subcode] PRIMARY KEY CLUSTERED 
(
	[subCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AssesseeRep]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssesseeRep](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[RepName] [nvarchar](125) NOT NULL,
	[RepFatherName] [nvarchar](125) NULL,
	[RepPAN] [nvarchar](10) NULL,
	[RepCapacity] [nvarchar](5) NULL,
	[RepAddress] [nvarchar](250) NULL,
	[RepAadhaar] [nvarchar](12) NULL,
	[Place] [nvarchar](50) NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_AssesseeRep] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AssesseeResStatus]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssesseeResStatus](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[resStatus] [nvarchar](10) NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[resStatusVal] [nvarchar](max) NULL,
 CONSTRAINT [PK_AssesseeResStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AyMaster]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AyMaster](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ayid] [int] NOT NULL,
	[name] [nvarchar](15) NOT NULL,
	[startDt] [nvarchar](10) NOT NULL,
	[endDt] [nvarchar](10) NOT NULL,
	[NonBusInc] [nvarchar](10) NULL,
	[BusInc] [nvarchar](10) NULL,
	[AuditCase] [nvarchar](10) NULL,
	[CompCase] [nvarchar](10) NULL,
	[Case94E] [nvarchar](10) NULL,
	[AdvInst1] [nvarchar](10) NULL,
	[AdvInst2] [nvarchar](10) NULL,
	[AdvInst3] [nvarchar](10) NULL,
	[AdvInst4] [nvarchar](10) NULL,
	[UpdNonBusInc] [nvarchar](10) NULL,
	[UpdBusInc] [nvarchar](10) NULL,
	[UpdAuditCase] [nvarchar](10) NULL,
	[UpdCompCase] [nvarchar](10) NULL,
	[UpdCase94E] [nvarchar](10) NULL,
 CONSTRAINT [PK_AyMasters] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BankDetails]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BankDetails](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[bankName] [nvarchar](125) NOT NULL,
	[branchName] [nvarchar](50) NOT NULL,
	[bankAdd] [nvarchar](50) NULL,
	[bankAcNo] [nvarchar](20) NOT NULL,
	[ifscCode] [nvarchar](11) NOT NULL,
	[bsrNo] [nvarchar](79) NULL,
	[micrNo] [nvarchar](9) NULL,
	[typeCode] [nvarchar](50) NULL,
	[ecs] [nvarchar](10) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[AppliesToYear] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_bank] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BillDetails]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillDetails](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[billId] [int] NOT NULL,
	[description] [nvarchar](50) NOT NULL,
	[prodCode] [numeric](8, 0) NULL,
	[unit] [nvarchar](10) NULL,
	[qty] [numeric](12, 2) NULL,
	[value] [numeric](15, 2) NOT NULL,
	[discount] [numeric](18, 2) NULL,
	[taxableValue] [numeric](15, 2) NOT NULL,
	[rateMain] [numeric](5, 2) NOT NULL,
	[amtIgst] [numeric](15, 2) NULL,
	[amtCgst] [numeric](15, 2) NULL,
	[amtSgst] [numeric](15, 2) NULL,
	[amtCess] [numeric](15, 2) NULL,
	[totAmount] [numeric](15, 2) NOT NULL,
 CONSTRAINT [PK_BillDetails] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BillHead]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillHead](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[periodId] [int] NULL,
	[conscode] [int] NOT NULL,
	[billNo] [int] NOT NULL,
	[billDt] [date] NOT NULL,
	[pos] [int] NOT NULL,
	[totAmt] [numeric](15, 3) NOT NULL,
	[amtReceived] [numeric](15, 3) NOT NULL,
	[amtDisc] [numeric](15, 3) NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_BillHead] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Billmast]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Billmast](
	[billid] [int] IDENTITY(1,1) NOT NULL,
	[date] [nvarchar](50) NULL,
	[subcode] [int] NULL,
	[billno] [int] NULL,
	[p1] [nvarchar](500) NULL,
	[p1amt] [decimal](18, 2) NULL,
	[p2] [nvarchar](500) NULL,
	[p2amt] [decimal](18, 2) NULL,
	[p3] [nvarchar](500) NULL,
	[p3amt] [decimal](18, 2) NULL,
	[p4] [nvarchar](500) NULL,
	[p4amt] [decimal](18, 2) NULL,
	[p5] [nvarchar](500) NULL,
	[p5amt] [decimal](18, 2) NULL,
	[p6] [nvarchar](500) NULL,
	[p6amt] [decimal](18, 2) NULL,
	[p7] [nvarchar](500) NULL,
	[p7amt] [decimal](18, 2) NULL,
	[p8] [nvarchar](500) NULL,
	[p8amt] [decimal](18, 2) NULL,
	[p9] [nvarchar](500) NULL,
	[p9amt] [decimal](18, 2) NULL,
	[p10] [nvarchar](500) NULL,
	[p10amt] [decimal](18, 2) NULL,
	[stax] [decimal](18, 2) NULL,
	[tamt] [decimal](18, 2) NULL,
	[sperc] [decimal](18, 2) NULL,
	[ramt] [decimal](18, 2) NULL,
	[ayid] [int] NULL,
	[conscode] [int] NULL,
	[damt] [decimal](18, 2) NULL,
	[receipt] [bit] NULL,
	[grpcode] [int] NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_Billmast] PRIMARY KEY CLUSTERED 
(
	[billid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BillReceipt]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillReceipt](
	[receiptno] [int] IDENTITY(1,1) NOT NULL,
	[date] [nvarchar](50) NULL,
	[subcode] [int] NULL,
	[billno] [int] NULL,
	[amount] [decimal](18, 2) NULL,
	[mode] [nvarchar](50) NULL,
	[number] [nvarchar](100) NULL,
	[billdate] [nvarchar](50) NULL,
	[ayid] [int] NULL,
	[conscode] [int] NULL,
	[discount] [decimal](18, 2) NULL,
	[billid] [int] NULL,
	[userid] [int] NULL,
	[lastupdate] [nvarchar](50) NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_BillReceipt] PRIMARY KEY CLUSTERED 
(
	[receiptno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BillReceipts]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillReceipts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ayId] [int] NOT NULL,
	[billId] [int] NOT NULL,
	[receiptNo] [int] NOT NULL,
	[receiptDt] [date] NOT NULL,
	[amtReceived] [numeric](15, 3) NOT NULL,
	[amtDisc] [numeric](15, 3) NOT NULL,
	[mode] [nvarchar](50) NOT NULL,
	[instrumentNo] [nvarchar](50) NULL,
	[instrumentDt] [date] NULL,
	[CreatedBy] [int] NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_BillReceipts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Check_period]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Check_period](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[quarter] [int] NULL,
	[month] [int] NULL,
	[ayid] [int] NULL,
 CONSTRAINT [PK_Check_period] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Consultant]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Consultant](
	[consCode] [int] IDENTITY(1,1) NOT NULL,
	[prodKey] [nvarchar](10) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[residenceNo] [nvarchar](50) NOT NULL,
	[residenceName] [nvarchar](50) NOT NULL,
	[roadOrStreet] [nvarchar](50) NOT NULL,
	[localityOrArea] [nvarchar](50) NULL,
	[city] [nvarchar](50) NOT NULL,
	[stateCode] [nvarchar](50) NULL,
	[state] [nvarchar](50) NOT NULL,
	[phoneOffice] [nvarchar](11) NOT NULL,
	[phoneResi] [nvarchar](50) NOT NULL,
	[mobile] [nvarchar](11) NOT NULL,
	[mobile2] [nvarchar](50) NOT NULL,
	[email] [nvarchar](125) NOT NULL,
	[partnerName] [nvarchar](50) NOT NULL,
	[membership] [nvarchar](20) NULL,
	[partnerDesignation] [nvarchar](50) NOT NULL,
	[slogan] [nvarchar](32) NOT NULL,
	[bankName] [nvarchar](100) NULL,
	[accNo] [nvarchar](25) NULL,
	[ifscCode] [nvarchar](11) NULL,
	[panFirm] [nvarchar](10) NULL,
	[frnNo] [nvarchar](7) NULL,
	[panPArtner] [nvarchar](10) NULL,
	[pin] [numeric](7, 0) NOT NULL,
	[gstno] [nvarchar](15) NULL,
	[userId] [nvarchar](10) NULL,
	[pwd] [nvarchar](25) NULL,
	[emailProvider] [nvarchar](20) NULL,
	[emailId] [nvarchar](50) NULL,
	[emailPwd] [nvarchar](50) NULL,
	[flagDefault] [bit] NOT NULL,
	[logo] [nvarchar](max) NULL,
	[emailSignature] [nvarchar](max) NULL,
	[flagPendingBillsNotifications] [bit] NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Consultant] PRIMARY KEY CLUSTERED 
(
	[consCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Country]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Country](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[District]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[District](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code] [int] NOT NULL,
	[stateCode] [int] NOT NULL,
	[name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_District] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FeePaidMarking]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FeePaidMarking](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[fyid] [int] NOT NULL,
	[periodId] [int] NULL,
	[feePaid] [bit] NOT NULL,
	[notes] [nvarchar](max) NULL,
	[createdOn] [datetime] NOT NULL,
	[modifiedOn] [datetime] NULL,
 CONSTRAINT [PK_FeePaidMarking] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Groups]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Groups](
	[grpcode] [int] IDENTITY(1,1) NOT NULL,
	[prodKey] [nvarchar](10) NOT NULL,
	[groupname] [nvarchar](100) NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[email] [nvarchar](75) NULL,
	[mobile] [nvarchar](10) NULL,
 CONSTRAINT [PK_Groups] PRIMARY KEY CLUSTERED 
(
	[grpcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Pincode]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pincode](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[pinCode] [float] NULL,
	[districtCode] [float] NULL,
	[stateCode] [float] NULL,
	[subDistrictCode] [float] NULL,
	[localityCode] [float] NULL,
	[postOfficeCode] [float] NULL,
 CONSTRAINT [PK_Pincode] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PostOffice]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostOffice](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code] [int] NOT NULL,
	[name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_PostOffice] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ReturnDates]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReturnDates](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subcode] [int] NOT NULL,
	[ayid] [int] NOT NULL,
	[quarter] [nvarchar](5) NOT NULL,
	[signingDate] [nvarchar](10) NOT NULL,
	[place] [nvarchar](75) NULL,
	[formName] [nvarchar](10) NOT NULL,
	[tokenNumber] [nvarchar](15) NULL,
	[addressChangeOrg] [bit] NOT NULL,
	[addressChangeAuth] [bit] NOT NULL,
	[aoApprovalNo] [nvarchar](20) NULL,
	[isRegularStatement] [bit] NOT NULL,
	[isNilReturn] [bit] NOT NULL,
	[nilSectionsCount] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[State]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[State](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_State] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SubDistrict]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubDistrict](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SubDistrict] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tdsaomaster]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tdsaomaster](
	[aocode] [int] IDENTITY(1,1) NOT NULL,
	[aoin] [nvarchar](50) NULL,
	[laoin] [nvarchar](50) NULL,
	[name] [nvarchar](200) NULL,
	[add1] [nvarchar](200) NULL,
	[add2] [nvarchar](200) NULL,
	[add3] [nvarchar](200) NULL,
	[add4] [nvarchar](200) NULL,
	[city] [nvarchar](100) NULL,
	[statecode] [int] NULL,
	[pin] [int] NULL,
	[std] [nvarchar](20) NULL,
	[phone] [nvarchar](50) NULL,
	[email] [nvarchar](200) NULL,
	[aperson] [nvarchar](200) NULL,
	[adesig] [nvarchar](200) NULL,
	[cat] [nvarchar](50) NULL,
	[lataocat] [nvarchar](50) NULL,
	[radd1] [nvarchar](200) NULL,
	[radd2] [nvarchar](200) NULL,
	[radd3] [nvarchar](200) NULL,
	[radd4] [nvarchar](200) NULL,
	[rcity] [nvarchar](100) NULL,
	[rstatecode] [int] NULL,
	[rpin] [nvarchar](20) NULL,
	[rstd] [nvarchar](20) NULL,
	[rphone] [nvarchar](50) NULL,
	[remail] [nvarchar](200) NULL,
	[rmobile] [nvarchar](50) NULL,
	[minname] [nvarchar](200) NULL,
	[sminname] [nvarchar](200) NULL,
	[sminname2] [nvarchar](200) NULL,
	[paoregno] [int] NULL,
	[statename] [nvarchar](100) NULL,
	[mobile] [nvarchar](50) NULL,
 CONSTRAINT [PK_Tdsaomaster] PRIMARY KEY CLUSTERED 
(
	[aocode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tdsded80]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tdsded80](
	[ded80id] [int] IDENTITY(1,1) NOT NULL,
	[dedsec] [nvarchar](20) NULL,
	[ded80name] [nvarchar](200) NULL,
	[ded80table] [nvarchar](50) NULL,
	[label1] [nvarchar](200) NULL,
	[label2] [nvarchar](200) NULL,
	[label3] [nvarchar](200) NULL,
	[label4] [nvarchar](200) NULL,
	[label5] [nvarchar](200) NULL,
	[label6] [nvarchar](200) NULL,
	[label7] [nvarchar](200) NULL,
	[label8] [nvarchar](200) NULL,
	[label9] [nvarchar](200) NULL,
	[label10] [nvarchar](200) NULL,
	[dedtype] [nvarchar](50) NULL,
	[pdedid] [int] NULL,
	[section] [nvarchar](20) NULL,
	[short] [nvarchar](50) NULL,
	[ind] [bit] NULL,
	[indnr] [bit] NULL,
	[huf] [bit] NULL,
	[hufnr] [bit] NULL,
	[firm] [bit] NULL,
	[company] [bit] NULL,
	[companynr] [bit] NULL,
	[coop] [bit] NULL,
	[sortid] [int] NULL,
	[ayid] [int] NULL,
	[ayid2] [int] NULL,
 CONSTRAINT [PK_Tdsded80] PRIMARY KEY CLUSTERED 
(
	[ded80id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsEntriesSection]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsEntriesSection](
	[Section] [nvarchar](10) NULL,
	[Paycode] [int] NULL,
	[Name] [nvarchar](200) NULL,
	[Limit] [int] NULL,
	[FormName] [nvarchar](6) NULL,
	[NewSection] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsNature]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsNature](
	[particular] [nvarchar](255) NULL,
	[code] [int] NOT NULL,
 CONSTRAINT [PK_Nature3] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsRate]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsRate](
	[ayid] [int] NULL,
	[tsId] [int] NULL,
	[PayCode] [int] NULL,
	[Rate] [numeric](5, 2) NULL,
	[Surch] [numeric](5, 2) NULL,
	[Limit] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 28-05-2026 21:16:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[userId] [int] IDENTITY(1,1) NOT NULL,
	[prodKey] [nvarchar](10) NOT NULL,
	[userName] [nvarchar](50) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[pwd] [nvarchar](500) NOT NULL,
	[emailId] [nvarchar](150) NOT NULL,
	[mobile] [nvarchar](10) NOT NULL,
	[userType] [nvarchar](40) NOT NULL,
	[assesseeAddFlag] [bit] NOT NULL,
	[assesseeEditFlag] [bit] NOT NULL,
	[assesseeDeleteFlag] [bit] NOT NULL,
	[viewPwdFlag] [bit] NOT NULL,
	[backupFlag] [bit] NOT NULL,
	[restoreFlag] [bit] NOT NULL,
	[efilingFlag] [bit] NOT NULL,
	[rptViewFlag] [bit] NOT NULL,
	[editFiledReturnFlag] [bit] NOT NULL,
	[selectedPer] [int] NULL,
	[CreatedBy] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedBy] [int] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_Users_1] PRIMARY KEY CLUSTERED 
(
	[prodKey] ASC,
	[userName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[ApplicationParams] ON 

INSERT [dbo].[ApplicationParams] ([Id], [name], [value]) VALUES (1, N'auth', N'0+YpdQZbXjn9MhW+xv315cTSkOZSpZChY7IqgAJ6UkOIzNG38meuFHrxHKa/nMNzmBWQQcJwwl8kfociGXlaSA==')
INSERT [dbo].[ApplicationParams] ([Id], [name], [value]) VALUES (2, N'ver', N'1.000')
INSERT [dbo].[ApplicationParams] ([Id], [name], [value]) VALUES (3, N'backupLoc', N'C:\Tds VScode\ProjectTDS\SmartTdsWinUI\bin\SmartTdsBackups')
INSERT [dbo].[ApplicationParams] ([Id], [name], [value]) VALUES (4, N'lastBackup', N'18/03/2026')
SET IDENTITY_INSERT [dbo].[ApplicationParams] OFF
GO
SET IDENTITY_INSERT [dbo].[AyMaster] ON 

INSERT [dbo].[AyMaster] ([id], [ayid], [name], [startDt], [endDt], [NonBusInc], [BusInc], [AuditCase], [CompCase], [Case94E], [AdvInst1], [AdvInst2], [AdvInst3], [AdvInst4], [UpdNonBusInc], [UpdBusInc], [UpdAuditCase], [UpdCompCase], [UpdCase94E]) VALUES (5, 25, N'2025-2026', N'01/04/2025', N'31/03/2026', N'15/09/2026', N'15/09/2026', N'31/10/2026', N'31/10/2026', N'30/11/2026', N'15/06/2025', N'15/09/2025', N'15/12/2025', N'15/03/2026', N'31/03/2031', N'31/03/2031', N'31/03/2031', N'31/03/2031', N'31/03/2031')
INSERT [dbo].[AyMaster] ([id], [ayid], [name], [startDt], [endDt], [NonBusInc], [BusInc], [AuditCase], [CompCase], [Case94E], [AdvInst1], [AdvInst2], [AdvInst3], [AdvInst4], [UpdNonBusInc], [UpdBusInc], [UpdAuditCase], [UpdCompCase], [UpdCase94E]) VALUES (7, 26, N'2026-2027', N'01/04/2026', N'31/03/2027', N'15/09/2027', N'15/09/2027', N'31/10/2027', N'31/10/2027', N'30/11/2027', N'15/06/2026', N'15/09/2026', N'15/12/2026', N'15/03/2027', N'31/03/2032', N'31/03/2032', N'31/03/2032', N'31/03/2032', N'31/03/2032')
SET IDENTITY_INSERT [dbo].[AyMaster] OFF
GO
SET IDENTITY_INSERT [dbo].[Check_period] ON 

INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (1, 1, 4, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (2, 1, 5, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (3, 1, 6, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (4, 2, 7, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (5, 2, 8, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (6, 2, 9, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (7, 3, 10, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (8, 3, 11, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (9, 3, 12, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (10, 4, 1, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (11, 4, 2, 0)
INSERT [dbo].[Check_period] ([id], [quarter], [month], [ayid]) VALUES (12, 4, 3, 0)
SET IDENTITY_INSERT [dbo].[Check_period] OFF
GO
SET IDENTITY_INSERT [dbo].[Country] ON 

INSERT [dbo].[Country] ([id], [code], [name]) VALUES (1, 91, N'INDIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (2, 9999, N'OTHERS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (3, 93, N'AFGHANISTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (4, 355, N'ALBANIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (5, 213, N'ALGERIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (6, 376, N'ANDORRA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (7, 244, N'ANGOLA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (8, 1268, N'ANTIGUA AND BARBUDA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (9, 54, N'ARGENTINA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (10, 374, N'ARMENIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (11, 61, N'AUSTRALIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (12, 43, N'AUSTRIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (13, 994, N'AZERBAIJAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (14, 1242, N'BAHAMAS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (15, 973, N'BAHRAIN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (16, 880, N'BANGLADESH')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (17, 1246, N'BARBADOS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (18, 375, N'BELARUS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (19, 32, N'BELGIUM')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (20, 501, N'BELIZE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (21, 229, N'BENIN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (22, 975, N'BHUTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (23, 591, N'BOLIVIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (24, 387, N'BOSNIA AND HERZEGOVINA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (25, 267, N'BOTSWANA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (26, 55, N'BRAZIL')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (27, 673, N'BRUNEI DARUSSALAM')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (28, 359, N'BULGARIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (29, 226, N'BURKINA FASO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (30, 257, N'BURUNDI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (31, 855, N'CAMBODIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (32, 237, N'CAMEROON')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (33, 1, N'CANADA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (34, 238, N'CAPE VERDE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (35, 236, N'CENTRAL AFRICAN REPUBLIC')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (36, 235, N'CHAD')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (37, 56, N'CHILE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (38, 86, N'CHINA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (39, 57, N'COLOMBIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (40, 270, N'COMOROS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (41, 242, N'CONGO REPUBLIC OF THE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (42, 506, N'COSTA RICA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (43, 225, N'COTE DIVOIRE (IVORY COAST)')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (44, 385, N'CROATIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (45, 53, N'CUBA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (46, 357, N'CYPRUS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (47, 420, N'CZECH REPUBLIC')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (48, 850, N'DEMOCRATIC PEOPLES REPUBLIC OF KOREA (NORTH KOR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (49, 243, N'DEMOCRATIC REPUBLIC OF THE CONGO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (50, 45, N'DENMARK')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (51, 253, N'DJIBOUTI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (52, 1767, N'DOMINICA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (53, 1809, N'DOMINICAN REPUBLIC')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (54, 593, N'ECUADOR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (55, 20, N'EGYPT')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (56, 503, N'EL SALVADOR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (57, 240, N'EQUATORIAL GUINEA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (58, 291, N'ERITREA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (59, 372, N'ESTONIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (60, 251, N'ETHIOPIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (61, 679, N'FIJI ISLANDS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (62, 358, N'FINLAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (63, 33, N'FRANCE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (64, 241, N'GABON')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (65, 220, N'GAMBIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (66, 995, N'GEORGIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (67, 49, N'GERMANY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (68, 233, N'GHANA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (69, 30, N'GREECE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (70, 1473, N'GRENADA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (71, 502, N'GUATEMALA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (72, 224, N'GUINEA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (73, 245, N'GUINEA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (74, 592, N'GUYANA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (75, 509, N'HAITI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (76, 852, N'HONG KONG')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (77, 36, N'HUNGARY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (78, 354, N'ICELAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (79, 91, N'INDIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (80, 62, N'INDONESIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (81, 98, N'IRAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (82, 964, N'IRAQ')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (83, 353, N'IRELAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (84, 972, N'ISRAEL')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (85, 5, N'ITALY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (86, 1876, N'JAMAICA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (87, 81, N'JAPAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (88, 962, N'JORDAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (89, 7, N'KAZAKHSTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (90, 254, N'KENYA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (91, 686, N'KIRIBATI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (92, 965, N'KUWAIT')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (93, 996, N'KYRGYZSTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (94, 856, N'LAO PEOPLES DEMOCRATIC REPUBLIC')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (95, 371, N'LATVIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (96, 961, N'LEBANON')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (97, 266, N'LESOTHO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (98, 231, N'LIBERIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (99, 218, N'LIBYA')
GO
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (100, 423, N'LIECHTENSTEIN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (101, 370, N'LITHUANIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (102, 352, N'LUXEMBOURG')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (103, 389, N'MACEDONIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (104, 261, N'MADAGASCAR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (105, 265, N'MALAWI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (106, 60, N'MALAYSIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (107, 960, N'MALDIVES')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (108, 223, N'MALI')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (109, 356, N'MALTA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (110, 692, N'MARSHALL ISLANDS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (111, 222, N'MAURITANIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (112, 230, N'MAURITIUS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (113, 52, N'MEXICO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (114, 691, N'MICRONESIA FEDERATED STATES OF')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (115, 377, N'MONACO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (116, 976, N'MONGOLIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (117, 382, N'MONTENEGRO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (118, 212, N'MOROCCO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (119, 258, N'MOZAMBIQUE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (120, 95, N'MYANMAR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (121, 264, N'NAMIBIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (122, 674, N'NAURU')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (123, 977, N'NEPAL')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (124, 31, N'NETHERLANDS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (125, 64, N'NEW ZEALAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (126, 505, N'NICARAGUA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (127, 227, N'NIGER')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (128, 234, N'NIGERIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (129, 47, N'NORWAY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (130, 968, N'OMAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (131, 92, N'PAKISTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (132, 680, N'PALAU')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (133, 507, N'PANAMA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (134, 675, N'PAPUA NEW GUINEA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (135, 595, N'PARAGUAY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (136, 51, N'PERU')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (137, 63, N'PHILIPPINES')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (138, 48, N'POLAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (139, 14, N'PORTUGAL')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (140, 974, N'QATAR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (141, 82, N'REPUBLIC OF KOREA (SOUTH KOREA)')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (142, 373, N'REPUBLIC OF MOLDOVA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (143, 40, N'ROMANIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (144, 8, N'RUSSIAN FEDERATION')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (145, 250, N'RWANDA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (146, 1869, N'SAINT KITTS AND NEVIS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (147, 1758, N'SAINT LUCIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (148, 1784, N'SAINT VINCENT AND THE GRENADINES')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (149, 685, N'SAMOA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (150, 378, N'SAN MARINO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (151, 239, N'SAO TOME AND PRINCIPE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (152, 966, N'SAUDI ARABIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (153, 221, N'SENEGAL')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (154, 381, N'SERBIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (155, 248, N'SEYCHELLES')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (156, 232, N'SIERRA LEONE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (157, 65, N'SINGAPORE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (158, 421, N'SLOVAKIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (159, 386, N'SLOVENIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (160, 677, N'SOLOMON ISLANDS')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (161, 252, N'SOMALIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (162, 28, N'SOUTH AFRICA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (163, 211, N'SOUTH SUDAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (164, 35, N'SPAIN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (165, 94, N'SRI LANKA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (166, 249, N'SUDAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (167, 597, N'SURINAME')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (168, 268, N'SWAZILAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (169, 46, N'SWEDEN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (170, 41, N'SWITZERLAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (171, 963, N'SYRIAN ARAB REPUBLIC')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (172, 992, N'TAJIKISTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (173, 66, N'THAILAND')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (174, 670, N'TIMOR')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (175, 228, N'TOGO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (176, 676, N'TONGA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (177, 1868, N'TRINIDAD AND TOBAGO')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (178, 216, N'TUNISIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (179, 90, N'TURKEY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (180, 993, N'TURKMENISTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (181, 688, N'TUVALU')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (182, 256, N'UGANDA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (183, 380, N'UKRAINE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (184, 971, N'UNITED ARAB EMIRATES')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (185, 44, N'UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (186, 255, N'UNITED REPUBLIC OF TANZANIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (187, 2, N'UNITED STATES OF AMERICA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (188, 598, N'URUGUAY')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (189, 998, N'UZBEKISTAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (190, 678, N'VANUATU')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (191, 58, N'VENEZUELA BOLIVARIAN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (192, 84, N'VIETNAM')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (193, 967, N'YEMEN')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (194, 260, N'ZAMBIA')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (195, 263, N'ZIMBABWE')
INSERT [dbo].[Country] ([id], [code], [name]) VALUES (196, 504, N'HONDURAS')
SET IDENTITY_INSERT [dbo].[Country] OFF
GO
SET IDENTITY_INSERT [dbo].[District] ON 

INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (1, 1, 1, N'SOUTH ANDAMAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (2, 2, 1, N'NORTH AND MIDDLE ANDAMAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (3, 3, 1, N'NICOBAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (4, 4, 2, N'ANANTHAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (5, 5, 2, N'CUDDAPAH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (6, 6, 2, N'CHITTOOR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (7, 7, 2, N'KURNOOL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (8, 8, 2, N'KRISHNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (9, 9, 2, N'WEST GODAVARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (10, 10, 2, N'NELLORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (11, 11, 2, N'GUNTUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (12, 12, 2, N'PRAKASAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (13, 13, 2, N'VISAKHAPATNAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (14, 14, 2, N'SRIKAKULAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (15, 15, 2, N'VIZIANAGARAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (16, 16, 2, N'EAST GODAVARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (17, 17, 3, N'WEST KAMENG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (18, 18, 3, N'TAWANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (19, 19, 3, N'WEST SIANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (20, 20, 3, N'CHANGLANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (21, 21, 3, N'DIBANG VALLEY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (22, 22, 3, N'EAST KAMENG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (23, 23, 3, N'LOHIT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (24, 24, 3, N'KURUNG KUMEY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (25, 25, 3, N'LOWER SUBANSIRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (26, 26, 3, N'UPPER SUBANSIRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (27, 27, 3, N'UPPER SIANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (28, 28, 3, N'EAST SIANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (29, 29, 3, N'PAPUM PARE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (30, 30, 4, N'NALBARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (31, 31, 4, N'BARPETA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (32, 32, 4, N'KAMRUP')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (33, 33, 3, N'TIRAP')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (34, 34, 4, N'NAGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (35, 35, 4, N'KARBI ANGLONG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (36, 36, 4, N'MARIGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (37, 37, 4, N'GOALPARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (38, 38, 4, N'SONITPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (39, 39, 4, N'DARRANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (40, 40, 4, N'KOKRAJHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (41, 41, 4, N'BONGAIGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (42, 42, 4, N'DHUBRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (43, 43, 4, N'JORHAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (44, 44, 4, N'GOLAGHAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (45, 45, 4, N'SIBSAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (46, 46, 4, N'DIBRUGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (47, 47, 4, N'LAKHIMPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (48, 48, 4, N'DHEMAJI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (49, 49, 4, N'HAILAKANDI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (50, 50, 4, N'CACHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (51, 51, 4, N'NORTH CACHAR HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (52, 52, 4, N'TINSUKIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (53, 53, 4, N'KARIMGANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (54, 54, 5, N'PATNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (55, 55, 5, N'NALANDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (56, 56, 5, N'BHOJPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (57, 57, 5, N'ROHTAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (58, 58, 5, N'BUXAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (59, 59, 5, N'KAIMUR (BHABUA)')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (60, 60, 5, N'JAMUI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (61, 61, 5, N'LAKHISARAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (62, 62, 5, N'ARWAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (63, 63, 5, N'JEHANABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (64, 64, 5, N'GAYA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (65, 65, 5, N'NAWADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (66, 66, 5, N'MUNGER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (67, 67, 5, N'SHEIKHPURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (68, 68, 5, N'BANKA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (69, 69, 5, N'BEGUSARAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (70, 70, 5, N'BHAGALPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (71, 71, 5, N'AURANGABAD(BH)')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (72, 72, 5, N'MADHEPURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (73, 73, 5, N'SARAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (74, 74, 5, N'SIWAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (75, 75, 5, N'GOPALGANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (76, 76, 5, N'SITAMARHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (77, 77, 5, N'SHEOHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (78, 78, 5, N'MADHUBANI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (79, 79, 5, N'MUZAFFARPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (80, 80, 5, N'VAISHALI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (81, 81, 5, N'EAST CHAMPARAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (82, 82, 5, N'WEST CHAMPARAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (83, 83, 5, N'DARBHANGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (84, 84, 5, N'SAMASTIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (85, 85, 5, N'SAHARSA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (86, 86, 5, N'SUPAUL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (87, 87, 5, N'KHAGARIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (88, 88, 5, N'KATIHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (89, 89, 5, N'PURNIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (90, 90, 5, N'KISHANGANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (91, 91, 5, N'ARARIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (92, 92, 33, N'RAJNANDGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (93, 93, 33, N'DURG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (94, 94, 33, N'KAWARDHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (95, 95, 6, N'CHANDIGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (96, 96, 33, N'RAIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (97, 97, 33, N'MAHASAMUND')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (98, 98, 33, N'BASTAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (99, 99, 33, N'BIJAPUR')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (100, 100, 33, N'DANTEWADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (101, 101, 33, N'DHAMTARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (102, 102, 33, N'KANKER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (103, 103, 33, N'BILASPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (104, 104, 33, N'JANJGIR-CHAMPA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (105, 105, 33, N'KORBA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (106, 106, 33, N'NARAYANPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (107, 107, 33, N'SURGUJA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (108, 108, 11, N'RAJKOT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (109, 109, 33, N'RAIGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (110, 110, 33, N'JASHPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (111, 111, 11, N'JAMNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (112, 112, 33, N'KORIYA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (113, 113, 11, N'PORBANDAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (114, 114, 11, N'JUNAGADH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (115, 115, 7, N'DADRA & NAGAR HAVELI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (116, 116, 8, N'DIU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (117, 117, 8, N'DAMAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (118, 118, 9, N'SOUTH EAST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (119, 119, 9, N'NORTH DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (120, 120, 9, N'NORTH WEST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (121, 121, 9, N'WEST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (122, 122, 9, N'CENTRAL DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (123, 123, 9, N'SOUTH WEST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (124, 124, 9, N'NORTH EAST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (125, 125, 10, N'NORTH GOA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (126, 126, 10, N'SOUTH GOA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (127, 127, 11, N'BHAVNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (128, 128, 11, N'AMRELI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (129, 129, 11, N'SURENDRA NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (130, 130, 11, N'GANDHI NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (131, 131, 11, N'AHMEDABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (132, 132, 11, N'MAHESANA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (133, 133, 11, N'KACHCHH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (134, 134, 11, N'MORBI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (135, 135, 11, N'SABARKANTHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (136, 136, 11, N'PATAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (137, 137, 11, N'BANASKANTHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (138, 138, 11, N'KHEDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (139, 139, 11, N'ANAND')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (140, 140, 11, N'VADODARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (141, 141, 11, N'DAHOD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (142, 142, 11, N'PANCH MAHALS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (143, 143, 11, N'NARMADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (144, 144, 11, N'BHARUCH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (145, 145, 11, N'SURAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (146, 146, 11, N'THE DANGS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (147, 147, 11, N'NAVSARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (148, 148, 11, N'VALSAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (149, 149, 12, N'REWARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (150, 150, 12, N'MAHENDRAGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (151, 151, 12, N'ROHTAK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (152, 152, 12, N'JHAJJAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (153, 153, 12, N'FARIDABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (154, 154, 12, N'GURGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (155, 155, 12, N'FATEHABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (156, 156, 12, N'HISAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (157, 157, 12, N'SIRSA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (158, 158, 12, N'AMBALA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (159, 159, 13, N'SHIMLA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (160, 160, 12, N'JIND')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (161, 161, 12, N'KARNAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (162, 162, 12, N'PANIPAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (163, 163, 12, N'YAMUNA NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (164, 164, 12, N'PANCHKULA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (165, 165, 12, N'BHIWANI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (166, 166, 12, N'KAITHAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (167, 167, 12, N'KURUKSHETRA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (168, 168, 12, N'SONIPAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (169, 169, 13, N'KULLU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (170, 170, 13, N'KINNAUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (171, 171, 13, N'SOLAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (172, 172, 13, N'LAHUL & SPITI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (173, 173, 13, N'SIRMAUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (174, 174, 13, N'HAMIRPUR(HP)')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (175, 175, 13, N'UNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (176, 176, 13, N'BILASPUR (HP)')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (177, 177, 13, N'MANDI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (178, 178, 13, N'KANGRA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (179, 179, 13, N'CHAMBA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (180, 180, 14, N'JAMMU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (181, 181, 14, N'UDHAMPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (182, 182, 14, N'KATHUA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (183, 183, 14, N'DODA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (184, 184, 14, N'POONCH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (185, 185, 14, N'RAJAURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (186, 186, 14, N'SRINAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (187, 187, 14, N'KUPWARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (188, 188, 14, N'ANANTHNAG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (189, 189, 14, N'BARAMULLA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (190, 190, 14, N'PULWAMA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (191, 191, 14, N'BUDGAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (192, 192, 14, N'BANDIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (193, 193, 14, N'LEH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (194, 194, 14, N'KARGIL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (195, 195, 35, N'SAHIBGANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (196, 196, 35, N'DUMKA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (197, 197, 35, N'GODDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (198, 198, 35, N'DEOGHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (199, 199, 35, N'JAMTARA')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (200, 200, 35, N'PAKUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (201, 201, 35, N'GIRIDH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (202, 202, 35, N'PALAMAU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (203, 203, 35, N'GARHWA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (204, 204, 35, N'LATEHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (205, 205, 35, N'BOKARO')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (206, 206, 35, N'KODERMA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (207, 207, 35, N'HAZARIBAG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (208, 208, 35, N'CHATRA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (209, 209, 35, N'RAMGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (210, 210, 35, N'DHANBAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (211, 211, 35, N'WEST SINGHBHUM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (212, 212, 35, N'SERAIKELA-KHARSAWAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (213, 213, 35, N'EAST SINGHBHUM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (214, 214, 35, N'RANCHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (215, 215, 35, N'SIMDEGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (216, 216, 35, N'KHUNTI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (217, 217, 35, N'GUMLA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (218, 218, 35, N'LOHARDAGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (219, 219, 15, N'BANGALORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (220, 220, 15, N'BANGALORE RURAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (221, 221, 15, N'KOLAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (222, 222, 15, N'CHIKKABALLAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (223, 223, 15, N'RAMANAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (224, 224, 15, N'TUMKUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (225, 225, 15, N'Mysuru')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (226, 226, 15, N'CHAMRAJNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (227, 227, 15, N'MANDYA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (228, 228, 15, N'KODAGU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (229, 229, 15, N'UDUPI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (230, 230, 15, N'DAKSHINA KANNADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (231, 231, 15, N'HASSAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (232, 232, 15, N'DAVANGARE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (233, 233, 15, N'CHICKMAGALUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (234, 234, 15, N'SHIMOGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (235, 235, 15, N'CHITRADURGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (236, 236, 15, N'GADAG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (237, 237, 15, N'DHARWARD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (238, 238, 15, N'UTTARA KANNADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (239, 239, 15, N'BELLARY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (240, 240, 15, N'HAVERI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (241, 241, 15, N'KOPPAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (242, 242, 15, N'BELGAUM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (243, 243, 15, N'GULBARGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (244, 244, 15, N'BIJAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (245, 245, 15, N'BAGALKOT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (246, 246, 15, N'RAICHUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (247, 247, 15, N'BIDAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (248, 248, 16, N'KOLLAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (249, 249, 16, N'KANNUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (250, 250, 16, N'PALAKKAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (251, 251, 16, N'IDUKKI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (252, 252, 16, N'PATHANAMTHITTA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (253, 253, 16, N'WAYANAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (254, 254, 16, N'KOTTAYAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (255, 255, 16, N'THIRUVANANTHAPURAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (256, 256, 16, N'THRISSUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (257, 257, 16, N'MALAPPURAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (258, 258, 16, N'ALAPPUZHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (259, 259, 16, N'KASARGOD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (260, 260, 16, N'KOZHIKODE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (261, 261, 16, N'ERNAKULAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (262, 262, 17, N'LAKSHADWEEP')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (263, 263, 18, N'EAST NIMAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (264, 264, 18, N'WEST NIMAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (265, 265, 18, N'BARWANI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (266, 266, 18, N'DHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (267, 267, 18, N'INDORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (268, 268, 18, N'DEWAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (269, 269, 18, N'UJJAIN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (270, 270, 18, N'MANDSAUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (271, 271, 18, N'RATLAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (272, 272, 18, N'JHABUA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (273, 273, 18, N'BETUL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (274, 274, 18, N'SHAJAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (275, 275, 18, N'NEEMUCH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (276, 276, 18, N'CHHINDWARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (277, 277, 18, N'HARDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (278, 278, 18, N'HOSHANGABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (279, 279, 18, N'NARSINGHPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (280, 280, 18, N'VIDISHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (281, 281, 18, N'RAISEN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (282, 282, 18, N'BHOPAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (283, 283, 18, N'SAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (284, 284, 18, N'RAJGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (285, 285, 18, N'SEHORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (286, 286, 18, N'DAMOH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (287, 287, 18, N'CHHATARPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (288, 288, 18, N'GUNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (289, 289, 18, N'SHIVPURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (290, 290, 18, N'PANNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (291, 291, 18, N'TIKAMGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (292, 292, 18, N'MORENA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (293, 293, 18, N'GWALIOR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (294, 294, 18, N'DATIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (295, 295, 18, N'BHIND')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (296, 296, 18, N'SHEOPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (297, 297, 18, N'SEONI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (298, 298, 18, N'BALAGHAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (299, 299, 18, N'MANDLA')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (300, 300, 18, N'DINDORI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (301, 301, 18, N'UMARIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (302, 302, 18, N'JABALPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (303, 303, 18, N'KATNI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (304, 304, 18, N'ANUPPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (305, 305, 18, N'SIDHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (306, 306, 18, N'SHAHDOL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (307, 307, 18, N'SATNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (308, 308, 18, N'REWA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (309, 309, 19, N'RAIGARH(MH)')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (310, 310, 19, N'THANE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (311, 311, 19, N'MUMBAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (312, 312, 19, N'AHMED NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (313, 313, 19, N'AURANGABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (314, 314, 19, N'PUNE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (315, 315, 19, N'SOLAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (316, 316, 19, N'OSMANABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (317, 317, 19, N'LATUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (318, 318, 19, N'SATARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (319, 319, 19, N'BEED')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (320, 320, 19, N'RATNAGIRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (321, 321, 19, N'SANGLI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (322, 322, 19, N'KOLHAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (323, 323, 19, N'SINDHUDURG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (324, 324, 19, N'NASHIK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (325, 325, 19, N'NANDURBAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (326, 326, 19, N'JALGAON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (327, 327, 19, N'DHULE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (328, 328, 19, N'JALNA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (329, 329, 19, N'PARBHANI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (330, 330, 19, N'NANDED')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (331, 331, 19, N'HINGOLI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (332, 332, 19, N'GONDIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (333, 333, 19, N'BHANDARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (334, 334, 19, N'CHANDRAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (335, 335, 19, N'WARDHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (336, 336, 19, N'GADCHIROLI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (337, 337, 19, N'NAGPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (338, 338, 19, N'BULDHANA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (339, 339, 19, N'AMRAVATI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (340, 340, 19, N'WASHIM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (341, 341, 19, N'AKOLA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (342, 342, 20, N'CHANDEL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (343, 343, 20, N'THOUBAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (344, 344, 20, N'CHURACHANDPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (345, 345, 20, N'SENAPATI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (346, 346, 20, N'IMPHAL WEST')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (347, 347, 19, N'YAVATMAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (348, 348, 20, N'IMPHAL EAST')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (349, 349, 20, N'TAMENGLONG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (350, 350, 20, N'UKHRUL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (351, 351, 20, N'BISHNUPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (352, 352, 21, N'WEST KHASI HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (353, 353, 21, N'EAST KHASI HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (354, 354, 21, N'WEST GARO HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (355, 355, 21, N'SOUTH GARO HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (356, 356, 21, N'RI BHOI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (357, 357, 21, N'EAST GARO HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (358, 358, 21, N'JAINTIA HILLS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (359, 359, 24, N'KHORDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (360, 360, 24, N'PURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (361, 361, 23, N'PHEK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (362, 362, 23, N'ZUNHEBOTTO')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (363, 363, 23, N'KOHIMA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (364, 364, 23, N'DIMAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (365, 365, 23, N'PEREN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (366, 366, 23, N'WOKHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (367, 367, 24, N'NAYAGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (368, 368, 23, N'MOKOKCHUNG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (369, 369, 23, N'TUENSANG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (370, 370, 23, N'MON')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (371, 371, 23, N'KIPHIRE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (372, 372, 22, N'AIZAWL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (373, 373, 22, N'KOLASIB')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (374, 374, 22, N'MAMMIT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (375, 375, 22, N'LUNGLEI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (376, 376, 22, N'SERCHHIP')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (377, 377, 23, N'LONGLENG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (378, 378, 22, N'CHAMPHAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (379, 379, 22, N'LAWNGTLAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (380, 380, 22, N'SAIHA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (381, 381, 24, N'CUTTACK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (382, 382, 24, N'JAGATSINGHAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (383, 383, 24, N'KENDRAPARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (384, 384, 24, N'JAJAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (385, 385, 24, N'BALESWAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (386, 386, 24, N'KENDUJHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (387, 387, 24, N'BHADRAK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (388, 388, 24, N'MAYURBHANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (389, 389, 24, N'DHENKANAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (390, 390, 24, N'ANGUL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (391, 391, 24, N'GANJAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (392, 392, 24, N'GAJAPATI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (393, 393, 24, N'KORAPUT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (394, 394, 24, N'BOUDH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (395, 395, 24, N'KANDHAMAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (396, 396, 24, N'MALKANGIRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (397, 397, 24, N'RAYAGADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (398, 398, 24, N'NABARANGAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (399, 399, 24, N'KALAHANDI')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (400, 400, 24, N'NUAPADA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (401, 401, 24, N'SAMBALPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (402, 402, 24, N'BALANGIR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (403, 403, 24, N'SONAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (404, 404, 24, N'DEBAGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (405, 405, 24, N'BARGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (406, 406, 24, N'JHARSUGUDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (407, 407, 24, N'SUNDERGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (408, 408, 25, N'KARAIKAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (409, 409, 26, N'RUPNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (410, 410, 26, N'PATIALA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (411, 411, 26, N'FATEHGARH SAHIB')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (412, 412, 25, N'PONDICHERRY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (413, 413, 26, N'JALANDHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (414, 414, 26, N'HOSHIARPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (415, 415, 26, N'LUDHIANA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (416, 416, 26, N'AMRITSAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (417, 417, 26, N'TARN TARAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (418, 418, 26, N'GURDASPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (419, 419, 26, N'Pathankot')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (420, 420, 26, N'NAWANSHAHR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (421, 421, 26, N'SANGRUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (422, 422, 26, N'MOGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (423, 423, 26, N'FIROZPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (424, 424, 26, N'KAPURTHALA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (425, 425, 26, N'BARNALA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (426, 426, 26, N'Fazilka')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (427, 427, 26, N'MUKTSAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (428, 428, 26, N'BATHINDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (429, 429, 26, N'FARIDKOT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (430, 430, 26, N'MANSA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (431, 431, 27, N'TONK')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (432, 432, 27, N'ALWAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (433, 433, 27, N'JAIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (434, 434, 27, N'DAUSA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (435, 435, 27, N'AJMER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (436, 436, 27, N'NAGAUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (437, 437, 27, N'RAJSAMAND')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (438, 438, 27, N'PALI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (439, 439, 27, N'BHILWARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (440, 440, 27, N'SIROHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (441, 441, 27, N'UDAIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (442, 442, 27, N'JALOR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (443, 443, 27, N'CHITTORGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (444, 444, 27, N'BHARATPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (445, 445, 27, N'KARAULI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (446, 446, 27, N'SAWAI MADHOPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (447, 447, 27, N'DUNGARPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (448, 448, 27, N'BUNDI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (449, 449, 27, N'BANSWARA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (450, 450, 27, N'BARAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (451, 451, 27, N'JHALAWAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (452, 452, 27, N'KOTA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (453, 453, 27, N'DHOLPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (454, 454, 27, N'SIKAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (455, 455, 27, N'JHUJHUNU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (456, 456, 27, N'GANGANAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (457, 457, 27, N'HANUMANGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (458, 458, 27, N'BIKANER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (459, 459, 27, N'CHURU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (460, 460, 27, N'JAISALMER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (461, 461, 27, N'JODHPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (462, 462, 27, N'BARMER')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (463, 463, 29, N'KANCHIPURAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (464, 464, 28, N'SOUTH SIKKIM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (465, 465, 28, N'EAST SIKKIM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (466, 466, 28, N'WEST SIKKIM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (467, 467, 28, N'NORTH SIKKIM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (468, 468, 29, N'VILLUPURAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (469, 469, 29, N'VELLORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (470, 470, 29, N'CHENNAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (471, 471, 29, N'TIRUVALLUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (472, 472, 29, N'CUDDALORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (473, 473, 29, N'TIRUVANNAMALAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (474, 474, 29, N'NAGAPATTINAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (475, 475, 29, N'ARIYALUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (476, 476, 29, N'TIRUVARUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (477, 477, 29, N'THANJAVUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (478, 478, 29, N'PUDUKKOTTAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (479, 479, 29, N'TIRUCHIRAPPALLI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (480, 480, 29, N'PERAMBALUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (481, 481, 29, N'SIVAGANGA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (482, 482, 29, N'KARUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (483, 483, 29, N'SALEM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (484, 484, 29, N'NAMAKKAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (485, 485, 29, N'RAMANATHAPURAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (486, 486, 29, N'DINDIGUL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (487, 487, 29, N'VIRUDHUNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (488, 488, 29, N'MADURAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (489, 489, 29, N'TUTICORIN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (490, 490, 29, N'THENI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (491, 491, 29, N'TIRUNELVELI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (492, 492, 29, N'TIRUPPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (493, 493, 29, N'KANYAKUMARI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (494, 494, 29, N'KRISHNAGIRI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (495, 495, 29, N'DHARMAPURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (496, 496, 29, N'ERODE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (497, 497, 29, N'COIMBATORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (498, 498, 29, N'NILGIRIS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (499, 499, 36, N'MEDAK')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (500, 500, 36, N'ADILABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (501, 501, 36, N'HYDERABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (502, 502, 36, N'K.V.RANGAREDDY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (503, 503, 36, N'NIZAMABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (504, 504, 36, N'KHAMMAM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (505, 505, 36, N'KARIM NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (506, 506, 36, N'WARANGAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (507, 507, 36, N'NALGONDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (508, 508, 36, N'MAHABUB NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (509, 509, 30, N'WEST TRIPURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (510, 510, 30, N'SOUTH TRIPURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (511, 511, 31, N'HATHRAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (512, 512, 31, N'ALIGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (513, 513, 30, N'DHALAI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (514, 514, 30, N'NORTH TRIPURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (515, 515, 31, N'GHAZIABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (516, 516, 31, N'BULANDSHAHR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (517, 517, 31, N'GAUTAM BUDDHA NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (518, 518, 31, N'MAINPURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (519, 519, 31, N'FIROZABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (520, 520, 31, N'AURAIYA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (521, 521, 31, N'ETAWAH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (522, 522, 31, N'ETAH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (523, 523, 31, N'FARRUKHABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (524, 524, 31, N'KANNAUJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (525, 525, 31, N'KANPUR DEHAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (526, 526, 31, N'KANPUR NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (527, 527, 31, N'AGRA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (528, 528, 31, N'UNNAO')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (529, 529, 31, N'BANDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (530, 530, 31, N'CHITRAKOOT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (531, 531, 31, N'HAMIRPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (532, 532, 31, N'ALLAHABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (533, 533, 31, N'KAUSHAMBI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (534, 534, 31, N'MAHOBA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (535, 535, 31, N'SANT RAVIDAS NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (536, 536, 31, N'VARANASI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (537, 537, 31, N'FATEHPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (538, 538, 31, N'CHANDAULI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (539, 539, 31, N'BALLIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (540, 540, 31, N'JAUNPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (541, 541, 31, N'SULTANPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (542, 542, 31, N'MAU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (543, 543, 31, N'AZAMGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (544, 544, 31, N'AMBEDKAR NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (545, 545, 31, N'FAIZABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (546, 546, 31, N'BARABANKI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (547, 547, 31, N'LUCKNOW')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (548, 548, 31, N'RAEBARELI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (549, 549, 31, N'MIRZAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (550, 550, 31, N'SONBHADRA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (551, 551, 31, N'PRATAPGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (552, 552, 31, N'GHAZIPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (553, 553, 31, N'HARDOI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (554, 554, 31, N'SHAHJAHANPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (555, 555, 31, N'BAREILLY')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (556, 556, 31, N'BUDAUN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (557, 557, 31, N'PILIBHIT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (558, 558, 31, N'RAMPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (559, 559, 31, N'MORADABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (560, 560, 31, N'JYOTIBA PHULE NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (561, 561, 31, N'BIJNOR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (562, 562, 31, N'MUZAFFARNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (563, 563, 31, N'SAHARANPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (564, 564, 31, N'MEERUT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (565, 565, 31, N'BAGPAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (566, 566, 31, N'SITAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (567, 567, 31, N'KHERI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (568, 568, 31, N'SHRAWASTI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (569, 569, 31, N'BAHRAICH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (570, 570, 31, N'GONDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (571, 571, 31, N'BALRAMPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (572, 572, 31, N'BASTI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (573, 573, 31, N'SANT KABIR NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (574, 574, 31, N'SIDDHARTHNAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (575, 575, 31, N'GORAKHPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (576, 576, 31, N'MAHARAJGANJ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (577, 577, 31, N'DEORIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (578, 578, 31, N'KUSHINAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (579, 579, 31, N'JHANSI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (580, 580, 31, N'JALAUN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (581, 581, 31, N'MATHURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (582, 582, 31, N'LALITPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (583, 583, 34, N'UDHAM SINGH NAGAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (584, 584, 34, N'NAINITAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (585, 585, 34, N'ALMORA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (586, 586, 34, N'CHAMOLI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (587, 587, 34, N'RUDRAPRAYAG')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (588, 588, 34, N'PAURI GARHWAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (589, 589, 34, N'DEHRADUN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (590, 590, 34, N'UTTARKASHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (591, 591, 34, N'TEHRI GARHWAL')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (592, 592, 34, N'HARIDWAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (593, 593, 34, N'CHAMPAWAT')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (594, 594, 34, N'PITHORAGARH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (595, 595, 32, N'BARDHAMAN')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (596, 596, 34, N'BAGESHWAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (597, 597, 32, N'NORTH 24 PARGANAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (598, 598, 32, N'HOWRAH')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (599, 599, 32, N'HOOGHLY')
GO
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (600, 600, 32, N'SOUTH 24 PARGANAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (601, 601, 32, N'MURSHIDABAD')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (602, 602, 32, N'KOLKATA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (603, 603, 32, N'WEST MIDNAPORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (604, 604, 32, N'EAST MIDNAPORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (605, 605, 32, N'BANKURA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (606, 606, 32, N'Purulia')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (607, 607, 32, N'NADIA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (608, 608, 32, N'BIRBHUM')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (609, 609, 32, N'MALDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (610, 610, 32, N'NORTH DINAJPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (611, 611, 32, N'SOUTH DINAJPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (612, 612, 32, N'JALPAIGURI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (613, 613, 32, N'COOCH BEHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (614, 614, 32, N'DARJILING')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (615, 615, 15, N'MYSORE')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (616, 616, 32, N'ALIPURDUAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (617, 617, 9, N'SOUTH DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (618, 621, 31, N'HAPUR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (619, 622, 9, N'EAST DELHI')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (620, 624, 19, N'PALGHAR')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (621, 625, 9, N'New Delhi')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (622, 627, 34, N'Haridwar ')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (623, 628, 34, N'Saharanpur')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (624, 629, 31, N'NOIDA')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (625, 630, 15, N'BENGALURU')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (626, 631, 32, N'PARGANAS')
INSERT [dbo].[District] ([id], [code], [stateCode], [name]) VALUES (627, 632, 32, N'BANKUR')
SET IDENTITY_INSERT [dbo].[District] OFF
GO
SET IDENTITY_INSERT [dbo].[State] ON 

INSERT [dbo].[State] ([id], [code], [name]) VALUES (1, 2, N'Andhra Pradesh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (2, 3, N'Arunachal Pradesh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (3, 4, N'Assam')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (4, 5, N'Bihar')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (5, 6, N'Chandigarh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (6, 8, N'Daman and Diu')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (7, 9, N'Delhi')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (8, 10, N'Goa')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (9, 11, N'Gujarat')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (10, 12, N'Haryana')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (11, 13, N'Himachal Pradesh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (12, 14, N'Jammu and Kashmir')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (13, 15, N'Karnataka')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (14, 16, N'Kerala')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (15, 17, N'Lakshadweep')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (16, 18, N'Madhya Pradesh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (17, 19, N'Maharashtra')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (18, 20, N'Manipur')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (19, 22, N'Mizoram')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (20, 23, N'Nagaland')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (21, 24, N'Odisha')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (22, 26, N'Punjab')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (23, 27, N'Rajasthan')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (24, 28, N'Sikkim')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (25, 29, N'Tamil Nadu')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (26, 30, N'Tripura')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (27, 31, N'Uttar Pradesh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (28, 32, N'West Bengal')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (29, 34, N'Uttarakhand')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (30, 35, N'Jharkhand')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (31, 36, N'Telangana')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (32, 99, N'Foreign')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (33, 37, N'Ladakh')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (34, 1, N'Andaman And Nicobar Islands')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (35, 7, N'Dadra & Nagar Haveli')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (36, 21, N'Meghalaya')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (37, 25, N'Puducherry')
INSERT [dbo].[State] ([id], [code], [name]) VALUES (38, 33, N'Chhattisgarh')
SET IDENTITY_INSERT [dbo].[State] OFF
GO
SET IDENTITY_INSERT [dbo].[Tdsded80] ON 

INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (1, N'80C', N'Life Insurance/PPF/NSC/ELSS/Housing Loan Principal/Tuition Fee', NULL, N'Total Investment u/s 80C', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80C', N'80C', 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (2, N'80D', N'Medical Insurance Premium', NULL, N'Self/Family Premium', N'Self/Family Premium (Sr.Citizen)', N'Parents Premium', N'Parents Premium (Sr.Citizen)', N'', N'', N'', N'', N'', N'', N'COMPLEX', 0, N'80D', N'80D', 1, 1, 1, 1, 0, 0, 0, 0, 2, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (3, N'80DD', N'Maintenance of Disabled Dependent', NULL, N'Medical Expenditure', N'Insurance Premium', N'', N'', N'', N'', N'', N'', N'', N'', N'FIXED', 0, N'80DD', N'80DD', 1, 1, 0, 0, 0, 0, 0, 0, 3, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (4, N'80E', N'Interest on Education Loan', NULL, N'Interest Amount Paid', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'FULL', 0, N'80E', N'80E', 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (5, N'80GG', N'Rent Paid (No HRA received)', NULL, N'Rent Paid', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'COMPLEX', 0, N'80GG', N'80GG', 1, 1, 0, 0, 0, 0, 0, 0, 5, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (6, N'80DDB', N'Medical Treatment of Specified Disease', NULL, N'Medical Expenditure', N'Insurance Reimbursement', N'', N'', N'', N'', N'', N'', N'', N'', N'FIXED', 0, N'80DDB', N'80DDB', 1, 1, 1, 1, 0, 0, 0, 0, 6, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (7, N'80CCC', N'Pension Fund Contribution', NULL, N'Contribution Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80CCC', N'80CCC', 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (8, N'80CCD', N'NPS Contribution (Employee)', NULL, N'Employee Contribution', N'Employer Contribution', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80CCD', N'80CCD', 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (9, N'80CCF', N'Infrastructure Bond', NULL, N'Investment Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80CCF', N'80CCF', 1, 1, 1, 1, 0, 0, 0, 0, 9, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (10, N'80G', N'Donations to Charitable Institutions', NULL, N'100% Deduction (Govt)', N'50% Deduction', N'10% of GTI Deduction (100%)', N'10% of GTI Deduction (50%)', N'', N'', N'', N'', N'', N'', N'COMPLEX', 0, N'80G', N'80G', 1, 1, 1, 1, 1, 1, 1, 1, 10, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (11, N'80GGA', N'Donation for Scientific Research', NULL, N'Donation Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'FULL', 0, N'80GGA', N'80GGA', 1, 1, 1, 1, 1, 1, 1, 1, 11, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (12, N'80GGC', N'Donation to Political Party', NULL, N'Donation Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'FULL', 0, N'80GGC', N'80GGC', 1, 1, 1, 1, 1, 1, 1, 1, 12, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (13, N'80TTA', N'Interest on Savings Account', NULL, N'Interest Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80TTA', N'80TTA', 1, 1, 1, 1, 0, 0, 0, 0, 13, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (14, N'80U', N'Disability of Self', NULL, N'Self Disability', N'Severe Disability', N'', N'', N'', N'', N'', N'', N'', N'', N'FIXED', 0, N'80U', N'80U', 1, 0, 0, 0, 0, 0, 0, 0, 14, 0, 0)
INSERT [dbo].[Tdsded80] ([ded80id], [dedsec], [ded80name], [ded80table], [label1], [label2], [label3], [label4], [label5], [label6], [label7], [label8], [label9], [label10], [dedtype], [pdedid], [section], [short], [ind], [indnr], [huf], [hufnr], [firm], [company], [companynr], [coop], [sortid], [ayid], [ayid2]) VALUES (15, N'80EE', N'Interest on Housing Loan (First Time)', NULL, N'Interest Amount', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'CAP', 0, N'80EE', N'80EE', 1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0)
SET IDENTITY_INSERT [dbo].[Tdsded80] OFF
GO
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'192', 21, N'SALARY', 0, N'24Q', N'392')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'192A', 57, N'Payment to resident u/s 192A', 50000, N'26Q', N'392(7)')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'193', 1, N'INTEREST ON SECURITIES', 10000, N'26Q', N'393(1) [Sl.No.5(i)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194', 58, N'Payment to resident u/s 194', 10000, N'26Q', N'393(1) [Sl.No.7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194A', 6, N'INTEREST OTHER THAN INTEREST ON SECURITIES', 10000, N'26Q', N'393(1) [Sl.No.5(iii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194B', 14, N'WINNING FROM LOTTERIES', 10000, N'26Q', N'393(3) [Sl.No.1]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194C', 2, N'PAYMENT MADE TO CONTRACTORS', 30000, N'26Q', N'393(1) [Sl.No.6(i).D(a)/D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194C', 3, N'PAYMENT MADE TO ADVERTISING CONTRACTORS', 30000, N'26Q', N'393(1) [Sl.No.6(i).D(a)/D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194C', 4, N'PAYMENT MADE TO SUB CONTRACTORS', 30000, N'26Q', N'393(1) [Sl.No.6(i).D(a)/D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194D', 9, N'INSURANCE COMMISSION', 20000, N'26Q', N'393(1) [Sl.No.1(i)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194DA', 52, N'Payment in respect of life insurance policy', 100000, N'26Q', N'393(1) [Sl.No.8(i)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194E', 99, N'Payment to NRI u/s194E', 0, N'26Q', N'393(1) [Sl.No.7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194EE', 22, N'NSS', 2500, N'26Q', N'393(3) [Sl.No.6]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194G', 23, N'COMMISSION ON SALE OF LOTTERY TICKETS', 20000, N'26Q', N'393(3) [Sl.No.4]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194H', 10, N'COMMISSION OR BROKERAGE', 20000, N'26Q', N'393(1) [Sl.No.1(ii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194I', 5, N'RENT', 120000, N'26Q', N'393(1) [Sl.No.2(ii).D(a)/D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194IA', 60, N'Payment u/s 194IA', 0, N'26Q', N'(393(1)[Sl.No.3(i)])')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194IC', 61, N'Payment u/s 194IC', 0, N'26Q', N'(393(1)[Sl.No.3(ii)])')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194J', 8, N'FEES FOR PROFEESIONAL / TECH. SERVICES', 50000, N'26Q', N'393(1) [Sl.No.6(iii).D(a)/D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LA', 40, N'Compensation on Acquisition of Immovable Properties', 500000, N'26Q', N'393(1) [Sl.No.3(iii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LAA', 41, N'Transfer on Immovable Property', 0, N'26Q', N'393(1)[Sl.7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LB', 50, N'Payment to NRI u/s 194LB', 0, N'26Q', N'393(2) [Sl.No.5]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBA', 53, N'Payment of the nature referred to in section 10(23FC)', 0, N'26Q', N'393(1) [Sl.No.4(ii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBA', 54, N'Payment of the nature referred to in section 10(23FC)', 0, N'26Q', N'393(2) [Sl.No.6 and 7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBB', 55, N'Payment to non-resident u/s 194LBB', 0, N'26Q', N'393(2) [Sl.No.8]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBB', 56, N'Payment to resident u/s 194LBB', 0, N'26Q', N'393(1) [Sl.No.4(iii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LC', 51, N'Payment to NRI u/s 194LC', 0, N'26Q', N'393(2) [Sl.No.2,3 and 4]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LD', 62, N'Payment to resident u/s 194LD', 0, N'26Q', N'393(2)')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194N', 63, N'Payment u/s 194N', 0, N'26Q', N'393(3) [Sl.No.5D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194O', 67, N'TDS on E-commerce transactions', 0, N'26Q', N'393(1) [Sl.No.8(v)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194Q', 70, N'TDS on purchase of goods u/s 194Q', 0, N'26Q', N'393(1) [Sl.No.8(ii)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'195', 11, N'NRI INTT. ON FORIEGN LOAN', 0, N'27Q', N'393(2) [Sl.No.17]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'195', 12, N'NRI LTC GAIN FOREIGNER', 0, N'27Q', N'393(2) [Sl.No.17]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'195', 13, N'NRI ANY OTHER INCOME', 0, N'27Q', N'393(2) [Sl.No.17]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'196C', 65, N'Payment to NRI u/s 196C', 0, N'27Q', N'393(2) [Sl.No.13 and 14]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'196D', 66, N'Payment to NRI u/s 196D', 0, N'27Q', N'393(2) [Sl.No.15 and 16]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 30, N'TCS - Sale of Alcholic Liquor', 0, N'27EQ', N'394(1) [Table: Sl. No. 1]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 31, N'TCS - Sale of Timber under Forest Lease', 0, N'27EQ', N'394(1) [Table: Sl. No. 3]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 32, N'TCS - Sale of Timber other than Forest Lease', 0, N'27EQ', N'394(1) [Table: Sl. No. 3]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 33, N'TCS - Sale of Forest Produce', 0, N'27EQ', N'394(1) [Table: Sl. No. 3]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 34, N'TCS - Sale of Scrap', 0, N'27EQ', N'394(1) [Table: Sl. No. 4]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 35, N'TCS - Mining', 0, N'27EQ', N'394(1) [Table: Sl. No. 9]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 37, N'TCS - Toll Plaza', 0, N'27EQ', N'394(1) [Table: Sl. No. 9]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 38, N'TCS - Car Parking', 0, N'27EQ', N'394(1) [Table: Sl. No. 9]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 42, N'TCS - Sale of Coal, Lignite and Iron', 0, N'27EQ', N'394(1) [Table: Sl. No. 5]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 43, N'TCS - Sale of Bullion and jewellery', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 44, N'TCS - Sale of Motor Vehciles', 0, N'27EQ', N'394(1) [Table: Sl. No. 6(a)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 45, N'TCS- Sale of Goods > 2 lacs', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 46, N'Providing of any services (other than Ch-XVII-B) > 2lac', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 48, N'Sale of Good > 50 lacs', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 49, N'LRS for purpose other than for purchase of overseas tour package or for educational loan taken from financial institution', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'206C', 81, N'LRS for purpose for purchase of overseas tour package', 0, N'27EQ', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194R', 71, N'Payment u/s 194R', 20000, N'26Q', N'393(1) [Sl.No.8(iv)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194S', 72, N'Payment u/s 194S', 10000, N'26Q', N'393(1) [Sl.No.8(vi)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194T', 75, N'Payment u/s 194T', 20000, N'26Q', N'393(3) [Sl.No.7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194B-P', 76, N'Winnings from lottery (consideration in kind or cash insufficient)', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194BB', 77, N'Payment u/s 194BB', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194F', 78, N'Payment u/s 194F', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194I(a)', 79, N'RENT - Plant and Machinery', 120000, N'26Q', N'393(1)[Sl. No.2(ii)D(a)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194I(b)', 80, N'RENT - Land, Building or Furniture/Fittings', 120000, N'26Q', N'393(1)[Sl. No.2(ii)D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBC', 82, N'Income in respect of investment in securitization trust', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194K', 83, N'Income From Mutual Fund Units', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194J(a)', 84, N'Fees for Technical Services (not professional), royalty, call centre @2%', 50000, N'26Q', N'393(1)[Sl. No.6(iii)D(a)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194J(b)', 85, N'Fee for professional service or royalty @10%', 50000, N'26Q', N'393(1)[Sl. No.6(iii)D(b)]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBA(a)', 86, N'Interest from units of a business trust to resident unit holder', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBA(b)', 87, N'Dividend from units of a business trust to resident unit holder', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194NF', 88, N'Payment in cash to non-filers (except co-operative societies)', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194RP', 89, N'Benefits or perquisites (benefit in kind or cash insufficient)', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194SP', 90, N'Payment for transfer of VDA (in kind or in exchange)', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194BA', 91, N'Winnings from online games', 0, N'26Q', N'394')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194BA-P', 92, N'Net Winnings from online games (in kind or cash insufficient)', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194NC', 93, N'Payment in cash to co-operative societies', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194N-FT', 94, N'Payment in cash to non-filers being co-operative societies', 0, N'26Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'196A', 95, N'Payment to NRI u/s 196A', 0, N'27Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'196B', 96, N'Payment to NRI u/s 196B', 0, N'27Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LC1', 97, N'Income under clause (i) and (ia) of sub-section (2) of section 194LC', 0, N'27Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LC2', 98, N'Income under clause (ib) of sub-section (2) of section 194LC', 0, N'27Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LC3', 99, N'Income under clause (ic) of sub-section (2) of section 194LC', 0, N'27Q', N'393(1) [Sl.No.7]')
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'194LBA(c)', 100, N'Income referred to in section 10(23FCA) from units of a business trust', 0, N'27Q', NULL)
INSERT [dbo].[TdsEntriesSection] ([Section], [Paycode], [Name], [Limit], [FormName], [NewSection]) VALUES (N'196D(1A)', 101, N'Income of specified fund from securities u/s 115AD (other than interest u/s 194LD)', 0, N'27Q', NULL)
GO
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'Select', 0)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'ADVERTISEMENT FEE', 1)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'AMC CHARGES', 2)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'ARCHITECTURAL SERVICES', 3)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'BANDWIDTH CHARGES', 4)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'BROKEREAGE CHARGES', 5)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'BUSINESS INCOME OTHER THAN THAT COVERED BY CATEGORIES ABOVE', 6)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CARGO HANDLING SERVICES INSPECTION & LOGISTICS SERVICES', 7)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CELLULAR ROAMING CHARGES', 8)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CHARTER HIRE CHARGES (SHIPPING)', 9)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CLEARING & FORWARDING CHARGES', 10)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'COMMISSION', 11)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'COMMUNICATION CHARGES', 12)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CONSULTING SERVICES', 13)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'DESIGNING FEE', 14)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'DIRECTORS FEES', 15)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'DIVIDEND', 16)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'DRILLING', 17)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'ENGINEERING SERVICES', 18)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'EQUIPMENT RENTAL CHARGES', 19)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'FABRICATION SERVICES', 20)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'FEES FOR TECHNICAL SERVICES/ FEES FOR INCLUDED SERVICES', 21)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'FREIGHT CHARGES', 22)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INCOME FROM IMMOVEABLE PROPERTY', 23)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INCOME FROM SHIPPING, INLAND WATERWAYS OR AIR TRANSPORT', 24)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INSTALLATION & COMMISSIONING SERVICES', 25)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INSURANCE COMMISSIONS', 26)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INTEREST PAYMENT', 27)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'INVESTMENT INCOME', 28)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'LEASE PAYMENT', 29)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'LICENSING FEE', 30)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'LONG TERM CAPITAL GAINS', 31)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'MEMBERSHIP FEE', 32)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'MOBILESTATION CHARGES', 33)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PAYMENTS FOR SOFTWARE BUNDLED WITH HARDWARE', 34)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PAYMENTS FOR SOFTWARE BUNDLED WITH HARDWARE?', 35)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PAYMENTS TO PROFESSORS, TEACHERS OR RESEARCH SCHOLARS', 36)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PAYMENTS TO SPORTS PERSON & ARTISTS', 37)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PAYMENTS TO STUDENTS OR BUSINESS APPRENTICE', 38)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PENSIONS(OTHER THAN THOSE RELATED TO PAST EMPLOYMENT)', 39)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PROCESSING CHARGES', 40)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PROFESSIONAL SERVICES', 41)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'PURCHASE OF SOFTWARE', 42)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'R&D CHARGES', 43)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'REGISTRATION CHARGES', 44)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'REIMBURSEMENT OF EXPENSES', 45)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'REPATRIATION OF SURPLUS FUNDS', 46)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'RETAINERSHIP FEES', 47)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'RETENTION FEES', 48)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'ROYALTY', 49)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SALES AND MARKETING SERVICES', 50)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SEISMIC DATA PROCESSING', 51)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SHORT TERM CAPITAL GAINS', 52)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SOFTWARE LICENCES', 53)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SPONSORSHIP FEES', 54)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SUBSCRIPTION FEES', 55)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SUPERVISION CHARGES', 56)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'SURVEY FEES', 57)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'TELECASTING SERVICES', 58)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'TENDER FEES', 59)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'TESTING CHARGES', 60)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'TRAINING', 61)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'WARRANTY SERVICES', 62)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'WINNING FROM HORSE RACES.', 63)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'WINNING FROM LOTTERIES, CROSSWORD PUZZLES, CARD GAMES AND OTHER GAMES OF ANY SORT.', 64)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'CONSULAR RECEIPTS', 65)
INSERT [dbo].[TdsNature] ([particular], [code]) VALUES (N'OTHER INCOME / OTHER (NOT IN THE NATURE OF INCOME)', 99)
GO
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 2, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 3, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 4, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 2, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 3, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 4, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 5, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 5, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 6, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 6, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 11, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 11, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 8, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 8, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 12, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 12, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 13, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 13, CAST(40.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 9, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 16, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 10, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 20, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 14, CAST(30.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 15, CAST(30.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 10, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 20, CAST(20.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 14, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 15, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 16, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 20, CAST(48.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 19, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 16, CAST(20.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 16, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 19, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 22, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 22, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 22, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 22, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 2, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 3, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 4, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 5, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 6, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 8, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 9, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 16, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 10, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 20, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 22, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 30, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 31, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 32, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 33, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 34, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 30, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 31, CAST(2.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 32, CAST(2.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 33, CAST(2.50 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 34, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 35, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 40, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 40, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 40, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 37, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 38, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 1, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 1, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 1, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 23, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 23, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 23, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 23, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 23, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 50, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 50, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 51, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 51, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 54, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 54, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
GO
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 62, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 62, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 55, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 55, CAST(30.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 63, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 63, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 81, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 81, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 81, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 81, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 81, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 3, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 4, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 84, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 84, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 84, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 85, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 85, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 85, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 79, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 79, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 79, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 1, 80, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 2, 80, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (25, 5, 80, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 2, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 3, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 4, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 2, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 3, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 4, CAST(1.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 5, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 5, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 6, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 6, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 11, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 11, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 8, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 8, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 12, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 12, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
GO
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 13, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 13, CAST(40.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 9, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 16, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 10, CAST(5.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 20, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 14, CAST(30.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 15, CAST(30.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 10, CAST(5.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 20, CAST(20.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 14, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 15, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 16, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 20, CAST(48.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 19, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 16, CAST(20.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 16, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 19, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 22, CAST(20.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 22, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 22, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 22, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 2, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 3, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 4, CAST(1.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 5, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 6, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 8, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 9, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 14, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 15, CAST(30.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 16, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 17, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 18, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 10, CAST(5.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 20, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 22, CAST(20.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 30, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 31, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 32, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 33, CAST(2.50 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 34, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 30, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 31, CAST(2.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 32, CAST(2.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 33, CAST(2.50 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 34, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 35, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 40, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 40, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 40, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 37, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 38, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 1, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 1, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 1, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 23, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 23, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 23, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 23, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 23, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 41, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 42, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 43, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 50, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 50, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 51, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 51, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 54, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 54, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 53, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 52, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 100000)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 56, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 57, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 58, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
GO
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 60, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 44, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 45, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 46, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 61, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 62, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 62, CAST(5.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 55, CAST(30.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 55, CAST(30.00 AS Numeric(5, 2)), CAST(2.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 63, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 63, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 65, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 66, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 48, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 49, CAST(5.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 67, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 81, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 81, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 81, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 81, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 81, CAST(2.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 3, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 4, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 99, CAST(20.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 70, CAST(0.10 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 71, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 72, CAST(1.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 75, CAST(10.00 AS Numeric(5, 2)), CAST(0.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 84, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 84, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 84, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 85, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 85, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 85, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 79, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 79, CAST(2.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 79, CAST(2.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 1, 80, CAST(10.00 AS Numeric(5, 2)), CAST(2.50 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 2, 80, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
INSERT [dbo].[TdsRate] ([ayid], [tsId], [PayCode], [Rate], [Surch], [Limit]) VALUES (26, 5, 80, CAST(10.00 AS Numeric(5, 2)), CAST(10.00 AS Numeric(5, 2)), 0)
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_ReturnDates_PerQuarterForm]    Script Date: 28-05-2026 21:16:44 ******/
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [UQ_ReturnDates_PerQuarterForm] UNIQUE NONCLUSTERED 
(
	[subcode] ASC,
	[ayid] ASC,
	[quarter] ASC,
	[formName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Assessee] ADD  CONSTRAINT [DF__assessee__status__075714DC]  DEFAULT ('01') FOR [assesseeStatus]
GO
ALTER TABLE [dbo].[Assessee] ADD  CONSTRAINT [DF__assessee__audy__084B3915]  DEFAULT ((0)) FOR [auditCase]
GO
ALTER TABLE [dbo].[Assessee] ADD  DEFAULT ('24Q,26Q,27Q,27EQ') FOR [applicableForms]
GO
ALTER TABLE [dbo].[BankDetails] ADD  DEFAULT ((0)) FOR [AppliesToYear]
GO
ALTER TABLE [dbo].[BillHead] ADD  CONSTRAINT [DF_BillHead_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [subcode]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [billno]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p1amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p2amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p3amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p4amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p5amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p6amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p7amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p8amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p9amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [p10amt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [stax]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [tamt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [sperc]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [ramt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [conscode]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [damt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [receipt]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [grpcode]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[Billmast] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [subcode]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [billno]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [amount]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [conscode]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [discount]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [billid]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [userid]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[BillReceipt] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[BillReceipts] ADD  CONSTRAINT [DF_BillReceipts_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Check_period] ADD  DEFAULT ((0)) FOR [quarter]
GO
ALTER TABLE [dbo].[Check_period] ADD  DEFAULT ((0)) FOR [month]
GO
ALTER TABLE [dbo].[Check_period] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[Consultant] ADD  CONSTRAINT [DF_Consultant_flagPendingBillsNotifications]  DEFAULT ((1)) FOR [flagPendingBillsNotifications]
GO
ALTER TABLE [dbo].[FeePaidMarking] ADD  CONSTRAINT [DF_FeePaidMarking_feePaid]  DEFAULT ((0)) FOR [feePaid]
GO
ALTER TABLE [dbo].[Groups] ADD  CONSTRAINT [DF_Groups_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [DF__ReturnDat__addre__1EA48E88]  DEFAULT ((0)) FOR [addressChangeOrg]
GO
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [DF__ReturnDat__addre__1F98B2C1]  DEFAULT ((0)) FOR [addressChangeAuth]
GO
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [DF__ReturnDat__isReg__208CD6FA]  DEFAULT ((1)) FOR [isRegularStatement]
GO
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [DF__ReturnDat__isNil__2180FB33]  DEFAULT ((0)) FOR [isNilReturn]
GO
ALTER TABLE [dbo].[ReturnDates] ADD  CONSTRAINT [DF__ReturnDat__nilSe__22751F6C]  DEFAULT ((0)) FOR [nilSectionsCount]
GO
ALTER TABLE [dbo].[Tdsaomaster] ADD  DEFAULT ((0)) FOR [statecode]
GO
ALTER TABLE [dbo].[Tdsaomaster] ADD  DEFAULT ((0)) FOR [pin]
GO
ALTER TABLE [dbo].[Tdsaomaster] ADD  DEFAULT ((0)) FOR [rstatecode]
GO
ALTER TABLE [dbo].[Tdsaomaster] ADD  DEFAULT ((0)) FOR [paoregno]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [pdedid]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [ind]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [indnr]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [huf]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [hufnr]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [firm]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [company]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [companynr]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [coop]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [sortid]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[Tdsded80] ADD  DEFAULT ((0)) FOR [ayid2]
GO
ALTER TABLE [dbo].[BillDetails]  WITH CHECK ADD  CONSTRAINT [FK_BillDetails_BillHead] FOREIGN KEY([billId])
REFERENCES [dbo].[BillHead] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[BillDetails] CHECK CONSTRAINT [FK_BillDetails_BillHead]
GO
ALTER TABLE [dbo].[BillHead]  WITH CHECK ADD  CONSTRAINT [FK_BillHead_Assessee] FOREIGN KEY([subCode])
REFERENCES [dbo].[Assessee] ([subCode])
GO
ALTER TABLE [dbo].[BillHead] CHECK CONSTRAINT [FK_BillHead_Assessee]
GO
ALTER TABLE [dbo].[BillReceipts]  WITH CHECK ADD  CONSTRAINT [FK_BillReceipts_BillHead] FOREIGN KEY([billId])
REFERENCES [dbo].[BillHead] ([id])
GO
ALTER TABLE [dbo].[BillReceipts] CHECK CONSTRAINT [FK_BillReceipts_BillHead]
GO
/****** Object:  Trigger [dbo].[insertUpdateReceipt]    Script Date: 28-05-2026 21:16:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[insertUpdateReceipt] ON [dbo].[BillReceipts] AFTER insert,update,delete 
AS 
BEGIN 
declare 
@Action as char(1),
@ID int,
@amtReceived numeric(15,2),
@amtDisc numeric(15,2)

select @ID=billId from inserted 
set @ID=(CASE WHEN EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
                        THEN (select billId from inserted)
                        WHEN EXISTS(SELECT * FROM INSERTED)
                        THEN (select billId from inserted)
                        WHEN EXISTS(SELECT * FROM DELETED)
                        THEN (select billId from deleted)
                        ELSE NULL
                    END)
if(@ID is not NULL)
begin
select @amtReceived=SUM(amtReceived),@amtDisc=SUM(amtDisc) from BillReceipts where billId=@ID and IsDeleted='false'
update BillHead set amtReceived=@amtReceived,amtDisc=@amtDisc where id=@ID 
end

END

GO
ALTER TABLE [dbo].[BillReceipts] ENABLE TRIGGER [insertUpdateReceipt]
GO
USE [master]
GO
ALTER DATABASE [MasterDbTds] SET  READ_WRITE 
GO
