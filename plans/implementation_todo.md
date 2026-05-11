# WealthLens Implementation Todo List

## Phase 1: Critical Security & Quality Fixes (Week 1-2)

### 🚨 Critical Security Issues
- [ ] **Complete backup encryption** in [`lib/services/backup/backup_service.dart`](lib/services/backup/backup_service.dart)
  - Implement AES-256-GCM encryption
  - Add key management with biometric unlock
  - Test backup/restore with encryption

- [ ] **Fix undefined identifiers** in UI screens
  - `activeLlmProvider` in [`lib/features/import/import_screen.dart`](lib/features/import/import_screen.dart)
  - `llmProvider` in import screens
  - `readAt` getter in notifications screen

- [ ] **Address linting errors** from `analysis.txt`
  - Run `dart fix --apply`
  - Fix remaining warnings manually
  - Add CI check to prevent regression

### 🔧 High Priority Code Quality
- [ ] **Fix unawaited futures** in import screens
- [ ] **Update deprecated methods** (`withOpacity` usage)
- [ ] **Add proper error handling** patterns
- [ ] **Remove unused imports** across codebase

## Phase 2: Performance Optimization (Week 2-3)

### 📊 Dashboard Performance
- [ ] **Move heavy computations to isolates** in dashboard data provider
- [ ] **Implement caching layer** for price feeds
  - Memory cache (LRU)
  - Database cache for offline access
  - HTTP cache with `dio_cache_interceptor`

- [ ] **Add pagination** for holdings list
- [ ] **Optimize database queries** with proper indexes

### 🗄️ Memory Management
- [ ] **Add cleanup** for long-running services
- [ ] **Implement memory monitoring**
- [ ] **Add lazy loading** for large datasets

## Phase 3: Architecture Refactoring (Week 3-4)

### 🏗️ Clean Architecture Implementation
- [ ] **Restructure to Clean Architecture layers**
  - Domain layer (entities, use cases, repository interfaces)
  - Data layer (repositories, data sources, models)
  - Presentation layer (UI, view models, providers)

- [ ] **Add dependency injection** with `get_it` + `injectable`
- [ ] **Create service interfaces** for all services
- [ ] **Implement repository pattern** for data access

### 🔌 Dependency Management
- [ ] **Decouple providers from service instantiation**
- [ ] **Add environment-specific configurations**
- [ ] **Implement service locator pattern**

## Phase 4: Testing Strategy (Week 4-5)

### 🧪 Integration Tests
- [ ] **Add integration tests** for all services
  - Price service with mocked API
  - LLM service with mocked responses
  - Backup service with file operations

- [ ] **API integration tests** with test endpoints
- [ ] **Database migration tests**

### 🖥️ UI/Widget Tests
- [ ] **Implement widget tests** for critical screens
  - Dashboard screen
  - Holdings screen
  - Import screen
  - Settings screen

- [ ] **Add golden tests** for UI consistency
- [ ] **Implement integration tests** for user flows

### 📈 Performance Tests
- [ ] **Add benchmark tests** for critical operations
  - Dashboard data loading
  - Portfolio calculations
  - Database queries

- [ ] **Load testing** for large portfolios (1000+ holdings)

## Phase 5: Security Enhancements (Week 5-6)

### 🔐 Advanced Security
- [ ] **Implement certificate pinning** for financial APIs
- [ ] **Add API key rotation** mechanism
- [ ] **Enhance input validation** across all services
- [ ] **Add security headers** for web version

### 🔒 Data Protection
- [ ] **Encrypt sensitive fields** in database
- [ ] **Implement secure storage** for credentials
- [ ] **Add data sanitization** for exports

## Phase 6: Offline & Sync Capabilities (Week 6-7)

### 📱 Offline-First Architecture
- [ ] **Implement sync queue** for offline operations
- [ ] **Add conflict resolution** strategy
- [ ] **Create local cache** with expiration

### 🔄 Background Sync
- [ ] **Add background fetch** for price updates
- [ ] **Implement periodic sync** with exponential backoff
- [ ] **Add sync status** indicators in UI

## Phase 7: UI/UX Improvements (Week 7-8)

### 🎨 Design System
- [ ] **Create consistent design system**
  - Theme extensions
  - Typography scale
  - Color palette
  - Spacing system

- [ ] **Add dark/light mode** improvements
- [ ] **Implement responsive design** patterns

### 🧭 Navigation & UX
- [ ] **Add deep linking** support
- [ ] **Implement navigation state persistence**
- [ ] **Add search functionality** across holdings
- [ ] **Improve onboarding** experience

## Technical Implementation Details

### Backup Encryption Implementation
```dart
// File: lib/services/backup/encrypted_backup_service.dart
class EncryptedBackupService {
  Future<void> createEncryptedBackup() async {
    final data = await _serializeData();
    final key = await _getOrCreateEncryptionKey();
    final encrypted = await AesGcm.encrypt(
      data: utf8.encode(data),
      secretKey: key,
      nonce: generateNonce(),
    );
    await _saveEncryptedFile(encrypted);
  }
}
```

### Caching Strategy Implementation
```dart
// File: lib/services/cache/price_cache_service.dart
class PriceCacheService {
  final LruCache<String, PriceData> _memoryCache;
  final PriceCacheDao _databaseCache;
  final DioCacheInterceptor _httpCache;
  
  Future<PriceData> getPrice(String symbol) async {
    // 1. Check memory cache
    if (_memoryCache.containsKey(symbol)) {
      return _memoryCache[symbol]!;
    }
    
    // 2. Check database cache
    final cached = await _databaseCache.getCachedPrice(symbol);
    if (cached != null && !cached.isExpired) {
      _memoryCache[symbol] = cached;
      return cached;
    }
    
    // 3. Fetch from network with HTTP cache
    final price = await _fetchFromNetwork(symbol);
    await _cachePrice(symbol, price);
    return price;
  }
}
```

### Clean Architecture Structure
```
lib/
├── domain/
│   ├── entities/
│   │   ├── holding.dart
│   │   ├── instrument.dart
│   │   └── portfolio.dart
│   ├── repositories/
│   │   ├── holding_repository.dart
│   │   ├── price_repository.dart
│   │   └── backup_repository.dart
│   └── usecases/
│       ├── get_portfolio_summary.dart
│       ├── calculate_xirr.dart
│       └── create_backup.dart
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── holding_datasource.dart
│   │   │   └── price_datasource.dart
│   │   └── remote/
│   │       ├── yahoo_finance_api.dart
│   │       └── coingecko_api.dart
│   ├── models/
│   │   ├── holding_model.dart
│   │   └── price_model.dart
│   └── repositories/
│       ├── holding_repository_impl.dart
│       └── price_repository_impl.dart
└── presentation/
    ├── pages/
    │   ├── dashboard/
    │   └── holdings/
    ├── widgets/
    │   ├── portfolio_chart.dart
    │   └── holding_card.dart
    └── providers/
        ├── portfolio_provider.dart
        └── price_provider.dart
```

## Dependencies to Add

### Security & Encryption
```yaml
dependencies:
  flutter_secure_storage: ^10.0.0
  encrypt: ^5.0.0
  pointycastle: ^3.7.0
```

### Caching
```yaml
dependencies:
  dio_cache_interceptor: ^3.4.0
  flutter_cache_manager: ^3.3.0
  hive: ^2.2.3
```

### Architecture & DI
```yaml
dependencies:
  get_it: ^7.6.0
  injectable: ^2.1.0
  
dev_dependencies:
  injectable_generator: ^2.1.0
  build_runner: ^2.4.0
```

### Testing
```yaml
dev_dependencies:
  mockito: ^5.4.0
  integration_test: ^1.3.0
  benchmark_harness: ^2.2.0
```

## Success Criteria Checklist

### Phase 1 Completion
- [ ] Zero linting errors in `analysis.txt`
- [ ] Backup encryption implemented and tested
- [ ] All undefined identifiers fixed
- [ ] No unawaited futures in codebase

### Phase 2 Completion
- [ ] Dashboard loads in < 2 seconds with 100 holdings
- [ ] Price cache hit rate > 70%
- [ ] Memory usage < 200MB with large portfolio

### Phase 3 Completion
- [ ] Clean architecture layers implemented
- [ ] Dependency injection working
- [ ] All services have interfaces
- [ ] Repository pattern implemented

### Phase 4 Completion
- [ ] Test coverage > 80%
- [ ] Integration tests for all services
- [ ] UI tests for critical screens
- [ ] Performance benchmarks established

### Phase 5 Completion
- [ ] Certificate pinning implemented
- [ ] API key rotation working
- [ ] All user inputs validated
- [ ] Security audit passed

### Phase 6 Completion
- [ ] Offline operations work without network
- [ ] Sync queue handles conflicts
- [ ] Background sync working
- [ ] Data consistency maintained

### Phase 7 Completion
- [ ] Design system implemented
- [ ] Dark/light mode working
- [ ] Deep linking functional
- [ ] UX improvements validated

## Risk Mitigation

### Technical Risks
1. **Database Migration Issues**
   - Create migration tests
   - Implement rollback strategy
   - Backup before migration

2. **Performance Regression**
   - Establish performance baselines
   - A/B test changes
   - Monitor with Firebase Performance

3. **Security Vulnerabilities**
   - Regular security scans
   - Penetration testing
   - Code review for security

### Development Risks
1. **Scope Creep**
   - Stick to phased approach
   - Regular stakeholder reviews
   - Prioritize must-have vs nice-to-have

2. **Team Capacity**
   - Realistic timeline
   - Buffer for unexpected issues
   - Cross-training team members

## Next Immediate Actions

### Day 1-2
1. Run `dart fix --apply` to fix linting issues
2. Create encrypted backup service prototype
3. Fix undefined identifiers in import screens

### Day 3-5
1. Implement price caching layer
2. Move dashboard computations to isolates
3. Add pagination to holdings list

### Week 2
1. Begin Clean Architecture refactoring
2. Add dependency injection
3. Create service interfaces

## Monitoring & Metrics

### Code Quality Metrics
- **Linting Score**: Target 10/10
- **Test Coverage**: Target > 80%
- **Cyclomatic Complexity**: Target < 10 per method

### Performance Metrics
- **Dashboard Load Time**: Target < 2s
- **Memory Usage**: Target < 200MB
- **API Response Time**: Target < 1s

### User Metrics
- **Crash Rate**: Target < 0.1%
- **User Retention**: Target > 60% at 30 days
- **App Rating**: Target > 4.5 stars

---

*This todo list is based on the comprehensive architectural review. Each item is actionable and can be implemented independently while maintaining backward compatibility.*