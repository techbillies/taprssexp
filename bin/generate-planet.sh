# Script used at blog.nilenso.com to pull recent changes and create a new build

#!/usr/bin/env sh

LOGFILE=/home/deploy/log/planet.log

# needed for rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

echo >> $LOGFILE
date >> $LOGFILE

cd /home/deploy/blog.nilenso.com \
    && git checkout deploy >> $LOGFILE 2>&1 \
    && git reset HEAD  >> $LOGFILE 2>&1 \
    && git checkout -- . >> $LOGFILE 2>&1 \
    && git fetch origin >> $LOGFILE 2>&1 \
    && git merge -X theirs origin/master >> $LOGFILE 2>&1 \
    && bundle exec planet generate >> $LOGFILE 2>&1 \
    && bundle exec jekyll build >> $LOGFILE 2>&1 \
    && git add --all . >> $LOGFILE 2>&1

if [ $(git --no-pager diff --name-only --diff-filter=AD --staged | wc -l) -gt 0 ]; then
    git commit -m "Deploy commit $(date)" >> $LOGFILE 2>&1 \
    && git push origin deploy >> $LOGFILE 2>&1
fi

echo "Logged to $LOGFILE"
