///////////////////////////////////////////////////////////////////////////////
class SwatWeaponFR extends Engine.SwatWeapon;
//Extended SwatWeapon class to avoid native restrictions
///////////////////////////////////////////////////////////////////////////////

//LASER 
var (Laser) config   bool bHasIRLaser;
var (Laser) config   bool bHasVisibleLaser;
var (Laser) private bool bWantLaser;
var (Laser) IRLaser IRLaserClass;
var (Laser) private bool CanSeeLaser;

//offset
var (Laser) config vector IRLaserPosition_1stPerson;
var (Laser) config rotator IRLaserRotation_1stPerson;
var (Laser) config vector IRLaserPosition_3rdPerson;
var (Laser) config rotator IRLaserRotation_3rdPerson;

//SCOPE CAMERA
var (Scope) config  bool  HasScope;
var (Scope) private config ScriptedTexture ScopeScreen;          // Scripted texture that we draw into
var (Scope) private config Material        ScopeShader;          // Shader applied to the first person mesh when active
var (Scope) private config Material        BlankScope;        // Material to use when the viewport isn't active
var (Scope) private config const int       SizeX;              // Size of the texture along the X axis
var (Scope) private config const int       SizeY;              // Size of the texture along the Y axis
var (Scope) private config const int       FOV;                // FOV for our viewport
var (Scope) private config const int	   ScopeIndex;         // texture index to apply scope camera 
var (Scope) private config const int       ScopeXAdjustment;   // X adjust for perfect aiming
var (Scope) private vector ScopeLocation;                 
var (Scope) private rotator ScopeRotation;    
var (Scope) private config Material FirstSkin;                 //used to avoid missing FirstPersonModel.Skin[0] texture.... god knows why....


//*******************************************************
//LASER
//*******************************************************
function LaserDraw()
{
	local vector traceEnd, hitNormal;
	local HandheldEquipmentModel WeaponModel;
	local vector PositionOffset;
	local rotator RotationOffset;
    local vector TraceStart;
	local vector HitLocation;
	
	//Dedicated server doesnt care about your laser
	assert(Level.Netmode != NM_DedicatedServer );
	
	if(bWantLaser && ( bHasIRLaser || bHasVisibleLaser) )
	{
	
	if (Pawn(Owner).isA('SwatPlayer') || Pawn(Owner).isA('SwatOfficer'))
	{
	
	if (InFirstPersonView())
    {
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
		WeaponModel = FirstPersonModel;
		
		IRLaserClass.SetRelativeLocation(PositionOffset);
		IRLaserClass.SetRelativeRotation(RotationOffset);
		WeaponModel.Owner.UpdateAttachmentLocations();
    }
    else 
    {
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
		WeaponModel = ThirdPersonModel;

	    //cant use player's attachment location cause UpdateAttachmentLocations() doesnt work when player's model is outside FOV 
		//and we want laser to start and be visible even when starting outside FOV
		//workaround it's not perfect (some kink rotation when crouched/low ready) but it works!!
		IrLaserClass.SetLocation(WeaponModel.Location + (positionoffset >> WeaponModel.Owner.GetBoneRotation('GripRHand') ));		
		IrLaserClass.SetRotation( Rotator( IrLaserClass.Location - WeaponModel.Owner.GetBoneCoords('GripRHand').Origin ) + RotationOffset );		
    }
	
	//we draw only if local player is on NVGs
	if ( bHasIRLaser )
	{
		//NVG assertion needed 
		if(SwatPlayer(Level.GetLocalPlayerController().Pawn).HasNVGActiveForLaser() && Level.GetLocalPlayerController().Pawn.IsFirstPerson() )
			IrLaserClass.Show();
		else
			IrLaserClass.Hide();
    }
	else
	{
		IrLaserClass.Show();
	}
	
	TraceStart = IrLaserClass.Location;
	TraceEnd = TraceStart + vector(IrLaserClass.Rotation) * 10000;
		
	if ( IrLaserClass.Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True) != None)
		IrLaserClass.LaserLength(VDist(TraceStart , hitLocation));
	else
		IrLaserClass.LaserLength(VDist(TraceStart , TraceEnd));
	
	//DEBUG
	//Level.GetLocalPlayerController().myHUD.AddDebugLine(traceStart, hitLocation,class'Engine.Canvas'.Static.MakeColor(0,255,0), 0.02);
	}
	
	}
	else
		IrLaserClass.Hide();
}

//client/AI laser use
simulated function SetLaser(bool bForce)
{
	//assert(Level.NetMode != NM_DedicatedServer);
	bWantLaser=bForce;
	
	//log("SetLaser() bWantLaser " $ bWantLaser $ " " $ Level.GetLocalPlayerController().Pawn.name );
	
	if (bWantLaser)
		InitLaser();
	else
		DestroyLaser();		
}


simulated function InitLaser()
{
	local HandheldEquipmentModel WeaponModel;	
	local vector PositionOffset;
	local rotator RotationOffset;
	
	//attach IRLaser class
	if (InFirstPersonView())
    {
		//assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up flashlight for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
    }
    else
    {
		//assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up flashlight for "$self$", ThirdPersonModel is None");
		WeaponModel = ThirdPersonModel;
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
    }
	
	if ( IRLaserClass != None )
		DestroyLaser();
	
	IRLaserClass=Spawn(class'IRLaser',WeaponModel);
	
	WeaponModel.Owner.AttachToBone(IRLaserClass, WeaponModel.EquippedSocket);
	
	IRLaserClass.SetRelativeLocation(PositionOffset);
	IRLaserClass.SetRelativeRotation(RotationOffset);
	WeaponModel.Owner.UpdateAttachmentLocations();
	
	if (bHasIRLaser)
		IRLaserClass.IRLaserColor();
    else if (bHasVisibleLaser)
		IRLaserClass.RedLaserColor();
	

}

simulated function bool IsLaserON()
{
	return bWantLaser;
}

simulated function DestroyLaser()
{
	IRLaserClass.Destroy();
}

simulated function bool HasIrLaser()
{
	return bHasIRLaser;
}

//*******************************************************
//SCOPE CAMERA 
//*******************************************************
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
	
	if( HasScope )
		Disable('Tick');
}

simulated function OnGivenToOwner()
{
   Super.OnGivenToOwner();
   
   
     if( HasScope )
	{
   
		if ( Pawn(Owner) != None && Pawn(Owner).Controller == Level.GetLocalPlayerController() )
		{	 
			ScopeScreen.Client = Self;
			ScopeScreen.bNotifyClientBeforeRendering = true;
			ScopeScreen.SetSize(SizeX, SizeY);
			Disable('Tick');
		
			assert( FirstPersonModel != None );  
			
			//missing Skin[0] texture workaround
			FirstPersonModel.Skins[0] = FirstSkin;
		}
	}
}

simulated function EquippedHook()
{
	if( HasScope )
		Enable('Tick');
	
    Super.EquippedHook();
}

simulated function UnequippedHook()
{
	if( HasScope )
		Disable('Tick');
  
  Super.UnequippedHook();
}

simulated event Destroyed()
{
	if( HasScope )
	{
		if (ScopeScreen != None && ScopeScreen.Client == Self)
		{
			// prevent GC failure due to hanging actor refs
			ScopeScreen.Client = None;
		}
	}

	Super.Destroyed();
}

// Render a portal to the lcdscreen from the desired viewport loc and rot
simulated event RenderTexture(ScriptedTexture inTexture)
{
    //local Color White;

    //White.R = 255; White.G = 0; White.B = 0;

    ViewportCalcView(ScopeLocation, ScopeRotation);
    ScopeScreen.DrawPortal(0, 0, SizeX, SizeY, Level.GetLocalPlayerController(), ScopeLocation, ScopeRotation, FOV);
    //LCDScreen.DrawTile(SizeX/2, SizeY/2,  512, 512, 0, 0, 512, 512, ReticleTexture, White);
}

simulated function Tick(float DeltaTime)
{
	if( HasScope )
	{
	  FirstPersonModel.Skins[0] =  FirstSkin; 
	  if(FirstPersonModel != None)
	  {
		FirstPersonModel.Skins[ScopeIndex] = ScopeShader;
	  }
		ScopeScreen.Revision++;

	  if (!Level.GetLocalPlayerController().WantsZoom) 
	  {
		if(FirstPersonModel != None)
		{
		  FirstPersonModel.Skins[ScopeIndex] = BlankScope;
		}
	  }
	 
		ViewportCalcView(ScopeLocation, ScopeRotation);	
    }
}

simulated function  ViewportCalcView(out Vector CameraLocation, out Rotator CameraRotation)
{
	local vector X,Y,Z;
	
    if(FirstPersonModel != None)
    { 
		GetPerfectFireStart(CameraLocation,CameraRotation);
		GetAxes(  CameraRotation, X, Y, Z );
		CameraLocation = CameraLocation + X * ScopeXAdjustment; //X * XAdjustment means offset forward to avoid clipping the scope model	
    }
}