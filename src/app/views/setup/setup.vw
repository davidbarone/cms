<h1>Database Setup</h1>

<form class="block-label" action="/setup" method="post">
  <fieldset>
    <legend>Administrator Details</legend>
    <div class='row s100 col'>
      <label for="no_name">Email:</label>
      <input type="text" name="email" placeholder="Enter email"/>
    </div>
  
    <div class='row s100 col'>
      <label for="no_layout">Name:</label>
      <input type="text" name="name" placeholder="Enter name"/>
    </div>

    <div class='row s100 col'>
      <label for="no_group">Password:</label>
      <input type="password" name="password" placeholder="Enter password" required pattern="[A-Za-z\d!@#$%^&*()? ]{8,}" title="Enter password (min 8 length)"/>
    </div>

    <div class='row s100 col'>
      <input type="submit" value="submit"/>
    </div>
  </fieldset>
</form>