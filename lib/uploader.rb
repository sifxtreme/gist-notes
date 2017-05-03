require_relative './config'

require 'octokit'
require 'pry'

module GistNotes
  class Uploader

    INDEX_GIST_NAME="my_gist_notes.md"

    def first_time_upload
      sync_folders_up
      sync_root_index_file_up
    end

    def folder_paths_to_sync
      folders = Dir.glob "#{Config::GIST_NOTES_PATH}/*/"

      folders.select { |x| is_folder_syncable?(x) }
    end

    def is_folder_syncable?(folder)
      files = files_in_folder(folder)

      # dont sync if folder has no valid files
      return false if files.nil? || files.empty?
      
      true
    end

    def files_in_folder(folder)
      files = Dir.glob("#{folder}*").select{ |e| File.file? e }
      file_hash = files.map { |x| [x,File.read(x)] }.to_h

      # dont sync blank files
      file_hash.reject! { |_,x| x.nil? || x.empty? }

      file_hash
    end

    def sync_root_index_file_up
      refresh_gists
            
      gists_on_device = folder_paths_to_sync.map {|x| get_folder_name(x)}

      gists_on_device_and_online = gists.select {|x| gists_on_device.include?(x[:description]) }

      index_file = create_index_file(gists_on_device_and_online)

      index_file_hash_to_upload = { 
        INDEX_GIST_NAME => {content: index_file}
      }

      upload_gist(INDEX_GIST_NAME, index_file_hash_to_upload)
    end

    def add_folder(path)
      folder_path = path.split("/")[0..-2].join("/")
      sync_folder_up("#{folder_path}/")
      
      sync_root_index_file_up
    end

    def delete_folder(path)
      refresh_gists
      folder_name, _ = path.gsub(Config::GIST_NOTES_PATH, "").split("/")
      gist_to_delete = gists.select {|x| x[:description] == folder_name}.first
      client.delete_gist(gist_to_delete[:id]) if gist_to_delete
      
      sync_root_index_file_up
    end

    def get_folder_name(path)
      path.gsub(Config::GIST_NOTES_PATH, "").split("/").reject {|x| x.empty?}.first
    end

    def format_file_hash_for_upload(files)
      files.map { |file_path, content| [file_path.split("/").last, {content: content}] }.to_h
    end


    def sync_folders_up
      folder_paths_to_sync.each do |folder_path|
        sync_folder_up(folder_path)
      end
    end

    def sync_folder_up(folder_path)
      folder_name = get_folder_name(folder_path)

      file_hash = files_in_folder(folder_path)

      files_to_sync = format_file_hash_for_upload(file_hash)

      # insert blank file at the beginning with names of other files
      index_file_hash = {
        "_#{folder_name}.md" => {content: create_index_file_for_gist(files_to_sync.keys)}
      }
      files_to_sync = index_file_hash.merge(files_to_sync)

      upload_gist(folder_name, files_to_sync)
    end

    def upload_gist(folder_name, files_to_sync)
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

    def client
      @client ||= Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
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

    def get_gist_for(description)
      gists.select {|x| x[:description] == description}.first
    end

    # consider moving to different class
    def create_index_file_for_gist(filepath_array)
      filepath_array.map {|x| "- #{x.split('/').last}"}.join("\n")
    end

    def create_index_file(my_gists)
      ["# MY GIST NOTES", "", "", my_gists.map {|x| md_for_gist(x)}].flatten.join("\n")
    end

    def md_for_gist(gist)
      [
        "### [#{gist[:description]}](#{gist[:html_url]})",
        "",
        md_for_gist_files(gist).compact,
        "",
        "",
      ].flatten.join("\n")
    end

    def md_for_gist_files(gist)
      gist[:files].map do |_,file|
        next if "_#{gist[:description]}.md" == file[:filename] # we created a special index file in a gist
        "- [#{file[:filename]}](#{gist[:html_url]}#file-#{file[:filename].gsub('.', '-').gsub(' ', '-')})"
      end
    end

  end
end

# GistNotes::Uploader.new.first_time_upload
