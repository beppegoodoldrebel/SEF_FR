class BatteringRam extends BreachingShotgun config(SwatEquipment); 

simulated function TraceFire()
{
	//do nothing here , just swing the ram 
}	

simulated function UsedHook()
{
	local vector PerfectStartLocation, StartLocation;
    local rotator PerfectStartDirection, StartDirection, CurrentDirection;
	local vector StartTrace, EndTrace;
    local int Shot;

	
    GetPerfectFireStart(PerfectStartLocation, PerfectStartDirection);
	
    StartLocation = PerfectStartLocation;
    StartDirection = PerfectStartDirection;
    ApplyAimError(StartDirection);
    StartTrace = StartLocation;
    for(Shot = 0; Shot < Ammo.ShotsPerRound; ++Shot) {
      ApplyRandomOffsetToRotation(StartDirection, GetChoke() * DEGREES_TO_RADIANS, CurrentDirection);
	  
	  if (inFirstPersonView())
	  {	  
		  //log("Battering Ram shot " $Shot $ " Owner " $ Owner.name " );
		  EndTrace = StartLocation + vector(CurrentDirection) * Range;
		  //Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(0,255,0));
	  }
	  else                                                 //AI
	  {
          StartTrace = Owner.Location;
	      EndTrace = StartTrace + vector(Owner.Rotation)*120;
		  //EndTrace = StartLocation + vector(CurrentDirection) * 120;  //fixed range for AI to be sure to hit door...	  
		  //DEBUG
		  Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(255,0,0));
	  }
	
      BallisticFire(StartTrace, EndTrace); 
    }

	 //TMC TODO 9/17/2003 move this into LocalFire() after Mike meets the milestone... then we don't need to do this redundant test.
    //LocalPlayerController = Level.GetLocalPlayerController();

    //if (Pawn(Owner).Controller == LocalPlayerController)    //I'm the one firing
    //{
    //    Magnitude = GetPerBurstRecoilMagnitude();
    //    Shot = 0;
    //    AutoMagnitude = 0.0;
    //    ForeDuration = RecoilForeDuration;
    //    BackDuration = RecoilBackDuration;

        //if(LocalPlayerController.WantsZoom)
        //{   // Recoil is decreased by 50% when we're zooming/aiming down sights.
        //    Magnitude *= 0.5;
        //    AutoMagnitude *= 0.5;
        //    ForeDuration *= 0.5;
        //    BackDuration *= 0.5;
        //}

        //LocalPlayerController.AddRecoil(BackDuration, ForeDuration, Magnitude, AutoMagnitude, Shot);
    //}
}

simulated function BallisticFire(vector StartTrace, vector EndTrace)
{
	local vector HitLocation, HitNormal, ExitLocation, ExitNormal;
	local actor Victim;
    local Material HitMaterial, ExitMaterial; //material on object that was hit
    local ESkeletalRegion HitRegion;
	local float Momentum;
	local float KillEnergy;
    local int BulletType;
	
	Momentum = MuzzleVelocity * Ammo.Mass;
	BulletType = Ammo.GetBulletType();
	KillEnergy = 0;
	
    foreach TraceActors(
        class'Actor',
        Victim,
        HitLocation,
        HitNormal,
        HitMaterial,
        EndTrace,
        StartTrace,
        /*optional extent*/,
        true, //bSkeletalBoxTest
        HitRegion,
        true,   //bGetMaterial
        true,   //bFindExitLocation
        ExitLocation,
        ExitNormal,
        ExitMaterial )
    {
        //dont see , dont care
		if ( Victim.DrawType != DT_Mesh && Victim.DrawType != DT_StaticMesh )
			 continue;

		if( Victim.isa('HandheldEquipmentModel') && Victim.Owner.isa('Hands') )
		{
	    	if ( self.Owner == Victim.Owner.Owner )
				continue;
		}
		
		if( Victim.isa('ShieldEquip')  ) //to avoid officers shoots their own shield
		{
			if ( self.Owner == Victim.Owner )
				continue;
		}

        //handle each ballistic impact until the bullet runs out of momentum and does not penetrate 
        if (!HandleBallisticImpact(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, HitRegion, Momentum, KillEnergy, BulletType, ExitLocation, ExitNormal, ExitMaterial))
            break;
		
	
    }
}

simulated function bool HandleBallisticImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    Material HitMaterial,
    ESkeletalRegion HitRegion,
    out float Momentum,
    out float KillEnergy,
    out int BulletType,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
	local vector PlayerToDoor;
	local float MaxDoorDistance;
	local float BreachingChance;
	local bool success;
	local SwatDoor TargetDoor;
	

	if(Role == Role_Authority)  // ONLY do this on the server!!
	{
		MaxDoorDistance = 99.45;		//1.5 meters in UU			
		
    	PlayerToDoor = HitLocation - Owner.Location;
			 
		//sound of hitting something
		if ( !Victim.IsA('SwatPawn') )
		{
			ThirdPersonModel.TriggerEffectEvent('Hit');

			if (GetHands() != None)
			{
				FirstPersonModel.TriggerEffectEvent('Hit');
			}
		}

	  log("Battering Ram Victim - " $Victim.name );
      if ( ( Victim.IsA('SwatDoor')  || Victim.Owner.IsA('SwatDoor')  )
	  && PlayerToDoor Dot PlayerToDoor < MaxDoorDistance*MaxDoorDistance )
	  {
		   if ( Victim.IsA('SwatDoor') )
				TargetDoor = SwatDoor(Victim);
		   else
				TargetDoor = SwatDoor(Victim.Owner);
		  
		
		if ( ( TargetDoor.IsLocked()  || TargetDoor.isWedged())
			&& 
		        ( TargetDoor.GetRamDamage() < 3.0 ) ) //door got less than 3 hits
		{	
			//door resistance based on material type
			switch (HitMaterial.MaterialVisualType)
			{
	    	case MVT_ThinMetal:
	    	case MVT_ThickMetal:
	    	case MVT_Default:
					BreachingChance = MetalBreachingChance;
	    		break;
	    	case MVT_Wood:
			case MVT_OpaqueGlass:
					BreachingChance = WoodBreachingChance;
	    		break;
	    	default:
	    		BreachingChance = 0.75;
	    		break;
			}
	    }
		else
			BreachingChance = 0.9; //not locked go blast

		TargetDoor.AddRamDamage();
		success = ShouldBreach(BreachingChance);
		//log("Battering Ram GetDamage() "  $ TargetDoor.GetRamDamage() ); 
		log("Battering Ram AddDamage() " $ TargetDoor.GetRamDamage() );
		log("Battering Ram BreachingChance " $ BreachingChance );
		log("Battering Ram success " $ success );
		
		
		if ( success )
		{  
			//shake when hitting something
			if ( Owner.isa('SwatPlayer') )
				SwatPlayer(Owner).ApplyHitEffect(0.5,0.5,0.5);
		  
			TargetDoor.OnSkeletalRegionHit(
                HitRegion,
                HitLocation,
                HitNormal,
                0,                  //damage: unimportant for breaching a door
                GetDamageType(),
                Owner);
        
			Momentum = 0; // All of the momentum is lost
		}
		else if ( ! success )
		{
		  //shake when hitting something
		  if ( Owner.isa('SwatPlayer') )
		    SwatPlayer(Owner).ApplyHitEffect(0.5,0.5,0.5);
			
		  Momentum = 0; // All of the momentum is lost
		}
	  
	  }

	}

	// We should still consider it to have ballistic impacts
	return false;
}

simulated function changeShellsMaterial()
{
	//Do nothing
}

defaultproperties
{
	WoodBreachingChance = 0.5  //to be tested
	MetalBreachingChance = 0.3 //to be tested
	bPenetratesDoors=false
	IgnoreAmmoOverrides=true
	bAbletoMelee=false
	Slot=Slot_BatteringRam
}
