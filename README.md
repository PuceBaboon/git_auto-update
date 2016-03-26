# git_auto-update
This is basically a shell script which will keep a collection of repositories up to date (if you ask it nicely).

## The concept
I found myself with a directory rapidly filling with sub-directories, all of which were copies of GitHub repositories (ESP8266 projects) and most of which were seriously out of date.  This script is a simple method of keeping stuff that you're interested in up to date.

There may well be a way to do this already within git, but to honest, I find the documentation to be overwhelming and confusing (too few grey cells available to parse the strange nomenclature).

## The solution
Fall back on the tried and tested shell-script-plus-cron method.

This script uses "find" to build a tree of the subdirectories below a given starting point and then checks for a .git subdirectory within each of them to decide whether to run a "pull" or not.

It recognizes an exclude file (currently named "Do_Not_Update.txt") in the top-level directory which should contain a list of subdirectories, one per line, which you do -not- want to have updated (these might be active branches which you're working on). Please refer to the included example Do_Not_Update.txt file for the format of entries for this file.  

The script also recognizes an empty file (named "Do_Not_Update") which, if present in a subdirectory, will cause that specific directory to be excluded from the automatic update process.

The script writes a log file with the status of each attempted pull request.  

All of these files can be customized by editing the settings in the top few lines of the script.  The WK_DIR variable sets the path to the top-level (starting point) directory and should be changed to suit your needs.

The idea is that the script will be called from cron once a week (or once a night, or once a month) and will quietly pull in the latest and greatest updates from all of those projects you've been following.  You might additionally want to email yourself a copy of the log file after the script completes.

```
# Auto update of ESP8266 projects (early on Monday mornings).
42	02	*	*	1	/bin/sh /FuLl/PaTh/To/git_auto_update.sh >> /var/tmp/GitPull.log 2>&1
```
