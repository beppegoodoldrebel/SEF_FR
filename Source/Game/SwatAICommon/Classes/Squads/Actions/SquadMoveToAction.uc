///////////////////////////////////////////////////////////////////////////////
// SquadMoveToAction.uc - SquadMoveToAction class
// this action is used to organize the Officer's MoveTo behavior

class SquadMoveToAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) vector			Destination;

// behaviors we use
var private array<MoveToGoal>	MoveToGoals;
var private array<MoveInFormationGoal>	MoveInFormationGoals;
var private Formation					ClearFormation;

// internal
var private LevelInfo			Level;

const kMinDistanceToReplyToOrder = 100.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	ClearOutMoveToGoals();
	ClearFormationGoals();
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
	
	
	
}
private function ClearFormationGoals()
{
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
}
///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our move to goals fail, we succeed so we don't get reposted!
	if (goal.IsA('MoveToGoal'))
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////

latent function MoveOfficersToDestination()
{
	local int PawnIterIndex, MoveToIndex , MoveInFormIndex;
	local Pawn PawnIter , ShieldOfficer;
	local NavigationPoint ClosestPointToDestination;
	local name DestinationRoomName;
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	
	DestinationRoomName       = SwatAIRepo.GetClosestRoomNameToPoint(Destination, CommandGiver);
	yield();

	// find the closest navigation point, but don't use any doors
	ClosestPointToDestination = SwatAIRepo.GetClosestNavigationPointInRoom(DestinationRoomName, Destination,,,'Door');
	assert(ClosestPointToDestination != None);
	yield();

	if (resource.pawn().logTyrion)
		log(Name $ " - DestinationRoomName is: " $ DestinationRoomName $ " ClosestPointToDestination: " $ ClosestPointToDestination $ " Destination: " $ Destination);
/*
	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		MoveToGoals[MoveToIndex] = new class'MoveToGoal'(AI_Resource(PawnIter.characterAI), ClosestPointToDestination);
		assert(MoveToGoals[MoveToIndex] != None);
		MoveToGoals[MoveToIndex].AddRef();
			
		MoveToGoals[MoveToIndex].PostGoal(self);

		++MoveToIndex;
	}
*/
	ShieldOfficer = GetFirstShieldOfficer();
	if ( ShieldOfficer == None )
			ShieldOfficer = GetClosestOfficerTo(ClosestPointToDestination,false,true);
	
	ClearFormation = new class'Formation'(ShieldOfficer);
	ClearFormation.AddRef();
	ISwatOfficer(ShieldOfficer).SetCurrentFormation(ClearFormation);
	
	
	
	if ( ShieldOfficer != None )
	{
		ShieldOfficer.DisableCollisionAvoidance(); //make possible to stay close to shield guy
			
		MoveToGoals[MoveToIndex] = new class'MoveToGoal'(AI_Resource(ShieldOfficer.characterAI), ClosestPointToDestination);
		assert(MoveToGoals[MoveToIndex] != None);
		MoveToGoals[MoveToIndex].AddRef();
			
		MoveToGoals[MoveToIndex].PostGoal(self);
		++MoveToIndex;
		
		while ( ShieldOfficer != GetClosestOfficerTo(ClosestPointToDestination, false, true) )
			sleep(1.0); //give shield officer time to move upfront
	}
	

	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		if ( PawnIter == ShieldOfficer )
		{
			/*
			PawnIter.DisableCollisionAvoidance(); //make possible to stay close to shield guy
			
			MoveToGoals[MoveToIndex] = new class'MoveToGoal'(AI_Resource(PawnIter.characterAI), ClosestPointToDestination);
			assert(MoveToGoals[MoveToIndex] != None);
			MoveToGoals[MoveToIndex].AddRef();
			
			MoveToGoals[MoveToIndex].PostGoal(self);
			++MoveToIndex;
			*/
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

	waitForAllGoalsInList(MoveToGoals);
	
	ShieldOfficer.EnableCollisionAvoidance(); //re-enable collision
	
	// cleanup!
	ClearOutMoveToGoals();
	
	//wait for the whole team to be in formation
	while( !AllSquadInFormation(ShieldOfficer) )
		yield();
	
	ClearFormationGoals();
}

function TriggerRepliedMoveToSpeech()
{
	local Pawn FirstOfficer;

	FirstOfficer = GetFirstOfficer();
	if (VSize2D(Destination - FirstOfficer.Location) > kMinDistanceToReplyToOrder)
	{
		ISwatOfficer(FirstOfficer).GetOfficerSpeechManagerAction().TriggerRepliedMoveToSpeech();
	}
}

function TriggerCompletedMoveToSpeech()
{
	ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerCompletedMoveToSpeech();
}

state Running
{
Begin:
	Level = resource.pawn().Level;
	assert(Level != None);
		
	TriggerRepliedMoveToSpeech();

	WaitForZulu();

	MoveOfficersToDestination();

	TriggerCompletedMoveToSpeech();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadMoveToGoal'
}