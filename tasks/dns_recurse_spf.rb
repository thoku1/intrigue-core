require 'dnsruby'
require 'whois'

class DnsRecurseSpf < BaseTask

  def metadata
    { :version => "1.0",
      :name => "dns_recurse_spf",
      :pretty_name => "DNS SPF Recursive Lookup",
      :authors => ["mstanislav","jcran"],
      :description => "DNS SPF Recursive Lookup",
      :references => [ "https://community.rapid7.com/community/infosec/blog/2015/02/23/osint-through-sender-policy-framework-spf-records"],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord", "IpAddress", "Info", "NetBlock" ]
    }
  end

  def run
    super

    dns_name = _get_entity_attribute "name"
    @task_log.log "Running SPF lookup on #{dns_name}"

    # Run a lookup on the entity
    lookup_txt_record (dns_name)
    @task_log.log "done!"

  end

  def lookup_txt_record(dns_name)

    begin

      res = Dnsruby::Resolver.new(
      :recurse => true,
      :query_timeout => 5)

      result = res.query(dns_name, Dnsruby::Types.TXT)

      # If we got a success to the query.
      if result
        @task_log.good "TXT lookup succeeded on #{dns_name}:"
        @task_log.good "Result:\n=======\n#{result.to_s}======"

        # Make sure there was actually a record
        unless result.answer.count == 0

          # Iterate through each answer
          result.answer.each do |answer|

            if answer.rdata.first =~ /^v=spf1/

              # We have an SPF record, so let's process it
              answer.rdata.first.split(" ").each do |data|

                @task_log.log "Processing SPF component: #{data}"

                if data =~ /^v=spf1/
                  next #skip!

                elsif data =~ /^include:.*/
                  spf_data = data.split(":").last
                  _create_entity "DnsRecord", {:name => spf_data}

                  # RECURSE!
                  lookup_txt_record spf_data

                elsif data =~ /^ip4:.*/
                  range = data.split(":").last

                  if data.include? "/"
                    _create_entity "NetBlock", {:name => range }
                  else
                    _create_entity "IpAddress", {:name => range }
                  end

                elsif data =~ /^google-site-verification.*/
                  _create_entity "Info", {:name => "DNS Verification Code", :type =>"Google", :content => data.split(":").last}

                elsif data =~ /^yandex-verification.*/
                  _create_entity "Info", {:name => "DNS Verification Code", :type =>"Yandex", :content => data.split(":").last}
                end

              end
            else
              _create_entity "Info", { :name => "Non-SPF TXT Record for #{dns_name}", :content => answer.to_s }
            end

          end

          @task_log.log "No more records"

        else
          @task_log.log "Lookup succeeded, but no records found"
        end
      else
        @task_log.log "Lookup failed, no result"
      end

    rescue Dnsruby::Refused
      @task_log.error "Lookup against #{dns_name} refused"

    rescue Dnsruby::ResolvError
      @task_log.error "Unable to resolve #{dns_name}"

    rescue Dnsruby::ResolvTimeout
      @task_log.error "Timed out while querying #{dns_name}."

    rescue Exception => e
      @task_log.error "Unknown exception: #{e}"
    end
  end


end
