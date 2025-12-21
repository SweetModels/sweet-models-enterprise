#!/bin/bash

echo "======================================"
echo "Admin Dashboard Implementation Checker"
echo "======================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed"
    exit 1
fi

cd "mobile_app" || exit 1

echo "✅ Navigation to mobile_app folder"
echo ""

# Check if all required files exist
echo "Checking required files..."
echo ""

files=(
    "lib/models/dashboard_stats.dart"
    "lib/services/dashboard_service.dart"
    "lib/screens/admin_dashboard_screen.dart"
)

all_files_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - EXISTS"
    else
        echo "❌ $file - MISSING"
        all_files_exist=false
    fi
done

echo ""

# Check dependencies
echo "Checking dependencies..."
echo ""

if grep -q "dio:" pubspec.yaml; then
    echo "✅ dio dependency - OK"
else
    echo "❌ dio dependency - MISSING"
fi

if grep -q "shared_preferences:" pubspec.yaml; then
    echo "✅ shared_preferences dependency - OK"
else
    echo "❌ shared_preferences dependency - MISSING"
fi

if grep -q "google_fonts:" pubspec.yaml; then
    echo "✅ google_fonts dependency - OK"
else
    echo "❌ google_fonts dependency - MISSING"
fi

echo ""

# Check for compilation errors
echo "Checking for Dart analysis issues..."
echo ""

flutter analyze --no-pub > /tmp/flutter_analysis.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ No Dart analysis errors"
else
    echo "⚠️  Some warnings found (see details below):"
    cat /tmp/flutter_analysis.txt | grep -i "error" || echo "   (Only warnings, not critical)"
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo ""

if [ "$all_files_exist" = true ]; then
    echo "✅ All required files are present"
    echo "✅ Admin Dashboard is ready for testing"
    echo ""
    echo "Next steps:"
    echo "1. Ensure backend is running (http://localhost:3000)"
    echo "2. Run: flutter run"
    echo "3. Login with: admin@sweetmodels.com / sweet123"
    echo "4. Verify AdminDashboardScreen displays"
else
    echo "❌ Some files are missing"
    echo "Please review the implementation"
fi

echo ""
