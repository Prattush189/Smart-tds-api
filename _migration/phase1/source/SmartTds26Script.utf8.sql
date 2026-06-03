USE [master]
GO
/****** Object:  Database [SmartTds26]    Script Date: 30-05-2026 18:04:27 ******/
CREATE DATABASE [SmartTds26] ON  PRIMARY 
( NAME = N'SmartTds26', FILENAME = N'Appdirectory\Db\SmartTds26.mdf' , SIZE = 192512KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'SmartTds26_log', FILENAME = N'Appdirectory\Db\SmartTds26_log.ldf' , SIZE = 540608KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [SmartTds26] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [SmartTds26].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [SmartTds26] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SmartTds26] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SmartTds26] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SmartTds26] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SmartTds26] SET ARITHABORT OFF 
GO
ALTER DATABASE [SmartTds26] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [SmartTds26] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SmartTds26] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SmartTds26] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SmartTds26] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SmartTds26] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SmartTds26] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SmartTds26] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SmartTds26] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SmartTds26] SET  DISABLE_BROKER 
GO
ALTER DATABASE [SmartTds26] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SmartTds26] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SmartTds26] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [SmartTds26] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [SmartTds26] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SmartTds26] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [SmartTds26] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [SmartTds26] SET RECOVERY FULL 
GO
ALTER DATABASE [SmartTds26] SET  MULTI_USER 
GO
ALTER DATABASE [SmartTds26] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SmartTds26] SET DB_CHAINING OFF 
GO
USE [SmartTds26]
GO
/****** Object:  Table [dbo].[AddChallan]    Script Date: 30-05-2026 18:04:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AddChallan](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[chId] [int] NULL,
	[ayId] [int] NOT NULL,
	[subCode] [int] NOT NULL,
	[ChallanDt] [nvarchar](10) NULL,
	[ChallanNo] [nvarchar](20) NULL,
	[TotalTds] [numeric](14, 2) NULL,
	[Tax] [numeric](14, 2) NULL,
	[SurChrg] [numeric](14, 2) NULL,
	[Cess] [numeric](14, 2) NULL,
	[Total] [numeric](14, 2) NULL,
	[Interest] [numeric](14, 2) NULL,
	[Others] [nvarchar](50) NULL,
	[Fee234E] [numeric](14, 2) NULL,
	[GrndTotal] [numeric](14, 2) NULL,
	[NameBnk] [nvarchar](50) NULL,
	[Address] [nvarchar](200) NULL,
	[BranchCd] [nvarchar](50) NULL,
	[Mode] [nvarchar](50) NULL,
	[CheqNo] [nvarchar](50) NULL,
	[DrawnOn] [nvarchar](50) NULL,
	[MinorCd] [nvarchar](50) NULL,
	[ActualTds] [nvarchar](50) NULL,
	[DeductedTds] [nvarchar](50) NULL,
	[DepositedTds] [nvarchar](50) NULL,
	[IntQ1] [decimal](18, 2) NOT NULL,
	[IntQ2] [decimal](18, 2) NOT NULL,
	[IntQ3] [decimal](18, 2) NOT NULL,
	[IntQ4] [decimal](18, 2) NOT NULL,
	[FormType] [nvarchar](10) NULL,
	[IsFromItdPortal] [bit] NOT NULL,
 CONSTRAINT [PK_AddChallan] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ApplicationParams]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationParams](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NULL,
	[value] [nvarchar](100) NULL,
 CONSTRAINT [PK_ApplicationParams] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Ddodet]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ddodet](
	[tid] [int] IDENTITY(1,1) NOT NULL,
	[subcode] [int] NULL,
	[ayid] [int] NULL,
	[period] [int] NULL,
	[aocode] [int] NULL,
	[dcode] [int] NULL,
	[tax] [decimal](18, 2) NULL,
	[tds] [decimal](18, 2) NULL,
	[nature] [nvarchar](50) NULL,
	[mapcode] [nvarchar](50) NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_Ddodet] PRIMARY KEY CLUSTERED 
(
	[tid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[F15hn]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[F15hn](
	[tid] [int] IDENTITY(1,1) NOT NULL,
	[subcode] [int] NULL,
	[ayid] [int] NULL,
	[pcode] [int] NULL,
	[amount] [decimal](18, 2) NULL,
	[desc] [nvarchar](500) NULL,
	[date] [nvarchar](50) NULL,
	[nature] [nvarchar](100) NULL,
	[section] [nvarchar](50) NULL,
	[income] [decimal](18, 2) NULL,
	[quarter] [nvarchar](10) NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_F15hn] PRIMARY KEY CLUSTERED 
(
	[tid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[F15hnPayee]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[F15hnPayee](
	[tid] [int] IDENTITY(1,1) NOT NULL,
	[subcode] [int] NULL,
	[ayid] [int] NULL,
	[pcode] [int] NULL,
	[formid] [int] NULL,
	[date15g] [nvarchar](50) NULL,
	[date15g2] [nvarchar](50) NULL,
	[date15g3] [nvarchar](50) NULL,
	[unqno15g] [nvarchar](100) NULL,
	[nof15g] [int] NULL,
	[value15g] [decimal](18, 2) NULL,
	[eincome] [decimal](18, 2) NULL,
	[cincome] [decimal](18, 2) NULL,
	[amtPaid] [decimal](18, 2) NULL,
	[layr] [nvarchar](50) NULL,
	[type] [nvarchar](10) NULL,
	[quarter] [nvarchar](10) NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_F15hnPayee] PRIMARY KEY CLUSTERED 
(
	[tid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FilingStatus]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FilingStatus](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[f241r] [nvarchar](100) NULL,
	[f241d] [nvarchar](50) NULL,
	[f242r] [nvarchar](100) NULL,
	[f242d] [nvarchar](50) NULL,
	[f243r] [nvarchar](100) NULL,
	[f243d] [nvarchar](50) NULL,
	[f244r] [nvarchar](100) NULL,
	[f244d] [nvarchar](50) NULL,
	[f261r] [nvarchar](100) NULL,
	[f261d] [nvarchar](50) NULL,
	[f262r] [nvarchar](100) NULL,
	[f262d] [nvarchar](50) NULL,
	[f263r] [nvarchar](100) NULL,
	[f263d] [nvarchar](50) NULL,
	[f264r] [nvarchar](100) NULL,
	[f264d] [nvarchar](50) NULL,
	[f271r] [nvarchar](100) NULL,
	[f271d] [nvarchar](50) NULL,
	[f272r] [nvarchar](100) NULL,
	[f272d] [nvarchar](50) NULL,
	[f273r] [nvarchar](100) NULL,
	[f273d] [nvarchar](50) NULL,
	[f274r] [nvarchar](100) NULL,
	[f274d] [nvarchar](50) NULL,
	[tcs1r] [nvarchar](100) NULL,
	[tcs1d] [nvarchar](50) NULL,
	[tcs2r] [nvarchar](100) NULL,
	[tcs2d] [nvarchar](50) NULL,
	[tcs3r] [nvarchar](100) NULL,
	[tcs3d] [nvarchar](50) NULL,
	[tcs4r] [nvarchar](100) NULL,
	[tcs4d] [nvarchar](50) NULL,
 CONSTRAINT [PK_FilingStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payee]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payee](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[tsId] [int] NULL,
	[EmpFlag] [nvarchar](1) NULL,
	[Pan] [nvarchar](20) NULL,
	[PanStatus] [nvarchar](10) NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Add1] [nvarchar](200) NULL,
	[Add2] [nvarchar](200) NULL,
	[Add3] [nvarchar](200) NULL,
	[Add4] [nvarchar](200) NULL,
	[City] [nvarchar](50) NULL,
	[DoB] [nvarchar](10) NULL,
	[DoJ] [nvarchar](10) NULL,
	[FName] [nvarchar](100) NULL,
	[Phone] [nvarchar](12) NULL,
	[Phone2] [nvarchar](12) NULL,
	[Pincode] [int] NULL,
	[Zipcode] [int] NULL,
	[StateName] [nvarchar](50) NULL,
	[Tin] [nvarchar](20) NULL,
	[UserCode] [nvarchar](20) NULL,
	[EmpDesig] [nvarchar](50) NULL,
	[StCode] [nvarchar](20) NULL,
	[DoL] [nvarchar](10) NULL,
	[DoR] [nvarchar](10) NULL,
	[Leaves] [nvarchar](12) NULL,
	[Email] [nvarchar](50) NULL,
	[Email2] [nvarchar](50) NULL,
	[PanStat] [nvarchar](10) NULL,
	[Flag206ABCCA] [nvarchar](1) NULL,
	[Flag115BAC] [nvarchar](1) NULL,
	[FreezePan] [bit] NULL,
	[Sex] [nvarchar](1) NULL,
	[Status] [nvarchar](20) NULL,
	[RStatus] [nvarchar](20) NULL,
	[Country] [int] NULL,
	[State] [int] NULL,
	[DirFlag] [bit] NULL,
	[TaxRegime] [nvarchar](20) NULL,
 CONSTRAINT [PK_Payee] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Salary]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Salary](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[salType] [nvarchar](10) NOT NULL,
	[nameOfEmployer] [nvarchar](125) NOT NULL,
	[natureOfEmployment] [nvarchar](10) NOT NULL,
	[panOfEmployer] [nvarchar](10) NULL,
	[tanOfEmployer] [nvarchar](10) NULL,
	[countryCode] [int] NULL,
	[addrDetail] [nvarchar](200) NOT NULL,
	[cityOrTownOrDistrict] [nvarchar](50) NOT NULL,
	[stateCode] [nvarchar](2) NOT NULL,
	[pinCode] [int] NULL,
	[zipCode] [nvarchar](10) NULL,
	[grossSalary] [numeric](15, 0) NOT NULL,
	[valueOfPerquisites] [numeric](15, 0) NOT NULL,
	[profitsinLieuOfSalary] [numeric](15, 0) NOT NULL,
	[incomeNotified89A] [numeric](15, 0) NOT NULL,
	[incomeNotifiedOther89A] [numeric](15, 0) NOT NULL,
	[incomeNotifiedPrYr89A] [numeric](15, 0) NOT NULL,
	[allwncExemptUs10] [numeric](15, 0) NULL,
	[increliefus89A] [numeric](15, 0) NULL,
	[deductionUnderSection16ia] [numeric](5, 0) NULL,
	[entertainmntalwncUs16ii] [numeric](4, 0) NULL,
	[professionalTaxUs16iii] [numeric](4, 0) NULL,
	[hra] [numeric](15, 0) NULL,
	[actualRent] [numeric](15, 0) NULL,
	[whetherMetro] [bit] NOT NULL,
	[exemptHra] [numeric](15, 0) NULL,
	[hraSalary] [numeric](15, 0) NULL,
	[arrears] [numeric](15, 0) NULL,
	[taxableSalary] [numeric](15, 0) NULL,
	[taxableSalaryNew] [numeric](15, 0) NULL,
	[deductionUnderSection16iaFlag] [bit] NOT NULL,
	[deductionUnderSection16iaNew] [numeric](8, 0) NULL,
	[DearnessAllwnc] [numeric](12, 0) NULL,
	[pcode] [int] NULL,
 CONSTRAINT [PK_Salary] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SalaryExemptAllowances]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalaryExemptAllowances](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[salId] [int] NOT NULL,
	[SalNatureDesc] [nvarchar](50) NOT NULL,
	[SalOthNatOfInc] [nvarchar](500) NOT NULL,
	[SalOthAmount] [numeric](15, 0) NOT NULL,
 CONSTRAINT [PK_SalaryExemptAllowances] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SalaryNatureDetails]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalaryNatureDetails](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[salId] [int] NOT NULL,
	[NatureDesc] [nvarchar](10) NOT NULL,
	[OthNatOfInc] [nvarchar](500) NOT NULL,
	[OthAmount] [numeric](15, 0) NOT NULL,
 CONSTRAINT [PK_SalaryNatureDetails] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SalaryPerquisiteDetails]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalaryPerquisiteDetails](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[salId] [int] NOT NULL,
	[NatureDesc] [nvarchar](10) NOT NULL,
	[OthNatOfInc] [nvarchar](500) NOT NULL,
	[OthAmount] [numeric](15, 0) NOT NULL,
 CONSTRAINT [PK_SalaryPerquisiteDetails] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsCompIncome]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsCompIncome](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NULL,
	[ayId] [int] NULL,
	[pcode] [int] NULL,
	[salary_id] [int] NULL,
	[SalaryOld] [numeric](14, 2) NULL,
	[SalaryNew] [numeric](14, 2) NULL,
	[BusinessOld] [numeric](14, 2) NULL,
	[BusinessNew] [numeric](14, 2) NULL,
	[PropertyOld] [numeric](14, 2) NULL,
	[PropertyNew] [numeric](14, 2) NULL,
	[StcgOld] [numeric](14, 2) NULL,
	[StcgNew] [numeric](14, 2) NULL,
	[Cg20Old] [numeric](14, 2) NULL,
	[Cg20New] [numeric](14, 2) NULL,
	[Cg125Old] [numeric](14, 2) NULL,
	[Cg125New] [numeric](14, 2) NULL,
	[OtherSrcOld] [numeric](14, 2) NULL,
	[OtherSrcNew] [numeric](14, 2) NULL,
	[NscIntOld] [numeric](14, 2) NULL,
	[NscIntNew] [numeric](14, 2) NULL,
	[PropLossOld] [numeric](14, 2) NULL,
	[PropLossNew] [numeric](14, 2) NULL,
	[LotteryOld] [numeric](14, 2) NULL,
	[LotteryNew] [numeric](14, 2) NULL,
	[AgriOld] [numeric](14, 2) NULL,
	[AgriNew] [numeric](14, 2) NULL,
	[GtiOld] [numeric](14, 2) NULL,
	[GtiNew] [numeric](14, 2) NULL,
	[Ded80COld] [numeric](14, 2) NULL,
	[Ded80CNew] [numeric](14, 2) NULL,
	[DedVIAOld] [numeric](14, 2) NULL,
	[DedVIANew] [numeric](14, 2) NULL,
	[TotalIncomeOld] [numeric](14, 2) NULL,
	[TotalIncomeNew] [numeric](14, 2) NULL,
	[TaxCG20Old] [numeric](14, 2) NULL,
	[TaxCG20New] [numeric](14, 2) NULL,
	[TaxCG125Old] [numeric](14, 2) NULL,
	[TaxCG125New] [numeric](14, 2) NULL,
	[TaxOtherIncOld] [numeric](14, 2) NULL,
	[TaxOtherIncNew] [numeric](14, 2) NULL,
	[TaxLotteryOld] [numeric](14, 2) NULL,
	[TaxLotteryNew] [numeric](14, 2) NULL,
	[TotalTaxOld] [numeric](14, 2) NULL,
	[TotalTaxNew] [numeric](14, 2) NULL,
	[Rebate87AOld] [numeric](14, 2) NULL,
	[Rebate87ANew] [numeric](14, 2) NULL,
	[SurchargeOld] [numeric](14, 2) NULL,
	[SurchargeNew] [numeric](14, 2) NULL,
	[CessOld] [numeric](14, 2) NULL,
	[CessNew] [numeric](14, 2) NULL,
	[TaxPayableOld] [numeric](14, 2) NULL,
	[TaxPayableNew] [numeric](14, 2) NULL,
	[ReliefOld] [numeric](14, 2) NULL,
	[ReliefNew] [numeric](14, 2) NULL,
	[NetTaxOld] [numeric](14, 2) NULL,
	[NetTaxNew] [numeric](14, 2) NULL,
	[AdoptedMethod] [nvarchar](20) NULL,
	[AdoptedTax] [numeric](14, 2) NULL,
	[PrevEmpSalary] [numeric](14, 2) NULL,
	[PrevEmpTds] [numeric](14, 2) NULL,
	[PrevEmpBasic] [numeric](14, 2) NULL,
	[Tds192_2B] [numeric](14, 2) NULL,
	[Tax192_1A] [numeric](14, 2) NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_TdsCompIncome] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsDeduction]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsDeduction](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[subCode] [int] NULL,
	[ayId] [int] NULL,
	[pcode] [int] NULL,
	[ded80id] [int] NULL,
	[amount] [numeric](14, 2) NULL,
	[amount1] [numeric](14, 2) NULL,
	[amount2] [numeric](14, 2) NULL,
	[amount3] [numeric](14, 2) NULL,
	[amount4] [numeric](14, 2) NULL,
	[amount5] [numeric](14, 2) NULL,
	[amount6] [numeric](14, 2) NULL,
	[amount7] [numeric](14, 2) NULL,
	[dedamt] [numeric](14, 2) NULL,
	[dedamt2] [numeric](14, 2) NULL,
	[grossamt] [numeric](14, 2) NULL,
	[senior] [bit] NULL,
	[Ssenior] [bit] NULL,
	[severe] [bit] NULL,
	[date] [nvarchar](20) NULL,
	[salary_id] [int] NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_TdsDeduction] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TdsEntry]    Script Date: 30-05-2026 18:04:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TdsEntry](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[payeeId] [int] NULL,
	[chId] [int] NULL,
	[subCode] [int] NOT NULL,
	[ayId] [int] NOT NULL,
	[PayeeName] [nvarchar](100) NULL,
	[PayerName] [nvarchar](100) NULL,
	[Section] [int] NULL,
	[Nature] [int] NULL,
	[Descrp] [nvarchar](100) NULL,
	[DatePayment] [nvarchar](10) NULL,
	[DateDeduct] [nvarchar](10) NULL,
	[TypeDeduct] [nvarchar](50) NULL,
	[AmtPay] [numeric](14, 2) NULL,
	[TdsRate] [numeric](5, 2) NULL,
	[Surcharge] [numeric](14, 2) NULL,
	[TdsDeduct] [numeric](14, 2) NULL,
	[SurDeduct] [numeric](14, 2) NULL,
	[Cess] [numeric](14, 2) NULL,
	[DateDeposit] [nvarchar](10) NULL,
	[TotalTds2] [numeric](14, 2) NULL,
	[TdsDedLater] [numeric](14, 2) NULL,
	[FormType] [nvarchar](5) NULL,
	[TdsApp] [nvarchar](10) NULL,
	[Ack15CA] [nvarchar](10) NULL,
	[CertNo] [nvarchar](10) NULL,
	[DtValF] [nvarchar](10) NULL,
	[DtValT] [nvarchar](10) NULL,
	[DtPaying] [nvarchar](10) NULL,
	[DtComm] [nvarchar](10) NULL,
	[eValid] [bit] NULL,
	[ActualTds] [numeric](14, 2) NULL,
	[ActualRate] [numeric](5, 2) NULL,
	[ChInterest] [numeric](14, 2) NULL,
	[ChTdsDep] [numeric](14, 2) NULL,
	[DeductionCode] [nvarchar](100) NULL,
	[pcode] [int] NULL,
 CONSTRAINT [PK_TdsEntry] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_Salary_Lookup]    Script Date: 30-05-2026 18:04:28 ******/
CREATE NONCLUSTERED INDEX [IX_Salary_Lookup] ON [dbo].[Salary]
(
	[subCode] ASC,
	[ayId] ASC,
	[pcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AddChallan] ADD  DEFAULT ((0)) FOR [IntQ1]
GO
ALTER TABLE [dbo].[AddChallan] ADD  DEFAULT ((0)) FOR [IntQ2]
GO
ALTER TABLE [dbo].[AddChallan] ADD  DEFAULT ((0)) FOR [IntQ3]
GO
ALTER TABLE [dbo].[AddChallan] ADD  DEFAULT ((0)) FOR [IntQ4]
GO
ALTER TABLE [dbo].[AddChallan] ADD  CONSTRAINT [DF_AddChallan_IsFromItdPortal]  DEFAULT ((0)) FOR [IsFromItdPortal]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [subcode]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [period]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [aocode]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [dcode]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [tax]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [tds]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[Ddodet] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [subcode]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [pcode]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [amount]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [income]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[F15hn] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [subcode]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [ayid]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [pcode]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [formid]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [nof15g]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [value15g]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [eincome]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [cincome]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [amtPaid]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[F15hnPayee] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f241r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f241d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f242r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f242d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f243r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f243d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f244r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f244d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f261r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f261d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f262r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f262d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f263r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f263d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f264r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f264d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f271r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f271d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f272r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f272d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f273r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f273d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f274r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [f274d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs1r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs1d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs2r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs2d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs3r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs3d]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs4r]
GO
ALTER TABLE [dbo].[FilingStatus] ADD  DEFAULT ('') FOR [tcs4d]
GO
ALTER TABLE [dbo].[Payee] ADD  DEFAULT (N'AUTOMATIC') FOR [TaxRegime]
GO
ALTER TABLE [dbo].[Salary] ADD  CONSTRAINT [DF_Salary_profitsinLieuOfSalary]  DEFAULT ((0)) FOR [profitsinLieuOfSalary]
GO
ALTER TABLE [dbo].[Salary] ADD  CONSTRAINT [DF_Salary_incomeNotified89A]  DEFAULT ((0)) FOR [incomeNotified89A]
GO
ALTER TABLE [dbo].[Salary] ADD  CONSTRAINT [DF_Salary_incomeNotifiedOther89A]  DEFAULT ((0)) FOR [incomeNotifiedOther89A]
GO
ALTER TABLE [dbo].[Salary] ADD  CONSTRAINT [DF_Salary_incomeNotifiedPrYr89A]  DEFAULT ((0)) FOR [incomeNotifiedPrYr89A]
GO
ALTER TABLE [dbo].[Salary] ADD  DEFAULT ((1)) FOR [deductionUnderSection16iaFlag]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [salary_id]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [SalaryOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [SalaryNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [BusinessOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [BusinessNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PropertyOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PropertyNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [StcgOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [StcgNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Cg20Old]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Cg20New]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Cg125Old]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Cg125New]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [OtherSrcOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [OtherSrcNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [NscIntOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [NscIntNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PropLossOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PropLossNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [LotteryOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [LotteryNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [AgriOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [AgriNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [GtiOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [GtiNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Ded80COld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Ded80CNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [DedVIAOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [DedVIANew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TotalIncomeOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TotalIncomeNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxCG20Old]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxCG20New]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxCG125Old]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxCG125New]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxOtherIncOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxOtherIncNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxLotteryOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxLotteryNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TotalTaxOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TotalTaxNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Rebate87AOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Rebate87ANew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [SurchargeOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [SurchargeNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [CessOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [CessNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxPayableOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [TaxPayableNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [ReliefOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [ReliefNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [NetTaxOld]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [NetTaxNew]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT (N'AUTOMATIC') FOR [AdoptedMethod]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [AdoptedTax]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PrevEmpSalary]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PrevEmpTds]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [PrevEmpBasic]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Tds192_2B]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [Tax192_1A]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[TdsCompIncome] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount1]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount2]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount3]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount4]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount5]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount6]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [amount7]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [dedamt]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [dedamt2]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [grossamt]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [senior]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [Ssenior]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [severe]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT (getdate()) FOR [ModifiedOn]
GO
ALTER TABLE [dbo].[TdsDeduction] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[TdsEntry] ADD  DEFAULT ((0)) FOR [pcode]
GO
ALTER TABLE [dbo].[SalaryExemptAllowances]  WITH CHECK ADD  CONSTRAINT [FK_SalaryExemptAllowances_Salary] FOREIGN KEY([salId])
REFERENCES [dbo].[Salary] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SalaryExemptAllowances] CHECK CONSTRAINT [FK_SalaryExemptAllowances_Salary]
GO
ALTER TABLE [dbo].[SalaryNatureDetails]  WITH CHECK ADD  CONSTRAINT [FK_SalaryNatureDetails_Salary] FOREIGN KEY([salId])
REFERENCES [dbo].[Salary] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SalaryNatureDetails] CHECK CONSTRAINT [FK_SalaryNatureDetails_Salary]
GO
ALTER TABLE [dbo].[SalaryPerquisiteDetails]  WITH CHECK ADD  CONSTRAINT [FK_SalaryPerquisiteDetails_Salary] FOREIGN KEY([salId])
REFERENCES [dbo].[Salary] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SalaryPerquisiteDetails] CHECK CONSTRAINT [FK_SalaryPerquisiteDetails_Salary]
GO
USE [master]
GO
ALTER DATABASE [SmartTds26] SET  READ_WRITE 
GO
