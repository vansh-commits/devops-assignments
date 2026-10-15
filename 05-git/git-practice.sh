#!/bin/bash

rm -rf /tmp/git-practice && mkdir -p /tmp/git-practice && cd /tmp/git-practice || exit 1
git init -b main

echo "version 1" > file1.txt
git status --short
git commit -m "add file1"                # fails: nothing staged

git add file1.txt
git commit -m "add file1"                # works

echo "version 2" > file1.txt             # modify tracked file
echo "new file" > file2.txt              # new untracked file
git status --short
git commit -a -m "update file1 using -a" # only file1.txt is committed
git status --short                       # file2.txt still untracked

git add file2.txt && git commit -m "add file2"

echo "# Git practice" > README.md
git add README.md && git commit -m "add README"
git log --oneline                        # 4 commits on main

git checkout -b feature
echo "feature work 1" > feat1.txt  && git add feat1.txt  && git commit -m "feature: add feat1"
echo "IMPORTANT FIX"  > bugfix.txt && git add bugfix.txt && git commit -m "feature: important bugfix"
echo "feature work 3" > feat3.txt  && git add feat3.txt  && git commit -m "feature: add feat3"
git log --oneline --graph --all

fix_hash=$(git log --format=%h --grep="important bugfix" -n 1)
echo "Commit to cherry-pick: $fix_hash"

git checkout main
ls
git cherry-pick "$fix_hash"

ls
cat bugfix.txt
git log --oneline
