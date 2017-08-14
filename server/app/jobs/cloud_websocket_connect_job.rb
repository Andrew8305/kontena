require_relative '../services/logging'
require_relative '../services/auth_provider'

class CloudWebsocketConnectJob
  include Celluloid
  include Logging
  include ConfigHelper # adds a .config method

  def initialize(perform = true)
    async.perform if perform
  end

  def perform
    sleep 0.1
    while running?
      update_connection
      sleep 30
    end
  end

  def running? # we can mock this in tests to return false
    true
  end

  def update_connection
    if cloud_enabled?
      connect(config)
    else
      disconnect
    end
  end

  def cloud_enabled?
    kontena_auth_provider? &&
      oauth_app_credentials? &&
      cloud_enabled_in_config? &&
      socket_api_uri?
  end

  def kontena_auth_provider?
    ap = AuthProvider.instance
    ap.valid? && ap.is_kontena?
  end

  def cloud_enabled_in_config?
    config['cloud.enabled'].to_s == 'true'
  end

  def socket_api_uri?
    !config['cloud.socket_uri'].to_s.empty?
  end

  def oauth_app_credentials?
    config['oauth2.client_id'] && config['oauth2.client_secret']
  end

  def connect(config)
    if @client.nil?
      @client = Cloud::WebsocketClient.new(config['cloud.socket_uri'],
        client_id: config['oauth2.client_id'],
        client_secret: config['oauth2.client_secret'],
      )
      @client.ensure_connect
    end
    @client
  end

  def disconnect
    if @client
      @client.disconnect
      @client = nil
    end
  end

  protected

  def client
    @client
  end

end
