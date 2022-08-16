plan loki::promtail(
  TargetSpec $targets,
) {
  apply_prep($targets)

  apply($targets) {
    class { 'promtail':
      server_config_hash    => lookup('promtail::server_config_hash'),
      clients_config_hash   => lookup('promtail::clients_config_hash'),
      positions_config_hash => lookup('promtail::positions_config_hash'),
      scrape_configs_hash   => lookup('promtail::scrape_configs_hash', { merge => 'deep' }),
    }
  }
}
