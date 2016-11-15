## A list of snippets

# Create a new snippet snippet!

$snippet1 = @{
 Title = 'New-Snippet'
 Description = 'Create a New Snippet'
 Text = @"
`$snippet = @{
 Title = `'Put Title Here`'
 Description = `'Description Here`'
 Text = @`"
 Code in Here 
`"@
}
New-IseSnippet @snippet
"@
}
New-IseSnippet @snippet1 –Force

# SMO Snippet

$snippet = @{
 Title = 'SMO-Server'
 Description = 'Creates a SQL Server SMO Object'
 Text = @"
 `$srv = New-Object Microsoft.SqlServer.Management.Smo.Server `$Server
"@
}
New-IseSnippet @snippet

## Data table snippet

$snippet = @{
 Title = 'New-DataTable'
 Description = 'Creates a Data Table Object'
 Text = @"
 # Create Table Object
 `$table = New-Object system.Data.DataTable `$TableName
  
 # Create Columns
 `$col1 = New-Object system.Data.DataColumn NAME1,([string])
 `$col2 = New-Object system.Data.DataColumn NAME2,([decimal])
  
 #Add the Columns to the table
 `$table.columns.add(`$col1)
 `$table.columns.add(`$col2)
  
 # Create a new Row
 `$row = `$table.NewRow() 
  
 # Add values to new row
 `$row.Name1 = 'VALUE'
 `$row.NAME2 = 'VALUE'
  
 #Add new row to table
 `$table.Rows.Add(`$row)
"@
 }
 New-IseSnippet @snippet
 #formatted duration snippet
 $snippet = @{
 Title = 'Formatted Duration'
 Description = 'Formats Get-SQLAgentJobHistory into timespan'
 Text = @"
   `$FormattedDuration = @{
    Name       = 'FormattedDuration'
    Expression = {
      [timespan]`$_.RunDuration.ToString().PadLeft(6,'0').insert(4,':').insert(2,':')
    }
    }
"@
}
New-IseSnippet @snippet

$snippet = @{
 Title = 'Prompt for input'
 Description = 'Simple way of gathering input from users with simple yes and no'
 Text = @"
 	# Get some input from users  
	`$title = "Put your Title Here" 
	`$message = "Put Your Message here (Y/N)" 
	`$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Will continue" 
	`$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Will exit" 
	`$options = [System.Management.Automation.Host.ChoiceDescription[]](`$yes, `$no) 
	`$result = `$host.ui.PromptForChoice(`$title, `$message, `$options, 0) 
	 
	if (`$result -eq 1) 
    { Write-Output "User pressed no!"}
    elseif (`$result -eq 0) 
    { Write-Output "User pressed yes!"}
"@
}
New-IseSnippet @snippet

$snippet = @{
 Title = 'Run SQL query with SMO'
 Description = 'creates SMO object and runs a sql command'
 Text = @"
`$srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList `$Server
`$SqlConnection = `$srv.ConnectionContext
`$SqlConnection.StatementTimeout = 8000
`$SqlConnection.ConnectTimeout = 10
`$SqlConnection.Connect()
`$Results = `$SqlConnection.ExecuteWithResults(`$Query).Tables
`$SqlConnection.Disconnect()
"@
}
New-IseSnippet @snippet

$snippet = @{
 Title = 'SQL Assemblies'
 Description = 'SQL Assemblies'
 Text = @"
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
"@
}
New-IseSnippet @snippet