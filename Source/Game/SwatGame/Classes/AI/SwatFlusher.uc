///////////////////////////////////////////////////////////////////////////////

class SwatFlusher extends SwatEnemy;

///////////////////////////////////////////////////////////////////////////////

protected function ConstructCharacterAIHook(AI_Resource characterResource)
{
    // Flushers try only to destroy evidence after spotting an officer. See SwatEnemy::ConstructCharacterAIHook
    characterResource.addAbility(new class'SwatAICommon.FlushAction');
	characterResource.addAbility(new class'SwatAICommon.AttackOfficerAction');
	characterResource.addAbility(new class'SwatAICommon.TakeCoverAndAttackAction');
}

///////////////////////////////////////////////////////////////////////////////
