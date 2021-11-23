# frozen_string_literal: true

module UffizziStubSupport
  def stub_uffizzi_login(url, body, response)
    stub_request(:post, url).with(body: body).to_return(status: response[:status], body: response[:body], headers: response[:headers])
  end
end
