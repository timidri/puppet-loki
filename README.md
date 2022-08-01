# Puppet-Loki integration

This is a bolt project demonstrating options for sending operational information 
from Puppet plans and Puppet reports to Grafana Loki.

This repo contains 3 main components and some supporting files:

## lib/puppet/functions/loki/push.rb

This is a Puppet function `loki::push` for pushing data to a Loki service.
This function can be used from plans.

## plans/test.pp

This is a plan showing how to use the function `loki::push`.

## lib/puppet/reports/loki.rb

This is a Puppet Report Processor which can push Puppet reports to Loki.
It is just for demo purposes, and has a hard-wired
Loki host and no configuration options.

For installing the report processor, see https://puppet.com/docs/puppet/7/reporting.html

## Supporting files

### plans/install.pp

A plan for installing Grafana + Loki on a server
