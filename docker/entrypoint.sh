#!/bin/bash
set -e

cp -rT /etc/skel /home/student 2>/dev/null || true

if [ -d /opt/course ]; then
  cp -rn /opt/course/. /home/student/ 2>/dev/null || true
  rm -f /home/student/banner.txt
fi

git config --global init.defaultBranch main
git config --global color.ui auto
git config --global user.name "student"
git config --global user.email "student@bashland.org"

if [ -f /opt/course/banner.txt ]; then
  cat /opt/course/banner.txt
  echo
fi

cd /home/student
exec /bin/bash --login
