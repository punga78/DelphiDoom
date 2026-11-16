{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the player                      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): utils.pas                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Player.Intf;

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>SE_REVERSOPILL ... SE_WARPJAMMER: the special effects of the player</summary>
  GREED_SE_NONE = 0;
  GREED_SE_REVERSO_PILL = 1;
  GREED_SE_DECOY = 2;
  GREED_SE_CLONE = 3;
  GREED_SE_INVISIBILITY = 4;
  GREED_SE_WARP_JAMMER = 5;
  /// <summary>MAXCHARTYPES</summary>
  GREED_CHAR_TYPES = 6;
  /// <summary>The sounds of the player (SN_HIT0 and SN_DEATH0 plus the type of the character)</summary>
  GREED_SN_HIT0 = 29;
  GREED_SN_DEATH0 = 34;

type
  /// <summary>What the rules of the player ask to the rest of the game (the flags and the clocks it keeps)</summary>
  IGreedPlayerContext = interface
    ['{5B3E9A24-7D18-4C60-B2F5-A9E01D847C36}']
    function GetGodMode: Boolean;
    /// <summary>One of the GREED_SE_ values (specialeffect)</summary>
    function GetSpecialEffect: Integer;
    function GetNetMode: Boolean;
    function GetTimeCount: Integer;
    /// <summary>nethurtsoundtime: the net game does not tell the others about each hit</summary>
    function GetNetHurtSoundTime: Integer;
    procedure SetNetHurtSoundTime(AValue: Integer);
    property GodMode: Boolean read GetGodMode;
    property SpecialEffect: Integer read GetSpecialEffect;
    property NetMode: Boolean read GetNetMode;
    property TimeCount: Integer read GetTimeCount;
    property NetHurtSoundTime: Integer read GetNetHurtSoundTime write SetNetHurtSoundTime;
  end;

  /// <summary>What the player makes happen outside of itself: the red border of the screen and the sounds</summary>
  IGreedPlayerFeedback = interface
    ['{E1A7C4D2-0B93-4F58-8A6D-3C25F97B1E40}']
    /// <summary>hurtborder := true</summary>
    procedure ShowHurtBorder;
    /// <summary>SoundEffect(sound, variation, x, y)</summary>
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    /// <summary>NetSoundEffect(sound, variation, x, y): the same sound to the other players</summary>
    procedure PlayNetSound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
  end;

implementation

end.
