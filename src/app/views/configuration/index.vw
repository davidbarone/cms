@section code {

  $(function() {
    $('div#data').grid({
      title: 'Configuration',
      height: 150,
      size: 10,
      url: '/configuration/json',
      columns: ["co_key", "co_value", "co_comment"],
      multiSelect: false,
      rowClick: function (row) {
        $('form').show();
        $('input#key').val(row.co_key);
        $('input#key2').val(row.co_key);
        $('input#value').val(row.co_value);
        $('input#comment').val(row.co_comment);
      },
      buttons: [
        {value: 'Delete', click: function(row) {
          $.ajax({
            url: "/configuration/delete",
            type: "GET",
            data: {"key": row.co_key}, 
            success: function(){location.reload(true);},
            error: function(xhr,status,error){alert(error);}
          });
        }},
        {value: 'New', click: function(row) {
          var key = prompt("Enter key:");
          $.ajax({
            url: "/configuration/create",
            type: "GET",
            data: {"key": key},
            success: function(){location.reload(true);},
            error: function(xhr,status,error){alert(error);}
          });
        }}
      ]
    });
  });

}@


@section content {

<div class='row'>
  <div id=data></div>

  <form class='block-label' style='display:none;' action="/configuration/edit" method="post">
    <fieldset>
      <legend>Edit configuration:</legend>

      <div class='s100 col'>
        <label for="key">Key:</label>
        <input id="key" type="hidden" name="key" />
        <input class="full-width" id="key2" type="text" name="key" value="XXX" disabled />
      </div>

      <div class='s100 col'>
        <label for="value">Value:</label>
        <input class="full-width" id="value" type="text" name="value" value="XXX" />
      </div>

      <div class='s100 col'>
        <label for="value">Comment:</label>
        <input class="full-width" id="comment" type="text" name="comment" value="XXX" />
      </div>

      <input type="submit" value="submit"/>
    </fieldset>

  </form>
</div>

}@