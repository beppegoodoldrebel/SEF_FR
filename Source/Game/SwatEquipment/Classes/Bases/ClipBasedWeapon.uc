class ClipBasedWeapon extends Engine.SwatWeapon;

var SpentMagDrop SpentMag; //static mesh of the spent mag to be dropped
var config bool bHasIRLaser;
var config bool bHasVisibleLaser;
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


//simulated function UnEquippedHook();  //TMC do we want to blank the HUD's ammo count?

simulated function OnReloadMagDump() //overrided function from FiredWeapon
{	

	if (IsInState('BeingReloadedQuick') || ( ( Owner.IsA('SwatEnemy') || Owner.IsA('SwatOfficer') ) && AIisQuickReloaded )   )
	{
		
		//log("ClipBasedWeapon::OnReloadMagDump() :: " $ Owner.name $ " .");
		
		//make clip unusable!
		if ( !self.isa('ShieldHandgun')  &&  !self.isa('TaserShield') )
		{
			if ( Ammo.RoundsRemainingBeforeReload() > 0 && !ClipBasedAmmo(Ammo).SpeedLoader )
				Ammo.SetClip(Ammo.GetCurrentClip(), 1 );
			else
				Ammo.SetClip(Ammo.GetCurrentClip(), 0 );
		}
		
		if ( Level.NetMode == NM_Standalone )
		{
			if ( inFirstPersonView() )
			{	
				SpentMag = Owner.Spawn( class'SpentMagDrop', Owner,
				,                   //tag: default
				GetHands().GetBoneCoords('GripRHand').Origin, //translation,
				GetHands().GetBoneRotation('GripRHand'), //rotTransl,
				true);              //bNoCollisionFail
			}
			else
			{
				SpentMag = Owner.Spawn( class'SpentMagDrop', Owner,
				,                   //tag: default
				ThirdPersonModel.Location, //translation,
				ThirdPersonModel.Rotation, //rotTransl,
				true);              //bNoCollisionFail
			}
		}
		else
		{
			
			if ( Level.NetMode != NM_DedicatedServer ) //we dont need that on server
			{
			SpentMag = Owner.Spawn( class'SpentMagDrop', Owner,
			,                   //tag: default
			Owner.GetBoneCoords('GripRHand').Origin, 
			Owner.GetBoneRotation('GripRHand'),
			true);              //bNoCollisionFail
			}
		}
		
		SpentMag.SetInitialVelocity(Vect(0,0,0));	
	}
}

//IR LASER
simulated function LaserDraw()
{
	local vector traceEnd, hitNormal;
	local HandheldEquipmentModel WeaponModel;
	local vector PositionOffset;
	local rotator RotationOffset;
	
	assert(bWantLaser && ( bHasIRLaser || bHasVisibleLaser) );
	
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
		if( ! (SwatPLayer(Level.GetLocalPlayerController().Pawn).HasNVGActiveForLaser() && Level.GetLocalPlayerController().Pawn.IsFirstPerson() ) )
			IrLaserClass.Hide();
		else
			IrLaserClass.Show();
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




