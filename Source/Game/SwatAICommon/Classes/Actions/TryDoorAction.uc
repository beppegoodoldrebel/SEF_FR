///////////////////////////////////////////////////////////////////////////////
// TryDoorAction.uc - TryDoorAction class
// The Action that causes the Officers to test and see if a door is blocked

class TryDoorAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Door				TargetDoor;
var(parameters) bool				bTriggerReportResultsSpeech;
var(parameters) bool 				bPeekDoor;
// behaviors we use
var private MoveToDoorGoal			CurrentMoveToDoorGoal;
var private RotateTowardActorGoal   CurrentRotateTowardActorGoal;

// door usage side
var private	AIDoorUsageSide			TryDoorUsageSide;
var private rotator					TryDoorUsageRotation;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToDoorGoal != None)
	{
		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;
	}
	
	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	// stop animating
	ISwatAI(m_Pawn).AnimStopSpecial();

	// unlock our aim (if it isn't already)
	ISwatAI(m_Pawn).UnlockAim();

	// make sure we re-enable collision avoidance
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
//

private function ReportResultsToTeam()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	assert(SwatAIRepo != None);

	SwatAIRepo.UpdateDoorKnowledgeForOfficers(TargetDoor);

	if (bTriggerReportResultsSpeech)
		TriggerReportResultsSpeech();
}

private function TriggerReportResultsSpeech()
{
	local ISwatDoor SwatTargetDoor;

	SwatTargetDoor = ISwatDoor(TargetDoor);
	assert(SwatTargetDoor != None);

	if (SwatTargetDoor.IsLocked())
	{
		// it's locked!  play a sound!
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportDoorLockedSpeech();
	}
	else if (SwatTargetDoor.IsWedged())
	{
		// it's wedged!  play a sound!
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportDoorWedgedSpeech();
	}
	else
	{
		// it's open!  play a sound!
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportDoorOpenSpeech();
	}
	
	
}

latent function ReportPossibleTrap()
{
	local ISwatDoor SwatTargetDoor;
	local bool TrappedLevel;
	local Door TempDoor;
	
	SwatTargetDoor = ISwatDoor(TargetDoor);
	assert(SwatTargetDoor != None && !SwatTargetDoor.isPartialOpen() );
	
	foreach level.AllActors( class'Door' , TempDoor )
	{
		TrappedLevel = (TrappedLevel || ISwatDoor(TempDoor).IsBoobyTrapped());	
	}
	
	log("check for traps in level: " $ TrappedLevel $ " ");
	
	if (SwatTargetDoor.IsDoorCheckLockTrapped() && TrappedLevel )		//might be trapped
	{
		Sleep(2.0);
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerExaminedFoundTrapSpeech();
	}
	
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToTryDoor()
{
	CurrentMoveToDoorGoal = new class'MoveToDoorGoal'(movementResource(), achievingGoal.priority, TargetDoor);
	assert(CurrentMoveToDoorGoal != None);
	CurrentMoveToDoorGoal.AddRef();

	CurrentMoveToDoorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToDoorGoal.SetShouldWalkEntireMove(false);
	CurrentMoveToDoorGoal.SetPreferSides();

	CurrentMoveToDoorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToDoorGoal);

	// save the side of the door we're going to try from
	TryDoorUsageSide     = CurrentMoveToDoorGoal.DoorUsageSide;
	TryDoorUsageRotation = CurrentMoveToDoorGoal.DoorUsageRotation;

	CurrentMoveToDoorGoal.unPostGoal(self);

	CurrentMoveToDoorGoal.Release();
	CurrentMoveToDoorGoal = None;
}

latent function TryDoor()
{
	local int AnimSpecialChannel;
	local name AnimName;
	local ISwatDoor SwatDoorTarget;
	local float frame,rate;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	if ( !SwatDoorTarget.isPartialOpen() )
	{
		
		AnimName		   = SwatDoorTarget.GetTryDoorAnimation(m_Pawn, TryDoorUsageSide);
		AnimSpecialChannel = m_Pawn.AnimPlaySpecial(AnimName);
		
		if (bPeekDoor && !SwatDoorTarget.IsLocked())
		{
			//check door is free
			if ( SwatDoorTarget.GetPendingInteractor() == None )
			{
			
				//book door opening
				SwatDoorTarget.SetPendingInteractor(m_Pawn);	
			
				while (frame < 0.30)
				{
					m_Pawn.GetAnimParams(AnimSpecialChannel,AnimName,frame,rate);
					yield();
				}
			
				if (SwatDoorTarget.ActorIsToMyLeft(m_Pawn))
					SwatDoorTarget.SetPositionForMove(DoorPosition_PartialOpenRight, MR_Interacted); 
				else 
					SwatDoorTarget.SetPositionForMove(DoorPosition_PartialOpenLeft, MR_Interacted); 
		
				SwatDoorTarget.Moved();
			
			}
		}
		
		m_Pawn.FinishAnim(AnimSpecialChannel);
	}
}

function bool DoorIsLockable()
{
	local ISwatDoor SwatDoorTarget;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	return !SwatDoorTarget.IsBroken();
}

private function bool CanInteractWithTargetDoor()
{
	return (! TargetDoor.IsEmptyDoorWay() && TargetDoor.IsClosed() && !TargetDoor.IsOpening()  /*&& !ISwatDoor(TargetDoor).IsBroken()*/) || ISwatDoor(TargetDoor).isPartialOpen() ;
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	// test to see if we can interact with this door first
	if (CanInteractWithTargetDoor())
	{
		MoveToTryDoor();

		useResources(class'AI_Resource'.const.RU_LEGS);

		// test again to see if we can interact with this door
		if (!DoorIsLockable())
		{
			ReportResultsToTeam();
		}
		else if (ISwatDoor(TargetDoor).isPartialOpen() ) //it's open...
		{
			ReportResultsToTeam();
		}
		else if (CanInteractWithTargetDoor() && ! ISwatDoor(TargetDoor).isPartialOpen() )
		{
			// keep us facing the correct direction
			ISwatAI(m_Pawn).AimToRotation(TryDoorUsageRotation);
			ISwatAI(m_Pawn).LockAim();
			ISwatAI(m_Pawn).AnimSnapBaseToAim();

			TryDoor();

			ISwatAI(m_Pawn).UnlockAim();

			// re-enable collision avoidance
			m_Pawn.EnableCollisionAvoidance();
			ReportResultsToTeam();
			
			if (!bPeekDoor || TargetDoor.IsLocked() )
				ReportPossibleTrap();
		}
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'TryDoorGoal'
}
