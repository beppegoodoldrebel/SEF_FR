class MagliteTorch extends BreachingShotgun config(SwatEquipment); 

var bool evidence_is_highlight;

simulated function OnHolderDesiredFlashlightStateChanged() //we dont shoot here....
{
	Super.OnHolderDesiredFlashlightStateChanged();
	
	evidence();
	
}

simulated function InitFlashlight()
{
	Super.InitFlashlight();
	
	if ( FlashlightDynamicLight != None )
	  FlashlightDynamicLight.LightCone = 20; //how wide the flashlight beam is
}

function evidence()
{
	
	if (!evidence_is_highlight)
	{
		Level.GetLocalPlayerController().ConsoleCommand("evidencehighlight 1");
		evidence_is_highlight=true;
	}
	else
	{
		Level.GetLocalPlayerController().ConsoleCommand("evidencehighlight 0");
		evidence_is_highlight=false;
	}
	
}

simulated latent protected function DoUsingHook()
{
	//it is supposed to do nothing... 
	//here just to avoid fire sound and shit
}


simulated function UnequippedHook() //remove evidence highlight when unequip.
{

Super.UnequippedHook();

Level.GetLocalPlayerController().ConsoleCommand("evidencehighlight 0");
evidence_is_highlight=false;

}


defaultproperties
{
	bAbletoMelee=false
    Slot=Slot_Maglite
}
