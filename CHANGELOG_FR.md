==============
Swat Elite Force: First Responders 
==============

SEF First Responders is coming along with the idea of a realistic and cinematic gameplay modification of Swat Elite Force. 
SEF 7.0 by Eezstreet is the base mod in which my mod starts , the only possible way to play Swat 4 nowadays. 
My idea is to expand the concept and explore boundaries of the visual assets and tactical gameplay.
New 3d models for weapons , equipment and environment combined with realistic sounds , weapon handling , slower pace gameplay and AI tweaks to make Swat 4 feel more "heavy" and "dangerous" than any other Swat 4 experience you had before.

Make sure to sure to join "SEF: First Responders" server on Discord for feedbacks, bug reports and coop game making!
https://discord.gg/Vu4r7sv7uF

==============
FEATURE LIST: 
==============
#### V0.68 Beta 1 ####

WEAPONS:
			 - OWN THE NIGHT: fully working Laser and Infrared Laser
		     
               M4 CQBs	   -> Infrared laser ( only visible with NVG )
			   All Tasers  -> visible lasers
			   More weapons to come in the next future!
			    
			   Toggle Laser command key is now settable under Game Controls/Interaction page
			   
GEAR:    	 
             - Battering Ram
			    - Doors resistance is based on material ( for example wooden doors are easier to open than metal )
				- fully integrated with Officers AI. Ram commands are under OPEN DOOR page!
				
			 - MS2000 IR Strobe added to Mich + NVG  
			    infrared strobe light is now on when player is using NVG. Can be seen by other players when using NVG.
				  
		     - Pockets under equipment page has been modified to be more user frilendly
			    - Breaching Shotgun/Battering Ram/C2/Optiwand/Medic Pouch are now in Special Tool pocket.
				- All breaching tools are now selectable with default key "7"
					
MULTIPLAYER:	 
			 - PVP has been re-enabled and fully working.
			      No modifications has been made to the gamemodes but they are now working with FRs features
			 
AI:          
			 - reworked sensors and engage-to-shoot routines to improve Suspect and Officer AI to better respond to threats
			 
FIXED:       
			 - Career COOP unlocked weapons are now correctly synced to clients
			 
#### V0.67 ####
WEAPONS: 
			 - Remingtom M870 Tactical
			 - M16A2 with Surefire M500 weaponlight
GEAR:
             - PASGT + Goggles and chinstraps to many helmets ( thx to TargetAquired )
			 - reworked Kevlar Armor(No Sleeves) now support full skins and nametags ( thx to TargetAquired )
GAMEPLAY:
			- The Shield: combined pistols (or taser) with a Level3A rated tactical shield. 
			            
						Can be equipped by AI officers and they can move in formation with it ( MOVE-TO command for example ).
						- Added dedicated flashlight to Shield
						
			- Medical System: bandages that can heal the limping player or AI Officer.
			            - single bandage 
						- Medic Kit with 5 bandages
						
						Press K (default key) to equip and Left Mouse buttun to use while near a wounded officer.
						
            - Quick Reload: pressing Hold Command (CTRL default) + Reload permits you to quick change magazine at the cost of losing it.
			
			- Breached Door Falling: Doors can now detach from the frame after a C2 explosion (for the maximum cinematic effect)
            - Blasted Doors with shotgun have now chance to be opened immediatly after the shot			
			- Restrained On Floor: 
			            - after reporting you can put anyone to floor by simply interacting again with the restrained.
						  Arrested has to have free space in front to be put on the floor.
            - First Responders Campaign mode : 
			            - no unlocks 
						- only FR weapons
						- no optiwand   :P
			- Damage values reworked for penetrating ammos. 			
			- Medical System: 
			            - healing gives 100% health
						- added "HEAL ME" AI command
						- new HEAL voice command lines ( i.e. "Gold , heal me" will result in AI heal you ) 
						
             - "CHECK CORNER" command 
			            - AI can move to corners and check whats behind that
						- command trigger on mirror points
						
             - WeaponBob activated 
			            - player's camera is moving during walk to give a more dynamic feeling
						
			 - restored Optiwand "under-door" capability 
			 - revised player speed 
			 - Fallen door chance after a blast or a breach is depending on door material		
MULTIPLAYER:
            - LOVETAP 
			       New function that let players tapping each others. When another player is tapped an Icon will appear on his screen. 
				   This will improve non-verbal communication between players.
				   
				   You can find the dedicated keybind in Multiplayer section of Game Control options.
GUI:
	         - Added selectable Custom Skins for Single Player mode.	
			 - New QUICK INFO hud icon
			       - SHIELD when near a shield guy the icon appears to indicate the shield formation command ( MOVE TO )
	               - LOVETAP when another player is tapping you the icon will appear for 4 seconds
AI: 
			 - fixed istances of AI shooting from impossible rotations
			 - minimum time to shoot is now respected
             - fixed many deadlocks in suspect AI actions that were making them idle for no reason
			 - reworked open-door behavior to avoid AI deadlock before opening the door
			 - Hostages can possibly comply by just seeing the officers.
			 - Minimum Time to Shoot reduced for Low/Medium Skill Suspects
			 - reworked Hearing Sensor for Suspects/Officers
			 - reworked Officer AI reactions
			             - improved sensors (Vision and Hearing ) to react on Suspect threats
						 - better behavior while "moving and clearing" dont let Officers disperse while clearing
						 - reduced time-to-shoot to have edge on suspects
			 - reworked Flee/Flush/Regroup/Escape actions to avoid bad behaviors on "attack while moving".
			 - reworked InvestigateAction to not make suspect standing without tasks.
			 - non compliant Suspects/Hostages will return to listen compliance if many officers are around them ( more than 4 in 10 meters around them )
SOUNDS:
			 - various replaced sounds effects  ( thx to Crusoe )
FIXED:      
			 - Suspect Threat detection is now activated just before they start to aim to avoid delays (particularly in MP) and bad ROE detection
             - fixed some wierd animation behaviors when "Restrained On Floor".
			 - Weapon image not loading on Loadout GUI on some campaign conditions
			 - improved animation manager

#### V0.66 ####

ADDED:
- Lean/Walk System , ability to lean and walk.... finally an hystoric moment for Swat4 modding!  
    New and old lean system are working together for a complete... lean experience! 
    	Q and E - new lean/walk system 
	   CTRL + Q and CTRL + E - old lean 
- Partial Open Door System , holding CTRL and Mouse Wheel Up/Down wil swing the door partially, making possible to shoot or throw a grenade.
- NEW TAC-AID: Maglite Torch! Using the light makes evidence glowing to allow player a faster search of them. Even AI can use this feature when got ordered to secure evidence!
- Dynamic shell textures on Breaching SG an Benelli M4 depending on shell type.
- Fleeing suspects are considered threat if running with a gun within 15 mts from a player 

- new body armors (from vanilla) , Level II armor and Kevlar (no sleeves). 
- new headgear ( boonie hat , ballistic glasses )

FIXED:
- Stuttering and weight bugs in MP : removed old SEF system in change of a new simplified system with better net performances.
- Suspects can remove wedges only within 35 mts from players.
- Trapped doors are signaled by AI only there are traps in the map.

#### V0.65 ####

ADDED
- Manual Low Ready system 
- removed penalty for suspects escaped
- Added "Pull Door" command to let player pull the door (thx Scape/S4 for the script)
- Separated Flashlight and NVG keybinds 
- AI Officers now can use NVG instead of flashlights 
- New keybinds to control NVG light
- Enemy suspects can now remove wedges (50% chance) and barricade just after.
- Enemies can use flashlights (chance depending on enemy skill)
- Enemy pickup weapon restored (thank you EFdee)
- Check Lock can possibly return the presence of a trap... but can be a false statement! 
  Also AI officers now report possible traps when checking the lock but... they can be wrong! 
- SP/COOP Career overhaul: unlock system redone for a better career experience.

REMOVED
- Optiwand now cant mirror under the door

FIXED
- MP5A4 Holo ADS point fixed
- Adjusted some weights here and there


#### V0.61 ####

FIXED
- Scar H Aimpoint Suppressed  sound .
- G36K Holo Suppressed sound crash the server 
- Toolkit lockpick dont open/lock door after use 
- CS gas crash!!!!!!! 
- reverted Unauth. use of force penalty to SEF7 

ADDED
-new Ninebang explosion sound
- Ryker's Tasers sounds
- Run speed revised : now "No Armor" is SEF speed level , "Ceramic Armor" FR level , "Kevlar Armor" something in between the two. Basically now if you want speed carry less armor. Other speeds dont touched, i think they are good as they are!!!


#### V0.6 FEATURES ####

VISUAL & SOUNDS:
- Gas mask breathing loop sound
- New weapons realistic sounds replacements

NEW WEAPONS:
- adding new weapons and new variation to actual weapons 
    - Beretta 92FS
    - Benelli M4 + Eotech 552 Holographic sight
    - M4 CQB + Holo + Silencer 
    - UMP  Holo + Silencer 
    - Sig 552 ( SEF model ) + Aimpoint + Silencer 
    - MP5A4 Holo + Silencer 
    - G36K Holo + Silencer
    - new M16A1 model!
	- Nine Bangers Flashbang 
	
GAMEPLAY: 
- chambered round counted in magazine-based weapons
- Penalties: every injury on compliant or arrested hostage/suspects is an unauthorized use of force (-5).
- Penalties: Sniper can only shoot suspects that are threats
- Flashlight to be turned off when unequip
- Flashlight cone reduced to match realistic cone size
- reviewed all weight system with real weights (bulk tweaked a bit for some tac-aid )
- little review of tact aids slot so i can expand different new grenade depending on type : 
                           -slot 1 for bangs only
                           -slot 2 for gas only
                           -slot 3 for sting only
other slot free for other tac aids equipment.
- 20% higher chance to have a hostage/suspect compliant if issued a comply with flashlight on

### v0.5
 
#### MAJOR FEATURES ####

- New weapon models to replace the vanilla ones (M4 , G36, 1911 , Glock , Mp5 , Taser X2 , UMP , Rem M870,Benelli Nova, Benelli M4 etc .  + Silenced and Aimpoint Variants)
- Replaced and tweaked gunshots sounds to be more realistic
- new Mich helmet models with variations , Safariland holster model and motorola radio 
- AI now react more to gunshots sound and investigate with more probability , tweaked enemy architype
- Door static meshes overhaul with updated knobs models
- updated hands models 
- new HUD with removed crosshair aim indicators
- slowed Swat movement for a more tactical gameplay
- new player camera position to fix weapons clipping! 
- zoomFov to 90 to better gunplay vision
- many bad guys guns models updated with new 3d models
- Enemy Achitypes revised for realistic suspects weapons
- added - 5 penalty for tasing hostages in any condition (considering real life procedures)
- nerfed Optiwand: 
           - now can be heard by suspects and can trigger them to investigate 
              doors
           - reduced FOV , lcd resolution and speed of lens movement 
- melee nerfed: reduced time of sting for AI 
- lockpicking nerfed: now it takes 30 second to open/lock a door and the sound of it triggers AI investigation
- all comply shouts now trigger AI investigation
- GUI update for all new weapons and equipment


==============
GNU LICENSE
==============
Modified source code from SEF 7 has been provided within the downloaded pack in the file Source.rar .
All the other files are free to be seen with SwatED and text editors.

==============
KNOWN BUGS:
==============

Known bugs:
- AI can be stuck by dealing with partial doors

=======
THANKS
=======

Eezstreet and all the gang that had contributed the SEF mod , the best of the best! 
Vetinari and nedd for the HUD reticle mod which has been "big bang moment" primary idea for starting this mod.
Scape for the tips on code! 
Mantas for the beautiful logos!
Panzer8, 4non , Mantas , Emil ,Scape for the massive trailer and showcase! 

All the supportive community that keeps me working and having fun on the mod!