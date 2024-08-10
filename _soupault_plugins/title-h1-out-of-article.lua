title = HTML.select_one(page, "article > .title")
if title then
  article = HTML.parent(title)
  HTML.insert_before(article, title)
end
