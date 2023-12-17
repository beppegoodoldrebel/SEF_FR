class Referendum extends Engine.Actor
  abstract;
import enum EMPMode from Engine.Repo;

var config bool bNoImmunity; // Ignores immunity
var config bool bUseTeam;
var PlayerController CallerPC;
var PlayerReplicationInfo CallerPRI;
var PlayerController TargetPC;
var String TargetStr;
var PlayerReplicationInfo TargetPRI;
var EMPMode NewGameType;

replication
{
  reliable if(bNetDirty && (Role == ROLE_Authority))
    CallerPC, CallerPRI, TargetPC, TargetStr, TargetPRI;
}

simulated function String ReferendumDescription();
function ReferendumDecided(bool YesVotesWin);

function InitializeReferendum(PlayerController Caller, optional PlayerController Target, optional string TargetStr_, optional EMPMode GameType )
{
  CallerPC = Caller;
  if(CallerPC != None)
  {
    CallerPRI = CallerPC.PlayerReplicationInfo;
  }
  TargetPC = Target;
  TargetStr = TargetStr_;
  NewGameType = GameType;
  
  if(TargetPC != None)
  {
    TargetPRI = TargetPC.PlayerReplicationInfo;
  }
}

function bool ReferendumCanBeCalledOnTarget(PlayerController Caller, PlayerController Target)
{
  return true;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true
}
