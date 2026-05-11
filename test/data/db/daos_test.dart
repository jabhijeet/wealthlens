import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/database.dart';
import 'package:wealthlens/data/db/daos.dart';

void main() {
  late AppDatabase database;
  late InstrumentDao instrumentDao;
  late HoldingDao holdingDao;

  setUp(() async {
    // Use an in-memory database for testing
    database = AppDatabase(NativeDatabase.memory());
    instrumentDao = InstrumentDao(database);
    holdingDao = HoldingDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('InstrumentDao', () {
    test('should insert and retrieve instrument', () async {
      final instrument = InstrumentsCompanion.insert(
        id: const Value('test-1'),
        name: 'Test Stock',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value('US1234567890'),
        exchange: const Value('NASDAQ'),
        metadataJson: const Value(null),
      );

      final id = await instrumentDao.insert(instrument);
      expect(id, 'test-1');

      final retrieved = await instrumentDao.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Stock');
      expect(retrieved.symbol, 'TEST');
    });

    test('should update instrument', () async {
      final instrument = InstrumentsCompanion.insert(
        id: const Value('test-2'),
        name: 'Old Name',
        symbol: const Value('OLD'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );

      await instrumentDao.insert(instrument);

      final updated = instrument.copyWith(
        name: const Value('New Name'),
        symbol: const Value('NEW'),
      );
      final success = await instrumentDao.update(updated);
      expect(success, isTrue);

      final retrieved = await instrumentDao.getById('test-2');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'New Name');
      expect(retrieved.symbol, 'NEW');
    });

    test('should delete instrument', () async {
      final instrument = InstrumentsCompanion.insert(
        id: const Value('test-3'),
        name: 'To Delete',
        symbol: const Value('DEL'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );

      await instrumentDao.insert(instrument);

      final count = await instrumentDao.delete('test-3');
      expect(count, 1);

      final retrieved = await instrumentDao.getById('test-3');
      expect(retrieved, isNull);
    });

    test('should get all instruments', () async {
      final instrument1 = InstrumentsCompanion.insert(
        id: const Value('test-4'),
        name: 'Instrument 1',
        symbol: const Value('INST1'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );

      final instrument2 = InstrumentsCompanion.insert(
        id: const Value('test-5'),
        name: 'Instrument 2',
        symbol: const Value('INST2'),
        assetClass: AssetClass.bond,
        country: Country.india,
        currency: 'INR',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );

      await instrumentDao.insert(instrument1);
      await instrumentDao.insert(instrument2);

      final all = await instrumentDao.getAll();
      expect(all.length, 2);
      expect(all.any((i) => i.name == 'Instrument 1'), isTrue);
      expect(all.any((i) => i.name == 'Instrument 2'), isTrue);
    });
  });

  group('HoldingDao', () {
    test('should insert and retrieve holding', () async {
      // First create an instrument
      final instrument = InstrumentsCompanion.insert(
        id: const Value('inst-1'),
        name: 'Test Instrument',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );
      await instrumentDao.insert(instrument);

      final holding = HoldingsCompanion.insert(
        id: const Value('hold-1'),
        instrumentId: 'inst-1',
        account: const Value('Brokerage Account'),
        quantity: '100.5',
        avgCostMinor: 5000, // $50.00 in minor units
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );

      final id = await holdingDao.insert(holding);
      expect(id, 'hold-1');

      final retrieved = await holdingDao.getById('hold-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.instrumentId, 'inst-1');
      expect(retrieved.quantity, '100.5');
      expect(retrieved.avgCostMinor, 5000);
    });

    test('should get holdings by instrument id', () async {
      // Create instrument
      final instrument = InstrumentsCompanion.insert(
        id: const Value('inst-2'),
        name: 'Test Instrument',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );
      await instrumentDao.insert(instrument);

      // Create multiple holdings for same instrument
      final holding1 = HoldingsCompanion.insert(
        id: const Value('hold-2'),
        instrumentId: 'inst-2',
        account: const Value('Account 1'),
        quantity: '50',
        avgCostMinor: 2500,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );

      final holding2 = HoldingsCompanion.insert(
        id: const Value('hold-3'),
        instrumentId: 'inst-2',
        account: const Value('Account 2'),
        quantity: '75',
        avgCostMinor: 3750,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );

      await holdingDao.insert(holding1);
      await holdingDao.insert(holding2);

      final holdings = await holdingDao.getByInstrumentId('inst-2');
      expect(holdings.length, 2);
      expect(holdings.any((h) => h.id == 'hold-2'), isTrue);
      expect(holdings.any((h) => h.id == 'hold-3'), isTrue);
    });

    test('should update holding', () async {
      // Create instrument
      final instrument = InstrumentsCompanion.insert(
        id: const Value('inst-3'),
        name: 'Test Instrument',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );
      await instrumentDao.insert(instrument);

      final holding = HoldingsCompanion.insert(
        id: const Value('hold-4'),
        instrumentId: 'inst-3',
        account: const Value('Old Account'),
        quantity: '100',
        avgCostMinor: 5000,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );
      await holdingDao.insert(holding);

      final updated = holding.copyWith(
        account: const Value('New Account'),
        quantity: const Value('150'),
      );
      final success = await holdingDao.update(updated);
      expect(success, isTrue);

      final retrieved = await holdingDao.getById('hold-4');
      expect(retrieved, isNotNull);
      expect(retrieved!.account, 'New Account');
      expect(retrieved.quantity, '150');
    });

    test('should delete holding', () async {
      // Create instrument
      final instrument = InstrumentsCompanion.insert(
        id: const Value('inst-4'),
        name: 'Test Instrument',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );
      await instrumentDao.insert(instrument);

      final holding = HoldingsCompanion.insert(
        id: const Value('hold-5'),
        instrumentId: 'inst-4',
        account: const Value('Account'),
        quantity: '100',
        avgCostMinor: 5000,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );
      await holdingDao.insert(holding);

      final count = await holdingDao.delete('hold-5');
      expect(count, 1);

      final retrieved = await holdingDao.getById('hold-5');
      expect(retrieved, isNull);
    });

    test('should get all holdings', () async {
      // Create instrument
      final instrument = InstrumentsCompanion.insert(
        id: const Value('inst-5'),
        name: 'Test Instrument',
        symbol: const Value('TEST'),
        assetClass: AssetClass.equity,
        country: Country.usa,
        currency: 'USD',
        isin: const Value(null),
        exchange: const Value(null),
        metadataJson: const Value(null),
      );
      await instrumentDao.insert(instrument);

      final holding1 = HoldingsCompanion.insert(
        id: const Value('hold-6'),
        instrumentId: 'inst-5',
        account: const Value('Account 1'),
        quantity: '50',
        avgCostMinor: 2500,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );

      final holding2 = HoldingsCompanion.insert(
        id: const Value('hold-7'),
        instrumentId: 'inst-5',
        account: const Value('Account 2'),
        quantity: '75',
        avgCostMinor: 3750,
        openedOn: DateTime.now(),
        notes: const Value(null),
        source: InstrumentSource.manual,
        isActive: const Value(true),
      );

      await holdingDao.insert(holding1);
      await holdingDao.insert(holding2);

      final all = await holdingDao.getAll();
      expect(all.length, 2);
      expect(all.any((h) => h.id == 'hold-6'), isTrue);
      expect(all.any((h) => h.id == 'hold-7'), isTrue);
    });
  });
}
