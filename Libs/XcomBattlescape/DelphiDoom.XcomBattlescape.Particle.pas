{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - a particle (Particle)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.Particle;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.Random;

type
  /// <summary>
  ///   A cloud particle that a projectile leaves under water: a point (or a block of up to four) drawn through a
  ///   transparency table that rises and fades (Particle). The jitter of every step comes from an injected
  ///   generator: the game uses RNG::seedless, which is not reproducible
  /// </summary>
  TXcomParticle = class
  strict private
    FXOffset: Single;
    FYOffset: Single;
    FDensity: Single;
    FColor: Byte;
    FOpacity: Byte;
    FSize: Byte;
    function GetSize: Integer;
  public
    /// <param name="AXOffset">The horizontal offset from the tile, in screen space</param>
    /// <param name="AYOffset">The vertical offset from the tile, in screen space</param>
    /// <param name="ADensity">The speed it rises at, inversely proportional to the size</param>
    /// <param name="AColor">The table of transparency to use</param>
    /// <param name="AOpacity">The level of the table (divided by ten)</param>
    constructor Create(AXOffset, AYOffset, ADensity: Single; AColor, AOpacity: Byte);
    /// <summary>animate: false when the particle is over</summary>
    function Animate(const ARandom: IXcomRandom): Boolean;
    property Size: Integer read GetSize;
    property Color: Byte read FColor;
    /// <summary>getOpacity: the level of the table, from 0 to 3</summary>
    function OpacityLevel: Integer;
    property XOffset: Single read FXOffset;
    property YOffset: Single read FYOffset;
    /// <summary>The raw opacity (what is left of its life), to write and compare it</summary>
    property Opacity: Byte read FOpacity;
    /// <summary>For the tests: the position, the density and the life as another run left them</summary>
    procedure Restore(AXOffset, AYOffset, ADensity: Single; AOpacity: Byte);
    property Density: Single read FDensity;
  end;

implementation

{ TXcomParticle }

constructor TXcomParticle.Create(AXOffset, AYOffset, ADensity: Single; AColor, AOpacity: Byte);
begin
  inherited Create;
  FXOffset := AXOffset;
  FYOffset := AYOffset;
  FDensity := ADensity;
  FColor := AColor;
  FOpacity := AOpacity;
  FSize := 0;
  if ADensity < 100 then
    FSize := 3
  else if ADensity < 125 then
    FSize := 2
  else if ADensity < 150 then
    FSize := 1;
end;

function TXcomParticle.Animate(const ARandom: IXcomRandom): Boolean;
var
  LStep: Double;
  LSign: Integer;
begin
  // the float members are updated through double expressions, as in the C++
  FYOffset := FYOffset - ((320 - FDensity) / 256.0);
  Dec(FOpacity);
  // the arguments of the C++ expression are evaluated right to left in the compiler of the reference build
  LStep := 0.25 + Single(ARandom.Generate(0, 9)) / 30;
  LSign := ARandom.Generate(0, 1) * 2 - 1;
  FXOffset := FXOffset + LSign * LStep;
  Result := FOpacity <> 0;
end;

function TXcomParticle.GetSize: Integer;
begin
  Result := FSize;
end;

function TXcomParticle.OpacityLevel: Integer;
begin
  Result := Min((FOpacity + 7) div 10, 3);
end;

procedure TXcomParticle.Restore(AXOffset, AYOffset, ADensity: Single; AOpacity: Byte);
begin
  FXOffset := AXOffset;
  FYOffset := AYOffset;
  FDensity := ADensity;
  FOpacity := AOpacity;
end;

end.
