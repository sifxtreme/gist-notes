# gist-notes

Automatically watch files in a folder and upload changes to Gist. You need to set these env variables to use this tool.

```
ENV["GITHUB_TOKEN"]
ENV['GIST_NOTES_PATH']
```

`GIST_NOTES_PATH` is the file directory where you will be authoring the files that you want converted automatically into gists.

This app assumes a file structure of

```
- root
    + directory1
        + file 1
        + file 2
    + directory2
        + file 3
        + file 4
        + ANY DIRECTORY AT THIS LEVEL WILL NOT BE UPLOADED
    + ANY FILE AT THIS LEVEL WILL NOT BE UPLOADED 
```

Empty directories will not be converted to gists. Empty files will not be converted to gists. In every gist, the first file will be an "index" file that has all the other files in the directory uploaded.

Also on every file change, a master index file will be uploaded/updated. This has a link to all your other uploaded gists (through this app).

Usage

```
rvm use
ruby lib/watcher.rb
```