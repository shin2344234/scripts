# Daily Mac Vendor Check

I wrote this one to check for specific devices on a subnet and to notify me via email. 
Basically if a voip phone is on the main vlan I want to know first thing in the AM so I can get it moved back; I.E., someone put it in the wrong port again...

This script is slow and rate-limited to 1 check per second as to not exceed macvendor's api restricitons.
You shouldn't need to run this more than once a day. if you do, use something like Angry IP Scanner.