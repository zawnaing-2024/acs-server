# Git Workflow - Step by Step Guide

## 🚀 Quick Commands Summary

### Push Changes to GitHub:
```bash
git add .
git commit -m "Fix GenieACS port 7547 issue - Updated to official image"
git push origin main
```

### Pull Latest Changes:
```bash
git pull origin main
```

---

## 📋 Step-by-Step Git Operations

### **Step 1: Check Current Status**
```bash
# See what files have been modified
git status
```

**Expected Output:**
```
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   docker-compose.yml

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        fix-genieacs.sh
        GIT-WORKFLOW.md
```

### **Step 2: Add Files to Staging**
```bash
# Add all modified and new files
git add .

# OR add specific files:
git add docker-compose.yml
git add fix-genieacs.sh
git add INSTALLATION-GUIDE.md
git add final-ubuntu-install.sh
```

### **Step 3: Commit Changes**
```bash
# Commit with a descriptive message
git commit -m "Fix GenieACS port 7547 issue - Updated to official image v1.2.8

- Changed from drumsergio/genieacs to official genieacs/genieacs:1.2.8
- Fixed command paths for GenieACS binaries
- Added fix-genieacs.sh script for automatic repair
- Updated installation guides with CPE device setup
- Added final-ubuntu-install.sh for complete automation"
```

### **Step 4: Push to GitHub**
```bash
# Push changes to main branch
git push origin main
```

**If you get authentication error:**
```bash
# Configure your GitHub credentials first
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Then push again
git push origin main
```

---

## 🔄 Pull Latest Changes from GitHub

### **Step 1: Check for Remote Changes**
```bash
# Fetch latest information from remote
git fetch origin

# Check if there are new commits
git status
```

### **Step 2: Pull Changes**
```bash
# Pull latest changes from main branch
git pull origin main
```

### **Step 3: Handle Conflicts (if any)**
If there are merge conflicts:
```bash
# Git will show which files have conflicts
# Edit the conflicted files to resolve conflicts
# Look for lines with <<<<<<< and >>>>>>>

# After resolving conflicts:
git add .
git commit -m "Resolve merge conflicts"
```

---

## 🛠️ Common Git Scenarios

### **Scenario 1: First Time Setup**
```bash
# Clone the repository
git clone https://github.com/zawnaing-2024/acs-server.git
cd acs-server

# Configure your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### **Scenario 2: Working with Branches**
```bash
# Create a new branch for features
git checkout -b feature/genieacs-fix

# Make your changes, then:
git add .
git commit -m "Fix GenieACS configuration"
git push origin feature/genieacs-fix

# Switch back to main
git checkout main

# Merge the feature branch
git merge feature/genieacs-fix
git push origin main
```

### **Scenario 3: Undo Changes**
```bash
# Undo changes to a specific file (before commit)
git checkout -- docker-compose.yml

# Undo last commit (keep changes in working directory)
git reset --soft HEAD~1

# Undo last commit (discard all changes)
git reset --hard HEAD~1
```

### **Scenario 4: View History**
```bash
# View commit history
git log --oneline

# View changes in last commit
git show

# View changes between commits
git diff HEAD~1 HEAD
```

---

## 🚨 Emergency Commands

### **Force Push (Use with Caution!)**
```bash
# Only use if you're sure about overwriting remote history
git push --force origin main
```

### **Reset to Remote State**
```bash
# Discard all local changes and match remote
git fetch origin
git reset --hard origin/main
```

### **Stash Changes Temporarily**
```bash
# Save current changes without committing
git stash

# Apply stashed changes later
git stash apply

# List all stashes
git stash list
```

---

## 📂 Current Repository Status

### **Repository:** https://github.com/zawnaing-2024/acs-server
### **Branch:** main
### **Recent Changes:**
- Fixed GenieACS Docker image issues
- Updated port 7547 configuration
- Added comprehensive installation guides
- Created automated fix scripts

### **Files to Push:**
- `docker-compose.yml` (Updated GenieACS configuration)
- `fix-genieacs.sh` (GenieACS repair script)
- `final-ubuntu-install.sh` (Complete automation script)
- `INSTALLATION-GUIDE.md` (Comprehensive setup guide)
- `CPE-DEVICE-SETUP.md` (Device configuration guide)

---

## 🎯 Quick Action Plan

### **Right Now - Push Current Fixes:**
```bash
# 1. Add all changes
git add .

# 2. Commit with message
git commit -m "Fix GenieACS port 7547 - Use official image v1.2.8"

# 3. Push to GitHub
git push origin main
```

### **Before Deployment - Pull Latest:**
```bash
# Always pull before deploying to server
git pull origin main

# Then run the installation
./final-ubuntu-install.sh
```

---

## 🔍 Verification Commands

### **After Push - Verify on GitHub:**
1. Visit: https://github.com/zawnaing-2024/acs-server
2. Check that your commits appear in the history
3. Verify files are updated

### **After Pull - Verify Locally:**
```bash
# Check that you have latest changes
git log --oneline -5

# Check file contents
ls -la
cat docker-compose.yml | grep genieacs
```

---

## 💡 Best Practices

### **Commit Messages:**
- Use present tense: "Fix bug" not "Fixed bug"
- Be descriptive but concise
- Reference issue numbers if applicable

### **Before Pushing:**
```bash
# Always check what you're about to commit
git diff --staged

# Test your changes locally
docker compose down && docker compose up -d
```

### **Before Pulling:**
```bash
# Save your work first
git add .
git commit -m "WIP: Save current work"

# Then pull
git pull origin main
```

---

*This guide covers all common Git operations for the ACS Management Portal project. Keep this handy for reference during development and deployment.* 