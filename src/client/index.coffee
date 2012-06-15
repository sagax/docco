# ## Widget A: Languages Stats
#
# Animate bar chart of languages statistics on page load.

if typeof $ isnt 'undefined'
  $ ->
    bars = $('.code_stats span[percent]')
    return unless bars.length
    start_index = bars.length

    do animate = ->
      return unless start_index
      bar = $ bars[--start_index]
      return animate() if bar.attr('percent') is bar.css('width')
      bar.animate
        width: bar.attr('percent')
      , 600, 'linear', animate

# ## GitHub Styled Repo Browser

{ user, repo } = docas if typeof docas isnt 'undefined'

# ### Hand-Made Template for Breadcrumb Navigation
breadcrumb_template = (path) ->
  path = [repo, path...]
  result = ''
  for dir, i in path
    if (i < path.length - 1)
      result += '<a depth=' + i + '>' + dir + '</a>&nbsp;/&nbsp;'
    else
      result += '<span>' + dir + '</span>'
  result

first_time = on

regist_events = (table, index_path) ->

  update_usernames()

  # #### Handling Content Interaction

  $(table).find('a[backward]').click ->
    new TreeBrowser index_path[0...index_path.length - 1]

  $(table).find('a[forward]').click ->
    new TreeBrowser index_path.concat $(@).html()

  $(table).find('a[readme]').click ->
    file_name = $(@).attr 'readme'
    if TreeBrowser._readme_path isnt [index_path..., file_name].join()
      show_readme index_path, file_name

  $(table).find('thead th:nth-child(3) span:nth-child(1)').click ->
    $.cookie 'size', 'sloc'
    $(@).addClass('selected').next().removeClass('selected')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(1)').removeClass('hidden')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(2)').addClass('hidden')

  $(table).find('thead th:nth-child(3) span:nth-child(2)').click ->
    $.cookie 'size', 'size'
    $(@).addClass('selected').prev().removeClass('selected')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(1)').addClass('hidden')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(2)').removeClass('hidden')

  $(table).find('thead th:nth-child(5) span:nth-child(1)').click ->
    $.cookie 'message', 'message'
    $(@).addClass('selected').next().removeClass('selected')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(1)').removeClass('hidden')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(2)').addClass('hidden')

  $(table).find('thead th:nth-child(5) span:nth-child(2)').click ->
    $.cookie 'message', 'description'
    $(@).addClass('selected').prev().removeClass('selected')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(1)').addClass('hidden')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(2)').removeClass('hidden')


  # #### Pushing / Poping the Table
  return if $(table).parent()[0]
  current_table = $('#filelists > div')[0]
  direction = if index_path.length > parseInt $(current_table).attr('depth') then 'l' else 'r'
  width = $(current_table).width() + parseInt $(current_table).css 'margin-right'
  $(table).css 'margin-left', -width if direction is 'r'
  $('#filelists')[if direction is 'r' then 'prepend' else 'append'] table
  $($('#filelists').children()[0]).animate
    'margin-left': (if direction is 'r' then 0 else -1) * width
  , 400, 'linear', -> $(current_table).remove()
 
show_readme = (index_path, file) ->
  $.ajax
    url: [index_path..., file].join '/'
    success: (html) ->
      return unless html
      TreeBrowser._readme_path = [index_path..., file].join()
      $('.readme').animate {
        opacity: 0
      }, 400, 'linear', ->
        readme_parent = $('.readme').parent()
        $('.readme').remove()
        new_readme = $("<div class='readme'>#{html}</div>").css('opacity', '0')
        $(readme_parent).append new_readme
        $(new_readme).animate {
           opacity: 1
        }, 400, "linear"

# ### Constructor Arguments
#
# 1. `user`, used to generate correct link for undocumented sources. E.g.,
# `https://github.com/user/repo/blob/master/awesome_file`
# 2. `repo`, also used to generate above link.
# 3. `index_path`, path to `docas.idx` file.
# 4. `index_depth`, the depth of the index file, `0` for root directory of the repo.
# 5. `current_depth`, optional, the depth of the current page, defaults to
# `index_depth`.
TreeBrowser = (index_path = []) ->

  return if TreeBrowser._ajaxing

  if first_time
    regist_events $('#filelists div')[0], index_path
    $('#filelists tbody td:nth-child(4)').forEach (td) ->
      $(td).html moment(new Date $(td).attr('val') * 1000).fromNow()
    return first_time = off

  $('.spinner').show()


  get_index = ->
    TreeBrowser._ajaxing = on

    # #### Ajax Call to Get Index
    $.ajax
      url: [index_path..., "docas.idx?timestamp=#{Date.now().valueOf()}"].join '/'

      error: ->
        delete TreeBrowser._ajaxing

      success: (index) ->
        delete TreeBrowser._ajaxing
        $('.spinner').hide()

        # #### Render Breadcrumb Navigator
        $('#breadcrumb')
          .html(breadcrumb_template index_path)
          .find('a').click ->
            new TreeBrowser index_path[0...$(@).attr('depth')]

        # #### Render Content Table
        table = $ list_template
          user       : user
          repo       : repo
          index_path : index_path
          entries    : process_index index
          size       : $.cookie 'size'
          message    : $.cookie 'message'
        console.log $.cookie('size'), $.cookie('message')
        regist_events table, index_path

    if TreeBrowser._readme_path isnt index_path.join()
      show_readme index_path, 'README.html'

  get_index()

TreeBrowser._ajaxing = off
TreeBrowser._readme_path = "README.html"

# ### Replace Emails by GitHub Logins
#
# By leveraging GitHub api, repo navigator can replace emails by real GitHub
# logins.
#
# **Notice:** every new domain should be registered through **Register a new
# OAuth application** before making cross-domain ajax requests successfully.

usernames = {}

update_usernames = ->
  emails = {}
  for span in $("#filelists span[email]")
    emails[$(span).attr("email")] = null
  for email of emails
    do (email) ->
      update_table = (username) ->
        $("span[email='#{email}']")
          .html("<a href='https://github.com/#{username}'>#{username}</a>")
          .removeAttr("email")
      if usernames.hasOwnProperty email
        update_table usernames[email]
      else
        $.ajax
          url: "https://api.github.com/legacy/user/email/#{email}"
          error: ->
            usernames[email] = null
          success: (data) ->
            update_table usernames[email] = JSON.parse(data).user.login

# ### Coda

if typeof window isnt "undefined"

  # Show each commit's date in relative format.
  $("#recent_commits span[val]").forEach (span) ->
    $(span).html ", " + moment(new Date(1 * $(span).attr("val"))).fromNow()

  # On page load, do:
  #
  #   + Show `size` or `sloc` according to cookie `size`.
  #   + Show `message` or `description` according to cookie `message`.
  $ ->

    if $.cookie('size') is 'sloc'
      $('.repo_nav th:nth-child(3) span:nth-child(1)').trigger 'click'

    if $.cookie('message') is 'description'
      $('.repo_nav th:nth-child(5) span:nth-child(2)').trigger 'click'

  # Regist repo browser's events.
  new TreeBrowser
