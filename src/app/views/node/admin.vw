@section code {

  $(function() {
    $('div#data').grid({
      size: 10,
      url: '/node/json',
      columns: ["no_id", "no_title", "no_updated_by", "no_status"],
      multiSelect: false,
      rowDblClick: function (row) {alert(row.no_id);},
      buttons: [
        {value: 'Edit', click: function(row) {window.location="/node/edit?id="+row.no_id;}},
        {value: 'Delete', click: function(row) {alert(row.no_name);}},
        {value: 'New', click: function(row) {window.location="/node/create";}}
      ]
    });
  });

}@

@section content {

  <div class='row'>
    <h1>Node Admin</h1>
    <p>Please select the node to modify from the list below:</p>
    <div id=data></div>
  </div>

}@