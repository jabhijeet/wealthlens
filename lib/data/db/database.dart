import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/connection.dart';

part 'database.g.dart';

enum AssetClass {
  equity,
  etf,
  mutualFund,
  bond,
  fixedDeposit,
  recurringDeposit,
  ppf,
  epf,
  nps,
  insuranceTerm,
  insuranceEndowment,
  insuranceMoneyback,
  insuranceUlip,
  insuranceAnnuity,
  cryptoSpot,
  cryptoStaked,
  cryptoLpToken,
  cryptoNft,
  cryptoStablecoin,
  realEstateResidentialSelfUse,
  realEstateResidentialRented,
  realEstateCommercialRented,
  realEstateCommercialVacant,
  realEstateLand,
  realEstateReit,
  cash,
  commodity,
  custom,
  other,
}

enum Country { india, singapore, usa, uk, other }

enum InstrumentSource { manual, importedPdf, importedExcel, importedImage, api }

enum TransactionType {
  buy,
  sell,
  dividend,
  interest,
  fee,
  contribution,
  withdrawal,
  bonus,
  split,
  fxAdjust,
  rentReceived,
  rentDeposit,
  rentRefund,
  propertyExpense,
  propertyTax,
  societyMaintenance,
  repair,
  loanEmi,
  loanPrepayment,
  stakingReward,
  airdrop,
  fork,
  gasFee,
  swap,
  premiumPaid,
  claimReceived,
  surrenderPayout,
  bonusDeclared,
}

class Instruments extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text()();
  TextColumn get symbol => text().nullable()();
  TextColumn get isin => text().nullable()();
  TextColumn get assetClass => textEnum<AssetClass>()();
  TextColumn get country => textEnum<Country>()();
  TextColumn get currency => text()(); // ISO-4217
  TextColumn get exchange => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Holdings extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get instrumentId => text().references(Instruments, #id)();
  TextColumn get account => text().nullable()();
  TextColumn get quantity => text()(); // decimal stored as text
  IntColumn get avgCostMinor =>
      integer()(); // cost basis in instrument.currency
  DateTimeColumn get openedOn => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => textEnum<InstrumentSource>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get type => textEnum<TransactionType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get quantity => text()(); // signed decimal as text
  IntColumn get priceMinor => integer()();
  IntColumn get feesMinor => integer().withDefault(const Constant(0))();
  IntColumn get taxMinor => integer().withDefault(const Constant(0))();
  TextColumn get fxRateToBase => text().nullable()(); // decimal as text
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceSnapshots extends Table {
  TextColumn get instrumentId => text().references(Instruments, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get closeMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {instrumentId, date};
}

class FxRates extends Table {
  DateTimeColumn get date => dateTime()();
  TextColumn get base => text()();
  TextColumn get quote => text()();
  TextColumn get rate => text()(); // decimal as text
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column> get primaryKey => {date, base, quote};
}

class FundamentalSnapshots extends Table {
  TextColumn get instrumentId => text().references(Instruments, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get peRatio => text().nullable()(); // decimal string
  TextColumn get pbRatio => text().nullable()(); // decimal string
  TextColumn get roe => text().nullable()(); // percentage as string
  TextColumn get roce => text().nullable()(); // percentage as string
  TextColumn get marketCap => text().nullable()(); // amount as string
  TextColumn get debtToEquity => text().nullable()(); // ratio as string
  TextColumn get source => text()(); // e.g. 'yahoo', 'screener'

  @override
  Set<Column> get primaryKey => {instrumentId, date};
}

class FdRdAccounts extends Table {
  TextColumn get holdingId => text().references(Holdings, #id)();
  IntColumn get principalMinor => integer()();
  IntColumn get installmentMinor => integer().nullable()(); // RD only
  TextColumn get annualRatePct => text()(); // decimal as text
  TextColumn get compoundingFrequency =>
      text()(); // monthly/quarterly/yearly/atMaturity
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get maturityDate => dateTime()();
  TextColumn get payoutType => text()(); // cumulative / payout
  TextColumn get payoutFrequency => text().nullable()();

  @override
  Set<Column> get primaryKey => {holdingId};
}

class PpfAccounts extends Table {
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get contributionsJson => text()(); // list of {date, amountMinor}
  TextColumn get rateHistoryJson =>
      text()(); // list of {fromDate, toDate, ratePct}
  DateTimeColumn get maturityDate => dateTime()();

  @override
  Set<Column> get primaryKey => {holdingId};
}

class InsurancePolicies extends Table {
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get policyNumber => text()();
  TextColumn get insurer => text()();
  TextColumn get type =>
      text()(); // term / endowment / ulip / moneyback / annuity
  IntColumn get premiumMinor => integer()();
  TextColumn get premiumFrequency =>
      text()(); // monthly/quarterly/half-yearly/yearly/single
  IntColumn get premiumPayingTermYears => integer()();
  IntColumn get sumAssuredMinor => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get maturityDate => dateTime()();
  IntColumn get surrenderValueMinor => integer().nullable()();
  DateTimeColumn get surrenderValueAsOf => dateTime().nullable()();
  IntColumn get bonusAccruedMinor => integer().withDefault(const Constant(0))();
  IntColumn get expectedMaturityMinor => integer().nullable()();
  TextColumn get ulipFundsJson => text().nullable()(); // ULIP only
  TextColumn get riders => text().nullable()();
  TextColumn get nominee => text().nullable()();
  TextColumn get policyDocsAttachmentIds => text().nullable()();

  @override
  Set<Column> get primaryKey => {holdingId};
}

class CryptoHoldings extends Table {
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get symbol => text()();
  TextColumn get network => text()();
  TextColumn get custody =>
      text()(); // exchange / hotWallet / hardwareWallet / customWallet / custodial
  TextColumn get walletLabel => text().nullable()();
  TextColumn get walletAddress => text().nullable()();
  TextColumn get acquisitionMethod =>
      text()(); // buy / mining / staking-reward / airdrop / fork / gift
  TextColumn get stakedQuantity => text().nullable()(); // decimal as text
  TextColumn get stakingAprPct => text().nullable()(); // decimal as text
  DateTimeColumn get stakingUnlockDate => dateTime().nullable()();
  TextColumn get lpPoolDetailsJson => text().nullable()();
  TextColumn get nftDetailsJson => text().nullable()();
  TextColumn get costBasisMethod =>
      text()(); // FIFO / LIFO / avgCost / specific

  @override
  Set<Column> get primaryKey => {holdingId};
}

class RealEstateHoldings extends Table {
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get propertyType => text()();
  TextColumn get addressLine => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get country => text().nullable()();
  IntColumn get builtUpAreaSqft => integer().nullable()();
  DateTimeColumn get acquisitionDate => dateTime()();
  IntColumn get acquisitionCostMinor => integer()();
  IntColumn get registrationCostMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get improvementCostMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get currentValuationMinor => integer().nullable()();
  DateTimeColumn get valuationAsOf => dateTime().nullable()();
  TextColumn get valuationSource => text()
      .nullable()(); // selfEstimate / governmentCircleRate / brokerEstimate / appraisal
  BoolColumn get hasLoan => boolean().withDefault(const Constant(false))();
  IntColumn get loanPrincipalMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get loanOutstandingMinor =>
      integer().withDefault(const Constant(0))();
  TextColumn get loanRatePct => text().nullable()(); // decimal as text
  IntColumn get loanEmiMinor => integer().withDefault(const Constant(0))();
  DateTimeColumn get loanStartDate => dateTime().nullable()();
  DateTimeColumn get loanEndDate => dateTime().nullable()();
  TextColumn get loanLender => text().nullable()();
  TextColumn get tenantName => text().nullable()();
  DateTimeColumn get leaseStartDate => dateTime().nullable()();
  DateTimeColumn get leaseEndDate => dateTime().nullable()();
  IntColumn get monthlyRentMinor => integer().withDefault(const Constant(0))();
  IntColumn get securityDepositMinor =>
      integer().withDefault(const Constant(0))();
  TextColumn get rentEscalationPct => text().nullable()(); // decimal as text
  IntColumn get rentDueDayOfMonth => integer().nullable()();
  TextColumn get maintenanceBorneBy =>
      text().nullable()(); // tenant / owner / shared
  TextColumn get occupancyStatus =>
      text().nullable()(); // occupied / vacant / partiallyOccupied
  IntColumn get propertyTaxAnnualMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get societyMaintenanceMonthlyMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get insuranceAnnualMinor =>
      integer().withDefault(const Constant(0))();
  BoolColumn get gstRegistered =>
      boolean().withDefault(const Constant(false))();
  TextColumn get tdsOnRentPct => text().nullable()(); // decimal as text

  @override
  Set<Column> get primaryKey => {holdingId};
}

class SystematicPlans extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get holdingId => text().references(Holdings, #id)();
  TextColumn get kind => text()(); // sip / swp / stp
  IntColumn get amountMinor => integer()();
  TextColumn get frequency => text()(); // weekly/monthly/quarterly/custom-cron
  IntColumn get dayOfMonth => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text()(); // active/paused/completed/cancelled
  TextColumn get fundingAccount => text().nullable()();
  TextColumn get destinationHoldingId => text().nullable().references(
    Holdings,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get lastExecutedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();
  TextColumn get targetCurrency => text()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get linkedHoldingIds => text()(); // JSON list

  @override
  Set<Column> get primaryKey => {id};
}

class Notifications extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get firedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Instruments,
    Holdings,
    Transactions,
    PriceSnapshots,
    FxRates,
    FdRdAccounts,
    PpfAccounts,
    InsurancePolicies,
    CryptoHoldings,
    RealEstateHoldings,
    SystematicPlans,
    Goals,
    Notifications,
    Settings,
    FundamentalSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(fxRates, fxRates.source);
      }
    },
  );

  /// Deletes all data from all tables in the database.
  /// This is used for the "Delete All Data" feature in settings.
  Future<void> deleteAllData() async {
    await transaction(() async {
      // Delete in reverse order of dependencies if possible,
      // but drift handles transactions well.
      // We'll go through all tables defined in the database.
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

AppDatabase openDatabase() {
  return AppDatabase(openConnection());
}
