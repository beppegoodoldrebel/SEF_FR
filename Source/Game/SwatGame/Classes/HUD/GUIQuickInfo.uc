class GUIQuickInfo extends GUI.GUIImage;

//image to display at the center of the reticle...
var(GUIQuickInfo) Material CenterPreviewImage;            //...when previewing a piece of equipment
var(GUIQuickInfo) config Color    TickColor;
var(GUIQuickInfo) Material Shield;
var(GUIQuickInfo) Material LoveTap;

var bool LoveTapTimer;

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

private function bool RenderReticle(canvas Canvas)
{
	local PlayerController Player; 
	
    Image = None;

	Player = PlayerOwner();
    if ( Player.Pawn == None )
       return false;
	
	Canvas.bNoSmooth = False;
    Canvas.Style = ImageRenderStyle;
    Canvas.DrawColor = TickColor;

	log ("RenderReticle CenterPreviewImage : " $  CenterPreviewImage $ " LoveTapTimer " $ LoveTapTimer $ " ");
	
	if (CenterPreviewImage != None) // is pointing at a 'hotspot' on a door
    {
		// render the 'quick equip' preview icon
        Image = CenterPreviewImage;
        ImageColor.A = 255;
    }
	
    
    return false;
}

event Timer()
{
	//BEWARE PRIORITIES!!!
	//beware of priorities!!!!
	// 1 - Lovetap
	// 2 - Shield
	
	//log ("Timer()  CenterPreviewImage : " $  CenterPreviewImage $ " LoveTapTimer " $ LoveTapTimer $ " ");
	
	if ( LoveTapTimer )
		ClearLoveTapQuickInfo();
	
}

//Priority 1
function LoveTapQuickInfo()
{	

	CenterPreviewImage=LoveTap;
		
	if ( !LoveTapTimer  )	
		LoveTapTimer = true;

	//log ("LoveTapQuickInfo()  CenterPreviewImage : " $  CenterPreviewImage $ " LoveTapTimer " $ LoveTapTimer $ " ");
	SetTimer(4.0,false);
}

function ClearLoveTapQuickInfo()
{
  LoveTapTimer = false;
  //log ("ClearLoveTapQuickInfo()  CenterPreviewImage : " $  CenterPreviewImage $ " LoveTapTimer " $ LoveTapTimer $ " ");
  CenterPreviewImage=None;
}

//Priority 2
function ShieldQuickInfo()
{
	if ( CenterPreviewImage==None ) //priority sanity
		CenterPreviewImage=Shield;
}

function ClearShieldQuickInfo()
{
  //log ("ClearShieldQuickInfo()  CenterPreviewImage : " $  CenterPreviewImage $ " LoveTapTimer " $ LoveTapTimer $ " ");
  if(!LoveTapTimer)
	CenterPreviewImage=None;

}


//Generic Clear
function ClearImage()
{
	//log ("ClearImage()  CenterPreviewImage : " $  CenterPreviewImage $ " ");
		CenterPreviewImage=None;
}

defaultproperties
{
    OnDraw=RenderReticle
    Shield=Material'gui_FR.qih_shield'
	LoveTap=Material'gui_FR.qih_lovetap'
	TickColor=(R=255,G=255,B=255,A=255)
    bPersistent=True
}

