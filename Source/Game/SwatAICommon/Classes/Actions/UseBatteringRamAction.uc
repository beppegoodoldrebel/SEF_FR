///////////////////////////////////////////////////////////////////////////////

class UseBatteringRamAction extends SwatCharacterAction
	implements IInterestedInDoorOpening
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private AimAtPointGoal		        CurrentAimAtPointGoal;
var private MoveToActorGoal             CurrentMoveToActorGoal;
var private MoveToDoorGoal              CurrentMoveToDoorGoal;

var private FiredWeapon		            BreachingShotgun;
var private vector						BreachAimLocation;

var private vector BreachFrom;
var private rotator CenterOpenRotation;

var(parameters) private Door            TargetDoor;
var(parameters) private NavigationPoint PostBreachPoint;
var private float WoodBreachingChance "The chance to breach a wooden door, per pellet.";
var private float MetalBreachingChance "The chance to breach a metal door, per pellet.";

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	local ISwatDoor SwatDoor;

	super.initAction(r, goal);

	SwatDoor = ISwatDoor(TargetDoor);
    assert(SwatDoor != None);
    BreachAimLocation = SwatDoor.GetRamAimPoint(m_Pawn);
}

function cleanup()
{
    local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

    super.cleanup();

	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}

/*	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}
*/
	
	if (CurrentMoveToDoorGoal != None)
	{
		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;
	}

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();

	if ((BreachingShotgun != None) && !BreachingShotgun.IsIdle())
	{
		BreachingShotgun.AIInterrupt();
	}

	// make sure the fired weapon is re-equipped
	Officer.InstantReEquipFiredWeapon();

    Officer.UnsetUpperBodyAnimBehavior(kUBABCI_UseBreachingShotgunAction);
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyDoorOpening(Door TargetDoor)
{
	// door is opening, can't remove the wedge (this should only happen if the door was breached)
	instantSucceed();
}

///////////////////////////////////////////////////////////////////////////////
//
// State code


latent function EquipBreachingShotgun()
{
    local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

    BreachingShotgun = FiredWeapon(Officer.GetItemAtSlot(SLOT_PrimaryWeapon));
		if(BreachingShotgun == None || !BreachingShotgun.IsA('BatteringRam'))
			BreachingShotgun = FiredWeapon(Officer.GetItemAtSlot(SLOT_SecondaryWeapon));

	if(BreachingShotgun == None || !BreachingShotgun.IsA('BatteringRam'))
	{
		instantFail(ACT_NO_WEAPONS_AVAILABLE);
	}

    if (!BreachingShotgun.IsEquipped())
    {
        BreachingShotgun.LatentWaitForIdleAndEquip();
    }

    Officer.SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UseBreachingShotgunAction);
}

function GetLocationToBreachFrom()
{
	local ISwatDoor SwatDoorTarget;
	

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	BreachFrom = SwatDoorTarget.GetBreachFromPoint(m_Pawn);
	// get the center mirroring point no matter what
	//SwatDoorTarget.GetOpenPositions(m_Pawn, false, BreachFrom, CenterOpenRotation);

}

latent function MoveToRamPosition()
{
	CurrentMoveToDoorGoal = new class'MoveToDoorGoal'(AI_Resource(m_Pawn.movementAI), TargetDoor);
	assert(CurrentMoveToDoorGoal != None);
	CurrentMoveToDoorGoal.AddRef();

	CurrentMoveToDoorGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToDoorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToDoorGoal);
	CurrentMoveToDoorGoal.unPostGoal(self);

	CurrentMoveToDoorGoal.Release();
	CurrentMoveToDoorGoal = None;
}

latent function MoveToPostBreachingPoint()
{
    CurrentMoveToActorGoal = new class'SwatAICommon.MoveToActorGoal'(movementResource(), achievingGoal.priority, PostBreachPoint);
    assert(CurrentMoveToActorGoal != None);
    CurrentMoveToActorGoal.AddRef();

    CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(false);

    CurrentMoveToActorGoal.postGoal(self);
    waitForGoal(CurrentMoveToActorGoal);
    CurrentMoveToActorGoal.unPostGoal(self);

    CurrentMoveToActorGoal.Release();
    CurrentMoveToActorGoal = None;
}

latent function AimAtDoor()
{
    CurrentAimAtPointGoal = new class'AimAtPointGoal'(weaponResource(), achievingGoal.priority,BreachAimLocation);
    assert(CurrentAimAtPointGoal != None);
    CurrentAimAtPointGoal.AddRef();

    CurrentAimAtPointGoal.postGoal(self);
}

private function StopAimingAtDoorKnob()
{
	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.unPostGoal(self);
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}
}

latent function BreachDoorWithRam()
{
	local int tries;
	ISwatAI(m_Pawn).SetWeaponTargetLocation(BreachAimLocation);

    // @NOTE: Pause for a brief moment before shooting to make the shot look
    // more deliberate
    Sleep(1.0);

	// we're no longer interested if the door is opening (we're about to open it)
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	BreachingShotgun.SetPerfectAimNextShot();

	// @HACK Break the door "before firing the shotgun. The AI literally always misses,
	// and there is a very noticable delay if we automatically break the door AFTER firing
	// the shotgun, but if we break the door FIRST it appears to happen exactly when the
	// shot is fired. In other words, this solution looks perfect. -K.F.

	//ISwatDoor(TargetDoor).Blasted(m_Pawn);
	
	while( TargetDoor.IsClosed() &&
		  !TargetDoor.IsOpening() &&
	       tries < 10)
	{	//log("UseBatteringRamAction tries " $ tries ); 
		tries++;
		BreachingShotgun.LatentUse();
		
		//DoorBlasting(ISwatDoor(TargetDoor));
	}
}

function DoorBlasting( ISwatDoor TargetDoor )
{
local float BreachingChance;

	if ( TargetDoor.IsLocked() )			
		{	
			//door resistance based on material type
			switch (TargetDoor.GetDoorMaterialVisualType())
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

    if ( FRand() < BreachingChance )
		TargetDoor.Blasted(m_Pawn);		
}

function TriggerReportedDeployingShotgunSpeech()
{
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedDeployingShotgunSpeech();
}

state Running
{
Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && ! TargetDoor.IsBroken())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		TriggerReportedDeployingShotgunSpeech();

		// no avoiding collision while we're breaching the door!
		m_Pawn.DisableCollisionAvoidance();

		MoveToRamPosition();
		
		useResources(class'AI_Resource'.const.RU_LEGS);

		clearDummyWeaponGoal();

		AimAtDoor();
		EquipBreachingShotgun();

		WaitForZulu();

		BreachDoorWithRam();

		StopAimingAtDoorKnob();
		ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

		// re-enable collision avoidance!
		m_Pawn.EnableCollisionAvoidance();

		useResources(class'AI_Resource'.const.RU_ARMS);
		clearDummyMovementGoal();

		if (PostBreachPoint != None)
		{
			MoveToPostBreachingPoint();
		}
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	WoodBreachingChance = 0.9  //to be tested
	MetalBreachingChance = 0.8 //to be tested
	satisfiesGoal = class'UseBatteringRamGoal'
}

///////////////////////////////////////////////////////////////////////////////
