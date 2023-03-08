#!/bin/bash
# if [ $# -eq 0 ];then
#   echo "Usage: ${0} commit-message"
# fi
git pull
git add . && git commit -m "weiyigeek.top"
git push