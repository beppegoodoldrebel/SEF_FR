class AnimNotify_MagDump extends AnimNotify_Scripted;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    local ICanHoldEquipment Holder;

	//log("QuickReload::AnimNotify_MagDump()");

    Holder = ICanHoldEquipment(Owner);
    AssertWithDescription(Holder != None,
        "[tcohen] AnimNotify_MagDump was called on "$Owner$" which cannot hold equipment.");

    Holder.OnReloadMagDump();
}
