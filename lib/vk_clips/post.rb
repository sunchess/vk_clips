require 'httparty'
require 'ostruct'
require 'forwardable'
require 'json'

module VkClips
  class Post
    extend Forwardable

    ERROR_CONF_DESCRIPTION = "Make sure configuration is passed VkClips.new.configure { |config| config.access_token = 'vk.123123.....'; ...}".freeze
    UPLOAD_URL_PATH = 'https://api.vk.com/method/shortVideo.create'.freeze
    VERSION = '5.245'.freeze

    def_delegators :@config, :access_token, :video_file_path, :description, :group_id
    attr_reader :config

    def configure
      yield(@config)
    end

    def initialize
      @config = Config.new
    end

    def get_upload_url
      raise ERROR_CONF_DESCRIPTION unless valid?

      response = HTTParty.post(UPLOAD_URL_PATH, body: build_upload_url_body)
      json = JSON.parse response.body, symbolize_names: true

      puts json
      raise 'Error occurred' if json.has_key?(:error)
      json.dig(:response, :upload_url)
    end

    def upload_video
      upload_url = get_upload_url
      fields = {
        file: File.open(video_file_path, 'rb')
      }

      response = HTTParty.post(upload_url, body: fields)
      response.body
    end

    private

    def valid?
      return false if [access_token, video_file_path, description, group_id].include?(nil)
      true
    end

    def build_upload_url_body
      {
        v: VERSION,
        group_id: group_id,
        file_size: File.size(video_file_path),
        access_token: access_token,
        description: description
      }
    end

    class Config
      attr_accessor :access_token, :video_file_path, :description, :group_id
    end
  end
end
