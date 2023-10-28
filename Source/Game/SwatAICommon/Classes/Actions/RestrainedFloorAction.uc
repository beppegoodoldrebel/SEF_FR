///////////////////////////////////////////////////////////////////////////////
// RestrainedFloorAction.uc - CowerAction class

class RestrainedFloorAction extends LookAtOfficersActionBase;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables
var(parameters)	Pawn	Restrainer;	// pawn that we will be working with

// behaviors we use
//var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
//var private bool FoundRotation;
//var private Rotator DesiredRestrainRotation;

// config variables
const kPostRestrainedGoalPriority      = 90;

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);
}

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}


function cleanup()
{
	super.cleanup();
	
}


///////////////////////////////////////////////////////////////////////////////
//
// State code


latent function PlayFloorAnimation()
{
	local int IdleChannel;
	
	//if ( ISwatAI(m_Pawn).GetIdleCategory() != 'RestrainedFloor')
	//{		
		IdleChannel = m_Pawn.AnimPlaySpecial('CuffedFloor', 0.1 , '', 0.8);    
	
		if ( frand() < 0.5 )
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerRestrainedSpeech();
	
		//m_Pawn.FinishAnim(IdleChannel);
		m_pawn.AnimFinishSpecial();
		m_Pawn.AnimStopSpecial();
		
		// swap in the restrained anim set
		if (ISwatAI(m_Pawn).GetIdleCategory() != 'RestrainedFloor' )
		{
			ISwatAI(m_Pawn).SetIdleCategory('RestrainedFloor');
			ISwatAI(m_Pawn).SwapInRestrainedFloorAnimSet();
		}
		
		
		//m_Pawn.ChangeAnimation();
	//}
	
	StopLookingAtOfficers();
	
}

/*

// rotate to the rotation that is the opposite of the restrainer's rotation
latent function RotateToRestrainablePosition()
{
	local vector StartVect,EndVect;
	local rotator GoodRot;
	local int YawRot , MaxIter;
	 	 
	while ( YawRot < 65536 && !FoundRotation && MaxIter < 10) 
	{
		MaxIter= MaxIter + 1;
		GoodRot = m_pawn.Rotation;
		GoodRot.Yaw = GoodRot.Yaw + YawRot;
		
		StartVect= m_Pawn.Location;
		EndVect= StartVect + vector(GoodRot)*80;
		
	    if ( m_pawn.FastTrace(EndVect,StartVect) )
		{
			Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
			
			//second trace at floor level
			StartVect.Z=StartVect.Z-50;
			EndVect.Z=EndVect.Z-50;
			if ( m_pawn.FastTrace(EndVect,StartVect) )
			{
				Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
				
				//third trace for stairs
				EndVect.Z=EndVect.Z-40;
				if ( !m_pawn.FastTrace(EndVect,StartVect) ) //if I catch something it's good
				{
					Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
					FoundRotation = true;
				}
			}
		}
		
		YawRot = YawRot + 3276;
	}
	FoundRotation = true; //make sure to end anyway!
	
	Level.GetLocalPlayerController().myHUD.AddDebugLine(m_pawn.Location, m_pawn.Location + vector(GoodRot)*80 , class'Engine.Canvas'.Static.MakeColor(0,255,0));
	DesiredRestrainRotation = rotator ( m_pawn.Location  - ( m_pawn.Location + vector(GoodRot)*80 ) ) ; 
	
	if (CurrentRotateTowardRotationGoal != None)
	{
	
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(),achievingGoal.priority, DesiredRestrainRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	
	WaitForGoal(CurrentRotateTowardRotationGoal);
	}
	
	if (CurrentRotateTowardRotationGoal != None)
	{
	CurrentRotateTowardRotationGoal.unPostGoal(self);
	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
	}
}

function CheckObstacleInFront()
{
	local vector StartVect,EndVect;
	
	StartVect= m_Pawn.Location;
	EndVect= StartVect + vector(m_pawn.Rotation)*100;
	
	Level.GetLocalPlayerController().myHUD.AddDebugLine(StartVect, EndVect, class'Engine.Canvas'.Static.MakeColor(255,0,0));
	
	if ( !m_pawn.FastTrace(EndVect,StartVect) )
	{
		//muoviti indietro
		m_pawn.SetCollisionSize(200,20);
	}
	
}
*/

state Running
{
 Begin:
	 	
		
	if (ISwatAI(m_Pawn).GetIdleCategory() != 'RestrainedFloor' )//sanitize
	{
		
	// don't move while being restrained
	m_Pawn.DisableCollisionAvoidance();	
		
	m_Pawn.AnimStopSpecial();
	
	PlayFloorAnimation();
	m_Pawn.SetPhysics(PHYS_Karma); //dont move, ever egain...
	
	}
	
	while (class'Pawn'.static.checkConscious(m_Pawn))
	{
		sleep(10.0);
		// don't move while being restrained
		m_Pawn.DisableCollisionAvoidance();
	}
	
	
	succeed();
	
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'RestrainedFloorGoal'
}
