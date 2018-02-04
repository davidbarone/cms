@section head {

  <script type="text/javascript" src="/resource/view?filename=jquery-1.11.1.min.js"></script>
  <script type="text/javascript" src="/resource/view?filename=grid.js"></script>
  
}@


@section style {

  .white
  {
    clear: both;
    background: #fff;
    padding:0px;
    height: 10000px;
  }
  </style>

}@


@section content {

<h3>Resources</h3>

<form class="block-label" action="/resource/index" method="post" enctype="multipart/form-data">
  <fieldset>
    <div class='s100 col'>
      <input type="file" name="uploader"/>
    </div>

    <div class='s100 col'>
      <input type="submit" value="Upload"/>
      <input type="button" value="Display" onclick="javascript:display();" />
    </div>

    <div class='s100 col' id='data'></div>
  </fieldset>
</form>

}@


@section code {

  display = function() {
     $('div#data').empty().grid({
        size: 10,
        url: '/resource/json',
        columns: ["filename", "thumbnail"],
        multiSelect: false,
        buttons: [
        {value: 'Delete', click: function(row) {
          $.ajax({
            url: "/resource/delete",
            type: "GET",
            data: {"filename": row.filename}, 
            success: function(){location.reload(true);},
            error: function(xhr,status,error){alert(error);}
          });
        }}]
      });
  }

  // displays result message on postback
  $(function() {
    #{ if message then }#
      alert("#{= message }#");
    #{ end }#
  });

}@
