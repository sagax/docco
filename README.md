
### Introducing Docas.io
#
# For most developers expecting an elegant and natural approach documenting
# their source code, [Docas.io] is simplier than this stand-alone version.
# Real-time synced documentation in just 2 steps:
#
#   1. Add **[docas]** as your collaborator.
#   2. Add service hook **[http://docas.io](http://docas.io)**.
#
# Docas.io syncs the documents on GitHub pages in real time when you push
# sources to GitHub.
#
### Back to the Topic
#
# **Docas** is a command-line program which streamlines GitHub repository
# documentation task. It relies on:
#
#   - **[Docco]**, a quick and dirty, hundred-line-long, literate-programming
#   style documentation generator invented by [Jeremy Ashkenas].
#
#   - **[Docci]**, renders an `index.html` for git repository, including: recent
#   commits log, stats of languages and [slocs], and a file browser for
#   documentations. *(Not a stand-alone command yet.)*
#
#   - **[Linguist]**, the language savant behind GitHub, inspecting over 150
#   languages.
#
# **Docas** can be executed as a stand-alone command from the developer's machine,
# which will:
#
#   1. Clone the GitHub repository into a temporary directory.
#   2. Create gh-pages branch (optional) and list dirty directories.
#   3. Generate the cover page using docci.
#   4. Documente sources for each directory using docco.
#   5. Push to the remote gh-pages branch.
#
# **However**, it's recommended to further simplify the task for your every
# commit using **[docas.io]**, a service keeps your documentation in sync with
# source code automatically.
#
# [Docas]: http://docas.github.com
# [Docco]: http://jashkenas.github.com/docco
# [Jeremy Ashkenas]: http://jashkenas.github.com
# [Docci]: http://baoshan.github.com/docas/src/docci.html
# [SLOCs]: http://en.wikipedia.org/wiki/Source_lines_of_code "Source lines of code"
# [Linguist]: https://github.com/github/linguist
# [docas.io]: http://docas.io
#
### Command-line usage:
# 
# Document a repository under local configured github username:
#
#     docas repository
#
# Document a repository under another user or organization name which you have
# write permission (being a collaborator or a team member):
#
#     docas username/repository


Relational Database Project for International Classical Music Database

## Gensis

## Contributor

## Structure

  * PowerShell Script
  * T-SQL Script

## yContribution


### Note
#
# Upon execution of this shell script, GitHub-Synchronizer has finished its
# job. *Bravo...!* Since on docas.io environment, master branch will be read
# only, so there'll be nothing in `git diff` and `git diff HEAD`. But always
# remember when invoking docas on a development environment, docas will **not** 
# try to checkout HEAD, but documenting the working directory, which can 
# lead to inconsistency between `gh-pages` and `master` branch. Do it with
# consciousness (or why not `commit` first?).
