#region TestTaskAction
Function TestTaskAction
{
	[OutputType([bool])]
	#region parameter
	param
	(
		[ciminstance[]]$Action,
		$TaskInstance
	)
	#endregion
	[bool]$Result = $True;
	Write-Verbose -Message ("Found action count "+ $Action.Count);
	foreach($item in $Action)
	{
		$hasvalue = $item.CimInstanceProperties.where({$_.IsValueModified -eq $True})
		$Action_Sys = $TaskInstance.Actions.where({$_.Execute -eq $item.Execute})
		if($Action_Sys)
		{
			Write-Verbose -Message ("found action  $($item.Execute)");
			$Re = CimComparator -CimObjects $hasvalue -Source $Action_Sys
			if(!$Re)
			{
				$Result = $false
			}
		}
		else
		{
			Write-Verbose -Message ("can not found action  $($item.Execute)");
			$Result =$false;
		}
	}
	return $Result;
}
#endregion
#region TestTaskUserPrincipal
Function TestTaskUserPrincipal
{
	[OutputType([bool])]
	param
	(
		[ciminstance]$UserPrincipal,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found UserPrincipal count "+ @($UserPrincipal).Count);
	$hasvalue = $UserPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
	$Re = CimComparator -Source $TaskInstance.Principal -CimObjects $hasvalue
	if(!$Re)
	{
		$Result = $false
	}
	$Result
}
#endregion
#region TestTaskGroupPrincipal
Function TestTaskGroupPrincipal
{
	[outputtype([bool])]
	param
	(
		[ciminstance]$GroupPrincipal,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found GroupPrincipal count "+ @($GroupPrincipal).Count);
	$hasvalue = $GroupPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
	$Re = CimComparator -CimObjects $hasvalue -Source $TaskInstance.Principal
	if(!$Re)
	{
		$Result = $false
	}
	$Result
}
#endregion
#region TestTaskSettingsSet
Function TestTaskSettingsSet
{
	param
	(
		[ciminstance]$SettingsSet,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found SettingsSet count "+ @($SettingsSet).Count);
	$hasvalue = $SettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and $_.CimType -ne "Instance"})
	$Re = CimComparator -CimObjects $hasvalue -Source $TaskInstance.Settings
	if(!$Re)
	{
		$Result = $false
	}
	$input_idle = $SettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -eq "Instance")}).Value.CimInstanceProperties.where({($_.IsValueModified -eq $True)})
	$Re = CimComparator -CimObjects $input_idle -Source $TaskInstance.Settings.IdleSettings
	Write-Verbose -Message ("Testing Task IdleSetting");
	if(!$Re)
	{
		$Result = $false
	}
	Write-Verbose -Message ("Testing Task IdleSetting $Result");
	$Result
}
#endregion
#region TestTaskNetworkSetting
Function TestTaskNetworkSetting
{
	param
	(
		[ciminstance]$NetworkSetting,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found NetworkSetting count "+ @($NetworkSetting).Count);
	$hasvalue = $NetworkSetting.CimInstanceProperties.where({$_.IsValueModified -eq $True})
	$Re =CimComparator -CimObjects $hasvalue -Source $TaskInstance.Settings.NetworkSettings
	if(!$Re)
	{
		$Result = $false
	}
	$Result
}
#endregion
#region TestIdleSetting
Function TestIdleSetting
{
	param
	(
		[ciminstance]$IdleSetting,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found IdleSetting count "+ @($IdleSetting).Count);
	$hasvalue = $IdleSetting.CimInstanceProperties.where({$_.IsValueModified -eq $True})
	$Re = CimComparator -Source $TaskInstance.Settings.IdleSettings -CimObjects $hasvalue
	if(!$Re)
	{
		$Result = $false
	}
	$Result
}
#endregion
#region TestTaskTriggers
Function TestTaskTriggers
{
	param
	(
		[ciminstance[]]$TaskTriggers,
		$TaskInstance
	)
	[bool]$Result = $True;
	Write-Verbose -Message ("Found TestTaskTriggers count "+ ($TaskTriggers).Count);
	foreach($item in $TaskTriggers)
	{
		$hasvalue = $item.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -ne "Instance")}) ## not incloud ciminstance
		$Input_WithID_in_Sys  = $TaskInstance.Triggers.where({$_.Id -eq $item.ID})
		if(!$Input_WithID_in_Sys)
		{
			$Result = $false;
			Write-Verbose -Message ("Find Trigger at ID $($item.ID)  $false")
		}
		else
		{
			Write-Verbose -Message ("Find Trigger at ID $($item.ID)  $true")
			$Re = CimComparator -Source $Input_WithID_in_Sys  -CimObjects $hasvalue
			if(!$Re)
			{
				$Result = $false
			}

			if($item.TaskRepetition)
			{
				$Cim_Repetition=$item.TaskRepetition.CimInstanceProperties.where({$_.IsValueModified -eq $True})
				$Re= CimComparator -Source $Input_WithID_in_Sys.Repetition  -CimObjects $Cim_Repetition
				if(!$Re)
				{
					$Result = $false
				}
			}
		}
	}
	$Result;
}
#endregion
#region CimSet
Function CimSet
{
	param
	(
		[Object]$Source,
		[object[]]$CimObjects
	)
	foreach($Cimobj in $CimObjects)
	{
		Write-Verbose -Message ("Set property at $($Cimobj.name) to $($Cimobj.value)")
		$Source.($Cimobj.Name) = $Cimobj.value
	}
}
#endregion
#region CimComparator
Function CimComparator
{
	param
	(
		[object]$Source,
		[object[]]$CimObjects
	)
	$Result =$true
	foreach($Cimobj in $CimObjects)
	{
		if($Source.($Cimobj.Name) -eq ($Cimobj.Value))
		{
			#Write-Verbose -Message ("Testting with $($Cimobj.name) $($Cimobj.value)"+" Match");
		}
		else
		{
			Write-Verbose -Message ("Testting with $($Cimobj.name) $($Cimobj.value)"+" Not Match");
			$Result =$false
		}
	}
	$Result;
}
#endregion  
#region Cim2Hashtable
Function Cim2Hashtable
{
	param
	(
		[object[]]$Cim,
		[switch]$Build
	)
	$has = @{}
	if($Build)
	{
		foreach($item in $Cim)
		{
			$has.Add( $item.Name , 
				(
					($item.Value) -as ([System.Type]::GetType("System.$($item.CimType)"))			
				))
		}
	}
	else
	{
		$Cim.foreach({$has.add($_.name,$_.value)})
	}
	$has
}
#endregion
#region Set-TargetResource
Function Set-TargetResource
{
	param
	(
		[parameter(Mandatory= $true)]
		[string]$Name,
		[parameter(Mandatory= $true)]
		[string]$Path,
		[parameter(Mandatory= $false)]
		[ciminstance[]]$TaskAction,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskUserPrincipal,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskGroupPrincipal,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskSettingsSet,
		[parameter(Mandatory= $false)]
		[ciminstance]$NetworkSetting,
		[parameter(Mandatory= $false)]
		[ciminstance[]]$TaskTriggers
		# for version 4.0
		#[parameter(Mandatory= $false)]
		#[ciminstance]$IdleSetting,
	)
	$New_Task_Parameter = @{}
	$Task = Get-ScheduledTask -TaskName $Name -TaskPath $Path -ErrorAction SilentlyContinue
	if($Task)
	{
		#Unregister-ScheduledTask -TaskName $Name -TaskPath $Path -Confirm:$false  
		#$Task = $null;
		#region action
		$Task.Actions = $null
		if($TaskAction)
		{
			$New_CIM_Actions = @()
			foreach($item in $TaskAction)
			{
				$InputValue = $item.CimInstanceProperties.where({$_.IsValueModified -eq $True})
				Write-Verbose -Message ("Add Action with Execute $($item.Execute)")
				$New_CIM_Action = New-ScheduledTaskAction -Execute $item.Execute
				CimSet -CimObjects $InputValue -Source $New_CIM_Action
				$New_CIM_Actions+= $New_CIM_Action
			}
			$Task.Actions = $New_CIM_Actions
		}	
		#endregion
		#region Trigger
		if($TaskTriggers)
		{
			$Task.Triggers = $null
			$New_CIM_Triggers = @()
			foreach($item in $TaskTriggers)
			{
				Write-Verbose -Message ("Add TaskTrigger")
				$New_CIM_Trigger = $null
				$hasvalue = $item.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -ne "Instance")}) ## not incloud ciminstance
				$Input_Repetition = $item.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -eq "Instance")}).Value.CimInstanceProperties.where({($_.IsValueModified -eq $True)}) 
				if($item.DaysInterval)
				{
					$New_CIM_Trigger =  New-ScheduledTaskTrigger  -At $item.StartBoundary -Daily -DaysInterval $item.DaysInterval
					CimSet -CimObjects $hasvalue -Source $New_CIM_Trigger
				}
				if($item.WeeksInterval)
				{
					$New_CIM_Trigger =  New-ScheduledTaskTrigger  -At $item.StartBoundary -Weekly -WeeksInterval $item.WeeksInterval -DaysOfWeek Friday
					CimSet -CimObjects $hasvalue -Source $New_CIM_Trigger
				}
				if($item.StateChange)
				{
					 #$New_CIM_Trigger=   New-CimInstance -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClassName "MSFT_TaskSessionStateChangeTrigger"  -ClientOnly -Property  (Cim2Hashtable -Cim $hasvalue) 
				}
				if($Input_Repetition)
				{
					#$h =@{}
					#$Input_Repetition.foreach({$h.add($_.name,$_.value)})
					$New_CIM_Trigger.Repetition =New-CimInstance -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClassName "MSFT_TaskRepetitionPattern"  -ClientOnly -Property (Cim2Hashtable -Cim $Input_Repetition) 
				}

				$New_CIM_Triggers += $New_CIM_Trigger
			}
			$Task.Triggers=$New_CIM_Triggers
		}
	#endregion
		#region setting
		if($TaskSettingsSet)
		{
			$Task.Settings = $null
			Write-Verbose -Message ("Add SettingsSet")
			$New_CIM_SettingsSet=New-ScheduledTaskSettingsSet
			$InputValue = $TaskSettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True)-and ($_.CimType -ne "Instance")})
			CimSet -CimObjects $InputValue -Source $New_CIM_SettingsSet
		
			$Task.Settings = $New_CIM_SettingsSet
			#region idle
			$Input_IdleSetting =  $TaskSettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True)-and ($_.CimType -eq "Instance")}).value.CimInstanceProperties.where({($_.IsValueModified -eq $True)})
			if($Input_IdleSetting)
			{
				Write-Verbose -Message ("Add IdleSetting")
				CimSet -CimObjects $Input_IdleSetting -Source $New_CIM_SettingsSet.IdleSettings
			}
			#endregion
		}
		#endregion
		#region network
		if($NetworkSetting)
		{
			Write-Verbose -Message ("Add NetworkSetting")
			$InputValue = $NetworkSetting.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			CimSet -CimObjects $InputValue -Source $Task.Settings.NetworkSettings
		}
		#endregion
		#region group
		if($TaskGroupPrincipal)
		{
			$Task.Principal = $null
			$New_CIM_GroupPrincipal  = New-ScheduledTaskPrincipal -GroupId $TaskGroupPrincipal.GroupID
			Write-Verbose -Message ("Add GroupPrincipal with GroupId $($TaskGroupPrincipal.GroupID)")
			$InputValue = $TaskGroupPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			CimSet -CimObjects $InputValue -Source $New_CIM_GroupPrincipal
			$Task.Principal=$New_CIM_GroupPrincipal
		}
		#endregion
		#region user
		if($TaskUserPrincipal)
		{
			$Task.Principal = $null
			$New_CIM_UserPrincipal  = New-ScheduledTaskPrincipal -UserId  $TaskUserPrincipal.UserID
			$InputValue = $TaskUserPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			Write-Verbose -Message ("Add UserPrincipal with UserID $($TaskUserPrincipal.UserID)")
			CimSet -CimObjects $InputValue -Source $New_CIM_UserPrincipal
			$Task.Principal=$New_CIM_UserPrincipal
		}
		#endregion
		$Task |Set-ScheduledTask 
	}
	else
	{
		#region action 
		if($TaskAction)
		{
			$New_CIM_Actions = @()
			foreach($item in $TaskAction)
			{
				$InputValue = $item.CimInstanceProperties.where({$_.IsValueModified -eq $True})
				Write-Verbose -Message ("Add Action with Execute $($item.Execute)")
				$New_CIM_Action = New-ScheduledTaskAction -Execute $item.Execute
				CimSet -CimObjects $InputValue -Source $New_CIM_Action
				$New_CIM_Actions+= $New_CIM_Action
			}
			##### build hash parameterbinds 
			$New_Task_Parameter.Add("Action",$New_CIM_Actions)
		}
		#endregion
		#region group
		if($TaskGroupPrincipal)
		{
			$New_CIM_GroupPrincipal  = New-ScheduledTaskPrincipal -GroupId $TaskGroupPrincipal.GroupID
			Write-Verbose -Message ("Add GroupPrincipal with GroupId $($TaskGroupPrincipal.GroupID)")
			$InputValue = $TaskGroupPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			CimSet -CimObjects $InputValue -Source $New_CIM_GroupPrincipal
			$New_Task_Parameter.Add("Principal",$New_CIM_GroupPrincipal)
		}
		#endregion
		#region user
		if($TaskUserPrincipal)
		{
			$New_CIM_UserPrincipal  = New-ScheduledTaskPrincipal -UserId  $TaskUserPrincipal.UserID
			$InputValue = $TaskUserPrincipal.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			Write-Verbose -Message ("Add UserPrincipal with UserID $($TaskUserPrincipal.UserID)")
			CimSet -CimObjects $InputValue -Source $New_CIM_UserPrincipal
			$New_Task_Parameter.Add("Principal",$New_CIM_UserPrincipal)
		}
		#endregion
		#region setting
		if($TaskSettingsSet)
		{
			Write-Verbose -Message ("Add SettingsSet")
			$New_CIM_SettingsSet=New-ScheduledTaskSettingsSet
			$InputValue = $TaskSettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True)-and ($_.CimType -ne "Instance")})
			CimSet -CimObjects $InputValue -Source $New_CIM_SettingsSet
		
			$New_Task_Parameter.Add("Settings",$New_CIM_SettingsSet)
			#region idle
			$Input_IdleSetting =  $TaskSettingsSet.CimInstanceProperties.where({($_.IsValueModified -eq $True)-and ($_.CimType -eq "Instance")}).value.CimInstanceProperties.where({($_.IsValueModified -eq $True)})
			if($Input_IdleSetting)
			{
				Write-Verbose -Message ("Add IdleSetting")
				CimSet -CimObjects $Input_IdleSetting -Source $New_CIM_SettingsSet.IdleSettings
			}
			#endregion
	}
		#endregion
		#region network
		if($NetworkSetting)
		{
			Write-Verbose -Message ("Add NetworkSetting")
			$InputValue = $NetworkSetting.CimInstanceProperties.where({$_.IsValueModified -eq $True})
			CimSet -CimObjects $InputValue -Source $New_CIM_SettingsSet.NetworkSettings
		}
		#endregion
		#region Trigger
		if($TaskTriggers)
		{
			$New_CIM_Triggers = @()
			foreach($item in $TaskTriggers)
			{
				Write-Verbose -Message ("Add TaskTrigger")
				$New_CIM_Trigger = $null
				$hasvalue = $item.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -ne "Instance")}) ## not incloud ciminstance
				$Input_Repetition = $item.CimInstanceProperties.where({($_.IsValueModified -eq $True) -and ($_.CimType -eq "Instance")}).Value.CimInstanceProperties.where({($_.IsValueModified -eq $True)}) 
				if($item.DaysInterval)
				{
					$New_CIM_Trigger =  New-ScheduledTaskTrigger  -At $item.StartBoundary -Daily -DaysInterval $item.DaysInterval
					CimSet -CimObjects $hasvalue -Source $New_CIM_Trigger
				}
				if($item.WeeksInterval)
				{
					$New_CIM_Trigger =  New-ScheduledTaskTrigger  -At $item.StartBoundary -Weekly -WeeksInterval $item.WeeksInterval -DaysOfWeek Friday
					CimSet -CimObjects $hasvalue -Source $New_CIM_Trigger
				}
				if($item.StateChange)
				{
					 #$New_CIM_Trigger=   New-CimInstance -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClassName "MSFT_TaskSessionStateChangeTrigger"  -ClientOnly -Property  (Cim2Hashtable -Cim $hasvalue) 
				}
				if($Input_Repetition)
				{
					#$h =@{}
					#$Input_Repetition.foreach({$h.add($_.name,$_.value)})
					$New_CIM_Trigger.Repetition =New-CimInstance -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClassName "MSFT_TaskRepetitionPattern"  -ClientOnly -Property (Cim2Hashtable -Cim $Input_Repetition) 
				}

				$New_CIM_Triggers += $New_CIM_Trigger
			}
			$New_Task_Parameter.Add("Trigger",$New_CIM_Triggers)
	}
	#endregion
		Write-Verbose -Message ("Add Task")
		$Task = New-ScheduledTask @New_Task_Parameter
		Register-ScheduledTask -InputObject $Task -TaskName $Name -TaskPath $Path
	}
}


#endregion
#region Get-TargetResource
Function Get-TargetResource
{
	[outputtype([hashtable])]
	param
	(
		[parameter(Mandatory= $true)]
		[string]$Name,
		[parameter(Mandatory= $true)]
		[string]$Path
	)
	[hashtable]$Result = @{}
	$Result.Add("Name",$Name)
	$Result.Add("Path",$Path)
	$actions = @()
	
	$Task = Get-ScheduledTask -TaskName $Name -TaskPath $Path -ErrorAction SilentlyContinue
	if($Task)
	{
		foreach($item in $Task.Actions)
		{#'root/microsoft/Windows/DesiredStateConfiguration'
			$CimProperty =@{}
			$CimProperty.Add("Execute",$item.Execute)
			$CimProperty.Add("Arguments",$item.Arguments)
			$CimProperty.Add("WorkingDirectory",$item.WorkingDirectory)
			$CimProperty.Add("ID",$item.ID)
			$actions +=$CimProperty 
		}
		$Result.Add("TaskAction",$actions);
		if($Task.Principal.UserID)
		{
			[hashtable]$User = @{}
			$User.Add("UserID",$Task.Principal.UserId)
			$User.Add("LogonType",$Task.Principal.LogonType.tostring())
			$User.Add("Id",$Task.Principal.Id)
			$User.Add("RunLevel",$Task.Principal.RunLevel.tostring())
			$User.Add("ProcessTokenSidType",$Task.Principal.ProcessTokenSidType.tostring())
			$User.Add("RequiredPrivilege",$Task.Principal.RequiredPrivilege)
			$Result.Add("TaskUserPrincipal",($User))
		}
		
		if($Task.Principal.GroupId)
		{
			[hashtable]$Group = @{}
			$Group.Add("GroupId",$Task.Principal.GroupId)
			$Group.Add("Id",$Task.Principal.Id)
			$Group.Add("RunLevel",$Task.Principal.RunLevel.tostring())
			$Group.Add("ProcessTokenSidType",$Task.Principal.ProcessTokenSidType.tostring())
			$Group.Add("RequiredPrivilege",$Task.Principal.RequiredPrivilege)
			$Result.Add("TaskGroupPrincipal",($Group))
		}
		#region setting
		$Setting = @{}
		$Setting.Add("AllowDemandStart",[bool]$Task.Settings.AllowDemandStart)
		$Setting.Add("AllowHardTerminate",[bool]$Task.Settings.AllowHardTerminate)
		$Setting.Add("Compatibility",$Task.Settings.Compatibility.tostring())
		$Setting.Add("DeleteExpiredTaskAfter",[string]$Task.Settings.DeleteExpiredTaskAfter)
		$Setting.Add("DisallowStartIfOnBatteries",[bool]$Task.Settings.DisallowStartIfOnBatteries)
		$Setting.Add("Enabled",[bool]$Task.Settings.Enabled)
		$Setting.Add("ExecutionTimeLimit",$Task.Settings.ExecutionTimeLimit)
		$Setting.Add("Hidden",[bool]$Task.Settings.Hidden)
		$Setting.Add("MultipleInstances",$Task.Settings.MultipleInstances.tostring())
		$Setting.Add("Priority",[string]$Task.Settings.Priority)
		$Setting.Add("RestartCount",[string]$Task.Settings.RestartCount)
		$Setting.Add("RestartInterval",[string]$Task.Settings.RestartInterval)
		$Setting.Add("RunOnlyIfIdle",[bool]$Task.Settings.RunOnlyIfIdle)
		$Setting.Add("RunOnlyIfNetworkAvailable",[bool]$Task.Settings.RunOnlyIfNetworkAvailable)
		$Setting.Add("StartWhenAvailable",[bool]$Task.Settings.StartWhenAvailable)
		$Setting.Add("StopIfGoingOnBatteries",[bool]$Task.Settings.StopIfGoingOnBatteries)
		$Setting.Add("WakeToRun",[bool]$Task.Settings.WakeToRun)
		$Setting.Add("DisallowStartOnRemoteAppSession",[bool]$Task.Settings.DisallowStartOnRemoteAppSession)
		$Setting.Add("UseUnifiedSchedulingEngine",[bool]$Task.Settings.UseUnifiedSchedulingEngine)
		$Setting.Add("volatile",[bool]$Task.Settings.volatile)
		#region idle
		[hashtable]$Idle = @{}
		$Idle.Add("IdleDuration",[String]$Task.Settings.IdleSettings.IdleDuration)
		$Idle.Add("RestartOnIdle",[bool]$Task.Settings.IdleSettings.RestartOnIdle)
		$Idle.Add("StopOnIdleEnd",[bool]$Task.Settings.IdleSettings.StopOnIdleEnd)
		$Idle.Add("WaitTimeout",[String]$Task.Settings.IdleSettings.WaitTimeout)
		$Idle_CIM= New-CimInstance -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -ClassName IdleSetting -Property $Idle  -ClientOnly 
		$Setting.Add("IdleSetting",($Idle_CIM))
		#endregion 
		$Result.Add("TaskSettingsSet",($Setting))
		#endregion
		#region NetworkSetting
		$Network = @{}
		$Network.Add("Name",[string]$Task.Settings.NetworkSettings.Name);
		$Network.Add("ID",[string]$Task.Settings.NetworkSettings.Id);
		$Result.Add("NetworkSetting",($Network))
		#endregion
		$Triggers = @()
		foreach($item in $Task.Triggers)
		{
			$t =@{}
			$t.Add("Id",[String]$item.Id)
			$t.Add("StateChange",[uint32]$item.StateChange)
			$t.Add("Enabled",[bool]$item.Enabled)
			$t.Add("DaysOfWeek",[Uint16]$item.DaysOfWeek)
			$t.Add("StartBoundary",[String]$item.StartBoundary)
			$t.Add("EndBoundary",[String]$item.EndBoundary)
			$t.Add("ExecutionTimeLimit",[String]$item.ExecutionTimeLimit)
			$t.Add("RandomDelay",[String]$item.RandomDelay)
			$t.Add("Delay",[String]$item.Delay)
			$t.Add("UserId",[String]$item.UserId)
			$t.Add("WeeksInterval",[uint16]$item.WeeksInterval)
			$t.Add("DaysInterval",[uint16]$item.DaysInterval)
			$Triggers+=$t
		}
		$Result.add("TaskTriggers",$Triggers)
		#region TaskTriggers

		#endregion
	}
	return $Result;
}
#endregion
#region Test-TargetResource

Function Test-TargetResource
{
	[CmdletBinding()]
	#region parameter
	param
	(
		[parameter(Mandatory= $true)]
		[string]$Name,
		[parameter(Mandatory= $true)]
		[string]$Path,
		[parameter(Mandatory= $false)]
		[ciminstance[]]$TaskAction,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskUserPrincipal,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskGroupPrincipal,
		[parameter(Mandatory= $false)]
		[ciminstance]$TaskSettingsSet,
		[parameter(Mandatory= $false)]
		[ciminstance]$NetworkSetting,
		[parameter(Mandatory= $false)]
		[ciminstance[]]$TaskTriggers

		## for vsersion 4.0.0. 
		#[parameter(Mandatory= $false)]
		#[ciminstance]$IdleSetting,
	)
	#endregion
	[bool]$Result = $true;
	$Task = Get-ScheduledTask -TaskName $name -TaskPath $Path -ErrorAction SilentlyContinue;
	#region it is test
	do
	{
		Write-Verbose ("Start Testing")
		#region test ok
		if(!$Task)
		{
			Write-Verbose -Message ("Testing Task exist ");
			$Result =$false;
			Write-Verbose -Message ("Testing Task exist " +$Re);
		}
		else
		{
			Write-Verbose -Message ("Testing Task exist " +$Result);
		}
		if($TaskAction)
		{
			Write-Verbose -Message ("Testing Task Action ");
			$Re = TestTaskAction -Action $TaskAction -TaskInstance $Task
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task Action "+$Re);
		}	
		if($TaskUserPrincipal)
		{
			Write-Verbose -Message ("Testing Task UserPrincipal");
			$Re = TestTaskUserPrincipal -UserPrincipal $TaskUserPrincipal -TaskInstance $Task
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task UserPrincipal "+$Re);
		}
		if($TaskGroupPrincipal)
		{
			Write-Verbose -Message ("Testing Task GroupPrincipal");
			$Re =TestTaskGroupPrincipal -GroupPrincipal $TaskGroupPrincipal -TaskInstance $Task
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task GroupPrincipal "+$Re);
		}
		if($TaskSettingsSet)
		{
			Write-Verbose -Message ("Testing Task SettingsSet");
			$Re =TestTaskSettingsSet -SettingsSet $TaskSettingsSet -TaskInstance $Task
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task SettingsSet "+$Re);
		}
		if($NetworkSetting)
		{
			Write-Verbose -Message ("Testing Task NetworkSetting");
			$Re = TestTaskNetworkSetting -NetworkSetting $NetworkSetting -TaskInstance $Task
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task NetworkSetting "+$Re);
		}
		if($TaskTriggers)
		{
			Write-Verbose -Message ("Testing Task Triggers");
			$Re = TestTaskTriggers -TaskInstance $Task -TaskTriggers $TaskTriggers
			if(!$Re)
			{
				$Result =$false;
			}
			Write-Verbose -Message ("Testing Task Triggers "+$Re);
		}
		#endregion
		break;
	}
	while($Result -eq $true)
	#endregion
	Write-Verbose ("Successful completion Testing Result $($Result)")
	return $Result;
}
#endregion
Export-ModuleMember -Function *TargetResource