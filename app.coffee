
{exec}        = require 'child_process'
loggly        = require 'loggly'
loggly_config =
  subdomain: 'baoshan'
  auth:
    username: 'baoshan'
    password: 'aBEGG-55376'
  json: true
loggly_client = loggly.createClient loggly_config
fairy         = require('fairy').connect()
source_queue  = yamg.queue 'docas'

# ## Step 1: Fetch (or Clone) the Repo
# 
# The repo will be stored at:
#
#   * `/repos/#{user}/#{repo}/master` for `master` branch, and
#   * `/repos/#{user}/#{repo}/gh-pages` for `gh-pages`.
docas_repo = (repo, callback) ->
  exec "docas #{repo}", (err, stdout, stderr) ->
    if err
      console.log "err", err, stdout, stderr
      callback {}, null
    else
      console.log 'done', repo, new Date, err, stdout, stderr
      callback null, null

# ## Phases of Synchronization
#
#   1. Get repository id (from Redis or GitHub API)
#   2. Synchronize the file system to the specific commit.
#   3. Enqueue the following task.
#
# When registering a task handler, YAMG will start monitoring the task queue.
source_queue.regist (repo, commit, queued_time, callback) ->
  console.log "processing:#{repo}@#{commit}"
  begin_processing_time = new Date
  docas_repo repo, (err, res) ->
    if err then callback err, res
    else
      log = 
        repo: "#{repo}@#{commit}"
        wait: begin_processing_time - queued_time
        done: (new Date) - begin_processing_time
        type: "docas"
      loggly_client.log '42aea450-29e6-4472-a483-e0ad99015e07', log 
      callback null, null
