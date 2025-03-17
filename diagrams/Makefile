.PHONY: all diagrams mermaid clean

# Default target to run all diagram generators
all: diagrams mermaid

# Generate graphical diagrams using diagrams Python library
diagrams:
	@echo "Generating graphical diagrams..."
	@python generate_diagrams.py

# Generate Mermaid diagrams for markdown
mermaid:
	@echo "Generating Mermaid markdown diagrams..."
	@python generate_mermaid.py

# Remove all generated diagrams
clean:
	@echo "Cleaning up generated diagrams..."
	@rm -rf output mermaid

# Install required dependencies
install:
	@echo "Installing dependencies..."
	@pip install diagrams 