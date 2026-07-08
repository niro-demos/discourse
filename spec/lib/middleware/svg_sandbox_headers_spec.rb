# frozen_string_literal: true

RSpec.describe Middleware::SvgSandboxHeaders do
  def app_returning(headers)
    lambda { |_env| [200, headers, ["body"]] }
  end

  it "adds the CSP sandbox header to image/svg+xml responses" do
    middleware = described_class.new(app_returning({ "Content-Type" => "image/svg+xml" }))

    _status, headers, _body = middleware.call({})

    expect(headers["Content-Security-Policy"]).to eq("sandbox;")
  end

  it "does not touch non-SVG responses" do
    middleware = described_class.new(app_returning({ "Content-Type" => "image/png" }))

    _status, headers, _body = middleware.call({})

    expect(headers["Content-Security-Policy"]).to be_nil
  end

  it "does not override a Content-Security-Policy the app already set" do
    middleware =
      described_class.new(
        app_returning(
          { "Content-Type" => "image/svg+xml", "Content-Security-Policy" => "sandbox;" },
        ),
      )

    _status, headers, _body = middleware.call({})

    expect(headers["Content-Security-Policy"]).to eq("sandbox;")
  end
end
