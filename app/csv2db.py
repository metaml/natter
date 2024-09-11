#!/usr/bin/env python

import csv

csv_file = './etc/conversation-member-and-friend.csv' 
with open(csv_file, mode ='r') as file:
  csv = csv.reader(file)
  for vals in csv:
    print(vals[0], "###", line[1])
