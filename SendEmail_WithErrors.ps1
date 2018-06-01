$PSEmailServer = 'PDC-EXMBX01.edensandavant.local'

#Try {

#    $errorvar = (1 / 0)

#}
#Catch { 

#Edens SMTP server

#Email dbadmins to inform of DB Restore
Send-MailMessage -SmtpServer "smtp.gmail.com" `
-Port 587 `
-to 'don.wilkie1@gmail.com' -From 'dwilkie@edens.com' `
-Subject "An error occured" `
-Credential (Get-Credential)

#}