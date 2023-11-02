///////////////////////////////////////////////////////////////////////////////
class ShieldHandgun extends Handgun
implements IShieldHandgun;


///////////////////////////////////////////////////////////////////////////////
var config bool HasShield;

var(Viewmodel) config class<ShieldEquip> ShieldModel_Third;
var ShieldEquip ShieldModel_TP; //thirdperson model
var(Viewmodel) config class<HandheldEquipmentModel> ShieldModel;
var HandheldEquipmentModel ShieldModel_FP;
//Flashlight
var (FlashlightShield) protected bool HasShieldAttachedFlashlight;
var(FlashlightShield) private config class<Light> FlashlightShieldCoronaLightClass "Type of CoronaLight to spawn for this weapon's flashlight";
var(FlashlightShield) Light  FlashlightShieldDynamicLight;                 // The actual light spawned for this weapon's flashlight
var(FlashlightShield) public config vector  FlashlightShieldPosition_1stPerson "Positional offset from the EquippedSocket on shield's FirstPersonModel to the point from which the flashlight emanates";
var(FlashlightShield) public config rotator FlashlightShieldRotation_1stPerson "Same idea as FlashlightPosition_1stPerson, but rotational offset";
var(FlashlightShield) public config vector  FlashlightShieldPosition_3rdPerson "Positional offset from the EquippedSocket on shield's ThirdPersonModel to the point from which the flashlight emanates";
var(FlashlightShield) public config rotator FlashlightShieldRotation_3rdPerson "Same idea as FlashlightPosition_3rdPerson, but rotational offset";
var(FlashlightShield) private Actor  FlashlightShieldReferenceActor;             // Reference point for the flashlight's position; this is where the flashlight appears to originate from (where the corona appears, and where traces are done from when using a moving pointlight on low end cards to approximate a spotlight)
var(FlashlightShield) private config int FlashlightShieldTextureIndex;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////

simulated function EquippedHook()
{
	local int i;
	Super.EquippedHook();
	
	if(HasShield)
	{		

		//should prevent any crazy MP de-sync
		for(i=0; i<=Pawn(Owner).Attached.length ; i++)
		{
			if (Pawn(Owner).Attached[i].isa('Shieldequip') &&  Pawn(Owner).Attached[i] != ShieldModel_TP )
			{
				Pawn(Owner).Attached[i].Destroy(); //prevent doubling shields 
			}
		}

		ShieldModel_TP.Equip();
		ShieldModel_TP.Show();
		
		if ( Pawn(Owner).GetHands() != None )
		{
			ShieldModel_FP.Show();
			ShieldModel_FP.OnEquipKeyFrame();
		}
		
		UpdateFlashlightState();
	}
}

simulated function UnequippedHook()
{
	Super.UnequippedHook();
	
	if(HasShield)
	{
		ShieldModel_TP.Unequip();
		ShieldModel_TP.Show();
		
		if ( Pawn(Owner).GetHands() != None)
		{
		ShieldModel_FP.Hide();
		ShieldModel_FP.OnUnequipKeyFrame();
		}
		
		if ( FlashlightShieldDynamicLight != None )
		{
			ICanToggleWeaponFlashlight(Owner).ToggleDesiredFlashlightState();
			DestroyFlashlight(0.01);
		}
	}
}

simulated function CreateModels()
{
	local int i;
	
	Super.CreateModels();
	
	//SHIELD
	if(HasShield)
	{	
		for(i=0; i<=Pawn(Owner).Attached.length ; i++)
		{
			if (Pawn(Owner).Attached[i].isa('Shieldequip'))
			{
				Pawn(Owner).Attached[i].Destroy(); //prevent doubling shields - happens in training cabinet mostly
			}
		}
		
		//humans only
		if (ShouldHaveFirstPersonModel && GetHands() != None )
		{
		
		ShieldModel_FP= Spawn ( ShieldModel, Pawn(Owner).GetHands() , , , , true);
		
		ShieldModel_FP.bNeedPostRenderCallback = true;
		ShieldModel_FP.Show();
		ShieldModel_FP.OnUnEquipKeyFrame();
		}
		
		if (ShouldHaveThirdPersonModel)
		{
				ShieldModel_TP= Spawn ( ShieldModel_Third, Owner , , , , true);
				ShieldModel_TP.Unequip();
				ShieldModel_TP.Show();
		}
	}
		
}

simulated function HandheldEquipmentModel GetShieldModelFP()
{
	return ShieldModel_FP;
}

simulated function SetShieldDamage(int damage)
{
	if (damage == 0)	
	{	
		ShieldModel_TP.Skins[0]= Material(DynamicLoadObject( "Shield_tex.Shield_glass", class'Material'));
		ShieldModel_FP.Skins[0]=Material(DynamicLoadObject( "Shield_tex.Shield_glass", class'Material'));
	
	}
	else if (damage == 1)	
	{	
		ShieldModel_TP.Skins[0]= Material(DynamicLoadObject( "Shield_tex.Shield_glass_1", class'Material'));
		ShieldModel_FP.Skins[0]=Material(DynamicLoadObject( "Shield_tex.Shield_glass_1", class'Material'));
	
	}
	else if (damage == 2)
	{
		ShieldModel_TP.Skins[0]= Material(DynamicLoadObject( "Shield_tex.Shield_glass_2", class'Material'));
		ShieldModel_FP.Skins[0]=Material(DynamicLoadObject( "Shield_tex.Shield_glass_2", class'Material'));
	}
	else if (damage == 3)
	{
		ShieldModel_TP.Skins[0]= Material(DynamicLoadObject( "Shield_tex.Shield_glass_3", class'Material'));
		ShieldModel_FP.Skins[0]=Material(DynamicLoadObject( "Shield_tex.Shield_glass_3", class'Material'));
	}
}

simulated function InitFlashlight()
{
	if ( super.HasFlashlight() )
		super.InitFlashlight();
	
	if (HasShieldAttachedFlashlight)
	{	
		// if the FlashlightUseFancyLights value has not been initialized yet...
		if (FlashlightUseFancyLights == -1)
		{
			// this will determine if flashlights use spots or point lights

			// If we don't support bumpmapping, then we don't have pixel shaders
			// and hence dynamic spotlights on BSP surfaces will not work
			bHighEndGraphicsBoard = bool(Level.GetLocalPlayerController().ConsoleCommand( "SUPPORTS BUMPMAP") );

        if (bHighEndGraphicsBoard)
			FlashlightUseFancyLights = 1;
		else
			FlashlightUseFancyLights = 0; // approximate spot light with moving point light
		//log("FLASHLIGHT Fancy lights: " $FlashlightUseFancyLights$" owner: "$owner);

			#if 1 // HACK HACK HACK:
			// This is a hack to get around a bug in ATI's drivers where the spotlight
			// pixel shader won't work. They say they'll fix this bug around Jan 05
			// in their new drivers.
			if (bool(Level.GetLocalPlayerController().ConsoleCommand( "USE_ATI_R200_SPOTLIGHT_WORKAROUND") ))
			{
				FlashlightUseFancyLights = 0;
			}
			#endif
		}



		if (InFirstPersonView())
		{
			FlashlightShieldReferenceActor = Spawn(FlashlightShieldCoronaLightClass,ShieldModel_FP,,,);
			FlashlightShieldReferenceActor.bCorona = false; 
	    
			ShieldModel_FP.Owner.AttachToBone(FlashlightShieldReferenceActor, ShieldModel_FP.EquippedSocket);
	
			FlashlightShieldReferenceActor.SetRelativeLocation(FlashlightShieldPosition_1stPerson);
			FlashlightShieldReferenceActor.SetRelativeRotation(FlashlightShieldRotation_1stPerson);
			
			if (FlashlightUseFancyLights == 1)
			{
				FlashlightShieldDynamicLight = Spawn(FlashlightSpotLightClass,ShieldModel_FP,,,);
				//FlashlightDynamicLight.bActorShadows = true; //doesn't seem to work
			
				FlashlightShieldDynamicLight.LightCone = 10; //how wide the flashlight beam is
				FlashlightShieldDynamicLight.LightRadius = FlashlightFirstPersonDistance; //distance the beam travels
			}
			else
				FlashlightShieldDynamicLight = Spawn(FlashlightPointLightClass,ShieldModel_FP,,,);
			
			FlashlightShieldDynamicLight.Tag = 'FirstPersonFlashlight';
			
		}
		else
		{
			FlashlightShieldReferenceActor = Spawn(FlashlightShieldCoronaLightClass,ShieldModel_TP,,,);
			FlashlightShieldReferenceActor.bCorona = true; // make coronas dissapear as angle to viewer approaches 90 degrees
	    
			ShieldModel_TP.Owner.AttachToBone(FlashlightShieldReferenceActor, ShieldModel_TP.AttachmentBone);
	
			FlashlightShieldReferenceActor.SetRelativeLocation(FlashlightShieldPosition_3rdPerson);
			FlashlightShieldReferenceActor.SetRelativeRotation(FlashlightShieldRotation_3rdPerson);
			
			if (FlashlightUseFancyLights == 1)
			{
				FlashlightShieldDynamicLight = Spawn(FlashlightSpotLightClass,ShieldModel_TP,,,);
				//FlashlightDynamicLight.bActorShadows = true; //doesn't seem to work
			
				FlashlightShieldDynamicLight.LightCone = 20; //how wide the flashlight beam is
				FlashlightShieldDynamicLight.LightRadius = FlashlightFirstPersonDistance; //distance the beam travels
			}
			else
			FlashlightShieldDynamicLight = Spawn(FlashlightPointLightClass,ShieldModel_TP,,,);
		}
		
		
		
		if (InFirstPersonView())
		{
			// attach the flashlight to the weapon model
			ShieldModel_FP.Owner.AttachToBone(FlashlightShieldDynamicLight, ShieldModel_FP.EquippedSocket);
			
			// Adjust the relative orientation and position of the light
			FlashlightShieldDynamicLight.SetRelativeLocation(FlashlightShieldPosition_1stPerson);
			FlashlightShieldDynamicLight.SetRelativeRotation(FlashlightShieldRotation_1stPerson);
			
			ShieldModel_FP.Owner.UpdateAttachmentLocations();
		}
		else
		{
			// attach the flashlight to the weapon model
			ShieldModel_TP.Owner.AttachToBone(FlashlightShieldDynamicLight, ShieldModel_TP.AttachmentBone);
			
			// Adjust the relative orientation and position of the light
			FlashlightShieldDynamicLight.SetRelativeLocation(FlashlightShieldPosition_3rdPerson);
			FlashlightShieldDynamicLight.SetRelativeRotation(FlashlightShieldRotation_3rdPerson);
			
			ShieldModel_TP.Owner.UpdateAttachmentLocations();
		}
		
		UpdateFlashlightLighting();
	
		if (!DebugDrawFlashlightDir)
		{
			FlashlightShieldDynamicLight.SetDrawType(DT_None);
			FlashlightShieldReferenceActor.SetDrawType(DT_None);
		}
		else
		{
			// but show the sprites if we are showing flashlight lines for debugging
			FlashlightShieldDynamicLight.bHidden     = false;
			FlashlightShieldReferenceActor.bHidden = false;
			FlashlightShieldDynamicLight.SetDrawType(DT_Sprite);
			FlashlightShieldReferenceActor.SetDrawType(DT_Sprite);
		}
	}
	
}

simulated function UpdateFlashlightLighting(optional float dTime)
{
	local Vector  PositionOffset;
    local Rotator RotationOffset, rayDirection;
	local Vector  hitLocation, hitNormal;
	local Vector  traceStart, traceEnd, PointLightPos, delta;
	local Actor   hitActor;
	local float   oldDistance, newDistance;
	
	super.UpdateFlashlightLighting();
	
	if( Level.NetMode == NM_DedicatedServer )
		return;
	
	// The stuff below is only done for the pointlight-to-spotlight modeling
	if (FlashlightUseFancyLights == 1)
		return;
	
	if (InFirstPersonView())
    {
		PositionOffset = FlashlightShieldPosition_1stPerson;
		RotationOffset = FlashlightShieldRotation_1stPerson;
	}
	else
	{
		PositionOffset = FlashlightShieldPosition_3rdPerson;
		RotationOffset = FlashlightShieldRotation_3rdPerson;
	}
	
	traceStart   = FlashlightShieldReferenceActor.Location;
	rayDirection = FlashlightShieldReferenceActor.Rotation;
	// the first person uses a much smaller max distance to avoid popping when
	// the light aims from a distant wall to a nearby object.
    if (InFirstPersonView())
		traceEnd = traceStart + Vector(rayDirection) * FlashlightFirstPersonDistance;
	else
		traceEnd = traceStart + Vector(rayDirection) * MaxFlashlightDistance;

	hitActor = Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True);

	if (hitActor == None)
	{
		hitLocation = traceEnd;
	}
	
	delta = hitLocation - traceStart;
	oldDistance = VSize(traceStart - FlashlightShieldDynamicLight.Location);
	newDistance = VSize(delta) * PointLightDistanceFraction;
	newDistance = oldDistance + (newDistance - oldDistance) * PointLightDistanceFadeRate;

	PointLightPos = traceStart + newDistance * Vector(FlashlightShieldReferenceActor.Rotation);
	FlashlightShieldDynamicLight.SetLocation(PointLightPos);
	
	if (InFirstPersonView())
	{
		// attenuate the radius if the light is approaching something very close
		FlashlightShieldDynamicLight.LightRadius = MinFlashlightRadius +
			(BaseFlashlightRadius - MinFlashlightRadius) * (newDistance/FlashlightFirstPersonDistance);
	}
	else
	{
		FlashlightShieldDynamicLight.LightRadius = MinFlashlightRadius + newDistance *	PointLightRadiusScale;
	}

	FlashlightShieldDynamicLight.LightBrightness = BaseFlashlightBrightness +
		FMin(newDistance/MaxFlashlightDistance, 1.0) * (MinFlashlightBrightness - BaseFlashlightBrightness);

	FlashlightShieldDynamicLight.bLightChanged = true;
		
}

// Is this weapon flashlight-capable?
simulated function bool HasFlashlight()
{
    return super.HasFlashlight() || HasShieldAttachedFlashlight;
}

simulated function OnHolderDesiredFlashlightStateChanged()
{
	local bool PawnWantsFlashlightOn;
	local String FlashlightShieldTextureName;
	local Material FlashlightShieldMaterial;
	local Name EventName;
	
	super.OnHolderDesiredFlashlightStateChanged();
	
	
	if ( HasShieldAttachedFlashlight)
    {
		PawnWantsFlashlightOn = ICanToggleWeaponFlashlight(Owner).GetDesiredFlashlightState();
	    if (PawnWantsFlashlightOn)
		{
			EventName = 'FlashlightSwitchedOn';
		    FlashlightShieldTextureName = "SWATgearTex.FlashlightLensOnShader";
		}
		else
		{
			 EventName = 'FlashlightSwitchedOff';
		}
		
		if (!super.HasFlashlight())
		{
		//the effect event is triggered on the FiredWeapon, but played on the Pawn
		TriggerEffectEvent(
            EventName,
            Owner,      //Other
            ,           //TargetMaterial
            ,           //HitLocation
            ,           //HitNormal
            true);      //PlayOnOther
		}
	    
		 // change texture on 3rd person model
	    if (! InFirstPersonView() && FlashlightShieldTextureIndex != -1)
	    {
			if (PawnWantsFlashlightOn) // turn on the glow texture on the flashlight bulb
			{
				FlashlightShieldMaterial = Material(DynamicLoadObject( FlashlightShieldTextureName, class'Material'));
			}
			else // turn off the glow texture
			{
				// hack.. force the skin to None so that GetCurrentMaterial will pull from
				// the default materials array instead of the skin
				ShieldModel_TP.Skins[FlashlightShieldTextureIndex] = None;

				FlashlightShieldMaterial = ShieldModel_TP.GetCurrentMaterial(FlashlightShieldTextureIndex);
			}

			ShieldModel_TP.Skins[FlashlightShieldTextureIndex] = FlashlightShieldMaterial;
	    }
		
		 UpdateFlashlightState();
	}
}

simulated function UpdateFlashlightState()
{
	local bool PawnWantsFlashlightOn;
	
	super.UpdateFlashlightState();
	
	if (!HasShieldAttachedFlashlight) //already done with the pistol , no need to go on
    {
		//Log("[ckline]: Weapon "$self$" on "$Owner$" is not flashlight-equipped, so can't toggle its state.");
		return;
    }

    PawnWantsFlashlightOn = ICanToggleWeaponFlashlight(Owner).GetDesiredFlashlightState();
    //Log("UpdateFlashlightState(): Pawn wants it on = "$PawnWantsFlashlightOn$", IsFlashlightOn = "$IsFlashlightOn()$" on "$owner);
	//LogGuardStack();

    if (PawnWantsFlashlightOn == (FlashlightShieldDynamicLight != None ))
    {
		// flashlight is already at desired state
		return;
    }

    // Setup the flashlight objects if necessary
    if (PawnWantsFlashlightOn) // should be on
    {
		InitFlashlight();
        if (!(FlashlightShieldDynamicLight != None ))
        {
		    assertWithDescription(false, "[ckline] Flashlight should be initialized but thinks it isn't. I must have messed something up.");
        }
    }
    else // flashlight should be off
    {
		if ((FlashlightShieldDynamicLight != None ))
		{
			DestroyFlashlight(ICanToggleWeaponFlashlight(Owner).GetDelayBeforeFlashlightShutoff());
		}
    }
}


function DestroyFlashlight(float SecondsBeforeDestroying)
{
	super.DestroyFlashlight(0.01);
	
	if (FlashlightShieldReferenceActor != None)
	{
        // Force FCoronaRender to gracefully remove the corona on next render pass
        FlashlightShieldReferenceActor.bCorona = false;

        // Destroy the corona light automatically after 1 second, after FCoronaRender has removed it
        FlashlightShieldReferenceActor.LifeSpan = 1;

		FlashlightShieldReferenceActor = None; // for sanity
	}
	
	if ( FlashlightShieldDynamicLight != None )
	{
		FlashlightShieldDynamicLight.LifeSpan = 0.01;

		FlashlightShieldDynamicLight = None; // for sanity
	}
}

defaultproperties
{
	HasShield=true
	bAbletoQuickReload=true //no fast animation , just mag dump
	AimAnimation=WeaponAnimAim_Shield
	LowReadyAnimation=WeaponAnimLowReady_Shield
	IdleWeaponCategory=IdleWithShield

	ComplianceAnimation=Compliance_Shield
	ShowCrosshairInIronsights=true
	
	HasShieldAttachedFlashlight=true
	FlashlightShieldTextureIndex=2
}