#!/bin/sh
# Count unique users (by IP address) of the RealCount web page.
# Typical log line of actual use (POST not GET) looks like this:
# ... Started POST "/server01/wordcounter" for 108.77.203.198 at 2022-02-07 14:52:46 -0500

awk 'BEGIN {FS=" "}
/Started POST "\/server01\/wordcounter"/ {IPs[$12]++}
END {total=0
  counter=0
  for (addr in IPs) {
    print addr "\t" IPs[addr]
    total+=IPs[addr]
    counter++
  }
  print "Unique users: " counter "  Total uses: " total
}' < ../log/production.log | sort
