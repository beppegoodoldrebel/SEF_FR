///////////////////////////////////////////////////////////////////////////////
class MachineGun extends ClipBasedWeapon;
///////////////////////////////////////////////////////////////////////////////

var config bool bHasIRLaser;
var private bool bWantLaser;
var IRLaser IRLaserClass;
var private bool CanSeeLaser;

var vector TraceStart;
var vector HitLocation;

//offset
var config vector IRLaserPosition_1stPerson;
var config rotator IRLaserRotation_1stPerson;
var config vector IRLaserPosition_3rdPerson;
var config rotator IRLaserRotation_3rdPerson;

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
	
	assert(bWantLaser && bHasIRLaser );
	
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
	if (SwatPLayer(Level.GetLocalPlayerController().Pawn).HasNVGActiveForLaser() &&
	    Level.GetLocalPlayerController().Pawn.IsFirstPerson() )//&& InFirstPersonView() )
	{
		TraceStart = IrLaserClass.Location;
		TraceEnd = TraceStart + vector(IrLaserClass.Rotation) * 10000;
		Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True);
	
		//poorman's beam effect lol
		Level.GetLocalPlayerController().myHUD.AddDebugLine(traceStart, hitLocation,class'Engine.Canvas'.Static.MakeColor(255,255,255), 0.02);
		log("Laser Draw Player " $ Pawn(Owner).name $ " laser "  $ IRLaserClass.name );
	}
    }
}

function ServerSetLaser()
{
	log("ServerSetLaser Laser Player " $ Pawn(Owner).name $ " laser "  $ IRLaserClass.name );
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

	Log("SetLaser Laser Player " $ Pawn(Owner).name $ " laser "  $ IRLaserClass.name );
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