### Copy From Location Modal
$props = @{
    Parameters = @(
        @{Name="copyFromLocation"; Title="Location - Copy From"; Options=$options; Tooltip="Choose an item."; Editor = "droptree"}
    )
    Title = "Location - Copy From"
    Description = "Choose an item."
    Width = 500
    Height = 300
    ShowHints = $true
}
$cfl = Read-Variable @props
if($cfl -ne "ok") {
    break
}


### Copy From Role Modal
$props = @{
    Parameters = @(
        @{Name="copyRoleFrom"; Title="Copy Permissions FROM Role"; Options=$options; Tooltip="Choose an item."; Editor = "multiple user role"}
    )
    Title = "Copy Permissions FROM Role"
    Description = "Choose an item."
    Width = 500
    Height = 300
    ShowHints = $true
}
$crf = Read-Variable @props
if($crf -ne "ok") {
    break
}



# Copy To Location Modal
$props = @{
    Parameters = @(
        @{Name="copyToLocation"; Title="Location - Copy To"; Options=$options; Tooltip="Choose an item."; Editor = "droptree"}
    )
    Title = "Location - Copy To"
    Description = "Choose an item."
    Width = 500
    Height = 300
    ShowHints = $true
}
$ctl = Read-Variable @props
if($ctl -ne "ok") {
    break
}



### Copy From Role Modal
$props = @{
    Parameters = @(
        @{Name="copyRoleTo"; Title="Copy Permissions TO Role"; Options=$options; Tooltip="Choose an item."; Editor = "multiple user role"}
    )
    Title = "Copy Permissions TO Role"
    Description = "Choose an item."
    Width = 500
    Height = 300
    ShowHints = $true
}
$crt = Read-Variable @props
if($crt -ne "ok") {
    break
}



## Confirm Inputs
$confirmText = "You are about to copy permissions from <b>" + $copyFromLocation.FullPath + "</b> and the <b>" + $copyRoleFrom + "</b> role to " 
$confirmText += "<b>" + $copyToLocation.FullPath + "</b> and the <b>" + $copyRoleTo + "</b> role"
$confirmText += ".  Do you want to continue?"
$confirm = Show-Confirm -Title $confirmText
if($confirm -eq "no") {
    break
}

## Get Items - This may not happen based on Query.MaxItems
$copyFromLocationPath = $copyFromLocation.FullPath + "//*"
$allItemsFrom = Get-Item -Path master:// -Query $copyFromLocationPath
$allItemsFrom += Get-Item -Path master:// -Query $copyFromLocation.Fullpath #Add Root item to list

### Loop through each item and compare "From" to "To"
ForEach ($item in $allItemsFrom) {
    
    $addPath = $item.Fullpath.Replace($copyFromLocation.FullPath, "")
    $toPath = $copyToLocation.FullPath + $addPath
    $toItem = Get-Item -Path $toPath -ErrorAction Ignore
    
    if(!$toItem) {
        Write-Output "No matching item in $toPath.  Skipping."
        continue
    }
    
    #Gets ACL from item for specific role
    $acls = Get-ItemAcl -Path $item.FullPath -Filter $copyRoleFrom[0] 
    
    if(!$acls) {
        $itemName = $item.Name
        Write-Output "No Permissions to copy for $copyRoleFrom on $itemName. Skipping."
        continue
    }
    
    #Create new ACL for access rights, but with different role
    ForEach($acl in $acls) {
    $aclModified = New-ItemAcl -Identity  $copyRoleTo[0] `
                            -AccessRight $acl."AccessRight" `
                            -PropagationType $acl."PropagationType" `
                            -SecurityPermission $acl."SecurityPermission"
    
    #Apply permissions to matching item
    Add-ItemAcl -AccessRules $aclModified -Path $toItem.FullPath
    }
    
    $toItemName = $toItem.Name
    Write-Output "ACL Updated on $toItemName" 
    Get-Item -Path $toItem.FullPath | Add-ItemAcl -AccessRules $aclModified
}
Write-Output "Updates Complete."