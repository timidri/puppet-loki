# Puppet-Loki integration

This is a bolt project demonstrating options for sending operational information
from Puppet plans and Puppet reports to Grafana Loki.

This repo contains 3 main components and some supporting files:

## lib/puppet/functions/loki/log.rb

This is a Puppet function `loki::log` for pushing data to a Loki service.
This function can be used from plans.

## plans/test.pp

This is a plan showing how to use the function `loki::log`.

## lib/puppet/reports/loki.rb

This is a Puppet Report Processor which can push Puppet reports to Loki.
It has the following configuration options to be set in `/etc/puppetlabs/puppet/loki.yaml`:

* `loki_uri`: for example, `http://your_loki_host:3100`. This setting is mandatory if `log_destination` is `loki`.
* `tenant`: the tenant to use by the report processor when pushing to Loki. Default: `undef`.
* `push_facts`: choose whether or not to push facts to Loki together with reports. Default: `true`.
* `include_facts`: an array of fact names to be included. Default: `null` (all facts).
* `log_destination`: if set to `loki`, will push the report to `loki_uri`. For all other values, will write into a log file in `log_dir` called `$host.log`. This file will rotate daily. Default: `loki`.
* `log_dir`: directory containing the log files, needs to grant permissions for creating files to the `pe-puppet` user. Default: `/var/log/loki_reports`.

For installing the report processor, see `https://puppet.com/docs/puppet/7/reporting.html`

## Supporting files

### plans/install.pp

A plan for installing Grafana + Loki on a server

## Installation of the Loki integration module

1. Install this module on the Puppet Primary. The plans and function should become available automatically.
1. To enable the loki report processor:
   1. Edit the file `/etc/puppetlabs/puppet/puppet.conf`
   1. Add `loki` to the reports configuration:

    ```ini
    reports = puppetdb,loki
    ```

1. Run the puppet agent on the primary: `puppet agent -t`
1. Restart puppetserver: `systemctl restart pe-puppetserver`
