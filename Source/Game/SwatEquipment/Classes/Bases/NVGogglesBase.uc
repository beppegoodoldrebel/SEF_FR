class NVGogglesBase extends Engine.ProtectiveEquipment
	implements Engine.IVisionEnhancement, Engine.IInterestedPawnDied
	native;

var protected bool Active;
var(Mesh) protected config StaticMesh ActivatedMesh;
var(Mesh) protected config StaticMesh DeactivatedMesh			"Staticmesh to use when goggles deactivated (use StaticMesh field for activated)";
var protected DynamicLightEffect Light;

var protected float TransitionStart;

var() float EffectDownTime;
var() float EffectUpTime;

// Extreme edge case that I don't feel like fixing --eez
simulated function float GetWeight() {
	return 0.68;		// IMPORTANT: Make sure to alter the value in DynamicLoadOutSpec.uc as well!
}

simulated function float GetBulk() {
	return 1.1466;	// IMPORTANT: Make sure to alter the value in DynamicLoadOutSpec.uc as well!
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// register to find out when a pawn dies or is destroyed
	Level.RegisterNotifyPawnDied(self);

	Light = Spawn(class'DynamicLightEffect');
	Light.RemoteRole = ROLE_None;
	Light.bImportantDynamicLight = true;
	Light.LightBrightness = 0; //64
	Light.LightHue = 0;
	Light.LightSaturation = 255;
}

simulated event PostNetBeginPlay()
{
	ActivatedMesh = StaticMesh;
	DeactivateEffect();
}

simulated function OnGivenToOwner()
{
	Super.OnGivenToOwner();

	SwatPawn(Owner).UpdateNightvision();
	Light.SetBase(Owner);
}

simulated function Destroyed()
{
	Super.Destroyed();

	Level.UnregisterNotifyPawnDied(self);

	if (Light != None)
		Light.Destroy();
}

simulated function OnOtherPawnDied(Pawn DeadPawn)
{
	if (DeadPawn == Owner)
	{
		Active = false;
		ApplyEnhancement();

		if (Light != None)
			Light.Destroy();
	}
}

simulated function bool IsActive()
{
	return false;
}

simulated function bool ShowOverlay()
{
	return false;
}

simulated function Activate();
simulated function Deactivate();

simulated function ActivateEffect()
{
	local SwatPawn P;

	Active = true;

	P = SwatPawn(Owner);

	if (P != None)
	{
		P.bIsWearingNightvision = Active;
		if (SwatGamePlayerController(P.Controller) != None)
			SwatGamePlayerController(P.Controller).RefreshCameraEffects(SwatPlayer(P));
	}

	SetNVGMesh(true);
	UpdateLight();
}

simulated function DeactivateEffect()
{
	local SwatPawn P;

	Active = false;

	P = SwatPawn(Owner);

	if (P != None)
	{
		P.bIsWearingNightvision = Active;
		if (SwatGamePlayerController(P.Controller) != None)
			SwatGamePlayerController(P.Controller).RefreshCameraEffects(SwatPlayer(P));
	}

	SetNVGMesh(false);
	UpdateLight();
}

simulated function SetNVGMesh( bool Activation )
{
	if (Activation )
		SetStaticMesh(ActivatedMesh);
	else
		SetStaticMesh(DeactivatedMesh);
}

simulated function ToggleActive()
{
	if (!IsActive())
	{
		Activate();
	}
	else
	{
		Deactivate();
	}
}

native simulated function ApplyEnhancement();

simulated event UpdateLight()
{
	local SwatPawn P;

	P = SwatPawn(Owner);

	if (Active && P.IsControlledByLocalHuman())
		Light.LightRadius = 255;
	else
		Light.LightRadius = 0;
}

//adjust NVG light down , controlled by SwatPawn and SwatGamePlayerController
function NVGLightDown()
{
	local SwatPawn P;

	P = SwatPawn(Owner);

	if (Active && P.IsControlledByLocalHuman())
	{
		if (Light.LightBrightness > 0)
		{
			Light.LightBrightness = Light.LightBrightness - 16;
		}
		
	}
}

//adjust NVG light up , controlled by SwatPawn and SwatGamePlayerController
function NVGLightUp()
{
	local SwatPawn P;

	P = SwatPawn(Owner);

	if (Active && P.IsControlledByLocalHuman())
	{
		if (Light.LightBrightness< 128)
		{
			Light.LightBrightness = Light.LightBrightness + 16;
		}
	}
}

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The NVGogglesBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}

auto simulated state Deactivated
{
	simulated function BeginState()
	{
		local SwatGamePlayerController PC;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			PC.GetHUDPage().UpdateProtectiveEquipmentOverlay();
			PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop = -PC.GetHUDPage().NVGogglesTransitionOverlay.WinHeight;
			TriggerEffectEvent('Deactivated');
		}
		else
			TriggerEffectEvent('DeactivatedThirdPerson');
	}

	simulated function Activate()
	{
		GotoState('Activating');
	}
}

simulated state Activating
{
	simulated function bool IsActive()
	{
		return true;
	}

	simulated function BeginState()
	{
		local SwatGamePlayerController PC;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			PC.GetHUDPage().UpdateProtectiveEquipmentOverlay();
			TriggerEffectEvent('Activating');
		}

		SetTimer(EffectDownTime, true);

		TransitionStart = Level.TimeSeconds;
	}

	simulated function Tick(float Delta)
	{
		local SwatGamePlayerController PC;
		local float A;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			A = Lerp((Level.TimeSeconds - TransitionStart) / EffectDownTime, 0, 1);
			PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop = -1 + A * A;
			
			if ( PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop >= -0.2 )
				SetCanSeeIRLaser(true);
		}
		
		UpdateStrobeLightPosition();
		
		Super.Tick(Delta);
	}

	simulated function Timer()
	{
		GotoState('Activated');
	}
}

simulated state Activated
{
	simulated function bool ShowOverlay()
	{
		return true;
	}

	simulated function bool IsActive()
	{
		return true;
	}

	simulated function Deactivate()
	{
		GotoState('Deactivating');
	}

	simulated function BeginState()
	{
		local SwatGamePlayerController PC;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			PC.GetHUDPage().UpdateProtectiveEquipmentOverlay();
			PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop = -PC.GetHUDPage().NVGogglesTransitionOverlay.WinHeight;
			TriggerEffectEvent('Activated');
			TriggerEffectEvent('ActivatedLoop');
		}
		else
			TriggerEffectEvent('ActivatedThirdPerson');

		ActivateEffect();
	}
	
	simulated function Tick(float Delta)
	{
		SetCanSeeIRLaser(true);
		UpdateStrobeLightPosition();
		Super.Tick(Delta);
	}	
	

	simulated function EndState()
	{
		DeactivateEffect();
		UntriggerEffectEvent('ActivatedLoop');
	}
}

simulated state Deactivating
{
	simulated function BeginState()
	{
		local SwatGamePlayerController PC;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			PC.GetHUDPage().UpdateProtectiveEquipmentOverlay();
		}

		SetTimer(EffectUpTime, true);
		TransitionStart = Level.TimeSeconds;
		TriggerEffectEvent('Deactivating');
	}

	simulated function Tick(float Delta)
	{
		local SwatGamePlayerController PC;
		local float A;

		PC = SwatGamePlayerController(Pawn(Owner).Controller);
		if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
		{
			A = Lerp((Level.TimeSeconds - TransitionStart) / EffectUpTime, 0, 1);
			PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop = 0 - A * A;
			
			if ( PC.GetHUDPage().NVGogglesTransitionOverlay.WinTop < -0.2 )
				SetCanSeeIRLaser(false);
		}
		else
			SetCanSeeIRLaser(false);
		
		UpdateStrobeLightPosition();

		Super.Tick(Delta);
	}

	simulated function Timer()
	{
		GotoState('Deactivated');
	}
}

static function bool IsUsableByPlayer()
{
	// sort of clever hack...allows the night vision goggles to be disabled, but not NVGogglesBase
	return default.class != class'SwatEquipment.NVGogglesBase';
}

simulated function bool GetCanSeeIRLaser();
simulated function SetCanSeeIRLaser(bool Set);
simulated function UpdateStrobeLightPosition();

defaultproperties
{
	ProtectedRegion = REGION_Head
	EffectDownTime=0.2
	EffectUpTime=0.2
}
