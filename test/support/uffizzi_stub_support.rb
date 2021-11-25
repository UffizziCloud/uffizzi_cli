# frozen_string_literal: true

module UffizziStubSupport
  def stub_uffizzi_login(url, status, body, headers)
    stub_request(:post, url).to_return(status: status, body: body.to_json, headers: headers)
  end
end
