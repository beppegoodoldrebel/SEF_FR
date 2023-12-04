class SwatCampaignCoopSettingsPanel extends SwatGUIPanel;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;
import enum eSwatGameRole from SwatGame.SwatGuiConfig;

var(SWATGui) EditInline Config GUILabel MyCampaignNameLabel;

// Server Settings Panel
var(SWATGui) EditInline Config GUICheckBoxButton MyPasswordedButton;
var(SWATGui) EditInline Config GUIEditBox MyNameBox;
var(SWATGui) EditInline Config GUIEditBox MyPasswordBox;
var(SWATGui) EditInline Config GUINumericEdit MyMaxPlayersSpinner;
var(SWATGui) EditInline Config GUIComboBox MyDifficultyComboBox;
var(SWATGui) EditInline Config GUIComboBox MyEntryComboBox;
var(SWATGui) EditInline Config GUILabel MyDifficultySuccessLabel;
var(SWATGui) EditInline Config GUIComboBox MyPublishModeBox;
var(SWATGui) EditInline Config GUIScrollTextBox MyEntryDescription;

// Server Info Panel
var(SWATGui) EditInline Config GUILabel MyServerNameLabel;
var(SWATGui) EditInline Config GUILabel MyMapNameLabel;
var(SWATGui) EditInline Config GUILabel MyDifficultyNameLabel;
var(SWATGui) EditInline Config GUIListBox MyUnlockedEquipmentBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyVotingEnabledBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyEnableKillsBox;

var protected localized config string PrimaryEntranceLabel;
var protected localized config string SecondaryEntranceLabel;
var protected localized config string DifficultyString;
var protected localized config string DifficultyLabelString;
var() private config localized string LANString;
var() private config localized string GAMESPYString;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

    Super.InitComponent(MyOwner);

    for(i = 0; i < eDifficultyLevel.EnumCount; i++)
    {
        MyDifficultyComboBox.AddItem(GC.DifficultyString[i]);
    }

    MyPublishModeBox.AddItem(LANString);
    MyPublishModeBox.AddItem(GAMESPYString);

    MyNameBox.MaxWidth = GC.MPNameLength;
    MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

    MyEntryComboBox.OnChange=ComboBoxOnChange;
    MyDifficultyComboBox.OnChange=ComboBoxOnChange;
    MyPasswordedButton.OnChange=GenericOnChange;
    MyMaxPlayersSpinner.OnChange=GenericOnChange;
    MyVotingEnabledBox.OnChange=GenericOnChange;
}

function GenericOnChange(GUIComponent Sender)
{
    switch(Sender)
    {
        case MyPasswordedButton:
            MyPasswordBox.SetEnabled(MyPasswordedButton.bChecked);
            break;
    }
}

function ComboBoxOnChange(GUIComponent Sender)
{
    local GUIComboBox Element;

    Element = GUIComboBox(Sender);

    switch(Element)
    {
        case MyDifficultyComboBox:
            GC.CurrentDifficulty = eDifficultyLevel(Element.GetIndex());
            MyDifficultyNameLabel.SetCaption(DifficultyString $ GC.DifficultyString[Element.GetIndex()]);
            MyDifficultySuccessLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
            break;

        case MyEntryComboBox:
            GC.SetDesiredEntryPoint(EEntryType(Element.GetIndex()));
            MyEntryDescription.SetContent(GC.CurrentMission.EntryDescription[Element.GetIndex()]);
            break;
    }
}

function InternalOnActivate()
{
    local ServerSettings Settings;
    local int i;

    Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

    MyPasswordedButton.SetChecked(Settings.bPassworded);
    MyPasswordBox.SetText(Settings.Password);
    MyDifficultyComboBox.SetIndex(GC.CurrentDifficulty);
    MyEntryComboBox.SetIndex(GC.GetDesiredEntryPoint());
    MyMapNameLabel.SetCaption(GC.CurrentMission.FriendlyName);
    MyCampaignNameLabel.SetCaption(SwatGUIController(Controller).GetCampaign().StringName);
    MyVotingEnabledBox.SetChecked(Settings.bAllowReferendums);

    if(Settings.bLAN)
    {
      MyPublishModeBox.SetIndex(0);
    }
    else
    {
      MyPublishModeBox.SetIndex(1);
    }

    MyMaxPlayersSpinner.SetValue(Settings.MaxPlayers, true);
    MyNameBox.SetText(GC.MPName);

    MyEntryComboBox.Clear();
    for(i = 0; i < GC.CurrentMission.EntryOptionTitle.Length; i++)
    {
        if(i == 0)
        {
            MyEntryComboBox.AddItem(GC.CurrentMission.EntryOptionTitle[i] $ " (Primary)");
        }
        else
        {
            MyEntryComboBox.AddItem(GC.CurrentMission.EntryOptionTitle[i] $ " (Secondary)");
        }
    }

	if(GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom)
	{
		PopulateCustomUnlocks();
	}
	else
	{
		PopulateCampaignUnlocks();
	}
}

////////////////////////////////////////////////////////////////////////////////
//
//

// Called when using a QMM campaign
function PopulateCustomUnlocks()
{
	local Campaign theCampaign;
	local int i;
	local class<Equipment> Item;
	local CustomScenarioPack thePack;

	// Clear it first
	MyUnlockedEquipmentBox.List.Clear();

	theCampaign = SwatGuiController(Controller).GetCampaign();
	thePack = GC.GetCustomScenarioPack();

	if(thePack == None || !thePack.UseGearUnlocks)
	{	// Either no pack is loaded or the pack doesn't use unlocks
		return;
	}

	// First unlocks
	for(i = 0; i < theCampaign.GetAvailableIndex() + 1 && i < thePack.FirstEquipmentUnlocks.Length; i++)
	{
		Item = class<Equipment>(thePack.FirstEquipmentUnlocks[i]);
		if(Item == None)
		{
			continue;
		}
		MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
	}

	// Second unlocks
	for(i = 0; i < theCampaign.GetAvailableIndex() + 1 && i < thePack.SecondEquipmentUnlocks.Length; i++)
	{
		Item = class<Equipment>(thePack.SecondEquipmentUnlocks[i]);
		if(Item == None)
		{
			continue;
		}
		MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
	}

	MyUnlockedEquipmentBox.List.Sort();
}

// Called when using a non-QMM campaign
function PopulateCampaignUnlocks()
{
    local Campaign theCampaign;
    local int i, CampaignPath;
    local class<ICanBeSelectedInTheGUI> Item;
	local ServerSettings Settings;

    // Clear it first
    MyUnlockedEquipmentBox.List.Clear();


	if ( PlayerOwner().Level.NetMode == NM_Client )
	{
		//get it from server and deal with it
		Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
		CampaignPath = Settings.CampaignCOOP & 65535;
	}
	else
	{
		theCampaign = SwatGUIController(Controller).GetCampaign();
		CampaignPath = theCampaign.CampaignPath;
	}

    
	if(CampaignPath == 0)
	{
		for(i = 0; i < theCampaign.GetAvailableIndex() + 1; i++)
		{
			Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i]);
			if(Item == None)
			{
				continue;
			}
			MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
		}

		for(i = class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length;
			i < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length + theCampaign.GetAvailableIndex() + 1;
			i++)
		{
			Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i]);
			if(Item == None)
			{
				continue;
			}
			MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
		}
		MyUnlockedEquipmentBox.List.Sort();
	}
	else if(CampaignPath == 3)
	{
		// unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment.Length; ++i)
        {
            Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatFRCareerPath'.default.UnlockedEquipment[i]);
			if(Item == None)
			{
				continue;
			}
			MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
        }
		MyUnlockedEquipmentBox.List.Sort();
	}
	else if(CampaignPath == 4)
	{
		// unlock only specific equipment
		for(i = 0; i < class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment.Length; ++i)
        {
            Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatFRPatrolCareerPath'.default.UnlockedEquipment[i]);
			if(Item == None)
			{
				continue;
			}
			MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
        }
		MyUnlockedEquipmentBox.List.Sort();
	}
	
	return;
}

function bool CheckCampaignValid( class EquipmentClass )
{
	local int MissionIndex;
	local int i;
	local int CampaignPath;
	local ServerSettings Settings;
	local CustomScenarioPack QMMPak;
	
	if ( PlayerOwner().Level.NetMode == NM_Client ) //Clients get equipment from Server settings
	{
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
	else 
	{
	// Host gets equipment from local GUI
	MissionIndex = SwatGUIControllerBase(Controller).GetCampaign().GetAvailableIndex();
	CampaignPath = SwatGUIControllerBase(Controller).GetCampaign().CampaignPath;
	QMMPak = GC.GetCustomScenarioPack();

	// Any equipment above the MissionIndex is currently unavailable
	if(QMMPak != None)
	{	// QMM
		// Check for it being on the list of unlocks, if unlocks are enabled.
		if(QMMPak.UseGearUnlocks)
		{
			// Disable everything that is after our current mission index
			for(i = MissionIndex + 1; i < QMMPak.FirstEquipmentUnlocks.Length; i++)
			{
				if(EquipmentClass == QMMPak.FirstEquipmentUnlocks[i])
				{
					return false;
				}
			}

			for(i = MissionIndex + 1; i < QMMPak.SecondEquipmentUnlocks.Length; i++)
			{
				if(EquipmentClass == QMMPak.SecondEquipmentUnlocks[i])
				{
					return false;
				}
			}
		}
	}
	else if(CampaignPath == 0) { // We only do this for the regular SWAT 4 missions
    // Check first set of equipment
		for (i = MissionIndex + 1; i < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length; ++i)
        {
            if (class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i] == EquipmentClass) {
                log("CheckCampaignValid failed on "$EquipmentClass);
				return false;
            }
        }

        // Check second set of equipment
		for(i = class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length + MissionIndex + 1;
			i < class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment.Length;
			++i)
        {
            if(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i] == EquipmentClass)
            {
                log("CheckCampaignValid failed on "$EquipmentClass);
                return false;
            }
        }
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
	else if(CampaignPath == 4) { // We only do this for the regular Patrol Officer missions mode
    		
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
}

defaultproperties
{
    OnActivate=InternalOnActivate

    PrimaryEntranceLabel="Primary"
    SecondaryEntranceLabel="Secondary"
    DifficultyString="Difficulty: "
    DifficultyLabelString="Score of [b]%1[\\b] required to advance."

    LANString="LAN"
    GAMESPYString="Internet"
}
