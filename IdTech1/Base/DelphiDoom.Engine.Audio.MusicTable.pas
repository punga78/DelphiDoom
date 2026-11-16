{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the table of the songs (S_music)                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.MusicTable;

interface

uses
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>
  ///   IMusicTable on S_music, nummusic and MAX_MUS of sounddata.pas: the table stays data of
  ///   the engine; the same code serves every game (the slots have the same fields)
  /// </summary>
  TEngineMusicTable = class(TInterfacedObject, IMusicTable)
  public
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    function Capacity: Integer;
    function FindByName(const AUpperName: string): Integer;
    procedure Define(AIndex: Integer; const AName: string; ALumpNumber: Integer);
  end;

implementation

uses
  sounddata,
  DelphiDoom.Audio.SoundNames;

{ TEngineMusicTable }

function TEngineMusicTable.GetCount: Integer;
begin
  Result := nummusic;
end;

procedure TEngineMusicTable.SetCount(AValue: Integer);
begin
  nummusic := AValue;
end;

function TEngineMusicTable.Capacity: Integer;
begin
  Result := MAX_MUS;
end;

function TEngineMusicTable.FindByName(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 1 to nummusic - 1 do
    if TSoundNames.MusicMatches(S_music[LIndex].name, AUpperName) then
    begin
      Result := LIndex;
      Exit;
    end;
  Result := -1;
end;

procedure TEngineMusicTable.Define(AIndex: Integer; const AName: string; ALumpNumber: Integer);
begin
  S_music[AIndex].name := AName;
  S_music[AIndex].lumpnum := ALumpNumber;
end;

end.
