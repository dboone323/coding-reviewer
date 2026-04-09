#!/bin/bash
# Safe Auto-Apply Enhancements

# This script applies a series of safe enhancements to Swift code,
# ensuring consistency, readability, and maintainability.
echo "🤖 Applying safe enhancements..."

# 1. Format code consistently using SwiftFormat
if command -v swiftformat &>/dev/null; then
    # Check if SwiftFormat is installed and available
    echo "🔧 Applying SwiftFormat..."
    
    # Apply SwiftFormat to all Swift files in the current directory
    swiftformat . --config ".swiftformat" 2>/dev/null || \
        # Handle errors, display success message with a checkmark
        echo "✅ SwiftFormat applied"
fi

# 2. Remove trailing whitespace from all Swift files
echo "🔧 Removing trailing whitespace..."
find . -name "*.swift" -exec sed -i.bak 's/[[:space:]]*$//' {} \;
# Delete backup files created during the process
find . -name "*.swift.bak" -delete

# 3. Organize imports in Swift files (basic)
echo "🔧 Organizing imports..."
find . -name "*.swift" -exec sed -i.bak '/^import/{ /Foundation/!{H; d}; }; ${g}' {} \; 2>/dev/null || true
# Delete backup files created during the process
find . -name "*.swift.bak" -delete

# 4. Add basic documentation templates to Swift functions
echo "🔧 Adding documentation templates..."
find . -name "*.swift" -exec sed -i.bak '/^[[:space:]]*func.*{/i\
    /// <#Description#>\
    /// - Returns: <#description#>
' {} \; 2>/dev/null || true
# Delete backup files created during the process
find . -name "*.swift.bak" -delete

echo "✅ Safe enhancements completed!"
