#    Browser-side script used by index.html

# ## Widget A: Languages Stats
#
# Animate bar chart of languages statistics on page load.

bars = $('#code_stats span[percent]')

if bars.length
  start_index = bars.length
  fps = 20
  duration = 1000
  do animate = ->
    return unless start_index
    bar = $ bars[--start_index]
    number_span = bar.next()
    total = 1 * number_span.attr 'total'
    do (number_span, total) ->
      current = 0
      step = total * 1000 / duration / fps
      do increase = ->
        if (current += step) > total
          current = total
        else
          setTimeout increase, 1000 / fps
        number_span.html Math.floor(current) + ' sloc'
    return animate() if bar.attr('percent') is bar.css('width')
    bar.animate
      width: bar.attr('percent')
    , duration, 'linear', animate


# ## Widget B: Markdown Browser

current_markdown_path = "README.html"

show_markdown = (index_path, file) ->
  $.ajax
    url: [index_path..., file].join '/'
    success: (html) ->
      return unless html
      current_markdown_path = [index_path..., file].join()
      $('.markdown_browser').animate {
        opacity: 0
      }, 400, 'linear', ->
        markdown_container = $('.markdown_browser').parent()
        $('.markdown_browser').remove()
        new_markdown = $("<div class='markdown_browser'>#{html}</div>").css('opacity', '0')
        $(markdown_container).append new_markdown
        $(new_markdown).animate {
           opacity: 1
        }, 400, "linear"

# ## Widget C: GitHub Styled Repo Browser
{ user, repo } = docas

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

post_render = (table, index_path) ->

  update_usernames()

  # #### Handling Content Interaction

  $(table).find('a[backward]').click ->
    render_tree_browser index_path[0...index_path.length - 1]

  $(table).find('a[forward]').click ->
    render_tree_browser [index_path..., $(@).html()]

  $(table).find('a[markdown]').click ->
    file_name = $(@).attr 'markdown'
    current_row = $(@).parent().parent()
    current_row.siblings().removeClass 'shown'
    current_row.addClass 'shown'
    if current_markdown_path isnt [index_path..., file_name].join()
      show_markdown index_path, file_name

  $(table).find('thead th:nth-child(3) > :first-child').click ->
    $.cookie 'size', 'sloc'
    $('.repo_nav tr > :nth-child(3)').attr 'class', 'sloc'

  $(table).find('thead th:nth-child(3) > :last-child').click ->
    $.cookie 'size', 'size'
    $('.repo_nav tr > :nth-child(3)').attr 'class', 'size'

  $(table).find('thead th:last-child > :first-child').click ->
    $.cookie 'message', 'message'
    $('.repo_nav tr > :last-child').attr 'class', 'message'

  $(table).find('thead th:last-child > :nth-child(2)').click ->
    $.cookie 'message', 'description'
    $('.repo_nav tr > :last-child').attr 'class', 'description'

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

waiting_for_response = off

render_tree_browser = (index_path) ->

  return if waiting_for_response

  $('.tree_browser_spinner').show()
  waiting_for_response = on

  # #### Ajax Call to Get Index
  #
  # If browser caching becomes a problem, append
  # 
  #     "?timestamp=#{Date.now().valueOf()}"
  #
  # as the query string.
  $.ajax
    url: [index_path..., 'docas.idx'].join '/'

    success: (index) ->
      waiting_for_response = off
      $('.tree_browser_spinner').hide()

      # #### Render Breadcrumb Navigator
      $('#breadcrumb')
        .html(breadcrumb_template index_path)
        .find('a').click ->
          render_tree_browser index_path[0...$(@).attr('depth')]

      # #### Render Content Table
      table = $ list_template
        user       : user
        repo       : repo
        index_path : index_path
        entries    : process_index index
        size       : $.cookie 'size'
        message    : $.cookie 'message'

      post_render table, index_path

  if current_markdown_path isnt [index_path..., 'README.html'].join()
    show_markdown index_path, 'README.html'

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

# ## Page Load

$.cookie('size', ($.cookie('size') or 'size'))
$.cookie('message', ($.cookie('message') or 'message'))

# On page load, do:
#
#   + Switch `size` or `sloc` according to cookie `size`.
#   + Switch `message` or `description` according to cookie `message`.
$ ->
  $('.repo_nav tr > :nth-child(3)').attr('class', $.cookie('size'))
  $('.repo_nav tr > :nth-child(5)').attr('class', $.cookie('message'))

# Calculate relative date.
$('[relative_date]').forEach (el) ->
  $(el).html moment(new Date 1 * $(el).attr('relative_date')).fromNow()

# Regist the initial repo browser's events.
post_render $('.repo_nav'), []
