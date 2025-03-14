
# File Migration Guide

## Authentication Files
- All auth providers → features/auth/domain/providers/
- Auth screens → features/auth/presentation/screens/
- Auth widgets → features/auth/presentation/widgets/
- Auth services → features/auth/data/services/
- Auth repositories → features/auth/data/repositories/
- Auth models → features/auth/domain/models/

## Navigation Files
- Route names → core/navigation/route_names.dart
- App router → core/navigation/app_router.dart
- Navigation services → core/navigation/navigation_service.dart

## Firebase Configuration
- Firebase options → firebase_options.dart (root)
- Firebase services → core/services/firebase_service.dart

## Global Services
- Global auth service → core/services/global_auth_service.dart
- Storage services → core/services/storage_service.dart
- Image services (consolidate) → core/services/image_service.dart

## Utils and Exceptions
- Debug logger → core/utils/debug_logger.dart
- Validators → core/utils/validators.dart
- Exception handlers → core/exceptions/app_exceptions.dart

## Feature-specific Files
- Home screen → features/home/presentation/screens/home_screen.dart
- Property details → features/property/presentation/screens/property_detail_screen.dart
- Profile screens → features/profile/presentation/screens/
- Admin screens → features/admin/presentation/screens/

## Shared Components
- Shared widgets → shared/widgets/
- Loading overlay → shared/widgets/loading_overlay.dart
