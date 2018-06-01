#Edens SMTP server
$PSEmailServer = "mxa-00268801.gslb.pphosted.com"

Send-MailMessage -to don.wilkie1@gmail.com -From dwilkie@edens.com -Subject "Test" -SmtpServer $PSEmailServer