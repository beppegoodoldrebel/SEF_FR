// GameMode Patrol Officer - Single Player

// Rules: 
// - limited equipment ( pistol + shotgun ) , no breaching tools needed
// - Doors are not locked and cant be locked by player or suspects


class GameModePatrolOfficer extends GameMode;

function Initialize()
{
	local NavigationPoint Iter;
	local SwatDoor Door;

	//unlock all doors! no breaching tools here!
	for(Iter = Level.navigationPointList; Iter != None; Iter = Iter.nextNavigationPoint)
	{
		Door = SwatDoor(Iter);

		if (Door != None)
			Door.SilentUnlock(); //unlock all
	}
	
	
}
