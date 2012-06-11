
_moment = if typeof window is 'undefined' then require '../../vendor/moment.js' else moment

# ## Fields of `docas.index`:
# * **type**: `f` or `d` for file and directory accordingly.
# * **name**: 'awesome.file'
# * **action**: 's' for documented source, ``
# * **size**: `32.9KB`
# * **sloc**: `275`
# * **author**: `Baoshan Sheng`
# * **email**: `sheng@icmd.org`
# * **date**: `1339388143`
# * **description**: `Comment at first line will become description of the file`
# * **message**: `Git commit message get from Grit`
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
  lines = index.split "\n"
  lines.pop()
  entries = []
  lines.forEach (line) ->
    entry = {}
    pattern = /[^\|]\|/g
    index = position = 0
    while result = pattern.exec line
      value = line.substring position, result.index
      value = value.replace '||', '|'
      entry[index_entry_segments[index++]] = value
      position = pattern.lastIndex + 1
    entry[index_entry_segments[index]] = line.substr(position).replace('||', '|')
    segments = entry.name.split '.'
    while segments[0] is ''
      segments.splice 0, 1
    entry.document = segments[0...(if segments.length > 1 then segments.length - 1 else segments.length)].join('.') + '.html' if entry.action is 's'
    entry.submodule = gitmodules[(if base then base + '/' else '') + entry.name]
    entry.modified = _moment(new Date entry.date * 1000).fromNow() if _moment
    entries.push entry
  entries.sort (a, b) -> if "#{a.type}#{a.name}" > "#{b.type}#{b.name}" then 1 else -1
