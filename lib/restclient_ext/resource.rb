module RestClient
  class Resource
    def delete_with_payload(payload, additional_headers={}, &block)
      headers = (options[:headers] || {}).merge(additional_headers)
      Request.execute(options.merge(
        :method => :delete,
        :url => url,
        :payload => payload,
        :headers => headers), &(block || @block))
    end
  end
end
