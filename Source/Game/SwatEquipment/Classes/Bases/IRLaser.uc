class IRLaser extends Engine.Actor;

var private StaticMesh SM;

function PreBeginPlay()
{
	Super.PreBeginPlay();
	
	SetStaticMesh(SM);
}

//Distance: 1 = 10  Unreal Unit scale
function LaserLength(float Distance)
{	
local vector Scale;

	Scale.X=Distance;
	Scale.Y=1.0;
	Scale.Z=1.0;
	
	SetDrawScale3d(Scale);
}

defaultproperties
{
	bHidden=false
    //RemoteRole=ROLE_None
    DrawType=DT_StaticMesh
	SM=StaticMesh'FR_Laser.IRLaser_sm'
	Skins[0]=Material'SWATgearTex.FlashlightLensOnShader'
	bAcceptsShadowProjectors=false
}