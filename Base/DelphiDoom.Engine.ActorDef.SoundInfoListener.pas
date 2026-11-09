{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what SNDINFO does to the sounds and songs of Hexen     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.ActorDef.SoundInfoListener;

{$IFDEF HEXEN}

interface

uses
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The lines of SNDINFO that Hexen reads for itself: $MAP gives the song of a map, and a
  ///   name that is the tag of a sound of the game gives that sound its lump
  /// </summary>
  TEngineSoundInfoListener = class(TInterfacedObject, IActorDefSoundInfoListener)
  public
    procedure SongForMap(AMapId: Integer; const ASongName: string);
    procedure AliasDeclared(const AName, AValue: string);
  end;

implementation

uses
  d_delphi,
  sounddata;

{ TEngineSoundInfoListener }

procedure TEngineSoundInfoListener.SongForMap(AMapId: Integer; const ASongName: string);
begin
  if (AMapId > 0) and (AMapId < nummusic) then
    S_music[AMapId].name := ASongName;
end;

procedure TEngineSoundInfoListener.AliasDeclared(const AName, AValue: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Ord(DO_NUMSFX) - 1 do
    if strupper(S_sfx[LIndex].tagname) = AName then
      S_sfx[LIndex].name := AValue;
end;

{$ELSE}

interface

implementation

{$ENDIF}

end.
