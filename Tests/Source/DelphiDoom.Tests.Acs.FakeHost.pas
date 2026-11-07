{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - a host that writes what it is asked  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.FakeHost;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Machine.Types, DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Tests.Acs.FakeWorld, DelphiDoom.Tests.Acs.FakeThinkers;

type
  /// <summary>
  ///   The host of the tests: it acts on a fake world and writes a line of the trace for every
  ///   thing that a script asks of the game, in the same words that the copy of the old
  ///   interpreter uses, so that the two traces can be compared
  /// </summary>
  TFakeAcsHost = class(TInterfacedObject, IAcsHost)
  strict private
    FWorld: TFakeWorld;
    FThinkers: TFakeThinkers;
  public
    constructor Create(AWorld: TFakeWorld; AThinkers: TFakeThinkers);
    function TicsPerSecond: Integer;
    function CurrentMap: Integer;
    function LevelTime: Integer;
    function GameType: TAcsGameType;
    function GameSkill: Integer;
    function PlayerCount: Integer;
    function NextRandom: Integer;
    function AllocateScript: PAcsScript;
    procedure ReleaseScript(AScript: PAcsScript);
    procedure ExecuteLineSpecial(ASpecial: Integer; const AArguments: TAcsSpecialArguments;
      ALine, AActivator: Pointer; ASide: Integer);
    function IsTagBusy(ATag: Integer): Boolean;
    function IsPolyobjectBusy(APolyobject: Integer): Boolean;
    procedure ChangeSectorFlat(ATag: Integer; const AFlatName: string; AFloor: Boolean);
    function CountThings(AThingType, ATid: Integer): Integer;
    procedure SetLineTexture(ALineTag, ASide, APosition: Integer; const ATextureName: string);
    procedure SetLineBlocking(ALineTag: Integer; ABlocking: Boolean);
    procedure SetLineSpecial(ALineTag, ASpecial: Integer;
      const AArguments: TAcsLineSpecialArguments);
    procedure ClearLineSpecial(ALine: Pointer);
    procedure PlaySectorSound(ALine: Pointer; const ASoundName: string; AVolume: Integer);
    procedure PlayThingSound(ATid: Integer; const ASoundName: string; AVolume: Integer);
    procedure PlayAmbientSound(const ASoundName: string; AVolume: Integer);
    procedure StartSoundSequence(ALine: Pointer; const ASequenceName: string);
    procedure ShowMessage(AActivator: Pointer; const AText: string);
    procedure ShowMessageToAll(const AText: string);
    procedure ShowConsoleMessage(const AText: string);
  end;

const
  FAKE_TICS_PER_SECOND = 35;

/// <summary>The words of the trace for a line special: the same for the old and the new code</summary>
function TraceLineSpecial(AWorld: TFakeWorld; ASpecial: Integer; const AArguments: array of Byte;
  ALine, AActivator: Pointer; ASide: Integer): string;

implementation

function TraceLineSpecial(AWorld: TFakeWorld; ASpecial: Integer; const AArguments: array of Byte;
  ALine, AActivator: Pointer; ASide: Integer): string;
begin
  Result := Format('special %d args=%d,%d,%d,%d,%d,%d,%d,%d line=%s activator=%s side=%d',
    [ASpecial, AArguments[0], AArguments[1], AArguments[2], AArguments[3], AArguments[4],
    AArguments[5], AArguments[6], AArguments[7], AWorld.Describe(ALine),
    AWorld.Describe(AActivator), ASide]);
end;

{ TFakeAcsHost }

constructor TFakeAcsHost.Create(AWorld: TFakeWorld; AThinkers: TFakeThinkers);
begin
  inherited Create;
  FWorld := AWorld;
  FThinkers := AThinkers;
end;

function TFakeAcsHost.TicsPerSecond: Integer;
begin
  Result := FAKE_TICS_PER_SECOND;
end;

function TFakeAcsHost.CurrentMap: Integer;
begin
  Result := FWorld.Map;
end;

function TFakeAcsHost.LevelTime: Integer;
begin
  Result := FWorld.LevelTime;
end;

function TFakeAcsHost.GameType: TAcsGameType;
begin
  Result := TAcsGameType(FWorld.GameType);
end;

function TFakeAcsHost.GameSkill: Integer;
begin
  Result := FWorld.Skill;
end;

function TFakeAcsHost.PlayerCount: Integer;
begin
  Result := FWorld.PlayerCount;
end;

function TFakeAcsHost.NextRandom: Integer;
begin
  Result := FWorld.NextRandom;
end;

function TFakeAcsHost.AllocateScript: PAcsScript;
begin
  Result := PAcsScript(FThinkers.Allocate(SizeOf(TAcsScript)));
end;

procedure TFakeAcsHost.ReleaseScript(AScript: PAcsScript);
begin
  FWorld.Log(Format('remove script %d', [AScript.Number]));
  FThinkers.Remove(AScript);
end;

procedure TFakeAcsHost.ExecuteLineSpecial(ASpecial: Integer; const AArguments: TAcsSpecialArguments;
  ALine, AActivator: Pointer; ASide: Integer);
begin
  FWorld.Log(TraceLineSpecial(FWorld, ASpecial, AArguments, ALine, AActivator, ASide));
end;

function TFakeAcsHost.IsTagBusy(ATag: Integer): Boolean;
begin
  Result := FWorld.IsTagBusy(ATag);
end;

function TFakeAcsHost.IsPolyobjectBusy(APolyobject: Integer): Boolean;
begin
  Result := FWorld.IsPolyobjectBusy(APolyobject);
end;

procedure TFakeAcsHost.ChangeSectorFlat(ATag: Integer; const AFlatName: string; AFloor: Boolean);
var
  LFlat: Integer;
  LPosition: Integer;
begin
  LFlat := TFakeWorld.NameNumber(AFlatName);
  FWorld.Log(Format('flat %s', [AFlatName]));
  LPosition := -1;
  while FWorld.FindSector(ATag, LPosition) >= 0 do
    if AFloor then
      FWorld.Sectors[LPosition].FloorPic := LFlat
    else
      FWorld.Sectors[LPosition].CeilingPic := LFlat;
end;

function TFakeAcsHost.CountThings(AThingType, ATid: Integer): Integer;
begin
  Result := FWorld.CountThings(AThingType, ATid);
end;

procedure TFakeAcsHost.SetLineTexture(ALineTag, ASide, APosition: Integer;
  const ATextureName: string);
var
  LTexture: Integer;
  LPosition: Integer;
  LLine: PFakeLine;
begin
  LTexture := TFakeWorld.NameNumber(ATextureName);
  FWorld.Log(Format('texture %s', [ATextureName]));
  LPosition := -1;
  LLine := FWorld.FindLine(ALineTag, LPosition);
  while Assigned(LLine) do
  begin
    FWorld.SetSideTexture(FWorld.SideOf(LLine, ASide), APosition, LTexture);
    LLine := FWorld.FindLine(ALineTag, LPosition);
  end;
end;

procedure TFakeAcsHost.SetLineBlocking(ALineTag: Integer; ABlocking: Boolean);
var
  LPosition: Integer;
  LLine: PFakeLine;
  LBlocking: Integer;
begin
  LBlocking := 0;
  if ABlocking then
    LBlocking := FAKE_BLOCKING;
  LPosition := -1;
  LLine := FWorld.FindLine(ALineTag, LPosition);
  while Assigned(LLine) do
  begin
    LLine.Flags := (LLine.Flags and not FAKE_BLOCKING) or LBlocking;
    LLine := FWorld.FindLine(ALineTag, LPosition);
  end;
end;

procedure TFakeAcsHost.SetLineSpecial(ALineTag, ASpecial: Integer;
  const AArguments: TAcsLineSpecialArguments);
var
  LPosition: Integer;
  LLine: PFakeLine;
  LIndex: Integer;
begin
  LPosition := -1;
  LLine := FWorld.FindLine(ALineTag, LPosition);
  while Assigned(LLine) do
  begin
    LLine.Special := ASpecial;
    for LIndex := 0 to 4 do
      LLine.Args[LIndex] := AArguments[LIndex];
    LLine := FWorld.FindLine(ALineTag, LPosition);
  end;
end;

procedure TFakeAcsHost.ClearLineSpecial(ALine: Pointer);
begin
  PFakeLine(ALine).Special := 0;
end;

procedure TFakeAcsHost.PlaySectorSound(ALine: Pointer; const ASoundName: string; AVolume: Integer);
var
  LOrigin: Pointer;
begin
  LOrigin := nil;
  if Assigned(ALine) then
    LOrigin := PFakeLine(ALine).FrontSector;
  FWorld.Log(Format('sound origin=%s id=%d volume=%d',
    [FWorld.Describe(LOrigin), TFakeWorld.NameNumber(ASoundName), AVolume]));
end;

procedure TFakeAcsHost.PlayThingSound(ATid: Integer; const ASoundName: string; AVolume: Integer);
var
  LPosition: Integer;
  LThing: PFakeThing;
begin
  LPosition := -1;
  LThing := FWorld.FindThing(ATid, LPosition);
  while Assigned(LThing) do
  begin
    FWorld.Log(Format('sound origin=%s id=%d volume=%d',
      [FWorld.Describe(LThing), TFakeWorld.NameNumber(ASoundName), AVolume]));
    LThing := FWorld.FindThing(ATid, LPosition);
  end;
end;

procedure TFakeAcsHost.PlayAmbientSound(const ASoundName: string; AVolume: Integer);
begin
  FWorld.Log(Format('sound origin=nil id=%d volume=%d',
    [TFakeWorld.NameNumber(ASoundName), AVolume]));
end;

procedure TFakeAcsHost.StartSoundSequence(ALine: Pointer; const ASequenceName: string);
var
  LOrigin: Pointer;
begin
  LOrigin := nil;
  if Assigned(ALine) then
    LOrigin := PFakeLine(ALine).FrontSector;
  FWorld.Log(Format('sequence origin=%s name=%s', [FWorld.Describe(LOrigin), ASequenceName]));
end;

procedure TFakeAcsHost.ShowMessage(AActivator: Pointer; const AText: string);
begin
  FWorld.Log(Format('message activator=%s text=%s', [FWorld.Describe(AActivator), AText]));
end;

procedure TFakeAcsHost.ShowMessageToAll(const AText: string);
begin
  FWorld.Log(Format('message all text=%s', [AText]));
end;

procedure TFakeAcsHost.ShowConsoleMessage(const AText: string);
begin
  FWorld.Log(Format('message console text=%s', [AText]));
end;

end.
