README
======

Git-Wiki is a a wiki that stores pages in a git repository.

Demo installation at http://git-wiki.kicks-ass.org/

Features
--------

- History
- Show diffs
- Edit page, append to page, upload files
- Plugin system
- Multiple renderers
- LaTeX
- Syntax highlighting (embedded code blocks)

Installation
------------

Run with `./run.ru -sthin -p4567` and point your browser at <http://localhost:4567>.
It automatically creates a repository in the directory '.wiki'.

Dependencies
------------

- [Sinatra][]
- [ruby-git][]
- [HAML][]
- [RubyPants][]

Optional Dependencies
---------------------

- [RubyPants][] to fix puncation
- [Pygments][] for syntax highlighting
- [latex-renderer][] for latex output (minad-latex-renderer gem from github)

Dependencies for page rendering
-------------------------------

- [creole][] for creole wikitext rendering (minad-creole gem from github)
- [RDiscount][] for markdown rendering
- [RedCloth][] for textile rendering

At least one of the renderers should be installed.

  [Sinatra]: http://www.sinatrarb.com
  [ruby-git]: http://github.com/schacon/ruby-git
  [HAML]: http://haml.hamptoncatlin.com
  [RDiscount]: http://github.com/rtomayko/rdiscount
  [RedCloth]: http://whytheluckystiff.net/ruby/redcloth/
  [RubyPants]: http://chneukirchen.org/blog/static/projects/rubypants.html
  [creole]: http://github.com/minad/creole
  [latex-renderer]: http://github.com/minad/latex-renderer
  [pygments]: http://pygments.org/

