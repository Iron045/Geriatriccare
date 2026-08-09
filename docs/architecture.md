# GeriatricCare architecture

The project follows feature-first Clean Architecture.

```text
lib/
├── app/                         # App composition, routes and theme
├── core/                        # Cross-feature code only
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/     # Firebase, REST and local storage access
│       │   ├── models/          # DTO and serialization
│       │   └── repositories/    # Domain repository implementations
│       ├── domain/
│       │   ├── entities/        # Pure Dart business objects
│       │   ├── repositories/    # Abstract contracts
│       │   └── usecases/        # One business operation per class
│       └── presentation/
│           ├── controllers/     # Riverpod state and orchestration
│           ├── pages/           # Screens
│           └── widgets/         # Feature-specific widgets
└── main.dart                    # Bootstrap only
```

`features/elder` owns the Elder shell and home screen. Health, SOS,
medication, profile, and account linking remain separate business features and
are composed by the Elder shell.

Authentication owns phone OTP, Firebase session state, and the `users/{uid}`
profile. `AuthGate` is the application entry point and selects the UI from the
stored user role.

Dependency direction:

```text
presentation -> domain <- data
app -> features + core
```

The domain layer must not import Flutter, Firebase, Riverpod, or concrete data models. The data layer converts Firebase documents into domain entities. Presentation calls use cases rather than Firebase directly.
