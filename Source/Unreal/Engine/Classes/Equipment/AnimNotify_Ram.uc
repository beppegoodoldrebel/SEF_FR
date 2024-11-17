class AnimNotify_Ram extends AnimNotify_Scripted;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    local ICanHoldEquipment Holder;
	
	//log("AnimNotify_Ram was called - Battering Ram");
	
    Holder = ICanHoldEquipment(Owner);
    AssertWithDescription(Holder != None,
        "[tcohen] AnimNotify_Ram was called on "$Owner$" which cannot hold equipment.");

    Holder.OnRamKeyFrame();
}
