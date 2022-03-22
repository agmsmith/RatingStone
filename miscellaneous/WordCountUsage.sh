#!/bin/sh
# Count unique users (by IP address) of the RealCount web page.
# Typical log line of actual use (POST not GET) looks like this:
# ...] Started POST "/server01/wordcounter" for 108.77.203.198 at 2022-02-07 14:52:46 -0500
# The HTTP field argument line where it is actually used:
# ... "commit"=>"Update the Count" ...
# The statistics of words counted:
# ...]   337 word script expanded to 341 words (4 extra).

awk 'BEGIN {
  FS=" "
  examples=0
  usecount=0
  wordtotal=0
  extratotal=0
}
/] Started POST "\/server01\/wordcounter"/ {IPs[$12]++}
/"commit"=>"Update the Count"/ {usecount++}
/]   [0-9]+ word script expanded to [0-9]+ words \([0-9]+ extra\)\./ {
  extra=substr($15,2) # Remove the bracket before the number of extra words.
  if (extra == 636) # Example text has 636 extra words.
    examples++
  else
  {
    wordtotal+=$8
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
  print "Unique users: " counter "  POSTs: " totalposts "  Examples: " examples "  Actual uses: " usecount "  Words: " wordtotal "  Extra words: " extratotal " (" extratotal * 100 / wordtotal "%)"
}' < ../log/production.log | sort
