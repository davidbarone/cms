@section navigate {
<div id="navigate"></div>
}@

@section style {
  #{= node.no_style}#
}@

@section code {

  // add siblings nav bar
  $.ajax({
    url: "/node/get_siblings",
    type: "GET",
    data: {"id": #{= node.no_id}#},
    success: function(json){
      if (json.rows>0) {
        $('#navigate').html('<h3>Related Articles:</h3><div />');
        // if node has siblings, display them
        // in nav bar
        $.each(json.data, function(i, v) {
          $('div#navigate>div').append('<a class="button" href="/node/view?id=' + v.key + '">' + v.value + '</a> ');
        });
      }
    },
    error: function(xhr,status,error){alert(error);}
  });

  // add children links
  $.ajax({
    url: "/node/get_children",
    type: "GET",
    data: {"id": #{= node.no_id}#},
    success: function(json){
      if (json.rows>0) {
        $('#children').html('<h3>Articles in this section:</h3><div />');
        // if node has children, display them
        // in nav bar
        $.each(json.data, function(i, v) {
          $('div#children').append('<a class="button" href="/node/view?id=' + v.key + '">' + v.value + '</a> ');
        });
      }
    },
    error: function(xhr,status,error){alert(error);}
  });

  #{= node.no_code}#
  
}@

@section head {
  #{= node.no_head}#
}@

@section content{

#{ local function do_content(str,markdown)
  local ret
  if markdown=="MARKDOWN" then
    ret = str:markdown()
  else
    ret = str
  end
  return ret
end }#

<div>
  <h2>#{= node.no_title}#</h2>
  <div>By #{= node.no_updated_by}# on #{= node.no_updated_ts}# #{= node.category_links}#</div>
  
  <a href="/node/create?parent= #{= node.no_parent_id }#">Add page</a> |
  <a href="/node/edit?id=#{= node.no_id }#">Edit</a> |
  <a href="/node/">Back</a>
  
  <p></p>
  #{= do_content(node.no_content, node.no_content_type) }#
  <p></p>

  <div id="children"></div>
</div>

<!-- comments -->
<h3>Comments:</h3>

#{ for _, c in pairs(comments) do }#

<div>
  By #{ if c.co_url then }#
    <a href="#{= c.co_url }#">#{= c.co_name }#</a>
  #{ else }#
    #{= c.co_name }#
  #{ end }# on #{= c.co_updated_ts }#
  <br>
  #{= c.co_comment:markdown() }#
</div>

#{ end }#

<!-- new comment -->
<div>

  #{ if comments_enabled==0 then }#
    Sorry, comments closed for this article.
  #{ else }#
    <form class="block-label" action="/comment/add" method="post">
      <input type="hidden" value="#{= node.no_id}#" name="id" />
      <fieldset>
        <legend>Add Comment</legend>

          <div class='s100 col'>
            <label for="title">Name:</label>
            <input type="text" class="full-width" name="name" placeholder="Enter name" required title="Enter name" pattern="[A-Za-z]{1,20}"/>
          </div>

          <div class='s100 col'>
            <label for="email">Email:</label>
            <input type="text" class="full-width" name="email" placeholder="Enter optional email." title="Enter optional email."/>
          </div>

          <div class='s100 col'>
            <label for="url">Url:</label>
            <input type="text" class="full-width" name="url" placeholder="Enter optional url." title="Enter optional url."/>
          </div>

          <div class='s100 col'>
            <label for="comment">Comment:</label>
            <textarea name="comment" class="full-width" rows=10 placeholder="Enter comment here. HTML markup not allowed."></textarea>
          </div>

          <div class='s100 col'>
            <input type="submit" value="submit"/>
          </div>

          <div class='s100 col'>
            Please note that all comments on this site are moderated. Comments may take up to 24 hours to be published.
          </div>
  
      </fieldset>
    </form>

  #{ end }#

</div>

}@