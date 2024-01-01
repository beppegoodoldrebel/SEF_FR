// ====================================================================
//  Class:  SwatGui.SwatMPLoadoutPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMPLoadoutPanel extends SwatLoadoutPanel
    ;

var array<class> ServerDisabledEquipment;

import enum EMPMode from Engine.Repo;

///////////////////////////
// Initialization & Page Delegates
///////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	SwatGuiController(Controller).SetMPLoadoutPanel(self);
}

function EvaluateServerDisabledEquipment()
{
	local ServerSettings Settings;
	local array<string> SplitString;
	local int i;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

	ServerDisabledEquipment.Length = 0;

	Split(Settings.DisabledEquipment, ",", SplitString);
	for(i = 0; i < SplitString.Length; i++)
	{
		if(SplitString[i] == "")
		{
			continue;
		}
		ServerDisabledEquipment[ServerDisabledEquipment.Length] = class<Equipment>(DynamicLoadObject(SplitString[i], class'Class'));
	}
}

function LoadMultiPlayerLoadout()
{
    //create the loadout & send to the server, then destroy it
    SpawnLoadouts();
    DestroyLoadouts();
}

protected function SpawnLoadouts()
{
	EvaluateServerDisabledEquipment();
    LoadLoadOut( "CurrentMultiplayerLoadOut", true );
}

protected function DestroyLoadouts()
{
    if( MyCurrentLoadOut != None )
        MyCurrentLoadOut.destroy();
    MyCurrentLoadOut = None;
}

///////////////////////////
//Utility functions used for managing loadouts
///////////////////////////
function LoadLoadOut( String loadOutName, optional bool bForceSpawn )
{
    Super.LoadLoadOut( loadOutName, bForceSpawn );

//    MyCurrentLoadOut.ValidateLoadOutSpec();
    SwatGUIController(Controller).SetMPLoadOut( MyCurrentLoadOut );
}

function SaveCurrentLoadout() {
  SaveLoadOut( "CurrentMultiPlayerLoadout" );
}

function ChangeLoadOut( Pocket thePocket )
{
    local class<actor> theItem;
//log("[dkaplan] changing loadout for pocket "$GetEnum(Pocket,thePocket) );
    Super.ChangeLoadOut( thePocket );
    SaveCurrentLoadout(); //save to current loadout

    switch (thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_PrimaryAmmo:
            SwatGUIController(Controller).SetMPLoadOutPocketWeapon( Pocket_PrimaryWeapon, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_PrimaryWeapon], MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_PrimaryAmmo] );
            break;
        case Pocket_SecondaryWeapon:
        case Pocket_SecondaryAmmo:
            SwatGUIController(Controller).SetMPLoadOutPocketWeapon( Pocket_SecondaryWeapon, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_SecondaryWeapon], MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_SecondaryAmmo] );
            break;
		    case Pocket_CustomSkin:
			      SwatGUIController(Controller).SetMPLoadOutPocketCustomSkin( Pocket_CustomSkin, String(EquipmentList[thePocket].GetObject()) );
			      break;
        default:
            theItem = class<actor>(EquipmentList[thePocket].GetObject());
            SwatGUIController(Controller).SetMPLoadOutPocketItem( thePocket, theItem );
            break;
    }
}

protected function MagazineCountChange(GUIComponent Sender) {
  local GUINumericEdit SenderEdit;
  SenderEdit = GUINumericEdit(Sender);

  Super.MagazineCountChange(Sender);

  if(ActivePocket == Pocket_PrimaryWeapon) {
    SwatGUIController(Controller).SetMPLoadoutPrimaryAmmo(SenderEdit.Value);
  } else if(ActivePocket == Pocket_SecondaryWeapon) {
    SwatGUIController(Controller).SetMPLoadoutSecondaryAmmo(SenderEdit.Value);
  }

  SaveCurrentLoadout();
}


function bool CheckValidity( class EquipmentClass, eNetworkValidity type )
{
	local int i;
	local int CampaignPath;
	local ServerSettings Settings;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
	
	CampaignPath = Settings.CampaignCOOP & 65535;
	
	
	if (Settings.IsCampaignCOOP() && CampaignPath == 3 && !Settings.bIsQMM) //FR campaign mode
	{
		//forget about skins
		if( Left(string(EquipmentClass),4) != "Swat")
		 return true;
			
	    // unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment.Length; ++i)
		{
			if(class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
			{
				return true;
			}
		}
	}
	else if (Settings.IsCampaignCOOP() && CampaignPath == 4 && !Settings.bIsQMM) //FR campaign mode
	{
		//forget about skins
		if( Left(string(EquipmentClass),4) != "Swat")
		 return true;
			
	    // unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment.Length; ++i)
		{
			if(class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
			{
				return true;
			}
		}
	}
		
	// Check for server disabled equipment
	for(i = 0; i < ServerDisabledEquipment.Length; i++)
	{
		if(EquipmentClass == ServerDisabledEquipment[i])
		{
			return false;
		}
	}
	
	//PVP skin validity
	if ( Settings.GameType != MPM_COOP && Settings.GameType != MPM_COOPQMM )
	{	
		if(Left(string(EquipmentClass),4) != "Swat") //skin classes
			return CheckTeamValidity(GetSkinTeamValidity(EquipmentClass));
	}
	
    return (type == NETVALID_MPOnly) || (Super.CheckValidity( EquipmentClass, type ));
}

function bool CheckCampaignValid( class EquipmentClass )
{
	local int MissionIndex;
	local int i;
	local int CampaignPath;
	local ServerSettings Settings;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

	MissionIndex = (Settings.CampaignCOOP & -65536) >> 16;
	CampaignPath = Settings.CampaignCOOP & 65535;

	// Any equipment above the MissionIndex is currently unavailable
	if(Settings.IsCampaignCOOP() && CampaignPath == 0 && !Settings.bIsQMM)
	{	// We only do this for the original career, not for QMM coop
    	// Check first set of equipment
		for (i = MissionIndex + 1; i < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length; ++i)
			if (class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
				return false;

	    // Check second set of equipment
		for(i = class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length + MissionIndex + 1;
			i < class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment.Length;
			++i)
	      if(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
	        return false;
	}
	else if(CampaignPath == 3) { // We only do this for the regular FR missions mode
    		
		//forget about skins
		if( Left(string(EquipmentClass),4) != "Swat")
		 return true;
			
        // unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment.Length; ++i)
        {
            if(class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
            {
                log("CheckCampaignValid failed on "$EquipmentClass);
                return true;
            }
        }
		return false;
    }
	else if(CampaignPath == 4) { // We only do this for the regular FR missions mode
    		
		//forget about skins
		if( Left(string(EquipmentClass),4) != "Swat")
		 return true;
			
        // unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment.Length; ++i)
        {
            if(class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
            {
                log("CheckCampaignValid failed on "$EquipmentClass);
                return true;
            }
        }
		return false;
    }
	return true;
}

function bool CheckWeightBulkValidity()
{
	local float Weight;
	local float Bulk;

	Weight = MyCurrentLoadOut.GetTotalWeight();
	Bulk = MyCurrentLoadOut.GetTotalBulk();

	log("MP Panel weight:" $ Weight $ " bulk " $ bulk $ " ");

	if(Weight > MyCurrentLoadOut.GetMaximumWeight())
	{
		log("Check weight false " $ MyCurrentLoadOut.GetMaximumWeight() $ " ");
	    TooMuchWeightModal();
	    return false;
	}
	else if(Bulk > MyCurrentLoadOut.GetMaximumBulk())
	{
		log("Check bulk false " $ MyCurrentLoadOut.GetMaximumbulk() $ " ");
	    TooMuchBulkModal();
	    return false;
	}
	else if(MyCurrentLoadout.LoadOutSpec[0] == class'SwatEquipment.NoWeapon' &&
	  			MyCurrentLoadOut.LoadOutSpec[2] == class'SwatEquipment.NoWeapon')
	{
		NoWeaponModal();
		return false;
	}

	return true;
}

function bool CheckTeamValidity( eTeamValidity type )
{
	local bool IsSuspect;

	if (PlayerOwner().Level.IsPlayingCOOP)
	{
		IsSuspect = false; // In coop the player is never a suspect
	}
	else
	{
		assert(PlayerOwner() != None);

		// If we don't have access to a team object assume the item is valid for the players future team
		// This case should only be true right after a level change when the player has no control over their team or loadout anyway
		// but we don't want the client to reset the loadout based on team without knowing the team. The server will never allow
		// an illegal loadout anyway so this is just a lax client side check.
		if (PlayerOwner().PlayerReplicationInfo == None || NetTeam(PlayerOwner().PlayerReplicationInfo.Team) == None)
			return true;

		// The suspect team always has a team number of 1
		IsSuspect = (NetTeam(PlayerOwner().PlayerReplicationInfo.Team).GetTeamNumber() == 1);
	}

	       // Item is usable by any team   or // Suspect only item and player is suspect    or // SWAT only item and player is not a suspect
	return Super.CheckTeamValidity( type ) || (type == TEAMVALID_SuspectsOnly && IsSuspect) || (type == TEAMVALID_SWATOnly && !IsSuspect);
}


defaultproperties
{
  EquipmentOverWeightString="You are equipped with too much weight. Your loadout will be changed to the default if you don't adjust it."
  EquipmentOverBulkString="You are equipped with too much bulk. Your loadout will be changed to the default if you don't adjust it."
  NoWeaponString="You do not have a weapon. Your loadout will be changed to the default if you don't adjust it."
}
