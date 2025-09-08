# Makefile for Aura One mobile app development
# Optimized for macOS development with Android emulator

.PHONY: install dev emulators devices clean help

# Default target
help:
	@echo "Available commands:"
	@echo "  make install    - Install all dependencies and tools needed for development"
	@echo "  make dev        - Launch Android emulator and run app with hot reload"
	@echo "  make emulators  - List available Android emulators"
	@echo "  make devices    - List connected devices and emulators"
	@echo "  make clean      - Clean build artifacts and dependencies"
	@echo "  make help       - Show this help message"

# Install everything needed for development on macOS
install:
	@echo "📦 Installing dependencies for macOS development..."
	@echo "→ Checking for Homebrew..."
	@which brew > /dev/null || (echo "Installing Homebrew..." && /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
	
	@echo "→ Checking for Android Studio..."
	@if ! [ -d "/Applications/Android Studio.app" ]; then \
		echo "Installing Android Studio..."; \
		brew install --cask android-studio; \
	else \
		echo "✓ Android Studio already installed"; \
	fi
	
	@echo "→ Checking for FVM..."
	@which fvm > /dev/null || (echo "Installing FVM..." && brew tap leoafarias/fvm && brew install fvm)
	
	@echo "→ Installing Flutter SDK via FVM..."
	@fvm install
	
	@echo "→ Installing Flutter dependencies..."
	@fvm flutter pub get
	
	@echo "→ Accepting Android licenses..."
	@yes | fvm flutter doctor --android-licenses 2>/dev/null || true
	
	@echo "→ Running Flutter doctor..."
	@fvm flutter doctor
	
	@echo ""
	@echo "✅ Installation complete!"
	@echo "Note: You may need to:"
	@echo "  1. Open Android Studio and set up an AVD (Android Virtual Device)"
	@echo "  2. Configure Android SDK path if needed"

# Run the app with hot reload on Android emulator
dev:
	@echo "🚀 Starting development server..."
	@echo "→ Checking for running emulators..."
	@if ! fvm flutter devices | grep -q "emulator"; then \
		echo "No emulator running. Available emulators:"; \
		fvm flutter emulators; \
		echo ""; \
		echo "Please start an emulator first:"; \
		echo "  1. Open Android Studio → Tools → AVD Manager"; \
		echo "  2. Click the play button next to your emulator"; \
		echo "  OR"; \
		echo "  Run: fvm flutter emulators --launch <emulator_name>"; \
		exit 1; \
	fi
	@echo "→ Running app with hot reload..."
	fvm flutter run

# List available emulators
emulators:
	@echo "📱 Available Android emulators:"
	@fvm flutter emulators

# List connected devices
devices:
	@echo "📱 Connected devices and emulators:"
	@fvm flutter devices

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@fvm flutter clean
	@echo "✅ Clean complete!"

# Additional helpful targets

# Run in release mode for better performance
release:
	@echo "🚀 Running in release mode..."
	fvm flutter run --release

# Build APK for distribution
build-apk:
	@echo "📦 Building APK..."
	fvm flutter build apk --target-platform android-arm64 --split-per-abi
	@echo "✅ APK built! Find it in build/app/outputs/flutter-apk/"

# Run tests
test:
	@echo "🧪 Running tests..."
	fvm flutter test

# Analyze code
analyze:
	@echo "🔍 Analyzing code..."
	fvm flutter analyze

# Format code
format:
	@echo "✨ Formatting code..."
	fvm dart format lib/

# Update dependencies
update:
	@echo "⬆️ Updating dependencies..."
	fvm flutter pub upgrade

# Quick emulator launch (tries to launch first available emulator)
quick-emulator:
	@echo "🚀 Launching first available emulator..."
	@EMULATOR=$$(fvm flutter emulators | grep -o "^[^•]*" | head -n 1 | xargs); \
	if [ -n "$$EMULATOR" ]; then \
		echo "Launching $$EMULATOR..."; \
		fvm flutter emulators --launch "$$EMULATOR"; \
	else \
		echo "No emulators found. Please create one in Android Studio."; \
		exit 1; \
	fi

# Combined command to launch emulator and run app
dev-full: quick-emulator
	@echo "⏳ Waiting for emulator to boot..."
	@sleep 10
	@$(MAKE) dev