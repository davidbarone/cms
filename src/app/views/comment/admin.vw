@section code {

  $(function() {
    $('div#data').grid({
      title: 'Comments',
      height: 150,
      size: 10,
      url: '/comment/json',
      multiSelect: false,
      columns: ["co_updated_ts", "co_name", "no_title", "co_comment", "co_status"]
    });
  });

}@


@section content {

  <div class='row'>
    <div id=data></div>
  </div>

}@