class BatteringRam extends BreachingShotgun config(SwatEquipment); 

simulated function TraceFire()
{
	
	/*
   local vector PerfectStartLocation, StartLocation;
    local rotator PerfectStartDirection, StartDirection, CurrentDirection;
	  local vector StartTrace, EndTrace;
    
    local int Shot;
    local float Magnitude;
    local float AutoMagnitude;
    local float ForeDuration, BackDuration;

    GetPerfectFireStart(PerfectStartLocation, PerfectStartDirection);
	
    StartLocation = PerfectStartLocation;
    StartDirection = PerfectStartDirection;
    ApplyAimError(StartDirection);
    StartTrace = StartLocation;
    for(Shot = 0; Shot < Ammo.ShotsPerRound; ++Shot) {
      ApplyRandomOffsetToRotation(StartDirection, GetChoke() * DEGREES_TO_RADIANS, CurrentDirection);
      EndTrace = StartLocation + vector(CurrentDirection) * Range;
      BallisticFire(StartTrace, EndTrace); "removed here 
    }
	

    PerfectAimNextShot = false;

    //TMC TODO 9/17/2003 move this into LocalFire() after Mike meets the milestone... then we don't need to do this redundant test.
    LocalPlayerController = Level.GetLocalPlayerController();

    if (Pawn(Owner).Controller == LocalPlayerController)    //I'm the one firing
    {
        Magnitude = GetPerBurstRecoilMagnitude();
        Shot = 0;
        AutoMagnitude = 0.0;
        ForeDuration = RecoilForeDuration;
        BackDuration = RecoilBackDuration;

        if(CurrentFireMode == FireMode_Auto || CurrentFireMode == FireMode_Burst)
        {
            AutoMagnitude = GetAutoRecoilMagnitude();
            Shot = AutoFireShotIndex;
        }

        if(LocalPlayerController.WantsZoom)
        {   // Recoil is decreased by 50% when we're zooming/aiming down sights.
            Magnitude *= 0.5;
            AutoMagnitude *= 0.5;
            ForeDuration *= 0.5;
            BackDuration *= 0.5;
        }

        LocalPlayerController.AddRecoil(BackDuration, ForeDuration, Magnitude, AutoMagnitude, Shot);
    }
	*/
}	

simulated function UsedHook()
{
	local vector PerfectStartLocation, StartLocation;
    local rotator PerfectStartDirection, StartDirection, CurrentDirection;
	local PlayerController LocalPlayerController;
	local vector StartTrace, EndTrace;
    local int Shot;
    local float Magnitude;
    local float AutoMagnitude;
    local float ForeDuration, BackDuration;
	
    GetPerfectFireStart(PerfectStartLocation, PerfectStartDirection);
	
    StartLocation = PerfectStartLocation;
    StartDirection = PerfectStartDirection;
    ApplyAimError(StartDirection);
    StartTrace = StartLocation;
    for(Shot = 0; Shot < Ammo.ShotsPerRound; ++Shot) {
      ApplyRandomOffsetToRotation(StartDirection, GetChoke() * DEGREES_TO_RADIANS, CurrentDirection);
	  
	  if ( Owner.isa('SwatPlayer') || Owner.isa('Hands') )
		EndTrace = StartLocation + vector(CurrentDirection) * Range;
	  else
	  {
		  EndTrace = StartLocation + vector(CurrentDirection) * 100;  //fixed range for AI to be sure to hit door...
		  //Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(255,0,0));
	  }
	
      BallisticFire(StartTrace, EndTrace); 
    }
	
	 //TMC TODO 9/17/2003 move this into LocalFire() after Mike meets the milestone... then we don't need to do this redundant test.
    LocalPlayerController = Level.GetLocalPlayerController();

    if (Pawn(Owner).Controller == LocalPlayerController)    //I'm the one firing
    {
        Magnitude = GetPerBurstRecoilMagnitude();
        Shot = 0;
        AutoMagnitude = 0.0;
        ForeDuration = RecoilForeDuration;
        BackDuration = RecoilBackDuration;

        /*
		if(CurrentFireMode == FireMode_Auto || CurrentFireMode == FireMode_Burst)
        {
            AutoMagnitude = GetAutoRecoilMagnitude();
            Shot = AutoFireShotIndex;
        }
		*/

        if(LocalPlayerController.WantsZoom)
        {   // Recoil is decreased by 50% when we're zooming/aiming down sights.
            Magnitude *= 0.5;
            AutoMagnitude *= 0.5;
            ForeDuration *= 0.5;
            BackDuration *= 0.5;
        }

        LocalPlayerController.AddRecoil(BackDuration, ForeDuration, Magnitude, AutoMagnitude, Shot);
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
				FirstPersonModel.OnUseKeyFrame();
				FirstPersonModel.TriggerEffectEvent('Hit');
			}
		}

      if ( ( Victim.IsA('SwatDoor')  || Victim.Owner.IsA('SwatDoor')  )
	  && PlayerToDoor Dot PlayerToDoor < MaxDoorDistance*MaxDoorDistance )
	  {
		
		if ( SwatDoor(Victim).IsLocked() )			
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
					BreachingChance = WoodBreachingChance;
	    		break;
	    	default:
	    		BreachingChance = 1;
	    		break;
			}
	    }
		else
			BreachingChance = 1; //not locked go blast

		success = ShouldBreach(BreachingChance);
		
		if ( success )
		{  
			//shake when hitting something
			if ( Owner.isa('SwatPlayer') )
				SwatPlayer(Owner).ApplyHitEffect(0.5,0.5,0.5);
		  
			//can be a door or something owned by it 
			if ( Victim.IsA('SwatDoor') )
			{
			IHaveSkeletalRegions(Victim).OnSkeletalRegionHit(
                HitRegion,
                HitLocation,
                HitNormal,
                0,                  //damage: unimportant for breaching a door
                GetDamageType(),
                Owner);
			}
			else if (Victim.Owner.IsA('SwatDoor') )
			{
			IHaveSkeletalRegions(Victim.Owner).OnSkeletalRegionHit(
                HitRegion,
                HitLocation,
                HitNormal,
                0,                  //damage: unimportant for breaching a door
                GetDamageType(),
                Owner);	
			}
        
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
	WoodBreachingChance = 0.9  //to be tested
	MetalBreachingChance = 0.8 //to be tested
	bPenetratesDoors=false
	IgnoreAmmoOverrides=true
	bAbletoMelee=false
	Slot=Slot_BatteringRam
}
