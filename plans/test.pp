# This plan tests logging task, command and puppet run results to Loki
#
# @param loki_dest The logging destination - either a Loki URL (no path), or an absolute file path.
# @param target The target host to run the plan tasks and commands on
# @param tenant The tenant for Loki
plan loki::test(
  Pattern[/^https?:\/\/.*/,Pattern[/^\/.*/]] $loki_dest,
  TargetSpec $targets,
  Optional[String[1]] $tenant = undef,
) {
  $labels = { 'host' => $targets, 'puppet' => 'plan_logs' }

  # apply_prep($targets)

  out::message('Loki test')
  $service_result = run_task('service', $targets, { 'action' => 'status', 'name' => 'sshd' })
  loki::log($loki_dest, $labels, $tenant, { 'note' => 'Ran service task', 'name' => 'sshd', 'results' => $service_result[0] })

  $package_result = run_task('package', $targets, { 'action' => 'status', 'name' => 'sshd' })
  loki::log($loki_dest, $labels, $tenant, $package_result[0])

  $command_result = run_command('wrongcommand', $targets, '_catch_errors' => true)
  loki::log($loki_dest, $labels, $tenant, $command_result[0])

  apply_prep($targets)
  $results = apply($targets, '_description' => 'Apply manifest', '_catch_errors' => true) {
    package { 'mlocate':
      ensure => installed,
    }
  }
  loki::log($loki_dest, $labels, $tenant, $results)
}
