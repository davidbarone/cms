<h1>Create User</h1>

<form class="block-label" action="/security/create_user" method="post">
  <fieldset>
    <legend>User Details</legend>

      <div class='s100 col'>
        <label for="name">Name:</label>
        <input type="text" name="name" placeholder="Enter name" required pattern="[A-Za-z \d]{1,20}" title="Enter text (Max 20 chars)"/>
      </div> 

      <div class='s100 col'>
        <label for="email">Email:</label>
        <input type="email" name="email" placeholder="Enter email address" title="Enter email address" required/>
      </div>

      <div class='s100 col'>
        <label for="password">Password:</label>
        <input type="text" name="password" placeholder="Enter password" required pattern="[A-Za-z\d!@#$%^&*()? ]{8,}" title="Enter password (min 8 length)"/>
      </div>

      <div class='s100 col'>
        <input type=submit name=submit value='create'/>
      </div>
</form>