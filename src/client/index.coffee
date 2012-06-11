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

{ user, repo, gitmodules } = docas if typeof docas isnt 'undefined'

# ### Micro Template Engine for Rendering Content
template = (str) ->
  new Function 'obj',
    'var p=[],print=function(){p.push.apply(p,arguments);};' +
    'with(obj){p.push(\'' +
    str.replace(/[\r\t\n]/g, " ")
       .replace(/'(?=[^<]*%>)/g,"\t")
       .split("'").join("\\'")
       .split("\t").join("'")
       .replace(/<%=(.+?)%>/g, "',$1,'")
       .split('<%').join("');")
       .split('%>').join("p.push('") +
       "');}return p.join('');"

# ### Hand-Made Template for Breadcrumb Navigation
breadcrumb_template = (path) ->
  result = ''
  path.forEach (dir, i) ->
    if (i < path.length - 1)
      result += '<a depth=' + i + '>' + dir + '</a>&nbsp;/&nbsp;'
    else
      result += '<span>' + dir + '</span>'
  result

# ### Template for File Browser
list_template = template """
<div depth="<%= index_depth %>" class="filelist">
<table class="repo_nav">
<thead><tr><th></th><th>name</th><th><span>sloc</span>&nbsp;&nbsp;<span class="selected">size</span></th><th>age</th><th><span class="selected">message</span>&nbsp;&nbsp;<span>description</span><div class="history"><a target="_blank" href="https://github.com/<%= user %>/<%= repo %>/commits/master">history</a></div></th></tr></thead>
<tbody>
<% if(index_depth) { %>
<tr class="directory"><td></td><td><a backward>..</a></td><td></td><td></td><td></td></tr>
<% } %>
<% entries.forEach(function(entry) { %>
<tr class="<%= entry.submodule ? "m" : entry.type %>">
<td class="icon"></td>
<td><a <%= entry.type == 'd' && !entry.submodule ? 'forward' : 'href=\"' + (entry.submodule ? 'https://github.com/' + entry.submodule : (entry.action === 's' ? (relative_base ? relative_base + '/' : '') + entry.document : 'https://github.com/' + user + '/' + repo + '/blob/master/' + (absolute_base ? absolute_base + '/' : '') + entry.name)) + '\"' %><%= entry.action === "g" ? "target=\'_blank\'": "" %>><%= entry.name %></a></td>
<td><span class="hidden <%= entry.sloc ? "" : "" %>"><%= entry.sloc ? (entry.sloc + " " + (entry.sloc > 1 ? "lines" : "line")) : "-" %></span><span><%= entry.size %></span></td>
<td><%= entry.modified %></td>
<td><div><span><%= entry.message %></span><span class="file_browser_author" email="<%= entry.email %>"> <%= entry.author %></span></div><div class="hidden"><%= entry.description %></div></td>
</tr>
<% }); %>
</tbody>
</table>
</div>
""".replace('\n', '')

first_time = on

regist_events = (table, index_path, index_depth, current_depth) ->

  update_usernames table

  # #### Handling Content Interaction

  $(table).find('a[backward]').click ->
    new_path = index_path.split '/'
    new_path.splice new_path.length - 2, 1
    new Repo_Navigator new_path.join('/'), index_depth - 1, current_depth

  $(table).find('thead th:nth-child(3) span:nth-child(1)').click ->
    $(table).find('thead th:nth-child(3) span:nth-child(1)').addClass('selected')
    $(table).find('thead th:nth-child(3) span:nth-child(2)').removeClass('selected')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(1)').removeClass('hidden')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(2)').addClass('hidden')

  $(table).find('thead th:nth-child(3) span:nth-child(2)').click ->
    $(table).find('thead th:nth-child(3) span:nth-child(1)').removeClass('selected')
    $(table).find('thead th:nth-child(3) span:nth-child(2)').addClass('selected')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(1)').addClass('hidden')
    $(table).find('tbody tr td:nth-child(3) span:nth-child(2)').removeClass('hidden')

  $(table).find('thead th:nth-child(5) span:nth-child(1)').click ->
    $(table).find('thead th:nth-child(5) span:nth-child(1)').addClass('selected')
    $(table).find('thead th:nth-child(5) span:nth-child(2)').removeClass('selected')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(1)').removeClass('hidden')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(2)').addClass('hidden')

  $(table).find('thead th:nth-child(5) span:nth-child(2)').click ->
    $(table).find('thead th:nth-child(5) span:nth-child(1)').removeClass('selected')
    $(table).find('thead th:nth-child(5) span:nth-child(2)').addClass('selected')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(1)').addClass('hidden')
    $(table).find('tbody tr td:nth-child(5) div:nth-child(2)').removeClass('hidden')

  $(table).find('a[forward]').click ->
    new_path = index_path.split '/'
    new_path.splice new_path.length - 1, 0, $(@).html()
    new Repo_Navigator new_path.join('/'), index_depth + 1, current_depth

  # #### Pushing / Poping the Table
  return if first_time
  current_table = $('#filelists div:first-child')[0]
  if current_table
    direction = if index_depth > parseInt $(current_table).attr('depth') then 1 else -1
    width = $(current_table).width() + parseInt $(current_table).css 'margin-right'
    $('#filelists')[if direction < 0 then 'prepend' else 'append'] table
    $(table).css 'margin-left', -width if direction is -1
    $($('#filelists').children()[0]).animate
      'margin-left': (if direction is -1 then 0 else -1) * width
    , 400, 'linear', -> $(current_table).remove()
  else
    $('#filelists').append table

# ### Constructor Arguments
#
# 1. `user`, used to generate correct link for undocumented sources. E.g.,
# `https://github.com/user/repo/blob/master/awesome_file`
# 2. `repo`, also used to generate above link.
# 3. `index_path`, path to `docas.index` file.
# 4. `index_depth`, the depth of the index file, `0` for root directory of the repo.
# 5. `current_depth`, optional, the depth of the current page, defaults to
# `index_depth`.
Repo_Navigator = (index_path = "docas.index", index_depth = 0, current_depth = index_depth) ->
 
  if first_time
    regist_events $('#filelists').children()[0], index_path, index_depth, current_depth
    first_time = off
    return 

  get_index = ->

    # #### Ajax Call to Get Index
    $.ajax
      type: 'GET'
      url: index_path

      success: (index) ->

        # #### Render Breadcrumb Navigator
        breadcrumb_path  = index_path.split '/'
        breadcrumb_end   = breadcrumb_path.length - 1
        breadcrumb_path  = breadcrumb_path[0...breadcrumb_end]
        $('#breadcrumb').html breadcrumb_template [repo, breadcrumb_path...]

        # #### Handling Breadcrumb Interaction
        $('#breadcrumb a').click ->
          new_depth = $(@).attr('depth') * 1
          new_path = index_path.split '/'
          new_path.splice new_path.length - index_depth + new_depth - 1, index_depth - new_depth
          new Repo_Navigator new_path.join('/'), new_depth, current_depth

        # #### Render Content Table
        #
        # `absolute_base` is used to generate github.com links for undocumented sources.
        # `relative_base` is used to generate links for documented sources.

        absolute_base = breadcrumb_path.join '/'
        depth_offset  = index_depth - current_depth
        if depth_offset > 0
          relative_base = breadcrumb_path[breadcrumb_path.length - depth_offset..].join '/'
        else
          relative_base = new Array(-depth_offset + 1).join '../'

        table = $ list_template
          user          : user
          repo          : repo
          index_depth   : index_depth
          absolute_base : absolute_base
          relative_base : relative_base
          entries       : process_index index, gitmodules, absolute_base

        regist_events table, index_path, index_depth, current_depth

  get_index()

# ### Replace Emails by GitHub Logins
#
# By leveraging GitHub api, repo navigator can replace emails by real GitHub
# logins.
#
# **Notice:** every new domain should be registered through **Register a new
# OAuth application** before making cross-domain ajax requests successfully.

usernames = {}

update_usernames = (table) ->
  emails = {}
  for span in $(table).find("span[email]")
    emails[$(span).attr("email")] = null
  for email of emails
    do (email) ->
      update_table = (username) ->
        $(table).find("span[email='#{email}']").html("<a href='https://github.com/#{username}'>#{username}</a>") if username
      if usernames.hasOwnProperty email
        update_table usernames[email]
      else
        $.getJSON "https://api.github.com/legacy/user/email/#{email}", (data) ->
          update_table usernames[email] = if data and data.user then data.user.login else null

# ### Coda
#
# Expose `repo_browser` constructor globally.
#
#   * For browser environment, initialize the (root level) `Repo_Navigator`.
#   * For node.js environment, expose:
#     + `process_index`: used for processing the (root level) `docas.index`
#     + `breadcrumb_template`: used for rendering the breadcrumb in the `index.html`
#     + `list_template`: used for rendering the content of the navigator in the `index.html`

if typeof window is 'undefined'
  module.exports =
    process_index       : process_index
    breadcrumb_template : breadcrumb_template
    list_template       : list_template
else
  new Repo_Navigator
