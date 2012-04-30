**Docco** is a quick-and-dirty, hundred-line-long, literate-programming-style
documentation generator. It produces HTML
that displays your comments alongside your code. Comments are passed through
[Markdown](http://daringfireball.net/projects/markdown/syntax), and code is
passed through [Pygments](http://pygments.org/) syntax highlighting.
This page is the result of running Docco against its own source file.

If you install Docco, you can run it from the command-line:

    docco src/*.coffee

...will generate an HTML documentation page for each of the named source files, 
with a menu linking to the other pages, saving it into a `docs` folder.

The [source for Docco](http://github.com/jashkenas/docco) is available on GitHub,
and released under the MIT license.

To install Docco, first make sure you have [Node.js](http://nodejs.org/),
[Pygments](http://pygments.org/) (install the latest dev version of Pygments
from [its Mercurial repo](http://dev.pocoo.org/hg/pygments-main)), and
[CoffeeScript](http://coffeescript.org/). Then, with NPM:

    sudo npm install -g docco

Docco can be used to process CoffeeScript, JavaScript, Ruby, Python, or TeX files.
Only single-line comments are processed -- block comments are ignored.

## Partners in Crime:

* If **Node.js** doesn't run on your platform, or you'd prefer a more 
convenient package, get [Ryan Tomayko](http://github.com/rtomayko)'s 
[Rocco](http://rtomayko.github.com/rocco/rocco.html), the Ruby port that's 
available as a gem. 

* If you're writing shell scripts, try
[Shocco](http://rtomayko.github.com/shocco/), a port for the **POSIX shell**,
also by Mr. Tomayko.

* If Python's more your speed, take a look at 
[Nick Fitzgerald](http://github.com/fitzgen)'s [Pycco](http://fitzgen.github.com/pycco/). 

* For **Clojure** fans, [Fogus](http://blog.fogus.me/)'s 
[Marginalia](http://fogus.me/fun/marginalia/) is a bit of a departure from 
"quick-and-dirty", but it'll get the job done.

* **Lua** enthusiasts can get their fix with 
[Robert Gieseke](https://github.com/rgieseke)'s [Locco](http://rgieseke.github.com/locco/).

* And if you happen to be a **.NET**
aficionado, check out [Don Wilson](https://github.com/dontangg)'s 
[Nocco](http://dontangg.github.com/nocco/).

