fs     = require 'fs'

module.exports = (conf) ->

  conf   = fs.readFileSync(conf).toString()
  result = {}

  result.project_page = project_page_match[1].trim() if project_page_match = conf.match /^project_page:(.*)$/m
  result.google_analytics = google_analytics_match[1].trim() if google_analytics_match = conf.match /^google_analytics:(.*)$/m

  if page_javascripts_match = conf.match /\npage_javascripts: *((\n  .*)*)/
    page_javascripts = {}
    for entry in page_javascripts_match[1].split('\n').filter((x) -> x).map((x) -> x.split(':').map((y) -> y.trim()))
      page_javascripts[entry[0]] = entry[1]  
    result.page_javascripts = page_javascripts

  if page_stylesheets_match = conf.match /\npage_stylesheets: *((\n  .*)*)/
    page_stylesheets = {}
    for entry in page_stylesheets_match[1].split('\n').filter((x) -> x).map((x) -> x.split(':').map((y) -> y.trim()))
      page_stylesheets[entry[0]] = entry[1]
    result.page_stylesheets = page_stylesheets

  result
