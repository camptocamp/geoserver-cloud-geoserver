#!/bin/bash

# Disable pagers for GitHub CLI
export GH_PAGER=""

# Check if version parameter is provided
if [ -z "$1" ]; then
  echo "Error: Version parameter is required"
  echo "Usage: $0 <version_to_delete>"
  exit 1
fi

VERSION_TO_DELETE="$1"
echo "Looking for packages with version: $VERSION_TO_DELETE"

# List all maven packages with pagination
echo "Fetching all Maven packages (handling pagination)..."
packages=""
page=1
per_page=100
more_pages=true

while [ "$more_pages" = true ]; do
  echo "  Fetching page $page..."
  response=$(gh api --method GET "/orgs/camptocamp/packages?package_type=maven&per_page=$per_page&page=$page")
  
  # Extract package names from current page
  page_packages=$(echo "$response" | jq -r '.[] | .name')
  
  # If no packages returned, we've reached the end
  if [ -z "$page_packages" ]; then
    more_pages=false
  else
    # Add to our package list
    if [ -z "$packages" ]; then
      packages="$page_packages"
    else
      packages="$packages"$'\n'"$page_packages"
    fi
    
    # Check if we got fewer packages than the per_page limit
    count=$(echo "$page_packages" | wc -l | tr -d ' ')
    if [ "$count" -lt "$per_page" ]; then
      more_pages=false
    else
      page=$((page + 1))
    fi
  fi
done

echo "Found $(echo "$packages" | wc -l | tr -d ' ') packages total."

echo "Looking for specific problematic packages..."
# Try to find specific packages that might not be in the generic list
for specific_pkg in "org.geoserver.geoserver" "org.geoserver"; do
  echo "  Checking for $specific_pkg package..."
  # Use 2>/dev/null to suppress error messages if the package doesn't exist
  if specific_package_result=$(gh api --method GET "/orgs/camptocamp/packages/maven/$specific_pkg" 2>/dev/null); then
    echo "  Found $specific_pkg package, adding to the list..."
    if ! echo "$packages" | grep -q "^$specific_pkg$"; then
      packages="$packages"$'\n'"$specific_pkg"
    fi
  else
    echo "  $specific_pkg package not found."
  fi
done

if [ -z "$packages" ]; then
  echo "No packages found."
  exit 0
fi

# Track counts
total_packages=0
packages_with_version=0
versions_deleted=0
errors=0

# For each package
for pkg in $packages; do
  total_packages=$((total_packages + 1))
  echo -e "\nProcessing package: $pkg"
  
  # Get all versions with the specified version with pagination
  echo "  Checking for versions matching '$VERSION_TO_DELETE'..."
  version_ids=""
  ver_page=1
  ver_per_page=100
  ver_more_pages=true
  
  while [ "$ver_more_pages" = true ]; do
    # Use 2>/dev/null to ignore errors from packages that don't exist
    ver_response=$(gh api --method GET "/orgs/camptocamp/packages/maven/$pkg/versions?per_page=$ver_per_page&page=$ver_page" 2>/dev/null)
    
    # Check if we got a valid response
    if [ -z "$ver_response" ] || echo "$ver_response" | grep -q "error"; then
      ver_more_pages=false
      continue
    fi
    
    # Extract version IDs from current page
    page_version_ids=$(echo "$ver_response" | jq -r ".[] | select(.name == \"$VERSION_TO_DELETE\") | .id")
    
    if [ -z "$page_version_ids" ]; then
      # No matching versions on this page
      if [ "$(echo "$ver_response" | jq -r '. | length')" -lt "$ver_per_page" ]; then
        # Less than per_page results means we're on the last page
        ver_more_pages=false
      else
        # Full page but no matches, check next page
        ver_page=$((ver_page + 1))
      fi
    else
      # Found matching versions on this page
      if [ -z "$version_ids" ]; then
        version_ids="$page_version_ids"
      else
        version_ids="$version_ids"$'\n'"$page_version_ids"
      fi
      
      # Check if we're on the last page
      if [ "$(echo "$ver_response" | jq -r '. | length')" -lt "$ver_per_page" ]; then
        ver_more_pages=false
      else
        ver_page=$((ver_page + 1))
      fi
    fi
  done
  
  if [ -z "$version_ids" ]; then
    echo "  No matching versions found for $pkg"
    continue
  fi
  
  packages_with_version=$((packages_with_version + 1))
  echo "  Found matching versions: $(echo "$version_ids" | wc -l | tr -d ' ')"
  
  # Check how many versions this package has - ignore errors
  total_versions=$(gh api --method GET "/orgs/camptocamp/packages/maven/$pkg/versions" 2>/dev/null | jq -r '. | length')
  if [ -z "$total_versions" ] || ! [[ "$total_versions" =~ ^[0-9]+$ ]]; then
    total_versions=0
  fi
  
  # Delete each matching version
  for id in $version_ids; do
    echo "  Deleting version ID: $id"
    
    if [ "$total_versions" -eq 1 ]; then
      echo "  ! This is the only version of this package. Deleting entire package instead."
      if gh api --method DELETE "/orgs/camptocamp/packages/maven/$pkg" >/dev/null 2>&1; then
        echo "  ✓ Successfully deleted entire package $pkg"
        versions_deleted=$((versions_deleted + 1))
      else
        echo "  ✗ Failed to delete package $pkg"
        errors=$((errors + 1))
      fi
      # Since we deleted the package, break out of the version loop
      break
    else
      # Try to delete the version - capture output for possible error handling
      delete_output=$(gh api --method DELETE "/orgs/camptocamp/packages/maven/$pkg/versions/$id" 2>&1 || echo "ERROR")
      
      if [ "$delete_output" = "ERROR" ] || echo "$delete_output" | grep -q "error"; then
        # Check if it failed because it's the last version
        if echo "$delete_output" | grep -q "last version"; then
          echo "  ! This is the last version. Deleting entire package instead."
          if gh api --method DELETE "/orgs/camptocamp/packages/maven/$pkg" >/dev/null 2>&1; then
            echo "  ✓ Successfully deleted entire package $pkg"
            versions_deleted=$((versions_deleted + 1))
          else
            echo "  ✗ Failed to delete package $pkg"
            errors=$((errors + 1))
          fi
          # Since we deleted the package, break out of the version loop
          break
        else
          echo "  ✗ Failed to delete version $VERSION_TO_DELETE (ID: $id) for package $pkg"
          errors=$((errors + 1))
        fi
      else
        echo "  ✓ Successfully deleted version $VERSION_TO_DELETE (ID: $id) for package $pkg"
        versions_deleted=$((versions_deleted + 1))
      fi
    fi
  done
done

# Print summary
echo -e "\n--- Summary ---"
echo "Total packages checked: $total_packages"
echo "Packages with version '$VERSION_TO_DELETE': $packages_with_version"
echo "Versions successfully deleted: $versions_deleted"
echo "Errors encountered: $errors"

if [ $errors -gt 0 ]; then
  exit 1
else
  exit 0
fi