class NVGHelmet extends NVGogglesBase;

var(Mesh) protected config StaticMesh AltActivatedMesh;
var(Mesh) protected config StaticMesh AltDeactivatedMesh;

var bool CanSeeIRLaser;


simulated function SetNVGMesh( bool Activation )
{
	Pawn(Owner).AttachToBone(self, AttachmentBone); //sound effects location fix
	
	if (Activation )
	{	
		if ( SwatPawn(Owner).HasInstructorMesh() && AltActivatedMesh != None)
			SetStaticMesh(AltActivatedMesh);
		else	
			SetStaticMesh(ActivatedMesh);
	}
	else
	{
		if ( SwatPawn(Owner).HasInstructorMesh() && AltDeactivatedMesh != None)
			SetStaticMesh(AltDeactivatedMesh);
		else	
			SetStaticMesh(DeactivatedMesh);
		
	}
}

simulated function bool GetCanSeeIRLaser()
{
	return CanSeeIRLaser;
}

simulated function SetCanSeeIRLaser(bool Set)
{
	CanSeeIRLaser = Set;
}