class BatteringRamAmmo extends FrangibleBreachingAmmo;


simulated function OnRoundUsed(Pawn User, Equipment Launcher)
{
	//Super.OnRoundUsed(User, Launcher);

	assertWithDescription(CurrentRounds > 0,
        "[tcohen] RoundBasedAmmo::OnRoundUsed() tried to use a round, but the magazine is empty.");

	//dont use rounds... no need here!
    //CurrentRounds--; 

    UpdateHUD();
}

defaultproperties
{
    bPenetratesDoor=false
    StaticMesh=StaticMesh'Hotel_sm.hot_bath_prodbot2'
}
