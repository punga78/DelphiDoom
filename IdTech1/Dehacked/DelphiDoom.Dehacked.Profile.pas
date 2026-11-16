{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the profile of a game                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Profile;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Intf;

type
  /// <summary>
  ///   The blocks that the patches of a game have: a reader for each word that opens one. A game
  ///   that has no block (Hexen has no Ammo) has no reader for its word, and the lines of the block
  ///   are not read, as the old parser did
  /// </summary>
  TDehackedProfile = class(TInterfacedObject, IDehackedProfile)
  private
    FGameName: string;
    FReaders: TDictionary<string, IDehackedSectionReader>;
  public
    constructor Create(const AGameName: string; const AReaders: array of IDehackedSectionReader);
    destructor Destroy; override;
    function GameName: string;
    function FindReader(const AKeyword: string): IDehackedSectionReader;
  end;

implementation

{ TDehackedProfile }

constructor TDehackedProfile.Create(const AGameName: string;
  const AReaders: array of IDehackedSectionReader);
var
  LReader: IDehackedSectionReader;
  LKeyword: string;
begin
  inherited Create;
  FGameName := AGameName;
  FReaders := TDictionary<string, IDehackedSectionReader>.Create;
  for LReader in AReaders do
    for LKeyword in LReader.Keywords do
      FReaders.AddOrSetValue(LKeyword, LReader);
end;

destructor TDehackedProfile.Destroy;
begin
  FReaders.Free;
  inherited Destroy;
end;

function TDehackedProfile.GameName: string;
begin
  Result := FGameName;
end;

function TDehackedProfile.FindReader(const AKeyword: string): IDehackedSectionReader;
begin
  if not FReaders.TryGetValue(AKeyword, Result) then
    Result := nil;
end;

end.
