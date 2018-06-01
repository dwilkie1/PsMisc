#add jdebi service account to admingroup
$DomainName = "corporate"
$ComputerName = "CAEAPP2"
$UserName = "sa_jdebi"
$AdminGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
$User = [ADSI]"WinNT://$DomainName/$UserName,user"
$AdminGroup.Add($User.Path)

#remove local jdebi account to admingroup
$DomainName = "caeapp2"
$ComputerName = "CAEAPP2"
$UserName = "jdebi"
$AdminGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
$User = [ADSI]"WinNT://$DomainName/$UserName,user"
$AdminGroup.remove($User.Path)