TODO
====

- Plugin system
- Stackable output filters/engines
   - rubypants as filter, latex support as filter....
- Documentation
- Code comments and rdoc generation
- More specs and more unit tests, or throw away
  the specs and write only unit tests. I don't like
  this spec syntax that much.
- LaTeX integration
- Captcha support
- Image support, Image gallery
- Create a larsch-creole gem
- Wiki installation under subpath (path_info translation could be done
  via rack middleware, generated links must be adapted)
- Cache-control and etag support
- Clean up stylesheet
- More caching where it makes sense
- Support for branching operations (Maybe not that important for a gui?)
- Switch to grit maybe (grit does not support some things yet, but has native implementation of some git features)
- (DONE) Problem with last modified dates, they always refer to the whole tree
- (DONE) Breadcrumbs for tree browsing
- (DONE) Automatic file extensions for wikitext files
- (DONE) Preview
- (DONE) Menu
- (DONE) Search
- (DONE) Edit uploaded files (overwrite)
- (DONE) Login
- (DONE) Editable user profile, change pw function
- (DONE, but could be a lot improved) RSS/Atom Changelog

Known bugs
----------

- Removed files have a next button for the last existing revision
  because the deletion is registered as commit for the respective file
  (see Page.next_commit)
- (WORKAROUND, no colspan used) Tablesorter doesn't get the colspan on /history
- If the page is too far in the past the next button does not work correctly
  (see Page.next_commit)

ruby-git TODO
-------------

- (DONE) Get my patches included
- (DONE) Commits aren't parsed correctly
- (DONE) Fix uninitialized variables ($VERBOSE = 1 in the tests)

