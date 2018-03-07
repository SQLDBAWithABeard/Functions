function Get-SqlServerBuildList {
 <#
     .Synopsis
        Downloads and parses the build list information from sqlserverbuilds.blogspot.com 
        and inserts it into a database
     .Description
        Downloads the build information from sqlserverbuilds.blogspot.com - the build information
        is extracted from the html tables and inserts it into a database
     .Example
        Get-SQLServerBuildList
     .Notes
     Version History 
     v1.0  - William Durkin - Initial Release 
     v1.1  - Rob Sewell - Added Datatable output for input to SQL
 #> 

    $url = 'http://sqlserverbuilds.blogspot.com/'
     ## Load database with details
    $sqlserver = ''  # instance holding database
    $database = '' # Database Name
    $table = 'info.SQLServerBuilds' # schema dot table name

    $result = Invoke-WebRequest $url
    $tables = @($result.ParsedHtml.getElementsByTagName("TABLE"))


         # Create table
     $DataTable =  New-Object system.Data.DataTable LastBoot
     #create columns
     $col0 = New-Object system.Data.DataColumn SQLbuildID,([int])
     $col1 = New-Object system.Data.DataColumn Build,([string])
     $col2 = New-Object system.Data.DataColumn SQLSERVREXEBuild,([string])
     $col3 = New-Object system.Data.DataColumn Fileversion,([string])
     $col4 = New-Object system.Data.DataColumn Q,([string])
     $col5 = New-Object system.Data.DataColumn KB,([string])
     $col6 = New-Object system.Data.DataColumn KBDescription,([string])
     $col7 = New-Object system.Data.DataColumn ReleaseDate,([DateTime])
     $col8 = New-Object system.Data.DataColumn ShortBuild,([float])
     $col9 = New-Object system.Data.DataColumn VersionString,([string])
     $col10 = New-Object system.Data.DataColumn BuildNo,([int])
     $DataTable.columns.add($col0)
     $DataTable.columns.add($col1)
     $DataTable.columns.add($col2)
     $DataTable.columns.add($col3)
     $DataTable.columns.add($col4)
     $DataTable.columns.add($col5)
     $DataTable.columns.add($col6)
     $DataTable.columns.add($col7)
     $DataTable.columns.add($col8)
     $DataTable.columns.add($col9)
     $DataTable.columns.add($col10)

    # There are two tables at the start of the webpage that are irrelevant to what we are wanting to scrape
     # The "hacky" way of skipping those first 2 tables on the webpage is to just start the loop at the 3rd table instance 
     # As this is a computer, counting is zero-based, so the third table will be 2. So $i = 2 is where we start
     
     for($i = 2; $i -le ($tables.Count)-1; $i++)
    {
         # Grab table $i from the html
         $table=$tables[$i]

        # Get the table rows
         $rows = @($table.Rows)
  
        # Do the parsing, this is where we do the *real* work and run the columns and rows and extract the data
         foreach($row in $rows)
        {

            $cells = @($row.Cells)
         
             # If we’ve found a table header, remember its titles

            if($cells[0].tagName -eq "TH")
            {
                $titles = @($cells | % { ("" + $_.InnerText).Trim() })
                continue
            }

            # If we haven’t found any table headers, make up names "P1", "P2", etc.

            if(-not $titles)
            {
                $titles = @(1..($cells.Count + 2) | % { "P$_" })
            }
            # Now go through the cells in the the row. Match each cell to the corresponding title.
            $resultObject = [Ordered] @{}
            for($counter = 0; $counter -lt $cells.Count; $counter++)
            {
                $title = $titles[$counter]
                if(-not $title) { continue }
                $resultObject[$title] = ("" + $cells[$counter].InnerText).Trim()
            }

            # And finally return the data as a PSCustomObject

            try
            {
            # [PSCustomObject] $resultObject
            # Create a new Row
            $trow = $datatable.NewRow() 
             
            $trow.Build = $resultObject['Build']
            $trow.SQLSERVREXEBuild  = $resultObject['SQLSERVR.EXE Build']
            $trow.'FileVersion' = $resultObject['File version']
            $trow.Q = $resultObject['Q']
            $trow.KB = $resultObject['KB']
            $trow.KBDescription = $resultObject['KB / Description']
            $version = [Version]$resultObject['Build'] 
            $trow.ShortBuild = "$($version.Major).$($version.Minor)"

            if($trow.Build -eq '11.00.9120')  ## Because Microsoft
            {
                $trow.ShortBuild = 12
            }
            
            $VersionString = switch ($trow.ShortBuild) 
            {
                7   {'SQL 7.'}
                8   {'SQL 2000'}
                9   {'SQL 2005'}
                10  {'SQL 2008'}
                10.5{'SQL 2008 R2'}
                11  {'SQL 2012'}
                12  {'SQL 2014'}
                13  {'SQL 2016'}
                14  {'vNext'}
            }

            if($trow.Build -eq '11.00.9000')
            {
                $VersionString = 'SQL 2012 CTP3' # Because Microsoft again
            }

            $trow.VersionString = $VersionString
            $trow.BuildNo = $version.Build
            if($resultObject['Release Date'] -eq '')
            {
                $trow.ReleaseDate = [DBNull]::Value            
            }

            elseif($resultObject['Release Date'] -match '`*new')
            {
                $trow.ReleaseDate = $resultObject['Release Date'].Replace('*new','')
            }
            else
            {
                $trow.ReleaseDate = $resultObject['Release Date']
            }
            #Add new row to table
            
                $datatable.Rows.Add($trow)
            }
            catch
            {
               $_
               Write-Warning "Failed to add row"
               Write-Warning "Result = $($resultObject)"
            }
           # $trow
        }
     }
   return  $DataTable
 }

 <#

$datatable = Get-SqlServerBuildList
$batchsize = 5000
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $SQLServer
$Query = "TRUNCATE TABLE " + $database + '.' + $table 
$srv.ConnectionContext.ExecuteNonQuery($Query)
$srv.ConnectionContext.Disconnect()

# Build the sqlbulkcopy connection, and set the timeout to infinite
$connectionstring = "Data Source=$sqlserver;Integrated Security=true;Initial Catalog=$database;"
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock)
$bulkcopy.DestinationTableName = $table
$bulkcopy.bulkcopyTimeout = 0
$bulkcopy.batchsize = $batchsize

$bulkcopy.WriteToServer($datatable)
$datatable.Clear()
$bulkcopy.Dispose()

#>