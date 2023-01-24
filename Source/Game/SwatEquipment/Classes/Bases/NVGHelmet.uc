class NVGHelmet extends NVGogglesBase;

var(Mesh) protected config StaticMesh AltActivatedMesh;
var(Mesh) protected config StaticMesh AltDeactivatedMesh;


simulated function SetNVGMesh( bool Activation )
{
	if (Activation )
	{	
		if ( SwatPlayer(Owner).HasInstructorMesh() && AltActivatedMesh != None)
			SetStaticMesh(AltActivatedMesh);
		else	
			SetStaticMesh(ActivatedMesh);
	}
	else
	{
		if ( SwatPlayer(Owner).HasInstructorMesh() && AltDeactivatedMesh != None)
			SetStaticMesh(AltDeactivatedMesh);
		else	
			SetStaticMesh(DeactivatedMesh);
		
	}
}