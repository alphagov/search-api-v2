# Domain model for a single piece of content on GOV.UK that can be stored in, and retrieved from, a
# search engine
#
# @attr_reader [String] content_id A unique UUID for this document across all GOV.UK content
# @attr_reader [String, nil] title The title of the document
Document = Data.define(:content_id, :title)
