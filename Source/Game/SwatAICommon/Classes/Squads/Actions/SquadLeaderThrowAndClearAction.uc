///////////////////////////////////////////////////////////////////////////////
// SquadLeaderThrowAndClearAction.uc - SquadLeaderThrowAndClearAction class
// this action is used to organize the Officer's throw & clear behavior

class SquadLeaderThrowAndClearAction extends SquadThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

var bool grenadeThrown;

///////////////////////////
// Since the thrower is not an AI-controlled officer, we don't need to worry about Formation

protected function bool ShouldThrowerBeFirstOfficer()
{
	return false;
}

protected latent function MoveUpThrower()
{
}

protected function SetThrower()
{
  Thrower = CommandGiver;
}

function Pawn GetThrowingOfficer(EquipmentSlot ThrownItemSlot)
{
	return CommandGiver;
}

///////////////////////////
// Set up the goal to wait for a grenade detonation
///////////////////////////

protected latent function WaitForGrenadeToBeThrown()
{
	while(!grenadeThrown) {
		yield();
	}

	sleep(PostGrenadeThrowDelayTime);
}

protected latent function PreTargetDoorOpened()
{
}

protected latent function PostTargetDoorOpened()
{
	WaitForGrenadeToBeThrown();
}

protected latent function PostTargetDoorBreached()
{
	WaitForGrenadeToBeThrown();
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	WaitForGrenadeToBeThrown();
}

function GrenadeGotDetonated(Pawn PawnThrower, EquipmentSlot ThrownItemSlot) {
	if(PawnThrower == Thrower) {
		PostGrenadeThrowDelayTime = 0;

		if (ThrownItemSlot == EquipmentSlot.Slot_CSGasGrenade) 
		{
			if(DoAllOfficersHave('gasMask') || DoAllOfficersHave('helmetgasMask') )
			{
				PostGrenadeThrowDelayTime = CSGrenadeDelayTimeGasMask;
			}
			else if(DoAllOfficersHave('RiotHelmet'))
			{
				PostGrenadeThrowDelayTime = CSGrenadeDelayTimeRiotHelmet;
			}
			else
			{
				PostGrenadeThrowDelayTime = CSGrenadeDelayTime;
			}
				
		}
		
		if (ThrownItemSlot == EquipmentSlot.Slot_Flashbang)
		{
			if( !DoAllOfficersHave('HelmetAndGoggles') )
			{
				if ( ISwatOfficer(Thrower).Hasa('NinebangGrenade') )//the thrower has Ninebangs
				{
					PostGrenadeThrowDelayTime=NinebangDelayTime;
				}
				else
				{
					PostGrenadeThrowDelayTime=FlashbangDelayTime;
				}
			}
		}

		if (ThrownItemSlot == EquipmentSlot.Slot_StingGrenade)
		{
			PostGrenadeThrowDelayTime=StingerDelayTime;
		}

		
		grenadeThrown = true;
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadLeaderThrowAndClearGoal'
}
