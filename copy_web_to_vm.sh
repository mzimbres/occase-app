#!/bin/bash

occasede="95.217.219.210"

root=build/web

a=$root/index.html
b=$root/main.dart.js
c=$root/assets/AssetManifest.json
d=$root/assets/data/parameters.txt
e=$root/assets/data/config.comp.tree.txt

#flutter build web

gzip < $a > $a.gz
gzip < $b > $b.gz
gzip < $c > $c.gz
gzip < $d > $d.gz
gzip < $e > $e.gz

tar cf web.tar $root

gzip web.tar
scp web.tar.gz ${occasede}:~/
rm web.tar.gz
