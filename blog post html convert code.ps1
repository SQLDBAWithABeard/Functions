<#

$Images = 1..20
# $Images = 'GitHub-Pull-Request-VsCode-Extension','viewing-a-change','checkout-pull-request-checkout','pester-tests','creating-contatiners','containers','check-connectivity','what-are-the-unit-tests','agent-wont-start','find-dbacommand','set-the-values','testing-the-checks','powershell-gallery'
$path = '2019/01/'

foreach($image in $Images){
 $Url = 'https://i1.wp.com/sqldbawithabeard.com/wp-content/uploads/' + $path + 'image-' + $Image + '.png'
# $Url = 'https://i1.wp.com/sqldbawithabeard.com/wp-content/uploads/' + $path + 'opsman' + $Image + '.jpg'
#  $Url = 'https://i1.wp.com/sqldbawithabeard.com/wp-content/uploads/' + $path + $Image + '.png' 

$fileName = $Url.Split('/')[-1]
$filepathpart = $Url.Split('/')[-3..(-1)] -join '\'
$OutputFile = 'C:\Users\mrrob\OneDrive\Documents\GitHub\robsewell\assets\uploads\' + $filepathpart
Invoke-WebRequest -Uri $Url -OutFile $OutputFile
}


#>

$posts = Get-ChildItem -Directory  'C:\Users\mrrob\Downloads\static-html-output\2019' -Recurse  | Where Name -NotMatch '\d\d' |Where{$_.Parent.Name -ne 'page'} | Where Name -notin ('page','amp','feed')

# $post = Get-Item C:\Users\mrrob\Downloads\static-html-output\2013\05\07\12-things-i-learnt-at-sqlbits-xi
# foreach ($post in $posts[6..($posts.Count)]){
foreach ($post in $posts){

# Set the post date
$Datepath = $post.PSParentPath.Split('\')[-3..-1] -join '-'

#set the destination file path
$fileName = 'C:\Users\mrrob\OneDrive\Documents\GitHub\robsewell\_posts\' + $Datepath + '-' + $post.Name + '.md'

# get the old post html
$oldpostpath =  $post.Fullname + '\index.html'

# get the old post HTML to variable
$oldpost  = New-Object -Com "HTMLFile"
$htmlrawcontent = Get-Content -Path $oldpostpath -Raw
$src = [System.Text.Encoding]::Unicode.GetBytes($htmlrawcontent)
$oldpost.write($src)

# grab the entry content from the html
$entrycontent = $oldpost.getElementsByClassName('entry-content')
$content = ($entrycontent | Select innerHTML).innerHTML 

# get just the post and not the fluff
$notfluff = ($content -split '(.*)\<DIV class="sharedaddy sd-sharing-enabled"\>')[0] -replace 'https://blog.robsewell.com/tags/#','https://blog.robsewell.com/tags/' -replace '<SPAN class=crayon-title></SPAN>','' -replace '<DIV class=crayon-tools style="FONT-SIZE: 12px !important; HEIGHT: 18px !important; LINE-HEIGHT: 18px !important">','' -replace '<DIV class=crayon-button-icon></DIV></DIV>' ,'' -replace '<DIV title="Toggle Plain Code" class="crayon-button crayon-plain-button">','' -replace '<DIV title="Toggle Line Wrap" class="crayon-button crayon-wrap-button">','' -replace '<DIV title="Expand Code" class="crayon-button crayon-expand-button">','' -replace '<DIV title=Copy class="crayon-button crayon-copy-button">','' -replace '<DIV title="Open Code In New Window" class="crayon-button crayon-popup-button">','' -replace '<DIV class=crayon-button-icon></DIV></DIV><SPAN class=crayon-language>PowerShell</SPAN></DIV></DIV>','' -replace '<DIV class=crayon-info style="MIN-HEIGHT: 16px !important; LINE-HEIGHT: 16px !important"></DIV>',''  -replace '<DIV class=crayon-plain-wrap><TEXTAREA class="crayon-plain print-no" style="FONT-SIZE: 12px !important; LINE-HEIGHT: 15px !important; -moz-tab-size: 4; -o-tab-size: 4;' ,'' -replace '-webkit-tab-size: 4; tab-size: 4" readOnly data-settings="dblclick">','' -replace '</TEXTAREA></DIV>','' -replace '<TABLE class=crayon-table>','' -replace '<TR class=crayon-row>','' -replace '<TD class="crayon-nums " data-settings="show">','' -replace '<DIV class=crayon-nums-content style="FONT-SIZE: 12px !important; LINE-HEIGHT: 15px !important">',''  -replace '<SPAN class=crayon-language>Transact-SQL</SPAN></DIV></DIV>','' -replace '<DIV class=crayon-main>','' -replace '<TBODY>','' -replace '<DIV title="Toggle Line Numbers" class="crayon-button crayon-nums-button">','' -replace 'https://i1.wp.com/sqldbawithabeard.com/wp-content', 'https://blog.robsewell.com/assets' -replace 'https://i0.wp.com/sqldbawithabeard.com/wp-content', 'https://blog.robsewell.com/assets' -replace 'https://i2.wp.com/sqldbawithabeard.com/wp-content', 'https://blog.robsewell.com/assets' -replace '<SPAN class=crayon-language>PowerShell</SPAN></DIV></DIV>',''  -replace 'https://blog.robsewell.com/\d\d\d\d/\d\d/\d\d', 'https://blog.robsewell.com'

$regex = [regex]::Matches($oldpost.body.innerHTML,'category-(\w{0,50})\s')
$categorynames = (($regex.groups|Select @{name='match';exp={$_.groups[1].value}})| Where match -ne $null).match

if($categorynames -eq $null){
    $categorynames = 'Blog'
}elseif($categorynames -match 'uncategorised') {
    $categorynames = $categorynames -replace 'uncategorised','Blog'
}
else{
    $categorynames = @($categorynames) + 'Blog'
}

$categories = $categorynames| ForEach-Object {"  - " + $Psitem } | Out-String

$regex = [regex]::Matches($oldpost.body.innerHTML,'tag-(\w{0,50})\s')
$tagnames = (($regex.groups|Select @{name='match';exp={$_.groups[1].value}})| Where match -ne $null).match

if($tagnames -eq $null){
    $tagnames = 'powershell'
}else{
    $tagnames = $tagnames 
}

$tags = $tagnames| ForEach-Object {"  - " + $Psitem } | Out-String
$title = $oldpost.title -replace ' \| SQL DBA with A Beard' , ''

$Yamlfront = @"
---
title: "$title"
categories:
$categories
tags:
$tags
---

"@

$filecontent = $Yamlfront + $notfluff

Set-Content -Value $filecontent -Path $fileName
}