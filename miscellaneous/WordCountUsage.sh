#!/bin/sh
# Count unique users (by IP address) of the RealCount web page.
# Input is the Rails log file to be parsed, usually ../log/production.log
#
# Typical log line of actual use (POST not GET) looks like this, starting with
# a unique GUID that identifies the request that the identically marked
# subsequent log lines are for (we'll ignore the multitasking problem):
# [f63b05d5-6e9a-4c03-9fc7-4c405f93d595] Started POST "/server01/wordcounter" for 172.56.71.108 at 2023-11-22 09:41:08 -0500
# ...] Processing by WordCounterController#update as HTML
# ...]   Parameters: {"authenticity_token"=>"[FILTERED]", "vo_script"=>"We are #1!", "commit"=>"Update the Count", ... "exp_www"=>"true"}
# ...]   839 word script expanded to 857 words (18 extra).
# ...] Completed 200 OK in 132ms (Views: 46.3ms | ActiveRecord: 0.0ms | Allocations: 85480)
#
# The "Started POST" marks the start of the operation,
# "commit"=>"Update the Count" means it is a real count, not an example etc,
# The "839 word script expanded to 857 words (18 extra)." gives us statistics.

awk 'BEGIN {
  FS=" "
  examplecount=0
  extratotal=0
  isexample=0
  usecount=0
  wordtotal=0
}
/^\[[0-9a-f-]+] Started POST "\/server01\/wordcounter"/ {IPs[$6]++}
/"commit"=>"Update the Count"/ {
  usecount++
  isexample=0
}
/"commit"=>"Example"/ {
  examplecount++
  isexample=1
}
/^\[[0-9a-f-]+] +[0-9]+ word script expanded to [0-9]+ words \([0-9]+ extra\)\./ {
  extra=substr($9,2) # Remove the bracket before the number of extra words.
  if (isexample == 0) {
    wordtotal+=$2
    extratotal+=extra
  }
}
END {totalposts=0
  counter=0
  for (addr in IPs) {
    print addr "\t" IPs[addr]
    totalposts+=IPs[addr]
    counter++
  }
  if (wordtotal <= 0)
    wordtotal=1 # Avoid divide by zero.
  print "Unique users: " counter "  POSTs: " totalposts "  Examples: " examplecount "  Actual uses: " usecount "  Words: " wordtotal "  Extra words: " extratotal " (" extratotal * 100 / wordtotal "%)"
}' < ../log/production.log | sort
