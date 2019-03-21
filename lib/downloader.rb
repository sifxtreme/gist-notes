require_relative './config'

require 'octokit'
require 'pry'

module GistNotes
  class Downloader

    def download_gists
      valid_gists = gists.select {|x| x[:files].first.last[:filename].start_with?("_")}

      valid_gists.each do |gist|
        files = gist[:files]
        folder_name = gist[:files].first.last[:filename].gsub("_","").gsub(".md","")

        Dir.chdir Config::GIST_NOTES_PATH
        `mkdir -p #{folder_name}`
        Dir.chdir folder_name

        gist[:files].drop(1).each do |gist_file|
          `curl #{gist_file.last[:raw_url]} --output #{gist_file.last[:filename]}`
        end
      end
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV["GIST_GITHUB_TOKEN"])
    end

    def user
      @user ||= client.user
    end

    def gists
      @gists ||= client.gists
    end

    def refresh_gists
      @gists = client.gists
    end

  end
end

GistNotes::Downloader.new.download_gists
