#!/bin/bash

# brrrrrn-ing
prefix=chr8.pan+refs.fa.pggb-W-s100000-l300000-p98-n20-a0-K16.seqwish-k47-B20000000.smooth-w200000-j10000-e10000-I0.95-R0.1-p1_7_11_2_33_1

# Take consensus path names
odgi paths -i $prefix.og -L | grep ^Cons >$prefix.consensus_path_names.txt

# Take original path names
odgi paths -i $prefix.og -L | grep ^Cons -v >$prefix.original_path_names.txt

# Calculate the depth
odgi depth -i $prefix.og -s $prefix.original_path_names.txt -R $prefix.consensus_path_names.txt -t 16 >$prefix.consensus_path_names.depth.tsv

# Remove artifacts and dark matter
awk '$4 >= 10 && $4 <= 500' $prefix.consensus_path_names.depth.tsv >$prefix.consensus_path_names.depth.10_500.tsv

# Take the paths touched by the references
odgi overlap -i $prefix.og -s $prefix.consensus_path_names.txt -b <(grep chr8 $prefix.original_path_names.txt) -t 16 | cut -f 4 >$prefix.consensus_path_names.touched.txt

# Take the link paths between consensus paths that we're saving
odgi build -g $prefix.consensus@10000__y_0_1000000.gfa -o $prefix.consensus@10000__y_0_1000000.og -t 16
odgi paths -i $prefix.consensus@10000__y_0_1000000.og -L |
  grep ^Link | awk '{ print NR":"$0 }' |
  grep -f <(
    cat consensus_path_names.touched.txt
    odgi paths -i $prefix.consensus@10000__y_0_1000000.og -L |
    grep ^Link | grep -n -o -Ff <($prefix.consensus_path_names.depth.10_500.tsv | cut -f 1) |
    cut -f 1 -d : | sort -n | uniq -c | awk '$1 == 2 { print "^"$2":"} '
  ) |
    cut -f 2 -d : >$prefix.link_paths.to_extract.txt

# Put it all together
cat <(cat $prefix.consensus_path_names.depth.10_500.tsv | cut -f 1) \
  $prefix.link_paths.to_extract.txt \
  $prefix.consensus_path_names.touched.txt |
  sort | uniq | awk 'NF > 0' >$prefix.consensus_path_names.to_extract.txt

# Extract
odgi build -g $prefix.consensus@10000__y_0_1000000.gfa -o - -t 16 | odgi chop -i - -o $prefix.consensus@10000__y_0_1000000.chop100.og -c 100
odgi extract -i $prefix.consensus@10000__y_0_1000000.chop100.og -b $prefix.consensus_path_names.to_extract.txt -c 1 -t 16 -o - | odgi unchop -i - -o $prefix.consensus@10000__y_0_1000000.brned.og

# Get the GFA for Bandage
odgi view -i $prefix.consensus@10000__y_0_1000000.brned.og -g >$prefix.consensus@10000__y_0_1000000.brned.gfa
