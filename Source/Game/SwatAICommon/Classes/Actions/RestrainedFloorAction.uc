///////////////////////////////////////////////////////////////////////////////
// RestrainedFloorAction.uc - CowerAction class

class RestrainedFloorAction extends LookAtOfficersActionBase;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables
var(parameters)	Pawn	Restrainer;	// pawn that we will be working with



// behaviors we use
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private bool FoundRotation;

// config variables
const kPostRestrainedGoalPriority      = 94;

function cleanup()
{
	super.cleanup();
	
	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// State code


latent function PlayFloorAnimation()
{
	local int IdleChannel;
	
	IdleChannel = m_Pawn.AnimPlaySpecial('CuffedFloor', 0.2);    
	
	if ( frand() < 0.5 )
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerRestrainedSpeech();
	
	m_Pawn.FinishAnim(IdleChannel);
	
	ISwatAI(m_Pawn).SetIdleCategory('RestrainedFloor');
	
	// swap in the restrained anim set
	ISwatAI(m_Pawn).SwapInRestrainedFloorAnimSet();
	
	m_Pawn.ChangeAnimation();
	
	StopLookingAtOfficers();
	
	while (class'Pawn'.static.checkConscious(m_Pawn))
	{
		sleep(1.0);
		// don't move while being restrained
		m_Pawn.DisableCollisionAvoidance();
	}
}

// rotate to the rotation that is the opposite of the restrainer's rotation
function RotateToRestrainablePosition()
{
	local Rotator DesiredRestrainRotation;
	local vector StartVect,EndVect;
	local rotator GoodRot;
	local int YawRot;
	 
	while ( YawRot < 65536 && !FoundRotation) 
	{
		GoodRot = m_Pawn.Rotation;
		GoodRot.Yaw = GoodRot.Yaw + YawRot;
		
		StartVect= m_Pawn.Location;
		EndVect= StartVect + vector(GoodRot)*80;
		
	    if ( m_pawn.FastTrace(EndVect,StartVect) )
		{
			//Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
			
			//second trace at floor level
			StartVect.Z=StartVect.Z-50;
			EndVect.Z=EndVect.Z-50;
			if ( m_pawn.FastTrace(EndVect,StartVect) )
			{
				//Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
				
				//third trace for stairs
				EndVect.Z=EndVect.Z-40;
				if ( !m_pawn.FastTrace(EndVect,StartVect) ) //if I catch something it's good
				{
					//Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
					FoundRotation = true;
				}
			}
		}
		
		YawRot = YawRot + 3276;
	}
	FoundRotation = true; //make sure to end anyway!
	
	DesiredRestrainRotation = GoodRot; 
	//DesiredRestrainRotation.Yaw += GoodRot.Yaw; 
	
	
		
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.Priority, DesiredRestrainRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);

	// make sure the rotation is set and lock it
	ISwatAI(m_Pawn).AimToRotation(DesiredRestrainRotation);
	ISwatAI(m_Pawn).LockAim();
	
}


state Running
{
 Begin:
	 
	// don't move while being restrained
	m_Pawn.DisableCollisionAvoidance();
		
	if (achievingGoal.priority != kPostRestrainedGoalPriority)
	{
		// set the priority lower now so that any higher priority goal 
		// (incapacitation, stunned, injury) will take over
		achievingGoal.changePriority(kPostRestrainedGoalPriority);
		ClearDummyGoals();
	}
	 
	while (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);
	
	if (!FoundRotation)
		RotateToRestrainablePosition();

	PlayFloorAnimation();
	
	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
	
	succeed();
	
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'RestrainedFloorGoal'
}
