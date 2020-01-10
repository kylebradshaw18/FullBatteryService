[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$APP_ID = '110366bd-56e2-47ed-9bdf-3ce1fa408b6c'
#0 = Nothing, 1 = Low, 2 = High
$LastEvent = 0
$ConsecutiveExecutions = 0
$MaxExecutions = 2
$Max = 99
$Min = 20

function Compare-Values($ShouldBe){
	if(-NOT ($script:LastEvent -eq $ShouldBe)){
		$script:LastEvent = $ShouldBe
		$script:ConsecutiveExecutions = 0
	}
}

function Get-Template($Empty){
	$template = "<toast><visual><binding template=`"ToastText02`"><text id=`"1`">Battery "
	if($Empty -eq $TRUE){
		$template = $template + "Low"
	} else {
		$template = $template + "Sufficiently Charged"
	}
	$template = $template + "</text></binding></visual></toast>"

	#rem check if we should return the template for the notification
	if($Empty -eq $TRUE){
		Compare-Values 1
	} else {
		Compare-Values 2
	}
	if ($script:ConsecutiveExecutions -gt $script:MaxExecutions){
		$template = $NULL
	} else {
		$script:ConsecutiveExecutions++
	}
	$template
}

while($TRUE)
{
	$colItems = get-wmiobject -class "Win32_Battery"
	$MessageTemplate = $NULL
	#Not on charger so check if we are low to send notification
	if ((-NOT ($colItems.BatteryStatus -eq 2)) -And ($colItems.EstimatedChargeRemaining -le $Min)){
		$MessageTemplate = Get-Template $TRUE
	} elseif(($colItems.BatteryStatus -eq 2) -And ($colItems.EstimatedChargeRemaining -ge $Max)){
		$MessageTemplate = Get-Template $FALSE
	}
	#Have a template so have to show message
	if(-NOT ($MessageTemplate -eq $NULL)){
		$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
		$xml.LoadXml($MessageTemplate)
		$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
		[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID).Show($toast)
	}
	#Sleep for 5 minutes before we check again
	start-sleep -seconds 300
}