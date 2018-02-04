@section content {

#{ for _, n in pairs(nodes) do }#
<div>
  <h2><a href="/node/view?id=#{= n.no_id}#">#{= n.no_title}#</a></h2>
  <div>By #{= n.no_updated_by}# on #{= n.no_updated_ts}# #{= n.category_links}#</div> 
  <p></p>
  #{= (n.no_teaser or ""):markdown() }#
  <p></p>
  <a href="/node/view?id=#{= n.no_id}#">View</a>
</div>
#{ end }#

<!-- pager -->
<div style='text-align:center; margin: 20px;'>
  #{ if page > 0 then }#
  <a href='/node/index?page=#{= page-1}#&category=#{= category}#'>Prev</a>
  #{ end }#
  #{ if eof == 0 then }#
  <a href='/node/index?page=#{= page+1}#&category=#{= category}#'>Next</a>
  #{ end }#
</div>

}@