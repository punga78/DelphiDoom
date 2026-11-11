{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what a dogfight tells its window         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Dogfight.Listener.Intf;

interface

type
  /// <summary>
  ///   The sounds of a dogfight: the ones of the constants of the rules (ufoFire, ufoHit, ufoCrash, ufoExplode,
  ///   interceptorHit, interceptorExplode, all of GEO.CAT) and the sound of the weapon that was fired
  /// </summary>
  TXcomDogfightSound = (dsUfoFire, dsUfoHit, dsUfoCrash, dsUfoExplode, dsInterceptorHit, dsInterceptorExplode,
    dsWeapon);

  /// <summary>
  ///   What the logic of a dogfight reports to its window (the calls that DogfightState makes on its surfaces and
  ///   on the sounds): the logic does not draw. A listener that does nothing is a dogfight without a screen
  /// </summary>
  IXcomDogfightListener = interface
    ['{6F2B4C1D-9A3E-4B75-8D10-176000000201}']
    /// <summary>setStatus: the text of the status line (the key of the translation)</summary>
    procedure StatusChanged(const AKey: string);
    /// <summary>The sound; for dsWeapon AWeaponSound is the index of the sound of the weapon</summary>
    procedure SoundPlayed(ASound: TXcomDogfightSound; AWeaponSound: Integer);
    /// <summary>drawCraftDamage: the damage of the craft changed</summary>
    procedure CraftDamaged;
    /// <summary>The ammunition of a weapon (0 or 1) changed (the text of the ammo)</summary>
    procedure AmmoChanged(AWeapon, AAmmo: Integer);
    /// <summary>The window of the dogfight asks the geoscape for a popup (DogfightErrorState)</summary>
    procedure CannotEngage(const AReason: string);
    /// <summary>animate: the window moves the radar waves and draws the UFO and the projectiles of this step</summary>
    procedure Animating;
  end;

implementation

end.
