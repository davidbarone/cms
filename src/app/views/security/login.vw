<form class="block-label" action="/security/login" method="post">
  <h3>Login</h3>
  <div class='row s100 col'>
    <label for="no_email">Email:</label>
    <input type="email" name="email" placeholder="Enter email address" title="Enter email address" required/>
  </div>

  <div class='row s100 col'>
    <label for="no_name">Password:</label>
    <input type="password" name="password" placeholder="Enter password" required pattern="[A-Za-z\d!@#$%^&*()? ]{8,}" title="Enter password (min 8 length)"/>
  </div>

  <div class='row s100 col'>
    <input type=submit class='button' name=submit value='login'/>
  </div>
</form>