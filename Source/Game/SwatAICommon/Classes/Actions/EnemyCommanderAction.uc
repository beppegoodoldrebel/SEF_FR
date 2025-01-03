///////////////////////////////////////////////////////////////////////////////
// EnemyCommanderAction.uc - the CommanderAction class
// the Enemy commander organizes the Enemy AIs behaviors, and responds to stimuli

class EnemyCommanderAction extends CommanderAction
	native
	dependson(ISwatEnemy);
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;
import enum EnemyState from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private Pawn								CurrentEnemy;
var private Pawn								OldEnemy;
var private InitialReactionGoal					CurrentInitialReactionGoal;
var private Timer								LostPawnTimer;

var private bool								bHasHadInitialReactionChance;
var private bool								bWasSurprised;
var private bool								bReceivedUsableWeaponsMoralePenalty;
var private bool								bHasFledWithoutUsableWeapon;
var private bool								bIgnoreCurrentEnemy;

var private Door								LastBlockedDoor;			// the door that last blocked us
var private int									BlockedDoorCount;			// how many times we've been blocked by the last blocked door
var config int									MaxBlockedDoorCount;		// the maximum number of times we will be blocked by a door before we barricade

// behaviors we use
var private InvestigateGoal						CurrentInvestigateGoal;
var private BarricadeGoal						CurrentBarricadeGoal;
var private EngageOfficerGoal					CurrentEngageOfficerGoal;
var private ConverseWithHostagesGoal			CurrentConverseWithHostagesGoal;
var private PickUpWeaponGoal					CurrentPickUpWeaponGoal;
var private AttackTargetGoal					CurrentAttackTargetGoal;

var private bool bAlreadyComplied;

var bool Unused1;
var float Unused2;
var float Unused3;
var float Unused4;
var float Unused5;
var float Unused6;
var float Unused7;
var float Unused8;
var float Unused9;
var float Unused10;
var float Unused11;
var float Unused12;
var float Unused13;
var float Unused14;
var float Unused15;
var float Unused16;
var float Unused17;
var float Unused18;
var float Unused19;
var float Unused20;
var float Unused21;
var float Unused22;
var float Unused23;
var float Unused24;
var float Unused25;
var float Unused26;
var float Unused27;
var float Unused28;
var float Unused29;
var float Unused30;
var float Unused31;
var float Unused32;
var float Unused33;
var float Unused34;
var float Unused35;
var float Unused36;
var float Unused37;
var float Unused38;
var float Unused39;
var float Unused40;
var float Unused41;
var float Unused42;
var float Unused43;
var float Unused44;
var float Unused45;
var float Unused46;
var float Unused47;
var float Unused48;
var float Unused49;
var float Unused50;
var float Unused51;
var float Unused52;


/*
// Initial Reaction variables

var config float								LowSkillInitialReactionChance;
var config float                                MediumSkillInitialReactionChance;
var config float                                HighSkillInitialReactionChance;

var config float								MinDistanceToOfficersToDoInitialReaction;

var config float								LowSkillScreamChance;
var config float                                MediumSkillScreamChance;
var config float                                HighSkillScreamChance;

// Morale variables

var config float                                SurprisedComplianceAngle;*/
var private float                               SurprisedComplianceDotProduct;/*
var config float                                MaxSurprisedComplianceDistance;
var config float                                LowSkillSurprisedComplianceMoraleModification;
var config float                                MediumSkillSurprisedComplianceMoraleModification;
var config float                                HighSkillSurprisedComplianceMoraleModification;

var config float								LowSkillWeaponDroppedMoraleModification;
var config float								MediumSkillWeaponDroppedMoraleModification;
var config float								HighSkillWeaponDroppedMoraleModification;

var config float								LowSkillFlashbangedMoraleModification;
var config float								MediumSkillFlashbangedMoraleModification;
var config float								HighSkillFlashbangedMoraleModification;

var config float								LowSkillGassedMoraleModification;
var config float								MediumSkillGassedMoraleModification;
var config float								HighSkillGassedMoraleModification;

var config float								LowSkillPepperSprayedMoraleModification;
var config float								MediumSkillPepperSprayedMoraleModification;
var config float								HighSkillPepperSprayedMoraleModification;

var config float								LowSkillStungMoraleModification;
var config float								MediumSkillStungMoraleModification;
var config float								HighSkillStungMoraleModification;

var config float								LowSkillTasedMoraleModification;
var config float								MediumSkillTasedMoraleModification;
var config float								HighSkillTasedMoraleModification;

var config float								LowSkillStunnedByC2MoraleModification;
var config float								MediumSkillStunnedByC2MoraleModification;
var config float								HighSkillStunnedByC2MoraleModification;

var config float								LowSkillShotMoraleModification;
var config float								MediumSkillShotMoraleModification;
var config float								HighSkillShotMoraleModification;

var config float								LowSkillKilledOfficerMoraleModification;
var config float								MediumSkillKilledOfficerMoraleModification;
var config float								HighSkillKilledOfficerMoraleModification;

var config float								LowSkillNearbyEnemyKilledMoraleModification;
var config float								MediumSkillNearbyEnemyKilledMoraleModification;
var config float								HighSkillNearbyEnemyKilledMoraleModification;

var config float								LowSkillOutOfUsableWeaponsMoraleModification;
var config float								MediumSkillOutOfUsableWeaponsMoraleModification;
var config float								HighSkillOutOfUsableWeaponsMoraleModification;

var config float								UnobservedComplianceMoraleModification;
var config float								LeaveCompliantStateMoraleThreshold;

// Engaging
var config float								DeltaDistanceToSwitchEnemies;

var config float								LowSkillReactToThrownGrenadeChance;
var config float								MediumSkillReactToThrownGrenadeChance;
var config float								HighSkillReactToThrownGrenadeChance;

var config float								MinLostPawnDeltaTime;
var config float								MaxLostPawnDeltaTime;
*/
// Constants
const kRotateToSuspiciousNoisePriority = 55;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	SurprisedComplianceDotProduct = cos(class'EnemyCommanderActionConfig'.default.SurprisedComplianceAngle / 2.0 * DEGREES_TO_RADIANS);
//	log("SurprisedComplianceDotProduct is "$SurprisedComplianceDotProduct);

	// enemies use the comply sensor
	ActivateComplySensor();

	// enemies have morale
	InitializeMorale();

	// set up automatic reloading
	// disabled for now because it may be causing an assertion when interrupted
//	SetupAutomaticReloading();

	// set up hostage conversing
	SetupHostageConversing();
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentInitialReactionGoal != None)
	{
		CurrentInitialReactionGoal.release();
		CurrentInitialReactionGoal = None;
	}

	if (CurrentInvestigateGoal != None)
	{
		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}

	if (CurrentBarricadeGoal != None)
	{
		CurrentBarricadeGoal.Release();
		CurrentBarricadeGoal = None;
	}

	if (CurrentEngageOfficerGoal != None)
	{
		CurrentEngageOfficerGoal.Release();
		CurrentEngageOfficerGoal = None;
	}

	if (CurrentConverseWithHostagesGoal != None)
	{
		CurrentConverseWithHostagesGoal.Release();
		CurrentConverseWithHostagesGoal = None;
	}

	if (CurrentPickUpWeaponGoal != None)
	{
		CurrentPickUpWeaponGoal.Release();
		CurrentPickUpWeaponGoal = None;
	}
	
	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}

	DeactivateLostPawnTimer();
}

// remove any non death goals for when we die or become incapacitated
function RemoveNonDeathGoals()
{
	super.RemoveNonDeathGoals();

	if (CurrentInitialReactionGoal != None)
	{
		CurrentInitialReactionGoal.unPostGoal(self);
		CurrentInitialReactionGoal.Release();
		CurrentInitialReactionGoal = None;
	}

	if (CurrentInvestigateGoal != None)
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}

	if (CurrentBarricadeGoal != None)
	{
		CurrentBarricadeGoal.unPostGoal(self);
		CurrentBarricadeGoal.Release();
		CurrentBarricadeGoal = None;
	}

	if (CurrentEngageOfficerGoal != None)
	{
		CurrentEngageOfficerGoal.unPostGoal(self);
		CurrentEngageOfficerGoal.Release();
		CurrentEngageOfficerGoal = None;
	}

	if (CurrentConverseWithHostagesGoal != None)
	{
		CurrentConverseWithHostagesGoal.unPostGoal(self);
		CurrentConverseWithHostagesGoal.Release();
		CurrentConverseWithHostagesGoal = None;
	}

	if (CurrentPickUpWeaponGoal != None)
	{
		CurrentPickUpWeaponGoal.unPostGoal(self);
		CurrentPickUpWeaponGoal.Release();
		CurrentPickUpWeaponGoal = None;
	}
	
	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
	
	
}

// prevent the AI from doing anything
function DisableAI()
{
	m_Pawn.SetPhysics(PHYS_None);				// stop physics
	m_Pawn.bHidden = true;						// make invisible
	m_Pawn.setCollision( false, false, false );	// disable collisions

	RemoveGoalsToDie();							// remove goals
	DisableSensingSystems();					// disable sensing
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

// TODO: verify this is the correct way to make the compliance behavior the only
// exclusive-like character behavior running
function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (goal == CurrentEngageOfficerGoal)
	{
		CurrentEngageOfficerGoal.unPostGoal(self);
		CurrentEngageOfficerGoal.Release();
		CurrentEngageOfficerGoal = None;
	}
	else if (goal == CurrentBarricadeGoal)
	{
		CurrentBarricadeGoal.unPostGoal(self);
		CurrentBarricadeGoal.Release();
		CurrentBarricadeGoal = None;
	}
	else if (goal == CurrentInvestigateGoal)
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}
	else if (goal == CurrentInitialReactionGoal)
	{
		CurrentInitialReactionGoal.unPostGoal(self);
		CurrentInitialReactionGoal.Release();
		CurrentInitialReactionGoal = None;
	}
	else if (goal == CurrentPickUpWeaponGoal)
	{
		CurrentPickUpWeaponGoal.unPostGoal(self);
		CurrentPickUpWeaponGoal.Release();
		CurrentPickUpWeaponGoal = None;
	}
	else if (goal == CurrentAttackTargetGoal)
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
}

protected function bool ShouldRemoveFailedPatrolGoal()
{
	return ((CurrentInvestigateGoal == None) || ISwatEnemy(m_Pawn).GetCurrentState() == EnemyState_Aware);
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function Pawn GetCurrentEnemy()
{
	return CurrentEnemy;
}

///////////////////////////////////////////////////////////////////////////////
//
// Conversing with Hostages

private function SetupHostageConversing()
{
	CurrentConverseWithHostagesGoal = new class'ConverseWithHostagesGoal'(characterResource());
	assert(CurrentConverseWithHostagesGoal != None);
	CurrentConverseWithHostagesGoal.AddRef();

	CurrentConverseWithHostagesGoal.postGoal(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// Stunning functions

function float GetFlashbangedMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillFlashbangedMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillFlashbangedMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillFlashbangedMoraleModification;
	}
}

function float GetGassedMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillGassedMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillGassedMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillGassedMoraleModification;
	}
}

function float GetPepperSprayedMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillPepperSprayedMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillPepperSprayedMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillPepperSprayedMoraleModification;
	}
}

function float GetStungMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillStungMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillStungMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillStungMoraleModification;
	}
}

function float GetTasedMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillTasedMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillTasedMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillTasedMoraleModification;
	}
}

function float GetStunnedByC2DetonationMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillStunnedByC2MoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillStunnedByC2MoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillStunnedByC2MoraleModification;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Shot functions

function float GetShotMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillShotMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillShotMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillShotMoraleModification;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Dropping

private function float GetWeaponDroppedMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillWeaponDroppedMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillWeaponDroppedMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillWeaponDroppedMoraleModification;
	}
}

function NotifyWeaponDropped()
{
	// change morale
	ChangeMorale(- GetWeaponDroppedMoraleModification(), "Dropped weapon");

	// remove any existing engage behaviors -- allows us to re-evaluate
	InterruptCurrentEngagement();
}

///////////////////////////////////////////////////////////////////////////////
//
// Other Morale Modifications

private function float GetKilledOfficerMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillKilledOfficerMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillKilledOfficerMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillKilledOfficerMoraleModification;
	}
}

function NotifyKilledOfficer(Pawn Officer)
{
	assert(Officer != None);

	ChangeMorale(GetKilledOfficerMoraleModification(), "Killed " $ Officer.Name);
}


private function float GetNearbyEnemyKilledMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillNearbyEnemyKilledMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillNearbyEnemyKilledMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillNearbyEnemyKilledMoraleModification;
	}
}

function NotifyNearbyEnemyKilled(Pawn NearbyEnemy, Pawn Officer)
{
	assert(NearbyEnemy != None);

	if (Officer != None)
	{
		ChangeMorale(- GetNearbyEnemyKilledMoraleModification(), "Nearby Enemy " $ NearbyEnemy.Name $ " Killed By " $ Officer.Name);
	// do some speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDownedSuspectSpeech();
	}
	else
	{
		ChangeMorale(- GetNearbyEnemyKilledMoraleModification(), "Nearby Enemy " $ NearbyEnemy.Name $ " Killed By an inanimate object");
	// do some speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDownedSuspectSpeech();
	}
}

private function float GetOutOfWeaponsMoraleModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillOutOfUsableWeaponsMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillOutOfUsableWeaponsMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillOutOfUsableWeaponsMoraleModification;
	}
}

// determine whether we're out of ammo for all of our weapons
// if we are we get a morale penalty
private function CheckOutOfUsableWeapons()
{
	if (! bReceivedUsableWeaponsMoralePenalty && ! ISwatAI(m_Pawn).HasUsableWeapon())
	{
		bReceivedUsableWeaponsMoralePenalty = true;

		ChangeMorale(- GetOutOfWeaponsMoraleModification(), "Has no usable weapons!");
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// Senses

// overridden completely from normal implementation found in CommanderAction so Enemies can use hearing when compliant or restrained
protected function DisableSensingSystems()
{
	// we don't need awareness
	ISwatAI(m_Pawn).DisableAwareness();

	// disable vision permanently
	ISwatAI(m_Pawn).DisableVision(true);
}


///////////////////////////////////////////////////////////////////////////////
//
// Vision Response

// we have seen an Enemy of ours.  Deal with it!
function OnPawnEncounteredVisionNotification()
{
	local Pawn Enemy;
	
	//assert( m_pawn.CanHitTarget(VisionSensor.LastPawnSeen) );
	
	if (VisionSensor.LastPawnSeen != None)
	{
		Enemy = VisionSensor.LastPawnSeen;
	}
	else
	{
		assert(VisionSensor.LastPawnLost != none);

		Enemy = VisionSensor.LastPawnSeen;
	}

	DeactivateLostPawnTimer();

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " OnPawnEncounteredVisionNotification - VisionSensor.LastPawnSeen: " $ VisionSensor.LastPawnSeen $ " LostPawnTimer: " $ LostPawnTimer $ " CurrentEnemy: " $CurrentEnemy);

	EncounterEnemy(Enemy);
	
}

function OnPawnLostVisionNotification()
{
	assert(VisionSensor.LastPawnLost != None);

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " OnPawnLostVisionNotification - VisionSensor.LastPawnLost: " $ VisionSensor.LastPawnLost $ " CurrentEnemy: " $CurrentEnemy);

	// if who we're dealing with now (if anyone) matches up with the last person we lost
	if (CurrentEnemy == VisionSensor.LastPawnLost)
	{
		if (!IsRunningAway() /*&& ! IsTakingCover()*/ && !IsThreateningHostage())
		{
			if ((GetBetterEnemy() != None) && (GetBetterEnemy() != CurrentEnemy))
			{
				InterruptCurrentEngagement();
			}
			else
			{
				ActivateLostPawnTimer();
			}
		}
	}
}

private function ActivateLostPawnTimer()
{
	if (LostPawnTimer == None)
	{
		LostPawnTimer = m_Pawn.Spawn(class'Timer');
		LostPawnTimer.timerDelegate = LostPawnTimerTriggered;
		LostPawnTimer.startTimer(RandRange(class'EnemyCommanderActionConfig'.default.MinLostPawnDeltaTime, class'EnemyCommanderActionConfig'.default.MaxLostPawnDeltaTime));
	}
}

private function DeactivateLostPawnTimer()
{
	if (LostPawnTimer != None)
	{
		LostPawnTimer.stopTimer();
		LostPawnTimer.timerDelegate = None;
		LostPawnTimer.Destroy();
		LostPawnTimer = None;
	}
}

function LostPawnTimerTriggered()
{
	if (m_Pawn.logAI)
		log("LostPawnTimerTriggered - removing any engage or initial reaction behaviors and setting CurrentEnemy to None");

	assert(LostPawnTimer != None);
	DeactivateLostPawnTimer();

	SetCurrentEnemy(None);

	InterruptCurrentEngagement();
}

function NotifyEnemyShotByEnemy(Pawn EnemyShot, float Damage, Pawn EnemyInstigator)
{
	assert(EnemyInstigator != None);
	assert(EnemyShot != None);

	TriggerShotAFriendSpeech(EnemyInstigator);
}

private function TriggerShotAFriendSpeech(Pawn EnemyInstigator)
{
	ISwatEnemy(EnemyInstigator).GetEnemySpeechManagerAction().TriggerShotAFriendSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// Hearing Response

private function bool DoesSoundCauseUsToKnowAboutPawn(name inSoundCategory)
{
	return (inSoundCategory == 'OfficerYelling');
}

private function bool DoWeKnowAboutPawn(Pawn inPawn)
{
	return ISwatAI(m_Pawn).GetKnowledge().HasKnownKnowledgeAboutPawn(inPawn);
}

function OnHeardNoise()
{
	local Actor HeardActor;
	local Pawn HeardPawn;
	local Pawn LastDoorInteractor;
	local name SoundCategory;
	local vector SoundOrigin;
	local float Distance;

	HeardActor    = HearingSensor.LastSoundMaker;
	SoundCategory = HearingSensor.LastSoundHeardCategory;
	SoundOrigin   = HearingSensor.LastSoundHeardOrigin;

	// if the heard actor is a fired weapon mode (an officer or player's gun),
	// and we have a line of sight to the weapon, react to the pawn
	if (HeardActor.IsA('FiredWeaponModel'))
	{
		HeardPawn = Pawn(FiredWeaponModel(HeardActor).HandheldEquipment.Owner);
	}
	else if (HeardActor.IsA('Ammunition'))
	{
		// the owner's owner of ammunition is a pawn
		HeardPawn = Pawn(HeardActor.Owner.Owner);
	}
	else
	{
		HeardPawn = Pawn(HeardActor);
	}

	if (m_Pawn.logTyrion)
		HearingSensor.DebugHearingSensorToLog();

//	log("OnHeardNoise - HeardActor: " $ HeardActor $ " SoundCategory: " $ SoundCategory $ " HeardPawn: " $ HeardPawn);

	if (m_Pawn.IsCompliant() || m_Pawn.IsArrested())
	{
		if (HeardActor.IsA('Ammunition') && (VSize(HeardActor.Location - m_Pawn.Location) < MinReactToGunshotDistance) && m_Pawn.LineOfSightTo(HeardActor))
		{
			PlayFlinch();
		}
	}
	else
	{
		if ( isDeadlyNoise(SoundCategory))
		{
			
			if ((HeardPawn != None)  //
				&& ISwatAI(m_Pawn).IsOtherActorAThreat(HeardPawn) 
				&& !m_Pawn.IsA('SwatGuard')
				)
			{
				
				if ( m_Pawn.LineOfSightTo(HeardPawn) || DoWeKnowAboutPawn(HeardPawn) )
				{//		log(m_Pawn.Name $ " going to encounter enemy");
					
					ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);
					EncounterEnemy(HeardPawn);
				}
				else
				{
					if (frand () < GetInvestigateSoundChance() )
						BecomeSuspicious(SoundOrigin,false,false); //investigate only
					else
						BecomeSuspicious(SoundOrigin,true,false); //barricade only
				}
			}
				
		}
		else	
		{
			Distance = VSize(HeardActor.Location - m_Pawn.Location);
			if ((HeardPawn != None) && 
			//ISwatAI(m_Pawn).IsOtherActorAThreat(HeardPawn) &&
			(DoesSoundCauseUsToKnowAboutPawn(SoundCategory) || DoWeKnowAboutPawn(HeardPawn)))
			{
				
				if ( m_Pawn.LineOfSightTo(HeardPawn) || Distance < 400  ) //sound sixth sense in close range
				{
					//		log(m_Pawn.Name $ " going to encounter enemy");
					ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);
					EncounterEnemy(HeardPawn);
					return;
				}
				else 
				{
					if ( Distance < 800 )
					{
					  ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);
					  RotateToFaceNoise(HeardPawn);
					  return;
					}
				}
			}
		

			if (SoundCategory == 'Footsteps')
			{
				HandleFootstepNoise(HeardPawn, SoundOrigin);
			}
			else if (SoundCategory == 'DoorInteraction')
			{
				assertWithDescription((HeardActor.IsA('SwatDoor')), "EnemyCommanderAction::OnHeardNoise - sound played by " $ HeardActor $ " with the Sound category 'DoorInteraction' is not a door!");

				LastDoorInteractor = ISwatDoor(HeardActor).GetLastInteractor();

				// if the other actor isn't a threat to us, ignore the door sound
				// yes this is cheating...  so sue me.
				if (ISwatAI(m_Pawn).IsOtherActorAThreat(LastDoorInteractor) && HasLineOfSightToDoor(Door(HeardActor)))
				{
					if (ISwatEnemy(m_Pawn).GetCurrentState() == EnemyState_Aware)
					{
						EncounterEnemy(LastDoorInteractor);
					}
					else
					{
						BecomeSuspicious(SoundOrigin);
					}
				}
			}
			else if (CurrentEnemy == None)	// if we're not currently pursuing an enemy, watch out
			{
				//log(m_Pawn.Name $ " becoming suspicious - HeardPawn is a sniper: " $ ((HeardPawn != None) && HeardPawn.IsA('SniperPawn')));

				// if we heard sniper fire, we shouldn't investigate, otherwise we let BecomeSuspicious determine what we should do
				BecomeSuspicious(SoundOrigin, ((HeardPawn != None) && HeardPawn.IsA('SniperPawn')));
			}
		
		}
	}
}

private function BecomeSuspicious(vector SuspiciousEventOrigin, optional bool bOnlyBarricade , optional bool bOnlyInvestigate)
{
	local bool bInvestigate;
	local bool bBarricade;

	if (ISwatEnemy(m_Pawn).GetCurrentState() < EnemyState_Suspicious)
	{
		// we are now suspicious
		ISwatEnemy(m_Pawn).SetCurrentState(EnemyState_Suspicious);
	}

	// if we're not actively engaging, investigate or barricade
	if (! isRunning())
	{
		bInvestigate = ISwatEnemy(m_Pawn).RollInvestigate();
		bBarricade = ISwatEnemy(m_Pawn).RollBarricade();

		// if we're not investigating or barricading, do that
		// if we're already invesgigating or barricading, and can fast trace to the point specified, look at the point
		if ( ( bInvestigate || bOnlyInvestigate ) && !bOnlyBarricade && ((CurrentInvestigateGoal == None) || CurrentInvestigateGoal.hasCompleted()))
		{
			if ( ( Vsize( SuspiciousEventOrigin - m_Pawn.Location ) < 800 ) )
				CreateInvestigateGoal(SuspiciousEventOrigin);
			else
				RotateToRotation(rotator(SuspiciousEventOrigin - m_Pawn.Location), kRotateToSuspiciousNoisePriority);
		}
		else if ((bOnlyBarricade || bBarricade) && ((CurrentBarricadeGoal == None) || CurrentBarricadeGoal.hasCompleted()))
		{
			ISwatEnemy(m_Pawn).StopInvestigating();	// don't investigate after we've already concluded that SWAT is here
			CreateBarricadeGoal(SuspiciousEventOrigin, true, true);
		}
		else if (m_Pawn.FastTrace(SuspiciousEventOrigin, m_Pawn.Location))
		{
			RotateToRotation(rotator(SuspiciousEventOrigin - m_Pawn.Location), kRotateToSuspiciousNoisePriority);
		}
	}
}

// If the footsteps were made within the specified distance by an officer or the player,
// become suspicious if we aren't already, or become aware of the Heard pawn if we're Aware
private function HandleFootstepNoise(Pawn HeardPawn, vector FootstepSoundOrigin)
{
//	log(m_Pawn.Name $ " HandleFootstepNoise - HeardPawn: " $ HeardPawn $ " FootstepSoundOrigin: " $ FootstepSoundOrigin);

	if ((HeardPawn != None) && (HeardPawn.IsA('SwatOfficer') || HeardPawn.IsA('SwatPlayer')))
	{
//		log("distance to footstep noise: " $ VSize(HeardPawn.Location - m_Pawn.Location) $ " GetMinHeardOfficerFootstepsDistance: " $ GetMinHeardOfficerFootstepsDistance());

		if (CurrentEnemy != None)
		{
			ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);

			// EncounterEnemy will take care of engaging this enemy instead of the one we're currently facing
			EncounterEnemy(HeardPawn);
		}
		else
		{
			BecomeSuspicious(FootstepSoundOrigin);
		}
	}
}

private function RotateToFaceNoise(Actor NoisyActor)
{
	assert(NoisyActor != None);

//	log(m_Pawn.Name $ " RotateToFaceNoise - NoisyActor: " $ NoisyActor $ " LineOfSightTo: " $ m_Pawn.LineOfSightTo(NoisyActor) $ " FastTrace: " $ m_Pawn.FastTrace(NoisyActor.Location));

	// just aim if we're moving, rotate if not
	if (VSize(m_Pawn.Velocity) > 0.0)
	{
		if ((CurrentAimAtTargetGoal == None) || CurrentAimAtTargetGoal.hasCompleted())
		{
			AimAtTarget(NoisyActor, 55, true, class'EnemyCommanderActionConfig'.default.MinAimAtNoiseWhileMovingTime, class'EnemyCommanderActionConfig'.default.MaxAimAtNoiseWhileMovingTime);
		}
	}
	else
	{
		// if we aren't rotating or have finished rotating, rotate to face the heard pawn
		if ((CurrentRotateTowardActorGoal == None) || CurrentRotateTowardActorGoal.hasCompleted())
		{
			RotateToFace(NoisyActor, 55);
		}
	}
}

private function float GetScreamChance()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillScreamChance;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillScreamChance;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillScreamChance;
	}
}

protected function bool ShouldScream()
{
	return (FRand() < GetScreamChance());
}

///////////////////////////////////////////////////////////////////////////////
//
// Compliance

function float GetSkillSpecificSurpriseComplianceModification()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillSurprisedComplianceMoraleModification;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillSurprisedComplianceMoraleModification;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillSurprisedComplianceMoraleModification;
	}
}

function float GetUnobservedComplianceMoraleModification()
{
	return class'EnemyCommanderActionConfig'.default.UnobservedComplianceMoraleModification;
}

function bool WasSurprised()
{
	if (bWasSurprised)
	{
		// we're no longer surprised!
		// Bad.....you are still surprised -J21C
		//bWasSurprised = false;
		return true;
	}
}

function bool CheckIfSurprisedByEnemy(Pawn Enemy)
{
	local vector EnemyDirectionNoZ, ViewDirectionNoZ;
    local float fDot, fDistanceToEnemy;

	fDistanceToEnemy = VSize(m_Pawn.Location - Enemy.Location);

	if (fDistanceToEnemy < class'EnemyCommanderActionConfig'.default.MaxSurprisedComplianceDistance)
	{
		EnemyDirectionNoZ   = Normal(Enemy.Location - m_Pawn.Location);
		EnemyDirectionNoZ.Z = 0.0;
		ViewDirectionNoZ    = vector(ISwatAI(m_Pawn).GetAimOrientation());
		ViewDirectionNoZ.Z  = 0.0;

		// this is a 2d calculation
		fDot = EnemyDirectionNoZ Dot ViewDirectionNoZ;

//		log("fDot: " $ fDot $ " SurprisedComplianceDotProduct: " $ SurprisedComplianceDotProduct);

		// check to see if we have been surprised
		if (fDot < SurprisedComplianceDotProduct)
		{
			bWasSurprised = true;
			return true;
		}
	}

	return false;
}

// allows subclasses to do things before we check for compliance
function PreComplianceCheck(Pawn ComplianceIssuer)
{
	assert(ComplianceIssuer != None);

    // we only do this check if we are unaware or suspicious
    // and if we're within the maximum distance to be surprised
    if (ISwatEnemy(m_Pawn).GetCurrentState() < EnemyState_Aware)
    {
        // we are now aware
        ISwatEnemy(m_Pawn).SetCurrentState(EnemyState_Aware);

		if (CheckIfSurprisedByEnemy(ComplianceIssuer))
		{
			ChangeMorale(- GetSkillSpecificSurpriseComplianceModification(), "Enemy surprised by "@ComplianceIssuer.Name);
        }
    }
}

function PostComplianceCheck(Pawn ComplianceIssuer, bool bWillComply)
{
	if (! bWillComply)
	{
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerUncompliantSpeech();
		EncounterEnemy(ComplianceIssuer);
	}
	else
	{
		if (CurrentAttackTargetGoal != None)
		{
			CurrentAttackTargetGoal.unPostGoal(self);
			CurrentAttackTargetGoal.Release();
			CurrentAttackTargetGoal = None;
		}
	}
}

protected function NotifyBecameCompliant()
{
	Super.NotifyBecameCompliant();

	SetCurrentEnemy(None);

	// remove the initial reaction goal engage officer goals right away
	if (CurrentInitialReactionGoal != None)
	{
		CurrentInitialReactionGoal.unPostGoal(self);
		CurrentInitialReactionGoal.Release();
		CurrentInitialReactionGoal = None;
	}

	if (CurrentEngageOfficerGoal != None)
	{
		CurrentEngageOfficerGoal.unPostGoal(self);
		CurrentEngageOfficerGoal.Release();
		CurrentEngageOfficerGoal = None;
	}

	if (CurrentInvestigateGoal != None)
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}

	if (CurrentBarricadeGoal != None)
	{
		CurrentBarricadeGoal.unPostGoal(self);
		CurrentBarricadeGoal.Release();
		CurrentBarricadeGoal = None;
	}

	if (CurrentConverseWithHostagesGoal != None)
	{
		CurrentConverseWithHostagesGoal.unPostGoal(self);
		CurrentConverseWithHostagesGoal.Release();
		CurrentConverseWithHostagesGoal = None;
	}

	if (CurrentPickUpWeaponGoal != None)
	{
		CurrentPickUpWeaponGoal.unPostGoal(self);
		CurrentPickUpWeaponGoal.Release();
		CurrentPickUpWeaponGoal = None;
	}

	// make sure the patrol goal goes away
	if (CurrentPatrolGoal != None)
	{
		CurrentPatrolGoal.unPostGoal(self);
		CurrentPatrolGoal.Release();
		CurrentPatrolGoal = None;
	}
	
	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Encounters / Engagement

// subclasses should override
protected function float GetSkillSpecificReactToThrownGrenadeChance()
{
	if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High)
	{
		return class'EnemyCommanderActionConfig'.default.HighSkillReactToThrownGrenadeChance;
	}
	else if (ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_Medium)
	{
		return class'EnemyCommanderActionConfig'.default.MediumSkillReactToThrownGrenadeChance;
	}
	else // == low skill
	{
		return class'EnemyCommanderActionConfig'.default.LowSkillReactToThrownGrenadeChance;
	}
}

protected function bool WillReactToGrenadeBeingThrown()
{
	return (FRand() < GetSkillSpecificReactToThrownGrenadeChance());
}

protected function bool IsTakingCover()
{
	return ((CurrentEngageOfficerGoal != None) &&
			(CurrentEngageOfficerGoal.achievingAction != None) &&
			CurrentEngageOfficerGoal.achievingAction.IsA('TakeCoverAction'));
}

protected function bool IsRunningAway()
{
	if ((CurrentEngageOfficerGoal != None) &&
		(CurrentEngageOfficerGoal.achievingAction != None))
	{
		return CurrentEngageOfficerGoal.achievingAction.IsA('FleeAction') || CurrentEngageOfficerGoal.achievingAction.IsA('RegroupAction');
	}

	return false;
}

protected function bool IsThreateningHostage()
{
	return ((CurrentEngageOfficerGoal != None) &&
			(CurrentEngageOfficerGoal.achievingAction != None) &&
			CurrentEngageOfficerGoal.achievingAction.IsA('ThreatenHostageAction'));
}

// return true if the new enemy is closer than the other enemy, or if we can hit the new enemy but not the old
// as well as within the distance to automatically encounter a new enemy
private function bool ShouldEncounterNewEnemy(Pawn NewEnemy)
{
	local float DistanceToCurrentEnemy, DistanceToNewEnemy;

	if ((CurrentEnemy != None) && (NewEnemy != CurrentEnemy))
	{
		DistanceToCurrentEnemy = VSize(CurrentEnemy.Location - m_Pawn.Location);
		DistanceToNewEnemy     = VSize(NewEnemy.Location - m_Pawn.Location);

		if (((DistanceToNewEnemy < DistanceToCurrentEnemy) && (DistanceToNewEnemy < class'EnemyCommanderActionConfig'.default.DeltaDistanceToSwitchEnemies)) ||
			(! m_Pawn.CanHit(CurrentEnemy) && m_Pawn.CanHit(NewEnemy)))
			//(! m_Pawn.CanSee(CurrentEnemy) && m_Pawn.CanSee(NewEnemy)))
		{
			return true;
		}
	}

	return false;
}

private function bool ShouldEncounterEnemy(Pawn Enemy)
{
	assert(Enemy != None);

	// debug info
	if (m_Pawn.logTyrion)
	{
		if (CurrentEngageOfficerGoal != None)
		{
			log(m_Pawn.Name $ " ShouldEncounterEnemy ("$Enemy.Name$") CurrentInitialReactionGoal: " $ CurrentInitialReactionGoal $ " CurrentEngageOfficerGoal.achievingAction: " $ CurrentEngageOfficerGoal.achievingAction);
		}
		else
		{
			log(m_Pawn.Name $ " ShouldEncounterEnemy ("$Enemy.Name$") CurrentInitialReactionGoal: " $ CurrentInitialReactionGoal $ " CurrentEngageOfficerGoal: " $ CurrentEngageOfficerGoal);
		}
	}

	// returns true if the Enemy is concious, and we're not dealing with someone else,
	// or if the new enemy is close enough that we should take another enemy
	return (class'Pawn'.static.checkConscious(Enemy) && !m_Pawn.IsCompliant() && !m_Pawn.IsArrested() &&
			(
			(CurrentEnemy == None) ||   													//true if no enemy
			((CurrentInitialReactionGoal == None) && (CurrentEngageOfficerGoal == None)) || //true if no business
		    ShouldEncounterNewEnemy(Enemy))											        //true if distance is ko
			 );
}

// another class can ask us to encounter an enemy
function EncounterEnemy(Pawn NewEnemy)
{
	if (ShouldEncounterEnemy(NewEnemy))
	{
		SetCurrentEnemy(NewEnemy);
		
			//a threat before the animation
		if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}	
		

		// we are now aware
        ISwatEnemy(m_Pawn).SetCurrentState(EnemyState_Aware);
		ISwatEnemy(m_Pawn).StopInvestigating(); // Don't investigate sounds after we've encountered an enemy

		// update knowledge about our current enemy
		ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(CurrentEnemy);

		// make sure the patrol goal goes away
		if (CurrentPatrolGoal != None)
		{
			CurrentPatrolGoal.unPostGoal(self);
			CurrentPatrolGoal.Release();
			CurrentPatrolGoal = None;
		}

		// remove the conversation goal
		if (CurrentConverseWithHostagesGoal != None)
		{
			CurrentConverseWithHostagesGoal.unPostGoal(self);
			CurrentConverseWithHostagesGoal.Release();
			CurrentConverseWithHostagesGoal = None;
		}

		// if we're idle, just start running
		// if we're engaging someone else, stop engaging them!
		if (isIdle() && (CurrentInitialReactionGoal == None))
		{
			runAction();
		}
		else if (CurrentEngageOfficerGoal != None)
		{
			CurrentEngageOfficerGoal.unPostGoal(self);
			CurrentEngageOfficerGoal.Release();
			CurrentEngageOfficerGoal = None;
		}
	}
}

function SetCurrentEnemy(Pawn NewEnemy)
{
	OldEnemy     = CurrentEnemy;
	CurrentEnemy = NewEnemy;
}

// if we don't have an enemy, we run our response behaviors
function NotifyTookHit()
{
	if ((CurrentEnemy == None) && !m_Pawn.IsCompliant() && !m_Pawn.IsArrested())
	{
		bIgnoreCurrentEnemy = true;

		if (isIdle())
			runAction();
	}
}

private function float GetInitialReactionChance()
{
	local EnemySkill CurrentEnemySkill;

    // @HACK: Special case, guards always want to have an initial reaction.
    // [darren]
    if (m_Pawn.IsA('SwatGuard'))
    {
        return 1.0;
    }
    else
    {
	    CurrentEnemySkill = ISwatEnemy(m_Pawn).GetEnemySkill();
	    switch(CurrentEnemySkill)
	    {
		    case EnemySkill_Low:
                return class'EnemyCommanderActionConfig'.default.LowSkillInitialReactionChance;
            case EnemySkill_Medium:
                return class'EnemyCommanderActionConfig'.default.MediumSkillInitialReactionChance;
            case EnemySkill_High:
                return class'EnemyCommanderActionConfig'.default.HighSkillInitialReactionChance;
            default:
                assert(false);
                return 0.0;
	    }
    }
}

private function float GetInvestigateSoundChance()
{
	local EnemySkill CurrentEnemySkill;

    // @HACK: Special case, guards always want to have an initial reaction.
    // [darren]
    if (m_Pawn.IsA('SwatGuard'))
    {
        return 0.0;
    }
    else
    {
	    CurrentEnemySkill = ISwatEnemy(m_Pawn).GetEnemySkill();
	    switch(CurrentEnemySkill)
	    {
		    case EnemySkill_Low:
                return class'EnemyCommanderActionConfig'.default.LowSkillInvestigateSoundChance;
            case EnemySkill_Medium:
                return class'EnemyCommanderActionConfig'.default.MediumSkillInvestigateSoundChance;
            case EnemySkill_High:
                return class'EnemyCommanderActionConfig'.default.HighSkillInvestigateSoundChance;
            default:
                assert(false);
                return 0.0;
	    }
    }
}



private function bool ShouldDoInitialReaction()
{
	local Hive HiveMind;

	// if we haven't had an initial reaction and the die roll is successful
	if (! bHasHadInitialReactionChance && (CurrentEnemy != None) && (FRand() <= GetInitialReactionChance()))
	{
		HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
		assert(HiveMind != None);

		// returns true if we are outside the required distance for playing the initial reaction
		return ! HiveMind.IsPawnWithinDistanceOfOfficers(m_Pawn, class'EnemyCommanderActionConfig'.default.MinDistanceToOfficersToDoInitialReaction, true);
	}
}

latent function ReactInitiallyToEnemy()
{
	assert(CurrentEnemy != None);

	CurrentInitialReactionGoal = new class'InitialReactionGoal'(AI_Resource(m_Pawn.characterAI), CurrentEnemy);
	assert(CurrentInitialReactionGoal != None);
	CurrentInitialReactionGoal.AddRef();

	// post and wait for the initial reaction behavior to uncomplete
	CurrentInitialReactionGoal.postGoal(self);
	WaitForGoal(CurrentInitialReactionGoal);

	if (CurrentInitialReactionGoal != None)
	{
		CurrentInitialReactionGoal.unPostGoal(self);

		CurrentInitialReactionGoal.Release();
		CurrentInitialReactionGoal = None;
	}
}

latent function EngageCurrentEnemy()
{
	
	if ( m_pawn.IsArrested() || IswatPawn(m_pawn).IsBeingArrestedNow() || !class'Pawn'.static.checkConscious(m_Pawn) )
	{
		//abort
		return;
	}
	
	//a threat before the animation
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
		yield();
	}	
		
	
	// If we had an engagement goal, drop it
	if(CurrentEngageOfficerGoal != None)
	{
		CurrentEngageOfficerGoal.unPostGoal(self);
		CurrentEngageOfficerGoal.Release();
		CurrentEngageOfficerGoal = None;
	}

	if ((CurrentEnemy != None) || bIgnoreCurrentEnemy)
	{
		CurrentEngageOfficerGoal = new class'EngageOfficerGoal'(AI_Resource(m_Pawn.characterAI));
		assert(CurrentEngageOfficerGoal != None);
		CurrentEngageOfficerGoal.AddRef();

		// post and wait for the engage officer behavior to complete
		CurrentEngageOfficerGoal.postGoal(self);
//		log("waiting for goal at time " $ Level.TimeSeconds);
		WaitForGoal(CurrentEngageOfficerGoal);
//		log("stop waiting for goal at time " $ Level.TimeSeconds);

		// we no longer should ignore the fact that we don't have an enemy
		bIgnoreCurrentEnemy = false;

		if (CurrentEngageOfficerGoal != None)
		{
			CurrentEngageOfficerGoal.unPostGoal(self);

			CurrentEngageOfficerGoal.Release();
			CurrentEngageOfficerGoal = None;
		}
	}
}


// interrupts and stops the current engage officer goal
// (hah! this function name rules.)
function InterruptCurrentEngagement()
{
	if ((CurrentEngageOfficerGoal != None) && (CurrentEngageOfficerGoal.achievingAction != None))
	{
		CurrentEngageOfficerGoal.achievingAction.instantFail(ACT_GENERAL_FAILURE);
	}

	if ((CurrentInitialReactionGoal != None) && (CurrentInitialReactionGoal.achievingAction != None))
	{
		CurrentInitialReactionGoal.achievingAction.instantFail(ACT_GENERAL_FAILURE);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Investigation / Barricading

function CreateInvestigateGoal(vector InvestigateLocation)
{
	// if there is an existing investigate goal, remove it so we can add a new one
	if (CurrentInvestigateGoal != None)
	{
		CurrentInvestigateGoal.unPostGoal(self);

		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}

	CurrentInvestigateGoal = new class'InvestigateGoal'(characterResource(), InvestigateLocation, true);
    assert(CurrentInvestigateGoal != None);
	CurrentInvestigateGoal.AddRef();

    CurrentInvestigateGoal.postGoal(self);
}

function CreateBarricadeGoal(vector StimuliOrigin, bool bAllowBarricadeDelay, bool bCanCloseDoors)
{
	// if there is an existing barricade goal, we don't want to add a new one
	if (CurrentBarricadeGoal == None)
	{
		CurrentBarricadeGoal = new class'BarricadeGoal'(AI_Resource(m_Pawn.characterAI), StimuliOrigin, bAllowBarricadeDelay, bCanCloseDoors);
		assert(CurrentBarricadeGoal != None);
		CurrentBarricadeGoal.AddRef();

		CurrentBarricadeGoal.postGoal(self);
	}
}

function CreatePickUpWeaponGoal(HandHeldEquipmentModel WeaponModel)
{
	if (CurrentPickUpWeaponGoal == None)
	{
		CurrentPickUpWeaponGoal = new class'PickUpWeaponGoal'(AI_Resource(m_Pawn.characterAI), WeaponModel);
		assert(CurrentPickUpWeaponGoal != None);
		CurrentPickUpWeaponGoal.AddRef();

		CurrentPickUpWeaponGoal.postGoal(self);
	}
}

function AttackEnemyWithWeapon(Actor Target)
{
		CurrentAttackTargetGoal = new class'AttackTargetGoal'(AI_Resource(m_Pawn.weaponAI), achievingGoal.priority, Target);
		assert(CurrentAttackTargetGoal != None);
		CurrentAttackTargetGoal.AddRef();

		CurrentAttackTargetGoal.SetOrderedToAttackTarget(true);
		CurrentAttackTargetGoal.SetHavePerfectAim(true);
		CurrentAttacktargetGoal.SetWaitTimeBeforeFiring(1.0f);
		CurrentAttackTargetGoal.postGoal(self);
}


// removes either the Barricade or Investigate goal
private function RemoveSuspiciousGoals()
{
	if (CurrentBarricadeGoal != None)
	{
		CurrentBarricadeGoal.unPostGoal(self);
		CurrentBarricadeGoal.Release();
		CurrentBarricadeGoal = None;
	}

	if (CurrentInvestigateGoal != None)
	{
		CurrentInvestigateGoal.unPostGoal(self);
		CurrentInvestigateGoal.Release();
		CurrentInvestigateGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

// if we find a wedged door
function NotifyDoorWedged(Door WedgedDoor)
{
	local ISwatDoor SD;
	local SwatAIRepository SwatAIRepo;
	local Controller C;
	local float Distance;
	local bool DoRemoveWedge;
	SD=ISwatDoor(WedgedDoor);

	//let the enemy remove wedges if they are high skill
    if( ISwatEnemy(m_Pawn).GetEnemySkill() == EnemySkill_High  && ( FRand() > 0.5 ) ) //  EnemySkill_High with 50% chance       
    {    
	   
		for (C = Level.ControllerList; C != none && !DoRemoveWedge ; C = C.nextController)
		{
			if (C.bIsPlayer)
			{
				Distance = VSize2D(WedgedDoor.Location - C.Location);
				if (Distance > 2000 ) //4000 estimated distance... to be tested!
					DoRemoveWedge=true;
			}

		}
		
		//DoRemoveWedge=true;
		
		// do remove wedge
		if (SD != None && DoRemoveWedge )
		{
		// do some speech
			ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDoorBlockedSpeech();
			
			if( !SD.IsLocked() ) //if door is not locked
			{	
				
				//actually remove the wedge from the door
				SD.EnemyRemoveWedge(m_Pawn);  
				
				//barricade after opening
				CreateBarricadeGoal(WedgedDoor.Location, false, false);
						
				//let officers know the wedge is gone. UpdateOfficersKnowledge()
				SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
				assert(SwatAIRepo != None);

				SwatAIRepo.NotifyOfficersDoorWedgeRemoved(WedgedDoor); 
			}
			else
			{
				//door is still locked anyway... just barricade!
				CreateBarricadeGoal(WedgedDoor.Location, false, false);
			}
		}
		
    }
    else // barricade!
	{ 
		// we're supposed to call down the chain
		super.NotifyDoorWedged(WedgedDoor);
		
		CreateBarricadeGoal(WedgedDoor.Location, false, false);
	}
}

// if we find a blocked door that is blocked by a player or officer, barricade!
// also, if we've been blocked by the same door for some time, stop engaging!
function NotifyDoorBlocked(Door BlockedDoor)
{
	// we're supposed to call down the chain
	super.NotifyDoorBlocked(BlockedDoor);

	if (ISwatDoor(BlockedDoor).WasBlockedBy('SwatOfficer') ||
		ISwatDoor(BlockedDoor).WasBlockedBy('SwatPlayer'))
	{
		// do some speech
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDoorBlockedSpeech();

		CreateBarricadeGoal(BlockedDoor.Location, false, false);
	}

	if (LastBlockedDoor == BlockedDoor)
	{
		BlockedDoorCount++;

		if (BlockedDoorCount >= MaxBlockedDoorCount)
		{
			if (CurrentEngageOfficerGoal != None)
			{
				CurrentEngageOfficerGoal.unPostGoal(self);
				CurrentEngageOfficerGoal.Release();
				CurrentEngageOfficerGoal = None;
			}

			CreateBarricadeGoal(BlockedDoor.Location, false, false);
		}
	}
	else
	{
		LastBlockedDoor  = BlockedDoor;
		BlockedDoorCount = 1;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Fleeing without a Usable Weapon

function bool HasFledWithoutUsableWeapon()
{
	return bHasFledWithoutUsableWeapon;
}

function SetHasFledWithoutUsableWeapon()
{
	bHasFledWithoutUsableWeapon = true;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function RespondToSeeingEnemy()
{
	// remove any suspicious goals
	RemoveSuspiciousGoals();

	// TODO: do we really need this, should this only happen if we don't have an initial reaction?
	if (! bHasHadInitialReactionChance && !bIgnoreCurrentEnemy)
	{
		// do some speech
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerOfficerEncounteredSpeech();
	}

	if (ShouldDoInitialReaction())
	{
		ReactInitiallyToEnemy();
	}

	// we now have had the chance to have an initial reaction,
	// we'll never have that chance again
	bHasHadInitialReactionChance = true;

	EngageCurrentEnemy();

	// check if we don't have any usable weapons left, if so we get a morale penalty
	CheckOutOfUsableWeapons();
}

function Pawn GetBetterEnemy()
{
	local Pawn BetterEnemy;

	BetterEnemy = VisionSensor.GetVisibleConsciousPawnClosestTo(m_Pawn.Location);

	return BetterEnemy;
}

function FindBetterEnemy()
{
	local Pawn NewEnemy;
	
	if (CurrentEnemy != None)
	{
		//if (! m_Pawn.CanSee(CurrentEnemy))
	    if (! m_Pawn.CanHit(CurrentEnemy))
		{
			NewEnemy = VisionSensor.GetVisibleConsciousPawnClosestTo(m_Pawn.Location);

			if ((NewEnemy != None) && (NewEnemy != CurrentEnemy))
			{
				EncounterEnemy(NewEnemy);
			}
		}

		if ((CurrentEnemy != None) && !CurrentEnemy.isConscious())
		{
			SetCurrentEnemy(None);
		}
	}
	
}

latent function FinishedEngagingEnemies()
{
	local AIKnowledge.KnowledgeAboutPawn OldEnemyKnowledge;
	local vector LastKnownLocation;

	// no visible enemies,
	assert(CurrentEnemy == None);

	if (ISwatAI(m_pawn).GetKnowledge().GetLastKnownKnowledgeAboutPawn(OldEnemy, OldEnemyKnowledge))
	{
		LastKnownLocation = OldEnemyKnowledge.Location;
	}
	else
	{
		LastKnownLocation = VisionSensor.LastLostPawnLocation;
	}

	while (!resource.requiredResourcesAvailable(class'BarricadeGoal'.static.GetDefaultPriority(), class'BarricadeGoal'.static.GetDefaultPriority()))
	{
		yield();
	}

	if (m_Pawn.logAI)
		log("FinishedEngagingEnemies - creating barricade goal!");

	CreateBarricadeGoal(LastKnownLocation, false, false);
}

function FinishedMovingEngageBehavior()
{
	if (!class'Pawn'.static.checkConscious(CurrentEnemy) || !m_Pawn.LineOfSightTo(CurrentEnemy))
	{
		SetCurrentEnemy(None);
	}
}

latent function DecideToStayCompliant()
{
	local HandHeldEquipmentModel FoundWeaponModel;

	log(name @ "DecideToStayCompliant: init check with morale:" @ GetCurrentMorale() );
	
	if(m_Pawn.IsA('SwatGuard') || m_Pawn.IsA('SwatUndercover'))
	{
		// Don't let guards or Jennings become uncompliant again, this is just dumb
		return;
	}

	while (class'Pawn'.static.checkConscious(m_Pawn) &&
			(GetCurrentMorale() < class'EnemyCommanderActionConfig'.default.LeaveCompliantStateMoraleThreshold || FoundWeaponModel == None))
	{
		// Sleep for a random amount of time for this "tick"
		// This might seem high, but keep in mind that half the values are going to be below this and the effect can stack.
		Sleep(FRand() * 2.0);

		// Increase moral when not being guarded (unobserved)
		if (ISwatAI(m_Pawn).IsUnobservedByOfficers())
			ChangeMorale( GetUnobservedComplianceMoraleModification(), "Unobserved Compliance" );
		
		if (GetCurrentMorale() >= class'EnemyCommanderActionConfig'.default.LeaveCompliantStateMoraleThreshold)
			FoundWeaponModel = ISwatEnemy(m_Pawn).FindNearbyWeaponModel();

		if (m_pawn.logTyrion)
			log(name @ "DecideToStayCompliant: morale now:" @ GetCurrentMorale());
		
	}

	if (FoundWeaponModel != None)
	{
		if (m_pawn.logTyrion)
			log(name @ "DecideToStayCompliant: FOUND WEAPON" @ FoundWeaponModel);

		// AI stopped being compliant
		ISwatAI(m_Pawn).SetIsCompliant(false);
		RemoveComplianceGoal();
        ISwatAICharacter(m_Pawn).SetCanBeArrested(false);

		// Reset AI (stop animating)
		m_pawn.ShouldCrouch(false);
		m_Pawn.ChangeAnimation();				// will swap in anim set
		ISwatAI(m_Pawn).SetIdleCategory('');	// remove compliance idles

		if (ISwatEnemy(m_Pawn).GetPrimaryWeapon() == None)
		{
			// necessary?
			while (!resource.requiredResourcesAvailable(class'PickUpWeaponGoal'.static.GetDefaultPriority(), class'PickUpWeaponGoal'.static.GetDefaultPriority()))
			{
				yield();
			}

			CreatePickUpWeaponGoal(FoundWeaponModel);
			if (CurrentPickUpWeaponGoal != None)
				WaitForGoal(CurrentPickUpWeaponGoal);
			//ISwatEnemy(m_Pawn).GetCommanderAction().CreateBarricadeGoal(???, false, false);
		}
	}
}

latent function AmbushCompliant()
{
	//we ambush officers!
	log("DecideToStayCompliant: AmbushCompliant() with morale:");
		
	// Sleep for a random amount of time for this "tick"
	Sleep(frand() * 20.0);
	
	if ( m_pawn.IsArrested() || IswatPawn(m_pawn).IsBeingArrestedNow() || !class'Pawn'.static.checkConscious(m_Pawn) )
	{
		//abort
		return;
	}
	
	// AI stopped being compliant
	ISwatAI(m_Pawn).SetIsCompliant(false);
	RemoveComplianceGoal();
	ISwatAICharacter(m_Pawn).SetCanBeArrested(false);

	// Reset AI (stop animating)
	m_pawn.ShouldCrouch(false);
	m_Pawn.ChangeAnimation();				// will swap in anim set
	ISwatAI(m_Pawn).SetIdleCategory('');	// remove compliance idles
	
	
	//a threat before the animation
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
		yield();
	}	
		
	
	//equip
	ISwatEnemy(m_Pawn).GetBackupWeapon().LatentWaitForIdleAndEquip();
	
	// try engaging again if not during arrest process...
	if (CurrentEngageOfficerGoal == None )
	{
		bHasFledWithoutUsableWeapon = false;	// don't cower except very rarely
				
		CurrentEngageOfficerGoal = new class'EngageOfficerGoal'(AI_Resource(m_Pawn.characterAI), 90);
		assert(CurrentEngageOfficerGoal != None);
		CurrentEngageOfficerGoal.AddRef();
		CurrentEngageOfficerGoal.postGoal(self);
		WaitForGoal(CurrentEngageOfficerGoal);		
	}
}

/*
private function CheckPawn()
{
	if ( m_pawn.IsArrested() || IswatPawn(m_pawn).IsBeingArrestedNow() || !class'Pawn'.static.checkConscious(m_Pawn) )
	{
		Level.GetLocalPlayerController().ConsoleMessage( " BUG! " $ m_pawn.name $ " - Restrained bug prevented! ");
		log(m_pawn.name $ " - Restrained bug prevented! ");
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
	}	
}
*/

state Running
{
 Begin:
	if (m_pawn.logTyrion)
		log(Name $ " paused at time " $ Level.TimeSeconds);

	// wait until something happens
	if (m_Pawn.IsCompliant())
	{
		
		if (CurrentAttackTargetGoal != None)
		{
			CurrentAttackTargetGoal.unPostGoal(self);
			CurrentAttackTargetGoal.Release();
			CurrentAttackTargetGoal = None;
		}
		
		if (CurrentEngageOfficerGoal != None)
		{
			CurrentEngageOfficerGoal.unPostGoal(self);

			CurrentEngageOfficerGoal.Release();
			CurrentEngageOfficerGoal = None;
		}
		
		if ( ISwatEnemy(m_Pawn).GetBackupWeapon() != None && !bAlreadyComplied && !ISwatPawn(m_pawn).IsBeingArrestedNow() && !m_pawn.IsArrested() ) //we just ambush once
			AmbushCompliant();
		else
			DecideToStayCompliant();
		
		bAlreadyComplied = true;
		
		yield();		// prevent runaway loop in rare case
		goto('Begin');
	}
	else
		pause();

	// wait one tick to allow information to disseminate (such as if we heard a noise, etc.)
	yield();

	if (m_pawn.logTyrion)
		log(Name $ " started running at time " $ Level.TimeSeconds);

	FindBetterEnemy();

	while ((CurrentEnemy != None) || bIgnoreCurrentEnemy)
	{
		if (m_Pawn.logTyrion)
			log("respond loop - CurrentEnemy: " $ CurrentEnemy);

		RespondToSeeingEnemy();

		FindBetterEnemy();

		yield();
	}

	// we have finished engaging enemies, so we should do something
	FinishedEngagingEnemies();

	if (m_Pawn.logAI)
		log(Name $ " is finished engaging at time " $ Level.TimeSeconds);

	goto('Begin');
}

///////////////////////////////////////////////////////////////////////////////
//
// Debug

private function string GetEnemyStateName()
{
    local EnemyState CurrentEnemyState;

    CurrentEnemyState = ISwatEnemy(m_Pawn).GetCurrentState();

    switch (CurrentEnemyState)
    {
        case EnemyState_Unaware:
            return "Unaware";
        case EnemyState_Suspicious:
            return "Suspicious";
        case EnemyState_Aware:
            return "Aware";
        default:
            assert(false);
            return "";
    }
}

private function string GetEnemySkillName()
{
    local EnemySkill Skill;

    Skill = ISwatEnemy(m_Pawn).GetEnemySkill();

    switch (Skill)
    {
        case EnemySkill_Low:
            return "Low";

        case EnemySkill_Medium:
            return "Medium";

        case EnemySkill_High:
            return "High";

        default:
            assert(false);
            return "";
    }
}

function SetSpecificDebugInfo()
{
    m_Pawn.AddDebugMessage(" ");

	m_Pawn.AddDebugMessage("Is A Threat:        "@ISwatEnemy(m_Pawn).IsAThreat(), class'Canvas'.Static.MakeColor(255,255,128));
    m_Pawn.AddDebugMessage("Enemy State:        "@GetEnemyStateName(), class'Canvas'.Static.MakeColor(255,255,128));
    m_Pawn.AddDebugMessage("Enemy Skill:        "@GetEnemySkillName(), class'Canvas'.Static.MakeColor(255,255,128));

    m_Pawn.AddDebugMessage(" ");

	m_Pawn.AddDebugMessage("Current Enemy:      "@CurrentEnemy);

	if (CurrentEnemy != None)
	{
		m_Pawn.AddDebugMessage("Can Hit Him:        "@m_Pawn.CanHitTarget(CurrentEnemy));
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
