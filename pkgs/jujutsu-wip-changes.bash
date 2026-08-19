wip_revset='::(@ | bookmarks() | (visible_heads() ~ ::remote_bookmarks()))
  ~ ::(trunk() | root())
  ~ (empty() & description(exact:""))'

wip_template='change_id.short(8) ++ if(self.contained_in("::remote_bookmarks()"), "", "*") ++ "\n"'

exec jj log --no-graph --revisions "$wip_revset" --template "$wip_template"
