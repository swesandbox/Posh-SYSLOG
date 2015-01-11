Add-Type -TypeDefinition @"
	public enum Syslog_Facility
	{
		kern,
		user,
		mail,
		daemon,
		auth,
		syslog,
		lpr,
		news,
		uucp,
		clock,
		authpriv,
		ftp,
		ntp,
		logaudit,
		logalert,
		cron, 
		local0,
		local1,
		local2,
		local3,
		local4,
		local5,
		local6,
		local7,
	}
"@

Add-Type -TypeDefinition @"
	public enum Syslog_Severity
	{
		Emergency,
		Alert,
		Critical,
		Error,
		Warning,
		Notice,
		Informational,
		Debug
	}
"@

function Send-SyslogMessage
{
<#
.SYNOPSIS
Sends a SYSLOG message to a server running the SYSLOG daemon

.DESCRIPTION
Sends a message to a SYSLOG server as defined in RFC 5424. A SYSLOG message contains not only raw message text,
but also a severity level and application/system within the host that has Generated the message.

.PARAMETER Server
Destination SYSLOG server that message is to be sent to

.PARAMETER Message
Our message

.PARAMETER Severity
Severity level as defined in SYSLOG specification, must be of ENUM type Syslog_Severity

.PARAMETER Facility
Facility of message as defined in SYSLOG specification, must be of ENUM type Syslog_Facility

.PARAMETER Hostname
Hostname of machine the mssage is about, if not specified, local hostname will be used

.PARAMETER Timestamp
Timestamp, myst be of format, "yyyy:MM:dd:-HH:mm:ss zzz", if not specified, current date & time will be used

.PARAMETER UDPPort
SYSLOG UDP port to send message to

.INPUTS
Nothing can be piped directly into this function

.OUTPUTS
Nothing is output

.EXAMPLE
Send-SyslogMessage mySyslogserver "The server is down!" Emergency Mail
Sends a syslog message to mysyslogserver, saying "server is down", severity emergency and facility is mail

.NOTES
NAME: Send-SyslogMessage
AUTHOR: Kieran Jacobsen
LASTEDIT: 2014 07 01
KEYWORDS: syslog, messaging, notifications

.LINK
https://github.com/kjacobsen/PowershellSyslog

.LINK
http://aperturescience.su

#>
[CMDLetBinding()]
Param
(
	[Parameter(mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String] 
	$Server,
	
	[Parameter(mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]
	$Message,
	
	[Parameter(mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[Syslog_Severity]
	$Severity,
	
	[Parameter(mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[Syslog_Facility] 
	$Facility,
	
	[Parameter(mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[String]
	$Hostname = $env:computername,
	
	[Parameter(mandatory=$false)]
	[ValidateNotNullOrEmpty()]
	[DateTime] 
	$Timestamp = [DateTime]::Now,
	
	[Parameter(mandatory=$false)]
	[ValidateNotNullOrEmpty()]
    [UInt16]
	$UDPPort = 514
)

# Create a UDP Client Object
$UDPCLient = New-Object System.Net.Sockets.UdpClient
$UDPCLient.Connect($Server, $UDPPort)

# Evaluate the facility and severity based on the enum types
$Facility_Number = $Facility.value__
$Severity_Number = $Severity.value__
Write-Verbose "Syslog Facility, $Facility_Number, Severity is $Severity_Number"

# Calculate the priority
$Priority = ($Facility_Number * 8) + $Severity_Number
Write-Verbose "Priority is $Priority"

# Assemble the full syslog formatted Message
$FullSyslogMessage = "<{0}>1 {1} {2} - - - - {3}" -f $Priority, $Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz'), $Hostname, $Message
Write-Verbose "Message to send will be $FullSyslogMessage"

# create an ASCII Encoding object
$Encoding = [System.Text.Encoding]::ASCII

# Convert into byte array representation
$ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)

# If the message is too long, shorten it
if ($ByteSyslogMessage.Length -gt 1024)
{
    $ByteSyslogMessage = $ByteSyslogMessage.SubString(0, 1024)
}

# Send the Message
$UDPCLient.Send($ByteSyslogMessage, $ByteSyslogMessage.Length) | Out-Null

}
