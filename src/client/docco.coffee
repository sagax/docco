
render_jump_to = (index_path, root_path, depth) ->

  $.get index_path.join('/'), (data) ->

    index = process_index data, {}, ''
    console.log index
    if index.length
      html = '<div id="jump_to">Jump To &hellip;<div id="jump_wrapper"><div id="jump_page">'
      if depth
        html += "<a dir='u' class='s d'>to upper dir</a>"
      for entry in index
        html += "<a class='source #{entry.type}' "
        if entry.action is 's'
          html += 'href="' + index_path[0...index_path.length - 1].join('/') + '/' + entry.document + '"'
        else if entry.action is 'g'
          html += 'href="https://github.com/' + docas.repo + '/' + root.join('/') + '/' + entry.name + '"'
        else if entry.type is 'd'
          html += 'dir="d"'
        html += '>' + entry.name + '</a>'
      html += '</div></div></div>'
      jump_to = $ $(html)[0]
      jump_to.find('a[dir]').click ->
        if $(@).attr('dir') is 'u'
          root.pop()
          if index_path.length > 1
            index_path.splice index_path.length - 2, 1
          else
            index_path.splice index_path.length - 1, 0, '..'
        else
          root.push $(@).html()
          index_path.splice index_path.length - 1, 0, $(@).html()
        console.log index_path, root, depth + (if $(@).attr('dir') is 'u' then -1 else 1 ) * 1
        render_jump_to index_path, root, depth + (if $(@).attr('dir') is 'u' then -1 else 1 ) * 1

      jump_wrapper = jump_to.find '#jump_wrapper'

      if $('#jump_to').length
        min_height = $('#jump_to > :first-child').height()
        jump_wrapper.css('min-height', min_height)
        jump_wrapper.addClass 'show'
        $('#jump_to').remove()

      jump_wrapper.on 'mouseout', (e) ->
        jump_wrapper.removeClass 'show' if e.target.id is 'jump_wrapper'

      jump_to.on 'mouseout', (e) ->
        jump_wrapper.removeClass 'show' if e.target.id is 'jump_to'

      jump_to.find('#jump_page a').on 'mouseover', ->
        jump_wrapper.css 'min-height', ''

      $('#background').after(jump_to)

# ## Initiate Jump To Links on Load
$ ->
  root_path = window.location.pathname.split '/'
  root_path.pop()
  root_path.shift()
  root_path = root_path.splice root_path.length - docas.depth
  render_jump_to ['docas.index'], root_path, docas.depth
