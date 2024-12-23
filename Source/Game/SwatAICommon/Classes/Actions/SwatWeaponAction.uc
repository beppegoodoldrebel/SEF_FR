///////////////////////////////////////////////////////////////////////////////
// SwatWeaponAction.uc - SwatWeaponAction class
// The base Action class for all Swat Tyrion Weapon Actions

class SwatWeaponAction extends Tyrion.AI_WeaponAction
	native
    dependson(ISwatEnemy);
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;
import enum AIEquipment from ISwatAICharacter;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var protected LevelInfo Level;
var protected Pawn		m_pawn;

const kLowSkillLevelErrorAngle    = 0.2079;     // 12 degrees
const kMediumSkillLevelErrorAngle = 0.1392;     // 8  degrees
const kHighSkillLevelErrorAngle   = 0.0698;     // 4  degrees

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	m_Pawn = AI_WeaponResource(r).m_pawn;
    assert(m_Pawn != None);

	Level = m_Pawn.Level;
	assert(Level != None);

    super.initAction(r, goal);
}

///////////////////////////////////////////////////////////////////////////////
//
// Accuracy

// @TODO: Crombie
// currently just for enemies! 
// UPDATE: Not used for now!
function vector GetAimSpot(vector vTargetLocation, vector vProjStart)
{
    local vector vAimSpot;

    vAimSpot  = vTargetLocation;
    vAimSpot += GetSkillLevelAimErrorOffset(vTargetLocation, vProjStart);    

    return vAimSpot;
}

function vector GetSkillLevelAimErrorOffset(vector vTargetLocation, vector vProjStart)
{
    local float TargetDistance, OffsetRadius, OffsetAngle;
    local vector vSkillLevelAimErrorOffset;

    OffsetAngle    = GetOffsetAngleForEnemy(ISwatEnemy(m_Pawn).GetEnemySkill());
    TargetDistance = VSize(vTargetLocation - vProjStart);
    OffsetRadius   = sin(OffsetAngle) * TargetDistance;

    vSkillLevelAimErrorOffset = VRand() * (OffsetRadius * FRand());
    return vSkillLevelAimErrorOffset;
}

function float GetOffsetAngleForEnemy(EnemySkill EnemySkill)
{
    switch(EnemySkill)
    {
        case EnemySkill_Low:
            return kLowSkillLevelErrorAngle;
        case EnemySkill_Medium:
            return kMediumSkillLevelErrorAngle;
        case EnemySkill_High:
            return kHighSkillLevelErrorAngle;
        default:
            assert(false);
            return 0.0;
    }
}

function bool HasWeaponEquipped()
{
	assert(m_Pawn != None);

	return (m_Pawn.GetActiveItem() != None);
}

///////////////////////////////////////////////////////////////////////////////
//
// Random Aiming

latent function AimAndHoldAtPoint(vector Point, float MinPauseTime, float MaxPauseTime)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        LatentAimAtPoint(Point);

        sleep(RandRange(MinPauseTime, MaxPauseTime));
    }
	else
	{
		warn(m_Pawn.Name $ " cannot aim " $ m_Pawn.GetActiveItem() $ " at Point: " $ Point);
	}
}

final latent function LatentAimAtPoint(vector Point)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        ISwatAI(m_pawn).AimAtPoint(Point);

        // wait until we aim at what we want to and have a weapon equipped
        while ((! ISwatAI(m_pawn).AnimIsAimedAtDesired() && HasWeaponEquipped()) ||
			    ISwatAI(m_Pawn).AnimAreAimingChannelsMuted())
        {
//			log("aiming at point update - AnimIsAimedAtDesired: " $ ISwatAI(m_pawn).AnimIsAimedAtDesired() $ " HasWeaponEquipped: " $ HasWeaponEquipped() $ " AnimAreAimingChannelsMuted: " $ ISwatAI(m_Pawn).AnimAreAimingChannelsMuted());

            yield();
        }
    }
	else
	{
		warn(m_Pawn.Name $ " cannot aim " $ m_Pawn.GetActiveItem() $ " at Point: " $ Point);
	}
}

final function AimAtPoint(vector Point)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        ISwatAI(m_pawn).AimAtPoint(Point);
    }
}

static function bool IsAThreatBasedOnAim(Pawn PotentialThreat, Pawn Target)
{
	local HandheldEquipment ActiveItem;
	assert(PotentialThreat != None);

	// if the potential threat does not have a weapon, he's not a threat
	ActiveItem = PotentialThreat.GetActiveItem();
	if ((ActiveItem == None) || ! ActiveItem.IsA('FiredWeapon'))
		return false;

	if (Target.IsA('Pawn'))
	{
		return true;
	}
	else
	{
		return false;
	}
}

final function UpdateThreatToTarget(Actor Target)
{
	local Pawn TargetPawn;

	TargetPawn = Pawn(Target);

	// only update threat if both source and target are alive
	if (class'Pawn'.static.checkConscious(m_Pawn) && class'Pawn'.static.checkConscious(TargetPawn) && class'SwatWeaponAction'.static.IsAThreatBasedOnAim(m_Pawn, TargetPawn))
	{
		if (m_Pawn.IsA('SwatEnemy') && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}

		if (TargetPawn.IsA('SwatAI'))
		{
			// we let the target pawn's threat sensor know that we're trying to aim at them!
			SwatCharacterResource(TargetPawn.characterAI).ThreatenedSensorAction.UpdateThreatFrom(m_Pawn);
		}
	}
}

final latent function LatentAimAtActor(Actor Target, optional float MaxWaitTime)
{
    // only aim at if if we can
	//local float CurrentTime;
	local float StartTime;
	local float fdot;
	local vector TargetDirection , ViewDirectionNoZ;

	StartTime = Level.TimeSeconds;

    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Target) && HasWeaponEquipped())
    {
		// added here so server can spread information on suspect intentions before even aiming.
//		if ( Level.NetMode != NM_Standalone )
//		{
			if( m_pawn.isa('SwatEnemy') || m_pawn.isa('SwatOfficer') )
			{
				UpdateThreatToTarget(Target);
				yield();
			}
//		}
		//////////////////////////////
		
        //ISwatAI(m_pawn).AimAtActor(Target);
		if ( ( target.isa('SwatPawn') || target.isa('SwatPlayer') ) && !m_pawn.GetActiveItem().isa('Pepperspray') )
		{
			
			//add time to avoid quickscope shooting
			TargetDirection = Normal( m_pawn.location - target.location);
			ViewDirectionNoZ = vector(m_pawn.Rotation);
			fDot =  ViewDirectionNoZ Dot TargetDirection;
			//log (m_pawn.name $ " attacking " $ target.name $ " fdot is: " $ fdot );
			
			if ( m_pawn.isa('SwatEnemy') )
			{
				if ( fdot > 0.707 )
				{
					//log ( m_pawn.name $ " quick scope added time on target 0.8" );
					MaxWaitTime = MaxWaitTime + 0.8;
				}
				else if ( fdot > 0.0 && fdot <= 0.707 )
				{
					//log ( m_pawn.name $ " quick scope added time on target 0.4" );
					MaxWaitTime = MaxWaitTime + 0.6;
				}
				else if ( fdot > -0.707 && fdot <= 0.0 )
				{
					//log ( m_pawn.name $ " quick scope added time on target 0.2" );
					MaxWaitTime = MaxWaitTime + 0.4;
				}
			}
		}
	    
		ISwatAI(m_pawn).AimAtActor(Target);
		
        // wait until we aim at what we want to
        while ( 
				//0.68 removed any aim check... just wait the right time to do it
				//(!ISwatAI(m_pawn).AnimIsAimedAtDesired() && 
		        // !m_Pawn.CanshootTarget(Target) && 
				// HasWeaponEquipped()) || //|| ISwatAI(m_Pawn).AnimAreAimingChannelsMuted() 
			     ( ( Level.TimeSeconds - StartTime ) <= MaxWaitTime  ) )
        {
//			log("aiming at actor update - AnimIsAimedAtDesired: " $ ISwatAI(m_pawn).AnimIsAimedAtDesired() $ " HasWeaponEquipped: " $ HasWeaponEquipped() $ " AnimAreAimingChannelsMuted: " $ ISwatAI(m_Pawn).AnimAreAimingChannelsMuted());
			// See if we have waited past the threshold
			UpdateThreatToTarget(Target);
            yield();
        }
    }
}

final function AimAtActor(Actor Target)
{
	if (Target != None) // possible bug fixing
	{
		if (ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Target))
        {
			
			ISwatAI(m_pawn).AimAtActor(Target);
		}
	}
}

latent function SetGunDirection( Actor Target ) // possible bug fixer
{
    local rotator rDirection;
    local vector  vDirection;
    local Coords  cTarget;
    local vector  vTarget;

    if( Target != none)
    {
		if (m_Pawn.IsA('SwatEnemy') && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
			yield();
		}
		UpdateThreatToTarget(Target);
		
		
		//if ( !AimHead )	
			cTarget = Target.GetBoneCoords('Bip01_Spine2');
		//else
		//	cTarget = Target.GetBoneCoords('Bip01_Head');
		
		vTarget = cTarget.Origin;

        // Find the pitch between the gun and the target
        vDirection = vTarget - m_pawn.Location;
        rDirection = rotator(vDirection);

        //m_pawn.m_wWantedAimingPitch = rDirection.Pitch/256;
        //m_pawn.m_rFiringRotation = rDirection;
		ISwatAI(m_pawn).AimToRotation(rDirection);
    }
}
///////////////////////////////////////////////////////////////////////////////
//
// Firing

// Function provides basic use of the weapon
// currently just for SwatEnemy
latent function ShootWeaponAt(Actor Target)
{
    local FiredWeapon CurrentWeapon;
	local float DistanceFromTarget;
	local vector EndTrace;

	assertWithDescription((Target != None), "SwatWeaponAction::ShootWeaponAt - Target is None!");
	assertWithDescription((m_Pawn != None), "SwatWeaponAction::ShootWeaponAt - m_Pawn is None!");

    CurrentWeapon = FiredWeapon(m_pawn.GetActiveItem());    


	if(CurrentWeapon.bAbleToMelee && CurrentWeapon!= None && CurrentWeapon.HasMeleeAnimation() )
	{
		DistanceFromTarget = Vsize( m_Pawn.Location - Target.Location ) ;
		
		if( DistanceFromTarget < 150  ) //melee range = 150 
		{		
			/*
			if (m_Pawn.IsA('SwatOfficer') ) 
			{
				if (! SwatAIRepository(Level.AIRepo).IsOfficerMovingAndClearing(m_Pawn)) //when clearing just shoot , too late for hands!
				{
					if ( !CurrentWeapon.IsLessLethal() ) //no need to punch when less lethal
					{
						if (FRand() < 0.1 ) //chance of meleeing
						{
							CurrentWeapon.Melee();
							sleep(2.0); //wait for melee to finish
							return; //officers always just melee instead of shooting , as trained professionals!
						}
					}
				}
			}
			else 
			*/
			if (m_Pawn.IsA('SwatEnemy')  && !ISwatAICharacter(m_Pawn).IsFemale() ) //women cant melee cause missing animations
			{
				if (FRand() < 0.1 ) //chance of meleeing
				{
					CurrentWeapon.Melee();
					sleep(2.0); //wait for melee to finish
					
						return; 					
				}
			}
		}
	}
		
    // if the weapon's not empty, use it
	if (CurrentWeapon!= None && !CurrentWeapon.IsEmpty())
    {
		
		if (m_pawn.IsA('SwatOfficer') )
		{
			EndTrace = Target.Location;
			//Level.GetLocalPlayerController().myHUD.AddDebugLine(m_pawn.GetEyeLocation(),Pawn(Target).GetChestLocation(),	class'Engine.Canvas'.Static.MakeColor(0,0,255), 15.0);
			if (CurrentWeapon.WillOfficerAvoidBadShot(Target, !CurrentWeapon.bIsLessLethal, EndTrace , true) ) //make sure Officers will avoid unintended casualties as trained professionals
			{ 
			  ISwatAI(m_Pawn).SetWeaponTarget(Target);
			  CurrentWeapon.LatentUse();
			}
			//else
			//Level.GetLocalPlayerController().myHUD.AddDebugLine(m_pawn.GetEyeLocation(),Pawn(Target).GetChestLocation(),	class'Engine.Canvas'.Static.MakeColor(255,0,0), 15.0);
		}
		else
		{
			ISwatAI(m_Pawn).SetWeaponTarget(Target);
			CurrentWeapon.LatentUse();
		}
//		log("finished shooting at time " $ m_Pawn.Level.TimeSeconds);
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Switching

function FiredWeapon GetBackupWeapon()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		return ISwatEnemy(m_Pawn).GetBackupWeapon();
	}
	else
	{
		assert(m_Pawn.IsA('SwatOfficer'));

		return ISwatOfficer(m_Pawn).GetBackupWeapon();
	}
}

function FiredWeapon GetPrimaryWeapon()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		return ISwatEnemy(m_Pawn).GetPrimaryWeapon();
	}
	else
	{
		assert(m_Pawn.IsA('SwatOfficer'));

		return ISwatOfficer(m_Pawn).GetPrimaryWeapon();
	}
}

function FiredWeapon GetOtherWeapon()
{
	local FiredWeapon CurrentWeapon, PrimaryWeapon;

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
	PrimaryWeapon = GetPrimaryWeapon();

	if (CurrentWeapon == PrimaryWeapon)
		return GetBackupWeapon();
	else
		return PrimaryWeapon; 
}


latent function SwitchWeapons()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatEnemy(m_Pawn).ThrowWeaponDown();
        ISwatAICharacter(m_Pawn).SetDesiredAIEquipment( AIE_Backup );
	}

	GetBackupWeapon().LatentWaitForIdleAndEquip();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
