#!/bin/bash

set -e  # Exit on error

DEFAULT_BRANCH="main"
RELEASE_BRANCH="release"

# Function to check if a branch exists remotely
branch_exists_remote() {
    git ls-remote --heads origin "$1" | grep -q "$1"
}

# Function to check if a branch exists locally
branch_exists_local() {
    git show-ref --verify --quiet refs/heads/"$1"
}

# Function to check for uncommitted changes
has_uncommitted_changes() {
    [ -n "$(git status --porcelain)" ]
}

# Ensure we are in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This is not a Git repository."
    exit 1
fi

# Handle different modes
case "$1" in
  release)
    echo "🚀 Preparing release..."

    # Ensure we are on the main branch
    git checkout "$DEFAULT_BRANCH"

    if has_uncommitted_changes; then
        echo "❌ Error: There are uncommitted changes in $DEFAULT_BRANCH."
        echo "💡 Please commit your changes first by running:"
        echo "   ./publish.sh"
        exit 1
    fi

    # Push latest main commits
    echo "🔄 Pushing latest commits to remote $DEFAULT_BRANCH..."
    git push origin "$DEFAULT_BRANCH"

    # Create release branch if it doesn't exist
    if ! branch_exists_local "$RELEASE_BRANCH"; then
        echo "⚠️ Creating new $RELEASE_BRANCH branch..."
        git branch "$RELEASE_BRANCH"
    fi

    if ! branch_exists_remote "$RELEASE_BRANCH"; then
        echo "⚠️ Setting up remote $RELEASE_BRANCH branch..."
        git push -u origin "$RELEASE_BRANCH"
    fi

    # Switch to release branch
    git checkout "$RELEASE_BRANCH"
    
    # Get the latest release branch state
    git fetch origin "$RELEASE_BRANCH"
    git reset --hard origin/"$RELEASE_BRANCH"

    echo "🔹 Enter release message: "
    read RELEASE_MESSAGE

    # Merge main into release with a squash merge
    git merge --squash "$DEFAULT_BRANCH"
    git commit -m "Release: $RELEASE_MESSAGE"
    
    # Push to release branch
    git push origin "$RELEASE_BRANCH"
    echo "✅ Changes released to $RELEASE_BRANCH!"

    # Switch back to main branch
    git checkout "$DEFAULT_BRANCH"
    ;;

  *)
    echo "🔹 Enter development commit message: "
    read COMMIT_MESSAGE
    git add .
    git commit -m "$COMMIT_MESSAGE" || {
        echo "✅ No new changes to commit."
        exit 0
    }
    echo "✅ Changes committed to the $DEFAULT_BRANCH branch!"
    echo "🔄 Pushing latest commits to remote $DEFAULT_BRANCH..."
    git push origin "$DEFAULT_BRANCH"
    ;;
esac

