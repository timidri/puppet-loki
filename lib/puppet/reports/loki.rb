# Loki Puppet report processor
require 'puppet'
require 'yaml'

Puppet::Reports.register_report(:loki) do
  desc 'Submit reports to Grafana Loki'

  def process
    # Puppet.notice(_('Processing report by Loki processor...'))
    with_report do |report|
      begin
        push_to_loki(report)
      end
    end
  rescue StandardError => e
    Puppet.err(_('Failed to submit reports to Loki: %{e}') % { e: e })
    Puppet.err(_('Backtrace: %{b}') % { b: e.backtrace })
  end

  def push_to_loki(report)
    loki_uri = settings['loki_uri']
    if !loki_uri 
      Puppet.err "`loki_uri`` not defined for reporting to Loki"
      return
    end

    endpoint = "#{loki_uri}/loki/api/v1/push"

    Puppet.info(_('Submitting report to Loki service at %{endpoint}') % { endpoint: endpoint })
    Puppet.debug(_('Report: %{r}') % { r: report })

    uri = URI.parse(endpoint)

    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['X-Scope-OrgID'] = 'tenant1'
    body = {
      "streams" => [{
            "stream" => { "puppet" => "reports", "host" => report[:host] },
            "values" => [
              # time needs to be in nanoseconds for Loki
              [Time.now.strftime('%s%9N'), report.to_json],
              [Time.now.strftime('%s%9N'), facts.to_json]
            ]
      }]
    }
    Puppet.info(_('Body: %{body}') % { body: body.to_json })
    req.body = body.to_json if body
    http = Net::HTTP.new(uri.host, uri.port)
    res = http.start { |sess| sess.request(req) }
  end

  def facts
    Puppet::Node::Facts.indirection.find(host).values
  end

  def with_report
    return unless block_given?

    # Do not report unless something has changed.
    return if status == 'unchanged' && !noop_pending

    yield({
      host: host,
      noop: noop,
      # TODO: We should consider selectively reporting facts.
      # facts: facts,
      status: status,
      time: time.iso8601,
      configuration_version: configuration_version,
      transaction_uuid: transaction_uuid,
      code_id: code_id,
      summary: summary,
      resource_statuses: resource_statuses
        .select { |_key, value| !value.skipped && (value.change_count > 0 || value.out_of_sync_count > 0) }
        .transform_values do |value|
          {
            resource_type: value.resource_type,
            title: value.title,
            change_count: value.change_count,
            out_of_sync_count: value.out_of_sync_count,
            containment_path: value.containment_path,
            corrective_change: value.corrective_change,
          }
        end,
    })
  end

  def settings
    return @settings if @settings
    @settings_file = Puppet[:confdir] + '/loki.yaml'
    @settings = YAML.load_file(@settings_file)
  end

end
