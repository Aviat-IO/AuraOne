.PHONY: install build dev preview clean help

# Default target
help:
	@echo "Available commands:"
	@echo "  make install  - Install dependencies using bun"
	@echo "  make dev      - Start development server"
	@echo "  make build    - Build for production"
	@echo "  make preview  - Preview production build"
	@echo "  make clean    - Clean build artifacts and node_modules"
	@echo "  make help     - Show this help message"

# Install dependencies
install:
	@echo "Installing dependencies with bun..."
	@bun install

# Start development server
dev:
	@echo "Starting development server..."
	@bun run dev

# Build for production
build:
	@echo "Building for production..."
	@bun run build

# Preview production build
preview:
	@echo "Previewing production build..."
	@bun run preview

# Clean build artifacts and dependencies
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf dist
	@rm -rf node_modules
	@rm -f bun.lockb
	@echo "Clean complete!"