#!/bin/bash

# Store current branch name (usually main)
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Create a fresh orphan branch
git checkout --orphan temp_branch

# Add all files
git add .

# Commit with a clean slate message
git commit -m "Fresh start: Clean repository state"

# Delete the old branch
git branch -D $current_branch

# Rename temp branch to the original branch name
git branch -m $current_branch

# Force push to remote
git push -f origin $current_branch

# Clean up refs and remove old objects
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Remove backup if everything went well
rm -rf .git.backup
