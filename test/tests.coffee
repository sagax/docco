
path          = require 'path'
fs            = require 'fs'
xfs           = require 'fs-extra'
rimraf        = require 'rimraf'

Docco         = require '../docco'

# Determine the test and resources paths
testPath      = path.dirname fs.realpathSync(__filename)
dataPath      = path.join testPath, "data"
resourcesPath = path.normalize path.join(testPath, "/resources")

# test runner
test = (msg, f) ->
  console.log "\n===========================================\n", msg
  f()

# a la jasmine: renamed test runnr which does nothing, 
# i.e. is used for (temporarily) disabled tests:
xtest = (msg, f) ->
  console.log "\n================SKIPPED===================\n", msg
  return

# assert function:
equal = (a, b, msg) ->
  throw new Error("TEST FAILED: " + msg + " (" + a + " !== " + b + ")") if (a != b)
  a == b

ensureDirectory = (dir, f) ->
  xfs.mkdirsSync(dir)
  f()


#### Docco Test Assertion Wrapper

# Run a Docco pass, and check that the number of output files
# is equal to what is expected.  We assume there is one CSS file
# that is always copied to the output, so we check that the
# number of output files is (matched_sources + 1).
testDoccoRun = (testName, sources, options=null, callback=null) ->
  destPath = path.join dataPath, testName
  # Remove the data directory for this test run
  cleanup = (callback) -> rimraf destPath, callback
  cleanup (error) ->
    equal not error, true, "path cleaned up properly"
    options?.output = destPath
    opts = options || {}
    opts.args = sources
    #console.log "going to run docco with options: ", opts
    Docco.document opts, (error, info) ->
      # Calculate the number of expected files in the output, and
      # then the number of files actually found in the output path.
      files       = []
      for src, i in sources
        #console.log "check output for file: ", {
        #  index: i
        #  src: src
        #}
        files = files.concat(info.source_infos[i].destDocFile)
      extra_files = 0
      if options
        if options.markdown
          extra_files = 2
        else if options.template
          extra_files = 0
        else if options.css
          extra_files = 2
        else
          extra_files = 2
      expected    = files.length + extra_files
      found       = fs.readdirSync(destPath).length

      # Check the expected number of files against the number of
      # files that were actually found.
      equal found, expected, "find expected output (#{expected} files) - (#{found})"

      # Trigger the completion callback if it's specified
      callback() if callback?

# **Optional markdown output should be supported**
test "markdown from docco", ->
  testDoccoRun "markdown_output", 
    ["#{testPath}/tests.coffee"],
    markdown: true

# **Custom jst template files should be supported**
test "custom JST template file", ->
  testDoccoRun "custom_jst",
    ["#{testPath}/tests.coffee"],
    template: "#{resourcesPath}/pagelet/docco.jst"

# **Custom CSS files should be supported**
test "custom CSS file", ->
  testDoccoRun "custom_css",
    ["#{testPath}/tests.coffee"],
    css: "#{resourcesPath}/pagelet/docco.css"

# **Specifying a filetype independent of extension should be supported** 
test "specify an extension", ->
  testDoccoRun "specify_extension",
    ["#{testPath}/comments/noextension"],
    extension: ".coffee"

# **Comments should be parsed properly**
#
# There are special data files located in `test/comments` for each supported
# language.  The first comment in  each file corresponds to the expected number
# of comments to be parsed from its contents.
#
# This test iterates over all the known Docco languages, and tests the ones
# that have a corresponding data file in `test/comments`.
test "single line and block comment parsing", ->
  commentsPath = path.join testPath, "comments"
  options =
    template: "#{commentsPath}/comments.jst"
    blocks  : true

  # Construct a list of languages to test asynchronously.  It's important
  # that these be tested one at a time, to avoid conflicts between multiple
  # file extensions for a language.  e.g. `c.c` and `c.h` both output to
  # c.html, so they must be run at separate times.
  languageKeys = (ext for ext,l of Docco.languages)

  testNextLanguage = (keys,callback) ->
    return callback?() if not keys.length

    extension       = keys.shift()
    language        = Docco.languages[extension]
    languageExample = path.join commentsPath, "#{language.name}#{extension}"
    languageTest    = "comments_test/#{language.name}"
    languagePath    = path.join dataPath, languageTest
    languageOutput  = path.join languagePath, "#{language.name}.html"

    # *Skip over this language if there is no corresponding test*
    return testNextLanguage(keys, callback) if not path.existsSync languageExample

    # Run them through docco with the custom `comments.jst` file that
    # outputs a CSV list of doc blocks text.
    testDoccoRun languageTest, [languageExample], options, ->

      # Be sure the expected output file exists
      equal true, path.existsSync(languageOutput), "#{languageOutput} -> output file created properly"

      # Read in the output file contents, split them into a list
      # of comments.
      content = fs.readFileSync(languageOutput).toString()
      comments = (c.trim() for c in content.split(',') when c.trim() != '')

      equal true, comments.length >= 1, 'expect at least the descriptor comment'

      # Parse the first comment (special case), to identify the expected
      # comment counts, based on whether we're matching block comments or not.
      descriptor = comments[0].match(/^Single:([0-9]*) - Block:([0-9]*)$/)
      if !descriptor
        console.log "comment is malformed! ", comments
      expected = parseInt(if l.blocks and options.blocks then descriptor[2] else descriptor[1])
      equal comments.length, expected, [
        ""
        "#{path.basename(languageOutput)} comments"
        "------------------------"
        " blocks   : #{options.blocks}"
        " expected : #{expected}"
        " found    : #{comments.length}"
      ].join '\n'

      # Invoke the next test
      testNextLanguage keys, callback

  # *Kick off the first language test*
  testNextLanguage languageKeys.slice(), ->
    # Test to be sure block comments are excluded when not explicitly
    # specified.  In this case, the test will check for the existence
    # of only 1 comment in all languages (a single-line)
    options.blocks = false
    testNextLanguage languageKeys.slice()

# **URL references should resolve across sections**
#
# Resolves [Issue 100](https://github.com/jashkenas/docco/issues/100)
test "url references (defined up front)", ->
  ensureDirectory dataPath, ->
    sourceFile = "#{dataPath}/_urlref.coffee"
    fs.writeFileSync sourceFile, [
      "# [google]: http://www.google.com",
      "#",
      "# Look at this link to [Google][]!",
      "console.log 'This must be Thursday.'",
      "# And this link to [Google][] as well.",
      "console.log 'I never could get the hang of Thursdays.'"
    ].join('\n')
    outPath = path.join dataPath, "_urlreferences1"
    outFile = "#{outPath}/_urlref.html"
    rimraf outPath, (error) ->
      equal not error, true
      Docco.document {
        cwd: dataPath,
        output: outPath,
        args: [sourceFile]
      }, ->
        contents = fs.readFileSync(outFile).toString()
        count = contents.match ///<a\shref="http://www.google.com">Google</a>///g
        equal count?.length, 2, "find expected (2) resolved url references"

test "url references (defined at the end)", ->
  ensureDirectory dataPath, ->
    sourceFile = "#{dataPath}/_urlref.coffee"
    fs.writeFileSync sourceFile, [
      "# Look at this link to [Google][]!",
      "console.log 'This must be Thursday.'",
      "# And this link to [Google][] as well.",
      "console.log 'I never could get the hang of Thursdays.'",
      "# [google]: http://www.google.com"
    ].join('\n')
    outPath = path.join dataPath, "_urlreferences2"
    outFile = "#{outPath}/_urlref.html"
    rimraf outPath, (error) ->
      equal not error, true
      Docco.document {
        cwd: dataPath,
        output: outPath,
        args: [sourceFile]
      }, ->
        contents = fs.readFileSync(outFile).toString()
        count = contents.match ///<a\shref="http://www.google.com">Google</a>///g
        equal count?.length, 2, "find expected (2) resolved url references"

# **Paths should be recursively created if needed**
#
# ensureDirectory should properly create complex output paths.
test "create complex paths that do not exist", ->
  exist = fs.existsSync or path.existsSync
  outputPath = path.join dataPath, 'complex/path/that/doesnt/exist'
  rimraf outputPath, (error) ->
    equal not error, true
    ensureDirectory outputPath, ->
      equal exist(outputPath), true, 'created output path: ' + outputPath
      stat = fs.statSync outputPath
      equal stat.isDirectory(), true, "target is directory"
