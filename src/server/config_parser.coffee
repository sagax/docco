fs = require 'fs'

module.exports.parse = (conf) ->

  conf = fs.readFileSync conf, 'utf-8'
  result = 
    page_javascripts: {}
    page_stylesheets: {}

  if project_page_match = conf.match /^project_page:(.*)$/m
    result.project_page = project_page_match[1].trim()

  if google_analytics_match = conf.match /^google_analytics:(.*)$/m
    result.google_analytics = google_analytics_match[1].trim()

  if page_javascripts_match = conf.match /(?:^|\n)page_javascripts: *((\n  .*)*)/

    entries = page_javascripts_match[1]
              .split('\n')
              .filter((x) -> x.trim())
              .map((x) -> x.split(':').map((y) -> y.trim()))

    for entry in entries
      result.page_javascripts[entry[0]] = entry[1]  

  if page_stylesheets_match = conf.match /(?:^|\n)page_stylesheets: *((\n  .*)*)/

    entries = page_stylesheets_match[1]
              .split('\n')
              .filter((x) -> x.trim())
              .map((x) -> x.split(':').map((y) -> y.trim()))

    for entry in entries
      result.page_stylesheets[entry[0]] = entry[1]

  result
