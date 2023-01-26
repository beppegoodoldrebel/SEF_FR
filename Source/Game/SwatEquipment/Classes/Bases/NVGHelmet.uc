class NVGHelmet extends NVGogglesBase;

var(Mesh) protected config StaticMesh AltActivatedMesh;
var(Mesh) protected config StaticMesh AltDeactivatedMesh;


simulated function SetNVGMesh( bool Activation )
{
	SetLocation( Pawn(Owner).Location ); //sound effects location fix
	
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