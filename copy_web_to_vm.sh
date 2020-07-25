#!/bin/bash

flutter build web
tar cf web.tar build/web
gzip web.tar
scp web.tar.gz db.occase.de:~/
