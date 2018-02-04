<form class="block-label" action="/security/logout" method="post">
  <h3>User:</h3>
  <div class='row s100 col'>
    Welcome: #{= name }# 
  </div>
  <div class='row s100 col'>
    <input type=submit class='button' name=submit value='logout'/>
  </div>

  <div class='row s100 col'>
    <a href='/admin'>Administration</a>
  </div>

  <div class='row s100 col'>
    <a href='/node/admin'>Node admin</a>
  </div>

  <div class='row s100 col'>
    <a href='/configuration''>Configuration</a>
  </div>

  <div class='row s100 col'>
    <a href='/comment/admin''>Comment Admin</a>
  </div>

  <div class='row s100 col'>
    <a href='/resource''>Resources</a>
  </div>

</form>