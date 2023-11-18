///////////////////////////////////////////////////////////////////////////////

class SwatUndercover extends SwatEnemy;

///////////////////////////////////////////////////////////////////////////////

protected function ConstructCharacterAIHook(AI_Resource characterResource)
{
    // Undercover guys don't attack, flee, regroup, threaten hostages, or
    // converse with hostages. See SwatEnemy::ConstructCharacterAIHook
}

///////////////////////////////////////////////////////////////////////////////

function BecomeAThreat()
{
	//dont become a threat for some SwatEnemy father class reason
}