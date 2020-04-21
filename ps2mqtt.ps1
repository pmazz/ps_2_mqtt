Clear-Host

function WriteMsg([string] $msg, [string] $color) {
    if (-not ([string]::IsNullOrEmpty($logfile))) {
        $msg | out-file $logfile -append
    }
    # Write-Output $msg
    if ([string]::IsNullOrEmpty($color)) {
        Write-Host $msg
    }
    else {
        Write-Host $msg -foregroundcolor $color
    }
}

function Initialize-Mqtt() {
    # Download M2Mqtt from https://www.nuget.org/packages/M2Mqtt
    $libpath = Join-Path $PSScriptRoot "bin\M2Mqtt.Net.dll"
    Add-Type -Path $libpath
}


function Publish-Mqtt($topic, $value) {
    WriteMsg([String]::Format("Publish '{0}' to topic '{1}'", $value, $topic))
    # Connect to mqtt
    $mqttClient = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($Global:MqttBroker, $Global:MqttPort, $false, [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None, $null, $null)
    $mqttclient.Connect([guid]::NewGuid(), $Global:MqttUser, $Global:mqttPwd)
    # Publish to the mqtt topic
    $MqttClient.Publish($topic, [System.Text.Encoding]::UTF8.GetBytes($value))
    WriteMsg "  Published"
    WriteMsg ""
}

function Subscribe-Mqtt($topic) {
    WriteMsg([String]::Format("Subscribe to topic '{0}'", $topic))
    # Connect to mqtt
    $mqttClient = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($Global:MqttBroker, $Global:MqttPort, $false, [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None, $null, $null)
    $mqttclient.Connect([guid]::NewGuid(), $Global:MqttUser, $Global:mqttPwd)
    # Register the event 'MqttMsgPublishReceived' for showing topic changes
    $regInfo = Register-ObjectEvent -inputObject $MqttClient -EventName MqttMsgPublishReceived -Action { Write-host ([String]::Format("{2} - New value in topic '{0}' -> '{1}'", $args[1].topic, [System.Text.Encoding]::ASCII.GetString($args[1].Message), [DateTime]::Now)) -ForegroundColor "red" }
    WriteMsg([String]::Format("Registered to event '{0}'", $regInfo.Name))
    # Subscribe to the mqtt topic
    $mqttClient.Subscribe($topic, 1)
    WriteMsg([String]::Format("Subscribed to topic '{0}'", $topic))
    WriteMsg ""
}

function Unsubscribe-Mqtt($topic) {
    WriteMsg([String]::Format("Unsubscribe from topic '{0}'", $topic))
    # Connect to mqtt
    $mqttClient = New-Object uPLibrary.Networking.M2Mqtt.MqttClient($Global:MqttBroker, $Global:MqttPort, $false, [uPLibrary.Networking.M2Mqtt.MqttSslProtocols]::None, $null, $null)
    $mqttclient.Connect([guid]::NewGuid(), $Global:MqttUser, $Global:mqttPwd)
    # Unsubscribe to the mqtt topic
    $mqttClient.Unsubscribe($topic)
    # Unregister all the events
    Get-EventSubscriber -Force | Unregister-Event -Force
    WriteMsg([String]::Format("Unsubscribed from topic '{0}'", $topic))
    WriteMsg ""
}


#--- INVOKE METHODS ---

# Uncomment row below to enable logging to file
# $logfile = Join-Path $PSScriptRoot ([String]::Format("ps2mqtt_{0:yyyyMMdd_HHmmss}.txt", [DateTime]::Now))

$MqttBroker = Read-Host -Prompt "Enter broker address"
$MqttPort = 1883
$MqttUser = Read-Host -Prompt "Enter username"
$MqttPwd = Read-Host -Prompt "Enter password" -AsSecureString

Initialize-Mqtt

# Subscribe to topic
Subscribe-Mqtt "home/smart_plug_1/stat/POWER"

# Publish to topic
Publish-Mqtt "home/smart_plug_1/cmnd/POWER" "ON"

# Unsubscribe to topic
Unsubscribe-Mqtt "home/smart_plug_1/stat/POWER"
