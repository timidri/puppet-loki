# This plan tests pushing task, command and puppet run results to Loki
#
plan loki::test(
  TargetSpec $loki_host,
  TargetSpec $target,
  String[1] $tenant = 'tenant1',
) {
  $labels = { 'host' => $target, 'puppet' => 'plan_logs' }

  out::message('Loki test')
  $service_result = run_task('service', $target, { 'action' => 'status', 'name' => 'sshd' })
  loki::push($loki_host, $labels, $tenant, $service_result[0])

  $package_result = run_task('package', $target, { 'action' => 'status', 'name' => 'sshd' })
  loki::push($loki_host, $labels, $tenant, $package_result[0])

  $command_result = run_command('wrongcommand', $target, '_catch_errors' => true)
  loki::push($loki_host, $labels, $tenant, $command_result[0])

  apply_prep($target)
  $results = apply($target, '_description' => 'Apply manifest') {
    package { 'mlocate':
      ensure => installed,
    }
  }
  loki::push($loki_host, $labels, $tenant, $results)
}
