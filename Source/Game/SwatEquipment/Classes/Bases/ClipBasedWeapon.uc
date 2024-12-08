class ClipBasedWeapon extends SwatWeaponFR;

var SpentMagDrop SpentMag; //static mesh of the spent mag to be dropped

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
