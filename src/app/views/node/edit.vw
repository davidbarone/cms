@section content {

#{

local function set_selected(value, selected)
  if value == selected then
    return "selected"
  else
    return ""
  end 
end

local function format_content(content)
  if content then
    return content:html_escape()
  else
    return ""
  end
end

}#

<h3>Edit Node</h3>

<form class="block-label" action="/node/#{= action }#" method="post">
  <input type="hidden" value="#{= node.no_id }#" name="id" />
  <fieldset>

    #{ if node.no_parent_id then }#
      <div class='s100 col'>
        <label for="no_parent_id">Parent Node Id:</label>
        <input type="text" readonly name="parent" class="full-width" value="#{= node.no_parent_id}#"/>
      </div>
    #{ end }#

    <div class='s100 col'>
      <label for="title">Node Title:</label>
      <input type="text" name="title" class="full-width" value="#{= node.no_title }#" placeholder="Enter title of node" required title="Enter text (1-10 chars)"/>
    </div>

    <div class='s100 col'>
      <label for="teaser">Node Teaser:</label>
      <textarea name="teaser" class="full-width" rows="5">#{= format_content(node.no_teaser) }#</textarea>
    </div>

    <div class='s100 col l33 col'>
      <label for="categories">Categories:</label>
      <input type="text" class="full-width" name="categories" value="#{= node.category_string }#" placeholder="Enter optional categories for this node." title="Enter categories, separated by comma"/>
    </div>

    <div class='s100 col l33 col'>
      <label for="content_type">Content Type:</label>
      <select name="content_type" class="full-width" value="${node.no_content_type}">
        <option value="HTML" #{= set_selected(node.no_content_type, "HTML") }#>HTML</option>
        <option value="MARKDOWN" #{= set_selected(node.no_content_type, "MARKDOWN") }#>MARKDOWN</option>
      </select>
    </div>

    <div class='s100 col l33 col'>
      <label for="status">Status:</label>
      <select name="status"  class="full-width">
        <option value="D" #{= set_selected(node.no_status,"D") }#>Draft</option>
        <option value="P" #{= set_selected(node.no_status, "P") }#>Published</option>
        <option value="X" #{= set_selected(node.no_status, "X") }#>Deleted</option>
      </select>
    </div>

    <div class='s100 col'>
      <label for="content">Head:</label>
      <textarea name="head" class="full-width" rows="5">#{= format_content(node.no_head) }#</textarea>
    </div>

    <div class='s100 col'>
      <label for="style">Style:</label>
      <textarea name="style" class="full-width" rows="5">#{= format_content(node.no_style) }#</textarea>
    </div>

    <div class='s100 col'>
      <label for="content">Code:</label>
      <textarea name="code" class="full-width" rows="10">#{= format_content(node.no_code) }#</textarea>
    </div>

    <div class='s100 col'>
      <label for="content">Content:</label>
      <textarea name="content" class="full-width" rows="20">#{= format_content(node.no_content) }#</textarea>
    </div>

    <div class='s100 col'>
      <input type="submit" value="submit"/>
      <a class='button' href="/node/create?parent= #{= node.no_id }#">Add child page</a>
      <a href="/node/">Back</a>
    </div>  
  </fieldset>
</form>

}@