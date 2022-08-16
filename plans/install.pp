# this plan installs and start PoC Loki+Grafana services on a VM $target
# not suitable for production!
plan loki::install(
  TargetSpec $targets,
  String[1] $install_dir = '/home/centos/loki',
) {
  apply_prep($targets);
  $result_set = apply($targets, '_description' => 'Install Docker') {
    include 'docker'
    class { 'docker::compose':
      ensure  => present,
      # version => '1.9.0',
    }
    include 'archive'
    archive { "${install_dir}/loki-config.yaml":
      url => 'https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/loki-config.yaml',
    }
    archive { "${install_dir}/promtail-local-config.yaml":
      url => 'https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/promtail-local-config.yaml',
    }
    archive { "${install_dir}/docker-compose.yaml":
      url => 'https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/docker-compose.yaml',
    }
  }

  run_command("cd ${install_dir} && /usr/local/bin/docker-compose up -d", $targets, 'Start loki')
}
