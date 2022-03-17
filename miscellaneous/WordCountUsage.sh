#!/bin/sh
# Count unique users (by IP address) of the RealCount web page.
# Typical log line of actual use (POST not GET) looks like this:
# ...] Started POST "/server01/wordcounter" for 108.77.203.198 at 2022-02-07 14:52:46 -0500
# The HTTP field argument line where it is actually used:
# ... "commit"=>"Update the Count" ...
# The statistics of words counted:
# ...]   337 word script expanded to 341 words (4 extra).

awk 'BEGIN {FS=" "}
/] Started POST "\/server01\/wordcounter"/ {IPs[$12]++}
/"commit"=>"Update the Count"/ {usecount++}
/]   [0-9]+ word script expanded to [0-9]+ words \([0-9]+ extra\)\./ {
  wordtotal+=$8
  extrawordtotal+=substr($15,2)
  }
END {totalposts=0
  counter=0
  for (addr in IPs) {
    print addr "\t" IPs[addr]
    totalposts+=IPs[addr]
    counter++
  }
  print "Unique users: " counter "  POSTs: " totalposts "  Actual uses: " usecount "  Words: " wordtotal "  Extra words: " extrawordtotal " (" extrawordtotal * 100 / wordtotal "%)"
}' < ../log/production.log | sort
