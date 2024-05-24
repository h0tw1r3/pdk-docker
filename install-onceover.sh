#!/bin/bash

set +x

for gembin in /opt/puppetlabs/pdk/private/ruby/*/bin/gem ; do
    cd $(dirname "$gembin") || continue
    ./gem install --no-document onceover
    ln -sf "$PWD/onceover" /usr/local/bin/onceover
done
