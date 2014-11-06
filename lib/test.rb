#!/usr/bin/env ruby
require 'rubygems'
require 'rbovirt'
cert_store = OpenSSL::X509::Store.new
cert_store.set_default_paths
cert_store.add_file '/Users/dbishop/Downloads/ca.crt'



con = OVIRT::Client.new('dbishop@controlscan.net','Ericb1994','https://vx-of-ovrt1-hw.ops.controlscan.net/api',{:ca_cert_store => cert_store})

puts con.diskprofiles.inspect

