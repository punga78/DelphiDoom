{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the sets of flags of a game                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FlagSets;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Intf;

type
  /// <summary>The sets of flags by name</summary>
  TDehackedFlagSets = class(TInterfacedObject, IDehackedFlagSets)
  private
    FSets: TDictionary<string, IDehackedFlagSet>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const ASet: IDehackedFlagSet);
    function Find(const AName: string): IDehackedFlagSet;
  end;

implementation

{ TDehackedFlagSets }

constructor TDehackedFlagSets.Create;
begin
  inherited Create;
  FSets := TDictionary<string, IDehackedFlagSet>.Create;
end;

destructor TDehackedFlagSets.Destroy;
begin
  FSets.Free;
  inherited Destroy;
end;

procedure TDehackedFlagSets.Add(const AName: string; const ASet: IDehackedFlagSet);
begin
  FSets.AddOrSetValue(AName, ASet);
end;

function TDehackedFlagSets.Find(const AName: string): IDehackedFlagSet;
begin
  if not FSets.TryGetValue(AName, Result) then
    Result := nil;
end;

end.
