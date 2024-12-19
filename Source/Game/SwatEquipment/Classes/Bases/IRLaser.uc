class IRLaser extends Engine.Actor;

var private StaticMesh SM;
var private string IRTexture;
var private string ColTexture;

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();
	
	SetStaticMesh(SM);
}

simulated event PostNetBeginPlay()
{
    super.PostNetBeginPlay();
	SetStaticMesh(SM);
}

simulated function RedLaserColor()
{
	Skins[0]=Material(DynamicLoadObject( ColTexture, class'Material'));
}

simulated function IRLaserColor()
{
	Skins[0]=Material(DynamicLoadObject( IRTexture, class'Material'));
}

//Distance: 1 = 10  Unreal Unit scale
simulated function LaserLength(float Distance)
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
	Physics=PHYS_None
    //RemoteRole=ROLE_SimulatedProxy
    DrawType=DT_StaticMesh
	SM=StaticMesh'FR_Laser.IRLaser_sm'
	IRTexture="FR_LaserTex.IRShader"
	ColTexture="FR_LaserTex.RedShader"
	bAcceptsShadowProjectors=false
}