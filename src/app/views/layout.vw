<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="description" content="David Barone - Business Analyst">
  <meta name="keywords" content="David Barone, Barone, Software Developer, Programmer, Business Intelligence, Central Coast, Sydney, Newcastle">
  <meta name="viewport" content="width=device-width">

  <title>David Barone - Business Analyst</title>

  <script type="text/javascript" src="/resource/view?filename=jquery-1.11.1.min.js"></script>
  <script type="text/javascript" src="/resource/view?filename=grid.js"></script>
  <link rel="Stylesheet" type="text/css" href="/resource/view?filename=normalize.css">
  <link rel="Stylesheet" type="text/css" href="/resource/view?filename=style.css">

  @rendersection{ head }@

  <style type='text/css'>
    @rendersection{ style }@
  </style>

  <script type='text/javascript'>

    $(function() {
      $.ajax({
        url: "/node/categories",
        success: function(json) {
          $.each(json.data, function(i, v) {
            $('div#categories').append('<a class="button" href="/node/index?category=' + v + '">' + v + '</a> ');
          });
          $('div#categories').append('<div style="clear:both;"></div>');
        }
      });

      $.ajax({
        url: "/node/archives",
        success: function(json) {
          $.each(json.data, function(i, v) {
            $('div#archives').append('<a style="display: block;" href="/node/index?archive=' + v.month_desc + '">' + v.month_desc + '</a>');
          });
          $('div#archives').append('<div style="clear:both;"></div>');
        }
      });

      $.ajax({
        url: "/security/status",
        success: function(data) {
          $('#security').append(data);
        }
      });

    });  

  </script>

</head>

<body>

  <header>
    <div class='container'>
      <a href='/'>Home</a>
    </div>
  </header>

  <main>

    <!-- Title area -->
    <div class='title'>
      <div class='container'>
        <div class='s100 m75 col'>David Barone - Business Analyst</div>
        <div class='s10 m25 col logo'>&nbsp;</div>
      </div>
    </div>

    <div class='container'>
      <div class='s100 m75 col'>
        @rendersection{ content }@
      </div>
      <div class='s0 m2 col'>
        &nbsp;
      </div>
      <div class='s100 m23 col'>
        <h3>About me:</h3>
        <p style="text-align: justify;">
        My name's David Barone, and I'm a software developer and 
        BI specialist based just north of Sydney, on Australia's
        Central Coast. You can contact me on:</p>
        <ul>
          <li>Tel: +61 2 4397 3410</li>
          <li>Mob: +61 4 1541 1594</li>
          <li>Mail: dbarone123@gmail.com</li>
        </ul>
      
        @rendersection{navigate}@
        <div id="categories"><h3>Categories:</h3></div>
        <div id="archives"><h3>Archives:</h3></div>
        <div id='security'></div>

      </div>
    </div>

  </main>

  <footer>
    <div class='container'>
      <div class='s100 col'>
        <div>&copy; 2015 - David Barone</div>
        <div>
          <a href="mailto:mail@dbarone.com">email</a> |
          <a href="http://www.dbarone.com/aboutme">about me</a> |
          <a href="http://www.dbarone.com/licence">licence</a>
        </div>
	<div>
          Validate <a title="Validate this page as HTML 4.01 Strict" href="http://validator.w3.org/check/referer">HTML</a>,
          <a title="Validate this page's stylesheet as CSS Version 2" href="http://jigsaw.w3.org/css-validator/validator?uri=http://www.dbarone.com/style.css">CSS</a>
        </div>
      </div>
    </div>
  </footer>

</body>

<head>
  <script type='text/javascript'>
    @rendersection{ code }@
  </script>
</head>
</html>