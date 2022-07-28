# Puppet function to push data to Loki
Puppet::Functions.create_function(:'loki::push') do
  dispatch :loki_push_s do
    param 'String', :loki_host
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'String', :string_data
  end

  dispatch :loki_push_r do
    param 'String', :loki_host
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'Result', :result
  end

  dispatch :loki_push_rs do
    param 'String', :loki_host
    param 'Hash[String,String]', :labels
    param 'Optional[String]', :tenant
    param 'ResultSet', :result_set
  end

  def loki_push_rs(loki_host, labels, tenant=null, result_set)
    loki_push_s(loki_host, labels, tenant, result_set.to_data[0].to_json)
  end

  def loki_push_r(loki_host, labels, tenant=null, result)
    loki_push_s(loki_host, labels, tenant, result.to_json)
  end

  def loki_push_s(loki_host, labels, tenant=null, string_data)
    puts "loki_host: #{loki_host}"
    puts "labels: #{labels}"
    puts "tenant: #{tenant}"
    puts "data: #{string_data}"
    puts post_data("http://#{loki_host}:3100/loki/api/v1/push", labels, tenant, string_data)
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
  end
end
