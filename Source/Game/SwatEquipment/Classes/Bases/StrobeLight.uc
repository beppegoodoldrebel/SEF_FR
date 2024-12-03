class StrobeLight extends Swatgame.DynamicLightEffect;

var private Timer Pulsing;
var private bool isActive;
var staticMesh StrobeMesh;

simulated function StartPulsing()
{
	Pulsing=Spawn(class'Timer');
	Pulsing.StartTimer(1.0,true,true);
	Pulsing.TimerDelegate = ToggleLight;
	LightType=LT_Steady;
	//bCorona=true;
	//isActive=true;
}

simulated function ToggleLight()
{
	if (GetStrobeLightOn())
		LightType=LT_None;
	else
		LightType=LT_Steady;
	
	//bCorona = !bCorona;
	//isActive = !isActive;
}

simulated function Stop()
{
	Pulsing.StopTimer();
	LightType=LT_None;
	//bCorona=false;
	//isActive=false;
}

simulated function bool GetStrobeIsActive()
{
	return IsActive;
}

simulated function bool GetStrobeLightOn()
{
	return LightType==LT_Steady;
}

simulated function SetIsActive(bool Set)
{
	isActive=Set;
}

defaultproperties
{
	bHidden=false
	bNoDelete=false
	bStatic=false
	bStasis=false
	bCorona=false
	CoronaRotation=5.0
	CoronaRotationOffset=1.0
	MaxCoronaSize=30.0
	Style=STY_Additive
	//Skins[0]=Texture'Coronas.FlashlightCorona'
	bImportantDynamicLight = true;
	LightType=LT_Steady
	LightBrightness=50
	LightHue = 0
	//LightSaturation=0
	LightRadius=10
	DrawType=DT_None
}