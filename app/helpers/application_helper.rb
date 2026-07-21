# frozen_string_literal: true

require "quicsilver_playground/web_transport_certificate"

module ApplicationHelper
  def webtransport_certificate_meta_tag
    return unless Rails.env.development?

    certificate = QuicsilverPlayground::WebTransportCertificate.fetch

    tag.meta(
      name: "wt-cert-hash",
      content: certificate.sha256
    )
  end
end
