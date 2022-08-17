loki_dest_type = 'Variant[Pattern[/^https?:\/\/.*/],Pattern[/^\/.*/]]'
# Puppet function to log data to Loki
Puppet::Functions.create_function(:'loki::log') do
  # Logs a string to Loki or a file.
  # @param loki_dest Loki log destination, either a Loki URI or an absolute file path.
  #        If logging to a path, the log file name will start with the value of the 'host' label
  #        or 'nohost' if none is present. The log file will rotate daily.
  # @param labels A hash containing Loki labels.
  # @param tenant An optional tenant string
  # @param string_data The data as a string
  # @example Logging string data to a Loki URL:
  #   loki::push('http://localhost://3100', { 'host' => 'myhost' }, 'tenant1', 'my data to log')
  #   loki::push('/my/log/path', { 'host' => 'myhost' }, 'tenant1', 'my data to log')
  dispatch :loki_log_s do
    param loki_dest_type, :loki_dest
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'String', :string_data
  end

  dispatch :loki_log_r do
    param loki_dest_type, :loki_dest
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'Result', :result
  end

  dispatch :loki_log_rs do
    param loki_dest_type, :loki_dest
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'ResultSet', :result_set
  end

  dispatch :loki_log_hash do
    param loki_dest_type, :loki_dest
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'Hash', :hash
  end

  def loki_log_hash(loki_dest, labels, tenant=null, hash)
    loki_log_s(loki_dest, labels, tenant, result_set.hash.to_json)
  end

  def loki_log_rs(loki_dest, labels, tenant=null, result_set)
    loki_log_s(loki_dest, labels, tenant, result_set.to_data[0].to_json)
  end

  def loki_log_r(loki_dest, labels, tenant=null, result)
    loki_log_s(loki_dest, labels, tenant, result.to_json)
  end

  def loki_log_s(loki_dest, labels, tenant=null, string_data)
    puts "loki_dest: #{loki_dest}"
    puts "labels: #{labels}"
    puts "tenant: #{tenant}"
    puts "data: #{string_data}"
    if loki_dest =~ /http/
      puts post_data("#{loki_dest}/loki/api/v1/push", labels, tenant, string_data)
    else
      puts write_log(loki_dest, labels, tenant, string_data)
    end
  end

  def write_log(path, labels, tenant, string_data)
    host = labels['host'] || 'nohost'
    log = Logger.new("#{path}/#{host}.log", 'daily')
    log.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end   
    puts("Writing loki log to file at #{path}/#{host}.log")
    log.info(string_data)
  end

  def post_data(endpoint, labels, tenant, data)  
      puts 'Submitting data to Loki service at #{endpoint}'
  
      uri = URI.parse(endpoint)
  
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req['X-Scope-OrgID'] = tenant if tenant
      body = {
        "streams" => [{
              "stream" => labels,
              "values" => [
                # time needs to be in nanoseconds for Loki
                [Time.now.strftime('%s%9N'), data]
              ]
        }]
      }
      puts "Body: #{body.to_json}"
      req.body = body.to_json if body
      http = Net::HTTP.new(uri.host, uri.port)
      res = http.start { |sess| sess.request(req) }
      res.value
  end
end
