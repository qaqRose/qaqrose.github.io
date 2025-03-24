#!/bin/bash

# 配置用户
git config user.name "qxq"
git config user.email "singleqaq@gmail.com"

# 中文乱码
git config core.quotepath false
# editor
git config core.editor vim

git status

git add .

if [ -n "$1" ]; then
    git commit -m "$1"
else
    git commit -m "commit"
fi


git fetch --all

git pull origin main

git push -u origin main
