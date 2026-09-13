exec jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template 'separate(" ",
  format_short_change_id(change_id),
  bookmarks,
  if(conflict, label("conflict", "(conflict)")),
  if(divergent, label("divergent", "(divergent)")),
  if(description, description.first_line(), if(!empty, description_placeholder))
)'
