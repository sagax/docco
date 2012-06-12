# **Docci** generates a simple cover page for each repository, helping users
# take a quick glance at the project. 
# The generated cover page contains following components:
#
#     1. A stats of languages and source lines of code.
#     2. Log of recent changes.
#     3. A GitHub-style file browser which can take you to the documentation
#        of that file.
#     4. Last but not least, everything in your README.md file.
#     
# Since the input for generating the cover page is the whole project, you should
# invoke it from the command-line as:
#
#     docci path_to_your_repository
#
# ...will generate an HTML documentation page for the repository., 
#
# The [source for Docci](http://github.com/baoshan/docas) is available on GitHub,
# and released under the MIT license.
#
# Docco can be used to process any languages recognized by Linguist.
#

#### Main Documentation Generation Functions

# Once all of the code is finished highlighting, we can generate the HTML file
# and write out the documentation. Pass the completed sections into the template
# found in `resources/index.jst`
generate_index = ->
  parse_recent_commits (recent_commits) ->
    readme = ''
    try readme = fs.readFileSync "#{source_dir}/README.md", 'utf-8'
    repo_index = fs.readFileSync "#{target_dir}/docas.idx", 'utf-8'
    call_github_repo_api (repo_object) ->
      index_html = index_template
        user: user
        repo: repo
        description: repo_object.description or ''
        readme: showdown.makeHtml readme
        language_statistics: parse_language_statistics()
        recent_commits: recent_commits
        files_list: list_template
          user          : user
          repo          : repo
          index_depth   : 0
          absolute_base : ''
          relative_base : ''
          entries : process_index repo_index
      fs.writeFileSync target_file, index_html

# ## Get GitHub Repo Data
# 
# Here, `docas` get repository data from GitHub [Repos API] using
# [Basic Authentication].
#
# The username and password for authenticate will be read from an `auth` file
# when presents.
#
# [Repos API]: http://developer.github.com/v3/repos/
# [Basic Authentication]: http://developer.github.com/v3/#authentication
call_github_repo_api = (callback) ->

  authentication = ''
  try authentication = fs.readFileSync __dirname + '/../../auth', 'utf-8'

  options = 
    host: 'api.github.com'
    path: "/repos/#{user}/#{repo}"
    auth: authentication

  req = https.get options, (res) ->
    return callback {} if res.statusCode isnt 200
    json = ''
    res.on 'data', (data) -> json += data.toString()
    res.on 'end', -> callback JSON.parse(json)

  req.end()
  req.on 'error', -> callback {}

# ## Parse Language Statistics
parse_language_statistics = ->
  data = fs.readFileSync "#{target_dir}/../.statist", 'utf-8'
  pattern = /(?:^|\n){(.*)}{(.*)}{(.*)}/g
  result = while match = pattern.exec data
    entry = 
      percent: match[1]
      sloc: match[2]
      language: match[3]
  result

# ## Get Recent Commits
parse_recent_commits = (callback) ->
  exec 'git log -5 --format="{%aD}{%an}{%s}"', {cwd: source_dir}, (err, data) ->
    return callback err, null if err
    pattern = /(?:^|\n){(.*)}{(.*)}{(.*)}/g
    result = while match = pattern.exec data
      commit = 
        date: new Date(match[1]).valueOf()
        author: match[2]
        subject: match[3]
    callback result

# Ensure that the destination directory exists.
ensure_directory = (dir, callback) ->
  exec "mkdir -p #{dir}", callback

# Require our external dependencies, including **Showdown.js**
# (the JavaScript implementation of Markdown).
_ = require 'underscore'
fs = require 'fs'
path = require 'path'
https = require 'https'
{exec} = require 'child_process'
showdown = require('../../vendor/showdown').Showdown
process_index = require '../shared/process_index'
list_template = require '../shared/list_template'
index_template = _.template fs.readFileSync __dirname + '/../../resources/index.jst', 'utf-8'

# Calling pattern:
#     docci source_dir target_dir
source_dir = process.ARGV[0]
target_dir = process.ARGV[1]
[user, repo] = process.ARGV[2].split '/'
config = {}
config = require('./config_parser').parse "#{source_dir}/.docas/conf"
console.log config
target_file = target_dir + '/' + (config.project_page or 'index.html')
ensure_directory path.dirname(target_file), ->
  generate_index()
