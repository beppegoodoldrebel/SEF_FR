class BatteringRam extends BreachingShotgun config(SwatEquipment); 

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

	if(Role == Role_Authority)  // ONLY do this on the server!!
	{
		MaxDoorDistance = 99.45;		//1.5 meters in UU
    	PlayerToDoor = HitLocation - Owner.Location;

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

      if ( ( Victim.IsA('SwatDoor')  || Victim.Owner.IsA('SwatDoor')  )
	  && PlayerToDoor Dot PlayerToDoor < MaxDoorDistance*MaxDoorDistance && ShouldBreach(BreachingChance) )
      {
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

	}

	// We should still consider it to have ballistic impacts
	return false;
}

defaultproperties
{
	WoodBreachingChance = 1  //to be tested
	MetalBreachingChance = 1 //to be tested
	bPenetratesDoors=false
	IgnoreAmmoOverrides=true
	bAbletoMelee=false
	Slot=Slot_BatteringRam
}
