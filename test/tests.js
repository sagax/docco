// Generated by CoffeeScript 1.10.0
(function() {
  var Docco, dataPath, ensureDirectory, equal, fs, path, resourcesPath, rimraf, test, testDoccoRun, testPath, xfs, xtest;

  path = require('path');

  fs = require('fs');

  xfs = require('fs-extra');

  rimraf = require('rimraf');

  Docco = require('../docco');

  testPath = path.dirname(fs.realpathSync(__filename));

  dataPath = path.join(testPath, "data");

  resourcesPath = path.normalize(path.join(testPath, "/resources"));

  test = function(msg, f) {
    console.log("\n===========================================\n", msg);
    return f();
  };

  xtest = function(msg, f) {
    console.log("\n================SKIPPED===================\n", msg);
  };

  equal = function(a, b, msg) {
    if (a !== b) {
      throw new Error("TEST FAILED: " + msg + " (" + a + " !== " + b + ")");
    }
    return a === b;
  };

  ensureDirectory = function(dir, f) {
    xfs.mkdirsSync(dir);
    return f();
  };

  testDoccoRun = function(testName, sources, options, callback) {
    var cleanup, destPath;
    if (options == null) {
      options = null;
    }
    if (callback == null) {
      callback = null;
    }
    destPath = path.join(dataPath, testName);
    cleanup = function(callback) {
      return rimraf(destPath, callback);
    };
    return cleanup(function(error) {
      var opts;
      equal(!error, true, "path cleaned up properly");
      if (options != null) {
        options.output = destPath;
      }
      opts = options || {};
      opts.args = sources;
      return Docco.document(opts, function(error, info) {
        var expected, extra_files, files, found, i, j, len, src;
        files = [];
        for (i = j = 0, len = sources.length; j < len; i = ++j) {
          src = sources[i];
          files = files.concat(info.source_infos[i].destDocFile);
        }
        extra_files = 0;
        if (options) {
          if (options.markdown) {
            extra_files = 2;
          } else if (options.template) {
            extra_files = 0;
          } else if (options.css) {
            extra_files = 2;
          } else {
            extra_files = 2;
          }
        }
        expected = files.length + extra_files;
        found = fs.readdirSync(destPath).length;
        equal(found, expected, "find expected output (" + expected + " files) - (" + found + ")");
        if (callback != null) {
          return callback();
        }
      });
    });
  };

  test("markdown from docco", function() {
    return testDoccoRun("markdown_output", [testPath + "/tests.coffee"], {
      markdown: true
    });
  });

  test("custom JST template file", function() {
    return testDoccoRun("custom_jst", [testPath + "/tests.coffee"], {
      template: resourcesPath + "/pagelet/docco.jst"
    });
  });

  test("custom CSS file", function() {
    return testDoccoRun("custom_css", [testPath + "/tests.coffee"], {
      css: resourcesPath + "/pagelet/docco.css"
    });
  });

  test("specify an extension", function() {
    return testDoccoRun("specify_extension", [testPath + "/comments/noextension"], {
      extension: ".coffee"
    });
  });

  test("single line and block comment parsing", function() {
    var commentsPath, ext, l, languageKeys, options, testNextLanguage;
    commentsPath = path.join(testPath, "comments");
    options = {
      template: commentsPath + "/comments.jst",
      blocks: true
    };
    languageKeys = (function() {
      var ref, results;
      ref = Docco.languages;
      results = [];
      for (ext in ref) {
        l = ref[ext];
        results.push(ext);
      }
      return results;
    })();
    testNextLanguage = function(keys, callback) {
      var extension, language, languageExample, languageOutput, languagePath, languageTest;
      if (!keys.length) {
        return typeof callback === "function" ? callback() : void 0;
      }
      extension = keys.shift();
      language = Docco.languages[extension];
      languageExample = path.join(commentsPath, "" + language.name + extension);
      languageTest = "comments_test/" + language.name;
      languagePath = path.join(dataPath, languageTest);
      languageOutput = path.join(languagePath, language.name + ".html");
      if (!path.existsSync(languageExample)) {
        return testNextLanguage(keys, callback);
      }
      return testDoccoRun(languageTest, [languageExample], options, function() {
        var c, comments, content, descriptor, expected;
        equal(true, path.existsSync(languageOutput), languageOutput + " -> output file created properly");
        content = fs.readFileSync(languageOutput).toString();
        comments = (function() {
          var j, len, ref, results;
          ref = content.split(',');
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            c = ref[j];
            if (c.trim() !== '') {
              results.push(c.trim());
            }
          }
          return results;
        })();
        equal(true, comments.length >= 1, 'expect at least the descriptor comment');
        descriptor = comments[0].match(/^Single:([0-9]*) - Block:([0-9]*)$/);
        if (!descriptor) {
          console.log("comment is malformed! ", comments);
        }
        expected = parseInt(l.blocks && options.blocks ? descriptor[2] : descriptor[1]);
        equal(comments.length, expected, ["", (path.basename(languageOutput)) + " comments", "------------------------", " blocks   : " + options.blocks, " expected : " + expected, " found    : " + comments.length].join('\n'));
        return testNextLanguage(keys, callback);
      });
    };
    return testNextLanguage(languageKeys.slice(), function() {
      options.blocks = false;
      return testNextLanguage(languageKeys.slice());
    });
  });

  test("url references (defined up front)", function() {
    return ensureDirectory(dataPath, function() {
      var outFile, outPath, sourceFile;
      sourceFile = dataPath + "/_urlref.coffee";
      fs.writeFileSync(sourceFile, ["# [google]: http://www.google.com", "#", "# Look at this link to [Google][]!", "console.log 'This must be Thursday.'", "# And this link to [Google][] as well.", "console.log 'I never could get the hang of Thursdays.'"].join('\n'));
      outPath = path.join(dataPath, "_urlreferences1");
      outFile = outPath + "/_urlref.html";
      return rimraf(outPath, function(error) {
        equal(!error, true);
        return Docco.document({
          cwd: dataPath,
          output: outPath,
          args: [sourceFile]
        }, function() {
          var contents, count;
          contents = fs.readFileSync(outFile).toString();
          count = contents.match(/<a\shref="http:\/\/www.google.com">Google<\/a>/g);
          return equal(count != null ? count.length : void 0, 2, "find expected (2) resolved url references");
        });
      });
    });
  });

  test("url references (defined at the end)", function() {
    return ensureDirectory(dataPath, function() {
      var outFile, outPath, sourceFile;
      sourceFile = dataPath + "/_urlref.coffee";
      fs.writeFileSync(sourceFile, ["# Look at this link to [Google][]!", "console.log 'This must be Thursday.'", "# And this link to [Google][] as well.", "console.log 'I never could get the hang of Thursdays.'", "# [google]: http://www.google.com"].join('\n'));
      outPath = path.join(dataPath, "_urlreferences2");
      outFile = outPath + "/_urlref.html";
      return rimraf(outPath, function(error) {
        equal(!error, true);
        return Docco.document({
          cwd: dataPath,
          output: outPath,
          args: [sourceFile]
        }, function() {
          var contents, count;
          contents = fs.readFileSync(outFile).toString();
          count = contents.match(/<a\shref="http:\/\/www.google.com">Google<\/a>/g);
          return equal(count != null ? count.length : void 0, 2, "find expected (2) resolved url references");
        });
      });
    });
  });

  test("create complex paths that do not exist", function() {
    var exist, outputPath;
    exist = fs.existsSync || path.existsSync;
    outputPath = path.join(dataPath, 'complex/path/that/doesnt/exist');
    return rimraf(outputPath, function(error) {
      equal(!error, true);
      return ensureDirectory(outputPath, function() {
        var stat;
        equal(exist(outputPath), true, 'created output path: ' + outputPath);
        stat = fs.statSync(outputPath);
        return equal(stat.isDirectory(), true, "target is directory");
      });
    });
  });

}).call(this);
