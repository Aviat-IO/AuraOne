.PHONY: install build dev clean


# Install dependencies
install: clean
	@echo "Installing dependencies with bun..."
	@bun install

# Start development server
dev: install
	@echo "Starting development server..."
	@bun run dev

# Build for production
build: install
	@echo "Building for production..."
	@bun run build

# Clean build artifacts and dependencies
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf dist
	@rm -rf node_modules
	@rm -f bun.lockb
	@echo "Clean complete!"
