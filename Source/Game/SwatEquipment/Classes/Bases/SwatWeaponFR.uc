///////////////////////////////////////////////////////////////////////////////
class SwatWeaponFR extends Engine.SwatWeapon;
//Extended SwatWeapon class to avoid native restrictions
///////////////////////////////////////////////////////////////////////////////

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

replication
{
  unreliable if( Role == ROLE_Authority )
	  bWantLaser;
}

//IR LASER
simulated function LaserDraw()
{
	local vector traceEnd, hitNormal;
	local HandheldEquipmentModel WeaponModel;
	local vector PositionOffset;
	local rotator RotationOffset;
    local vector TraceStart;
	local vector HitLocation;
	
	if(bWantLaser && ( bHasIRLaser || bHasVisibleLaser) )
	{
	
	//if (Pawn(Owner).Controller == Level.GetLocalPlayerController() )
	if (Pawn(Owner).isA('SwatPlayer') || Pawn(Owner).isA('SwatOfficer'))
	{
		
	if (InFirstPersonView())
    {
		assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up flashlight for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
    }
    else // todo: handle 3rd person flashlight, including when controller changes
    {
		assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up flashlight for "$self$", ThirdPersonModel is None");
		WeaponModel = ThirdPersonModel;
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
    }
	
	IRLaserClass.SetRelativeLocation(PositionOffset);
	IRLaserClass.SetRelativeRotation(RotationOffset);
	
	WeaponModel.Owner.UpdateAttachmentLocations();
	
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
	Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True);
	
	
	IrLaserClass.LaserLength(VDist(TraceStart , hitLocation));
	//Level.GetLocalPlayerController().myHUD.AddDebugLine(traceStart, hitLocation,class'Engine.Canvas'.Static.MakeColor(255,0,0), 0.02);
	}
	
	}
	else
		IrLaserClass.Hide();
}

function ServerSetLaser()
{
	bWantLaser=!bWantLaser;
	SetLaser(bWantLaser);	
}

//client/AI laser use
simulated function SetLaser(bool bForce)
{
	//assert(Level.NetMode != NM_DedicatedServer);
	
	bWantLaser=bForce;
	
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
		assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up flashlight for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
    }
    else
    {
		assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up flashlight for "$self$", ThirdPersonModel is None");
		WeaponModel = ThirdPersonModel;
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
    }
	
	IRLaserClass=Spawn(class'IRLaser',WeaponModel,,,);
	
	if (bHasIRLaser)
		IRLaserClass.IRLaserColor();
    else if (bHasVisibleLaser)
		IRLaserClass.RedLaserColor();
	
	WeaponModel.Owner.AttachToBone(IRLaserClass, WeaponModel.EquippedSocket);
	
	IRLaserClass.SetRelativeLocation(PositionOffset);
	IRLaserClass.SetRelativeRotation(RotationOffset);
	WeaponModel.Owner.UpdateAttachmentLocations();
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
