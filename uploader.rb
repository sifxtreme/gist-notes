require 'octokit'
require 'pry'

NOTES_FILE_PATH='../gist-note-files'

module GistNotes
  class Uploader

    def runner
      sync_all_files_up
      sync_index_file_up
    end

    def get_files_to_sync
      folders = Dir.glob "#{NOTES_FILE_PATH}/*/"

      folders.map do |folder|
        files = Dir.glob("#{folder}*").select{ |e| File.file? e }
        
        [folder, files]
      end.to_h
    end

    def sync_all_files_up
      get_files_to_sync.each do |folder, files|
        folder_name = folder.split("/").last
        files_to_sync = files.map { |x| [x.split("/").last, {content: File.read(x)}] }.to_h

        # insert blank file at the beginning with names of other files
        index_file_hash = {
          "_#{folder_name}" => {content: create_index_file_for_gist(files_to_sync)}
        }
        files_to_sync = index_file_hash.merge(files_to_sync)

        # see if gist exists
        if existing_gist = get_gist_for(folder_name)
          files_on_github = existing_gist[:files].map {|k,_| k.to_s}
          files_to_delete = files_on_github - files_to_sync.keys

          new_files_to_sync = files_to_sync.merge!(files_to_delete.map { |x| [x, nil] }.to_h)

          client.edit_gist(existing_gist[:id], {files: new_files_to_sync})          
        else
          client.create_gist(
            description: folder_name, 
            public: false, 
            files: files_to_sync
          )
        end
      end
    end

    def create_index_file_for_gist(files_to_sync)
      files_to_sync.keys.map {|x| "- #{x}"}.join("\n")
    end

    def client
      @client ||= Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
    end

    def user
      @user ||= client.user
    end

    def gists
      @gists ||= client.gists
    end

    def get_gist_for(description)
      gists.select {|x| x[:description] == description}.first
    end

  end
end


GistNotes::Uploader.new.sync_all_files_up