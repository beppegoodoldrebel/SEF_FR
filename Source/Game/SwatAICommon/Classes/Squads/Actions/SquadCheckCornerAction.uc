///////////////////////////////////////////////////////////////////////////////
// SquadMirrorCornerAction.uc - SquadMirrorCornerAction class
// this action is used to organize the Officer's mirroring of corners

class SquadCheckCornerAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use

var private array<MoveToLocationGoal>	MoveToGoals;
var private array<MoveInFormationGoal>	MoveInFormationGoals;
var private Formation					ClearFormation;
var private array<CheckCornerGoal>	CurrentCheckCornerGoal;

// copied from our goal
var(parameters) Actor					TargetMirrorPoint;
var(parameters) vector                  CommandOrigin;
var(parameters) Pawn				    CommandGiver;

// internal
var private LevelInfo			Level;

const kMinDistanceToMirrorPoint = 100.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();
	
	ClearOutMoveToGoals();
}

private function ClearOutMoveToGoals()
{
	while (MoveToGoals.Length > 0)
	{
		if (MoveToGoals[0] != None)
		{
			MoveToGoals[0].Release();
			MoveToGoals[0] = None;
		}

		MoveToGoals.Remove(0, 1);
	}
	
	/*
	while (MoveInFormationGoals.Length > 0)
	{
		if (MoveInFormationGoals[0] != None)
		{
			MoveInFormationGoals[0].Release();
			MoveInFormationGoals[0] = None;
		}

		MoveInFormationGoals.Remove(0, 1);
	}
	*/
	while (CurrentCheckCornerGoal.Length > 0)
	{
		if (CurrentCheckCornerGoal[0] != None)
		{
			CurrentCheckCornerGoal[0].Release();
			CurrentCheckCornerGoal[0] = None;
		}

		CurrentCheckCornerGoal.Remove(0, 1);
	}
	
	
	/*
	// clear out the formation
	if (ClearFormation != None)
	{
		ClearFormation.Cleanup();
		ClearFormation.Release();
		ClearFormation = None;
	}
	*/
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our goals fail, we succeed so we don't get reposted!
	if (goal.IsA('CheckCornerGoal'))
	{
		instantSucceed();
	}
}
///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveOfficersToDestination()
{
	local int PawnIterIndex, MoveToIndex , MoveInFormIndex;
	local Pawn PawnIter , ShieldOfficer;
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	ShieldOfficer = GetFirstShieldOfficer();
	if ( ShieldOfficer == None )
		ShieldOfficer = GetClosestOfficerTo(TargetMirrorPoint, false, true);
	
	ClearFormation = new class'Formation'(ShieldOfficer);
	ClearFormation.AddRef();
	ISwatOfficer(ShieldOfficer).SetCurrentFormation(ClearFormation);
	
	if ( ShieldOfficer != None )
	{
		ShieldOfficer.DisableCollisionAvoidance(); //make possible to stay close to shield guy
			
		MoveToGoals[MoveToIndex] = new class'MoveToLocationGoal'(AI_Resource(ShieldOfficer.MovementAI),achievingGoal.priority,   ( IMirrorPoint(TargetMirrorPoint).GetMirroringFromPoint() + IMirrorPoint(TargetMirrorPoint).GetMirroringToPoint()) /2);
		assert(MoveToGoals[MoveToIndex] != None);
		MoveToGoals[MoveToIndex].AddRef();
		
		MoveToGoals[MoveToIndex].SetRotateTowardsPointsDuringMovement(true);
		MoveToGoals[MoveToIndex].SetShouldWalkEntireMove(false);
		MoveToGoals[MoveToIndex].SetWalkThreshold(450.0);

		
		MoveToGoals[MoveToIndex].PostGoal(self);
		++MoveToIndex;
		
		while ( ShieldOfficer != GetClosestOfficerTo(TargetMirrorPoint, false, true) )
			sleep(1.0); //give shield officer time to move upfront
	}
	

	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		if ( PawnIter == ShieldOfficer )
		{
			//do nothing
		}
		else
		{
			
			ClearFormation.AddMember(PawnIter);
			
			ISwatOfficer(PawnIter).SetCurrentFormation(ClearFormation);
			
			MoveInFormationGoals[MoveInFormIndex] = new class'MoveInFormationGoal'(AI_MovementResource(PawnIter.MovementAI));
			assert(MoveInFormationGoals[MoveInFormIndex] != None);
			MoveInFormationGoals[MoveInFormIndex].AddRef();
			
			// Let the aim around action perform the aiming and rotation for us
			MoveInFormationGoals[MoveInFormIndex].SetRotateTowardsPointsDuringMovement(true);
			MoveInFormationGoals[MoveInFormIndex].SetAcceptNearbyPath(true);
			MoveInFormationGoals[MoveInFormIndex].SetWalkThreshold(192.0);
			
			if ( ShieldOfficer != None )
				MoveInFormationGoals[MoveInFormIndex].SetMoveToThresholds(75.0,75.0,75.0);
			
			MoveInFormationGoals[MoveInFormIndex].PostGoal(self);

			++MoveInFormIndex;
		}
			
	}

	while ( Vsize(ShieldOfficer.Location - TargetMirrorPoint.location ) > kMinDistanceToMirrorPoint )
		 yield();
	
	
	waitForAllGoalsInList(MoveToGoals);

	ShieldOfficer.EnableCollisionAvoidance(); //re-enable collision
	
	// cleanup!
	//ClearOutMoveToGoals();
	
}

latent function CheckAroundCorner()
{
	local int PawnIterIndex;
	local Pawn Officer,PawnIter;
	
	Officer = GetClosestOfficerTo(TargetMirrorPoint, false, true);
	assert(Officer != None);
	
	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		if ( PawnIter == Officer )
		{
			CurrentCheckCornerGoal[PawnIterIndex] = new class'CheckCornerGoal'(AI_Resource(PawnIter.CharacterAI),TargetMirrorPoint,CommandOrigin);
			assert(CurrentCheckCornerGoal[PawnIterIndex] != None);
			CurrentCheckCornerGoal[PawnIterIndex].AddRef();
			CurrentCheckCornerGoal[PawnIterIndex].PostGoal(self);
		}
	}
	
	waitForAllGoalsInList(CurrentCheckCornerGoal);

		// cleanup!
	ClearOutMoveToGoals();
}

protected function TriggerCoverReplySpeech()
{
	local Pawn ClosestOfficerToCommandGiver;

	ClosestOfficerToCommandGiver = GetClosestOfficerTo(CommandGiver, false, false);

	if (ClosestOfficerToCommandGiver != None)
	{
		// trigger a generic reply
		ISwatOfficer(ClosestOfficerToCommandGiver).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
	}
}

// Tell the officer to say "Roger" etc
function TriggerSpeech()
{
	local Pawn ClosestOfficerToCommandGiver;

	ClosestOfficerToCommandGiver = GetClosestOfficerTo(CommandGiver, false, false);

	if (ClosestOfficerToCommandGiver != None)
	{
		// trigger a generic reply
		ISwatOfficer(ClosestOfficerToCommandGiver).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
	}
}

function bool IsSquadMovingForCover()
{
local int PawnIterIndex;
local Pawn PawnIter;	
	
	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];
		
		if ( VSize2D(PawnIter.Velocity) > 0)
			return true;
	}
	
	return false;
	
}

state Running
{
Begin:
	
	TriggerSpeech();
	MoveOfficersToDestination();

	WaitForZulu();

	TriggerCoverReplySpeech();
	CheckAroundCorner();
	
	while(IsSquadMovingForCover())
		yield();
	
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadCheckCornerGoal'
}