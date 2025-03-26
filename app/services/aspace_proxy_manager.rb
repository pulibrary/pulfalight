# frozen_string_literal: true
# This is a helper class to create an HTTP Proxy for our ASpace client.
# Lyrasis only lets us access the staff API from our boxes, so this creates a
# SOCKS5 proxy to a Pulfalight box, converts that proxy to an HTTP proxy with
# http-proxy-to-socks, and then a rake task can point the ASpace client to it.
class AspaceProxyManager
  @pids = []
  class << self
    attr_accessor :pids
    attr_accessor :outs
  end
  def self.spawn!(host:, user:)
    @pids = @pids.select(&:alive?)
    return unless @pids.empty?
    @pids =
      begin
        _, _, socks_pid = Open3.popen2e("ssh", "-t", "-D", "9094", "#{user}@#{host}")
        _, out, proxy_to_socks_pid = Open3.popen2e(Rails.root.join("node_modules", "http-proxy-to-socks", "bin", "hpts.js").to_s, "-s", "127.0.0.1:9094")
        sleep(1) until out.readline.include?("http-proxy listening")
        [socks_pid, proxy_to_socks_pid]
      end
  end
  at_exit do
    AspaceProxyManager.pids.each do |pid|
      Process.kill("KILL", pid.pid) if pid.alive?
    end
    AspaceProxyManager.pids = AspaceProxyManager.pids.select(&:alive?)
  end
end
