#!/usr/bin/env bash
#MISE description="Run the tests and enforce the minimum test count"
# Runs the suite once and fails when a test fails or when the count drops below the
# floor, so deleting corpus cases cannot pass silently. The report goes to stdout and,
# in GitHub Actions, to the job summary.
set -euo pipefail

min_tests=115

# Capture the output and the exit code without letting set -e stop the script.
test_exit=0
test_output=$(tree-sitter test 2>&1) || test_exit=$?

# grep -c already prints 0 when nothing matches; `|| true` only swallows its exit 1
total=$(echo "$test_output" | grep -cE "^\s+[0-9]+\." || true)
passing=$(echo "$test_output" | grep -cE "^\s+[0-9]+\. ✓" || true)
failing=$(echo "$test_output" | grep -cE "^\s+[0-9]+\. ✗" || true)

coverage=0
if [ "$total" -gt 0 ]; then
  coverage=$(((passing * 100) / total))
fi

report=$(
  echo "## Test Coverage Report"
  echo ""
  echo "- **Total Tests:** $total"
  echo "- **Passing:** $passing ✅"
  echo "- **Failing:** $failing ❌"
  echo "- **Coverage:** $coverage%"
  echo ""
  echo "### Test Files"
  echo "$test_output" | grep -E "^[[:space:]]+[A-Za-z0-9._/\\-]+:" | sed 's/^/- /' || true
)

echo "$report"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "$report" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$total" -lt "$min_tests" ]; then
  echo "❌ Expected at least $min_tests tests, found $total"
  exit 1
fi

if [ "$failing" -gt 0 ] || [ "$test_exit" -ne 0 ]; then
  echo "❌ Found $failing failing tests or test runner failed (exit code: $test_exit)"
  exit 1
fi

echo "✅ Test coverage is acceptable: $passing/$total tests passing ($coverage%)"
