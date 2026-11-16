{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the play list of the legacy MIDI player }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.MidiPlaylist;

interface

uses
  System.Generics.Collections;

type
  /// <summary>
  ///   The files that the legacy MIDI player goes through, and which one is current
  ///   (MidiFileNames and MidiID of i_midi_legacy.pas)
  /// </summary>
  TMidiPlaylist = class
  strict private
    FNames: TList<string>;
    FCurrent: Integer;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName: string);
    /// <summary>Removes the files; the current index is not changed</summary>
    procedure Clear;
    /// <summary>Removes the files and goes back to the first one</summary>
    procedure Reset;
    /// <summary>Makes the file at AIndex the current one; false (nothing changes) if there is no such file</summary>
    function Select(AIndex: Integer): Boolean;
    /// <summary>The current file</summary>
    function CurrentName: string;
    /// <summary>The next file, in a circle: the first one after the last</summary>
    function Advance: string;
    /// <summary>The ASCII upper case of a name, how the player compares the names of two songs</summary>
    class function Normalize(const AFileName: string): string; static;
    property Count: Integer read GetCount;
    property CurrentIndex: Integer read FCurrent;
  end;

implementation

{ TMidiPlaylist }

constructor TMidiPlaylist.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
end;

destructor TMidiPlaylist.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TMidiPlaylist.GetCount: Integer;
begin
  Result := FNames.Count;
end;

procedure TMidiPlaylist.Add(const AFileName: string);
begin
  FNames.Add(AFileName);
end;

procedure TMidiPlaylist.Clear;
begin
  // the current index stays where it was, as MidiID of the old code: Select or Reset change it
  FNames.Clear;
end;

procedure TMidiPlaylist.Reset;
begin
  FNames.Clear;
  FCurrent := 0;
end;

function TMidiPlaylist.Select(AIndex: Integer): Boolean;
begin
  Result := (AIndex > -1) and (AIndex < FNames.Count);
  if Result then
    FCurrent := AIndex;
end;

function TMidiPlaylist.CurrentName: string;
begin
  Result := FNames[FCurrent];
end;

function TMidiPlaylist.Advance: string;
begin
  if FCurrent >= FNames.Count - 1 then
    FCurrent := 0
  else
    Inc(FCurrent);
  Result := FNames[FCurrent];
end;

class function TMidiPlaylist.Normalize(const AFileName: string): string;
var
  LIndex: Integer;
begin
  Result := AFileName;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Chr(Ord(Result[LIndex]) - 32);
end;

end.
