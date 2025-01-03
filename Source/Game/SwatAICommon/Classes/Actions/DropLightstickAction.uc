///////////////////////////////////////////////////////////////////////////////
// DropLightstickAction.uc - DropLightstickAction class
// The Action that causes the Officers to drop a lightstick at the specfied location

class DropLightstickAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) private vector			DropPoint;

// behaviors we use
var private MoveToLocationGoal			CurrentMoveToLocationGoal;

var private HandheldEquipment			Lightstick;

var private float StartDrop;
var private bool Dropped;
///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// make sure the fired weapon is re-equipped
	//ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}
	
	
	
	if ((Lightstick != None) && !Lightstick.IsIdle())
	{
		if ( (Level.TimeSeconds - StartDrop ) > 0.5 && !Dropped) 
		{
		log("DropLightstickAction aborted LatentUse() dropping stick");
		Lightstick.OnUseKeyFrame();
		}
		Lightstick.AIInterrupt();
	}
	

}


///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);
	
	// if our movement goal fails, we succeed so we don't get reposted!
	if (goal == CurrentMoveToLocationGoal)
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveIntoPosition()
{
  	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.priority, DropPoint);
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

    CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToLocationGoal.SetAcceptNearbyPath(true);
	CurrentMoveToLocationGoal.SetMoveToThreshold(40.0);

	// post the goal and wait for it to complete
	CurrentMoveToLocationGoal.postGoal(self);
	WaitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

latent function DropLightstick()
{
	Lightstick = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_Lightstick);
	if ( Lightstick == None) {
		return;
	}

	if (DropLightstickGoal(achievingGoal).GetPlaySpeech()) {
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerDeployingLightstickSpeech();
	}
	
	StartDrop = Level.TimeSeconds;
	Lightstick.LatentUse();
	Dropped = true;
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	MoveIntoPosition();

	useResources(class'AI_Resource'.const.RU_LEGS);
	DropLightstick();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'DropLightstickGoal'
}
