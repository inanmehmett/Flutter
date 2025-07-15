# Daily English - Flutter App

A Flutter application for learning English through reading and interactive exercises.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following structure:

```
lib/
├── core/                    # Core functionality
│   ├── app/                # App-level configurations
│   ├── cache/              # Caching mechanisms
│   ├── config/             # App configuration
│   ├── constants/          # App constants
│   ├── di/                 # Dependency injection
│   ├── error/              # Error handling
│   ├── managers/           # Business logic managers
│   ├── network/            # Network layer
│   ├── settings/           # App settings
│   ├── storage/            # Local storage
│   ├── sync/               # Data synchronization
│   ├── theme/              # App theming
│   └── widgets/            # Reusable widgets
├── features/               # Feature modules
│   ├── auth/               # Authentication
│   ├── home/               # Home screen
│   ├── main/               # Main app flow
│   ├── onboarding/         # Onboarding
│   ├── quiz/               # Quiz functionality
│   ├── reader/             # Book reading
│   └── user/               # User management
└── main.dart               # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK (>=3.2.3)
- Android Studio / VS Code

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd daily_english
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

## 🧹 Clean Code Guidelines

### 1. **Naming Conventions**

- Use `camelCase` for variables and methods
- Use `PascalCase` for classes and enums
- Use `snake_case` for file names
- Use descriptive names that explain intent

### 2. **File Organization**

- One class per file
- Group related functionality in folders
- Keep files under 300 lines
- Use meaningful folder names

### 3. **Code Structure**

- Follow Single Responsibility Principle
- Keep methods short and focused
- Use meaningful comments for complex logic
- Avoid deep nesting (max 3 levels)

### 4. **Error Handling**

- Use `Either<Failure, T>` for error handling
- Don't ignore exceptions
- Provide meaningful error messages
- Log errors appropriately

### 5. **Dependency Injection**

- Use GetIt for service locator pattern
- Register dependencies in `injection.dart`
- Use `@injectable` annotations
- Keep dependencies minimal

## 📱 Features

- **Authentication**: User login and registration
- **Book Reading**: Interactive reading experience
- **Progress Tracking**: Track reading progress
- **Offline Support**: Read books without internet
- **Quiz System**: Test comprehension
- **Favorites**: Save favorite words and books

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: BLoC Pattern
- **Dependency Injection**: GetIt + Injectable
- **Network**: Dio
- **Local Storage**: Hive + SharedPreferences
- **Error Handling**: Dartz (Either)
- **Code Generation**: Build Runner

## 🔧 Configuration

### Environment Variables

Set the following environment variables:

```bash
# API Configuration
API_BASE_URL=http://192.168.1.101:5173

# Build Configuration
flutter run --dart-define=API_BASE_URL=http://192.168.1.101:5173
```

## 📊 Code Quality

### Linting

The project uses strict linting rules defined in `analysis_options.yaml`:

- `avoid_print`: Prevents debug print statements
- `prefer_single_quotes`: Consistent string quotes
- `prefer_const_constructors`: Performance optimization
- And many more...

### Running Analysis

```bash
flutter analyze
```

### Code Formatting

```bash
dart format lib/
```

## 🚨 Common Issues & Solutions

### 1. **Duplicate Files**

- ✅ **Fixed**: Removed duplicate data source files
- **Solution**: Keep only one implementation per interface

### 2. **Excessive Logging**

- ✅ **Fixed**: Removed debug print statements
- **Solution**: Use proper logging framework for production

### 3. **Over-Engineered Interfaces**

- ✅ **Fixed**: Simplified repository interface
- **Solution**: Follow Interface Segregation Principle

### 4. **Hardcoded Values**

- ✅ **Fixed**: Moved to environment variables
- **Solution**: Use configuration files or environment variables

## 🤝 Contributing

1. Follow the clean code guidelines
2. Write meaningful commit messages
3. Add tests for new features
4. Update documentation
5. Run `flutter analyze` before committing

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
