#!/bin/bash

current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "========================================="
echo "        SYSTEM INFORMATION SCRIPT        "
echo "========================================="
echo "Current Date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"
echo "-----------------------------------------"

echo "Disk Usage:"
df -h
echo "-----------------------------------------"

echo "Running Processes (first 10):"
ps aux | head -10
echo "-----------------------------------------"

read -p "Enter a directory name to create: " dir_name
read -p "Enter a file name to create inside it: " file_name

mkdir -p "$dir_name"
touch "$dir_name/$file_name"

ps aux > "$dir_name/$file_name"

echo "-----------------------------------------"
echo "Created directory : $dir_name"
echo "Created file      : $dir_name/$file_name"
echo "Saved $(( $(wc -l < "$dir_name/$file_name") )) lines of process info into the file."
echo "========================================="
