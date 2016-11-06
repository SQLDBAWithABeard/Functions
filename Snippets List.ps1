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
