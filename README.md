# PasswordManager
Simple script application what allows user to keep links, logins and passwords.

## How to use

### Launching
Right click on `password-manager.ps1` and select `Run with PowerShell` from the context menu.

### Editing password list
Open `password-manager.ps1` with any text editor.\
Links, logins and password can be edited in XML at the very top of the script:
```
<Sites>
	<!-- Put Your passwords below. -->
	<Site Link="https://online.store.com" Login="user1@yahoo.com" Password="Password1234" />
	<Site Link="https://mymail.com" Login="user2@mymail.com" Password="Pass3256" />
	<!-- Put Your passwords above. -->
</Sites>
```
Each `Site` node represents one link, login and password set.\
You can add, remove and edit those nodes as You like.

### Searching
You can search links, logins and passwords in a grid.\
Hit `F3` to open Search window.\
Type a phrase to search and hit `Enter` or `F3`, cells what contain typed phrase will be selected in a grid.\
Hit `Escape` to cancel the search.
