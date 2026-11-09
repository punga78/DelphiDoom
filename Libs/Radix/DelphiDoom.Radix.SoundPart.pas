{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSoundPart                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateSounds of radix_xlat_wad.pas (the names are radix_sounds)   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SoundPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context;

type
  /// <summary>DS_nnnnn: the sounds of the DAT, and SNDINFO that gives a name to each of them</summary>
  TRadixSoundPart = class(TInterfacedObject, IRadixPart)
  public
    /// <summary>The names of the sounds of the DAT in the order of the enumeration radixsound_t</summary>
    class function SoundNames: TArray<string>; static;
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

{ TRadixSoundPart }

class function TRadixSoundPart.SoundNames: TArray<string>;
begin
  Result := ['SndScrape', 'SndShot', 'SndMoveSurface', 'SndStopSurface', 'SndMissle', 'SndExplode',
    'SndExplodeShort', 'SndMissile', 'SndMissileOther', 'SndGravityWell', 'SndExplodeOther',
    'SndGravityWave', 'SndPlasma', 'SndSiren', 'SndTelePort', 'SndPowerUp', 'SndEndOfLevel',
    'SndButtonClick', 'SndAlert', 'SndSpawnShot', 'SndEngine', 'SndEngineAfter', 'SndShip',
    'SndPlanet', 'SndDroid', 'SndPlaneHit', 'SndGenAlarm', 'SndEOLAlarm', 'SndBioSpawn', 'SndRadar',
    'SndAlienHum', 'SndLoudHum', 'SndFodderExp', 'SndPlasmaBomb', 'SndCannon', 'SndTranspo',
    'SndEnemyFire', 'SndPrimAhead', 'SndPrimComplete', 'SndPrimInComplete', 'SndTargetsAhead',
    'SndEnemy', 'SndSecAhead', 'SndSecComplete', 'SndSplash'];
end;

procedure TRadixSoundPart.Build(const AContext: TRadixTranslationContext);
var
  LNames: TArray<string>;
  LIndex: Integer;
  LBytes: TBytes;
  LWadName: string;
  LInfo: string;
  LAny: Boolean;
begin
  LNames := SoundNames;
  LInfo := '// Radix Sounds' + #13#10 + #13#10;
  LAny := False;
  for LIndex := 0 to High(LNames) do
    if AContext.Container.TryRead(LNames[LIndex], LBytes) then
    begin
      LWadName := Format('DS_%.5d', [LIndex]);
      AContext.Wad.AddLump(LWadName, LBytes);
      AContext.AddAlias(LWadName, LNames[LIndex]);
      LInfo := LInfo + 'radix/' + LNames[LIndex] + ' ' + LWadName + #13#10;
      LAny := True;
    end;
  if LAny then
    AContext.Wad.AddText('SNDINFO', LInfo);
end;

end.
