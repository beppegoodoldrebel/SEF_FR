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
  reliable if( Role == ROLE_Authority )
  	  bWantLaser;
}


//IR LASER
function LaserDraw()
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
	
	log("LaserDraw() routine");
	
	if (InFirstPersonView())
    {
		assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up laser for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
    }
    else // todo: handle 3rd person flashlight, including when controller changes
    {
		assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up laser for "$self$", ThirdPersonModel is None");
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

simulated function ServerSetLaser()
{
	
	
	if ( Level.NetMode == NM_Standalone )
	{
		log("ServerSetLaser() Stand alone " $ Level.GetLocalPlayerController().Pawn.name );
		bWantLaser=!bWantLaser;
		SetLaser(bWantLaser);	
	}
	else
	{
		
		bWantLaser=!bWantLaser;
		SetLaser(bWantLaser);	
		/*
		local SwatGamePlayerController current;
		local Controller iController, LocalPC;
		local NetPlayer theNetPlayer;
		
		log("ServerSetLaser() Net bWantLaser " $ bWantLaser $ " " $ Level.GetLocalPlayerController().Pawn.name );
		
		bWantLaser=!bWantLaser;
		SetLaser(bWantLaser);
		
		for ( iController = Level.ControllerList; iController != None; iController = iController.NextController )
		{
			current = SwatGamePlayerController( iController );
			if ( current != None && current != LocalPC )
			{
				theNetPlayer = NetPlayer( current.Pawn );
				if ( theNetPlayer != None )
				{
					log( self$" on server: calling SetLaser() by "$theNetPlayer );
					FiredWeapon(theNetPlayer.GetActiveItem()).SetLaser(bWantLaser);
				}
			}
		}
		*/
		
		
	}
	
	
}

//client/AI laser use
simulated function SetLaser(bool bForce)
{
	//assert(Level.NetMode != NM_DedicatedServer);
	bWantLaser=bForce;
	
	log("SetLaser() bWantLaser " $ bWantLaser $ " " $ Level.GetLocalPlayerController().Pawn.name );
	
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
	
	//IRLaserClass=Spawn(class'IRLaser',WeaponModel,,,);
	IRLaserClass=Spawn(class'IRLaser');
	
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
