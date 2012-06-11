
index_entry_segments = [
  "type"
  "name"
  "action"
  "size"
  "sloc"
  "author"
  "email"
  "date"
  "description"
  "message"
]

process_index = (index, gitmodules, base) ->
  lines = index.split("\n")
  lines.pop()
  entries = []
  lines.forEach (line) ->
    entry = {}
    pattern = /[^\|]\|/g
    index = position = 0
    while result = pattern.exec line
      value = line.substring position, result.index + 1
      value = if typeof $ is 'undefined' then value.trim() else $.trim value
      value = value.replace '||', '|'
      entry[index_entry_segments[index++]] = value
      position = pattern.lastIndex
    entry[index_entry_segments[index]] = line.substr(position).replace('||', '|')
    entry.type = if entry.type is 'd' then 'directory' else 'file'
    segments = entry.name.split '.'
    while segments[0] is ''
      segments.splice 0, 1
      entry.document = segments[0...(if segments.length > 1 then segments.length - 1 else segments.length)].join('.') + '.html' if entry.action is 's'
    entry.submodule = gitmodules[(if base then base + '/' else '') + entry.name]
    entry.modified = moment(new Date entry.date * 1000).fromNow()
    entries.push entry
    
  entries.sort (a, b) -> if [a.type, a.name] > [b.type, b.name] then 1 else -1


$ ->
  $.get 'docas.index', (data) ->
    index = process_index data, {}, ''
    index = index.filter (entry) -> entry.action is 's'
    if index.length > 1
      html = '<div id="jump_to">Jump To &hellip;<div id="jump_wrapper"><div id="jump_page">'
      for entry in index
        html += '<a class="source" href="' + entry.document + '">' + entry.name + '</a>'
      html += '</div></div></div>'
      $('#background').after($(html))
