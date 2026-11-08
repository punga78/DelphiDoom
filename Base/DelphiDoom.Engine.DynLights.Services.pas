{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the dynamic lights library asks of the game       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.DynLights.Services;

{$I Doom32.inc}

interface

uses
  DelphiDoom.DynLights.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The questions of the parser of LIGHTDEF/GLDEFS, answered by the game: the random bytes of the
  ///   animation, the numbers of objects and sprites, the table of the states (where the lights
  ///   are attached), the texts of the WAD and PAK lumps and the script preprocessor.
  ///   One class for several small interfaces: each user of the library sees only its own
  /// </summary>
  TEngineDynLightServices = class(TInterfacedObject, IDynLightRandom, IDynLightObjectResolver,
    IDynLightSpriteResolver, IDynLightStateTable, IDynLightTextSource, IDynLightTextFilter)
  private
    // JVAL: random index for the light animation, don't bother resetting it
    FRandomIndex: Integer;
    FPreprocessor: IScriptTextPreprocessor;
    FRandom: IGameRandom;
    FPakFiles: IPakFileSystem;
    FLumps: IEngineLumps;
  public
    /// <param name="APreprocessor">The script preprocessor of Filter (includes, directives, defines)</param>
    /// <param name="APakFiles">The PAK file system that has the GLDEFS and LIGHTDEF files</param>
    /// <param name="ARandom">The generator of the animation bytes (NextWithIndex)</param>
    /// <param name="ALumps">The lumps of the loaded WADs</param>
    constructor Create(const APreprocessor: IScriptTextPreprocessor; const APakFiles: IPakFileSystem;
      const ARandom: IGameRandom; const ALumps: IEngineLumps);
    function NextByte: Integer;
    function ObjectForName(const AUpperName: string): Integer;
    function SpriteForName(const AUpperName: string): Integer;
    function StateCount: Integer;
    function SpriteOf(AState: Integer): Integer;
    function FrameOf(AState: Integer): Integer;
    function StatesOfObject(AObject: Integer): TArray<Integer>;
    function HasLights(AState: Integer): Boolean;
    procedure CreateLights(AState: Integer);
    procedure RemoveLightsOfObject(AState, AObject: Integer);
    procedure AddLight(AState, AObject, ALight: Integer);
    function WadLumpTexts(const AName: string): TArray<string>;
    function PakTexts(const AFileName: string): TArray<string>;
    function Filter(const AText: string): string;
  end;

implementation

uses
  d_delphi,
  doomdef,
  info_h,
  info,
  info_common,
  System.SysUtils,
  p_pspr;

const
  SPreprocessorMissing = 'TEngineDynLightServices: the preprocessor is nil';
  SRandomMissing = 'TEngineDynLightServices: the random generator is nil';
  SPakFilesMissing = 'TEngineDynLightServices: the PAK file system is nil';

{ TEngineDynLightServices }

constructor TEngineDynLightServices.Create(const APreprocessor: IScriptTextPreprocessor;
  const APakFiles: IPakFileSystem; const ARandom: IGameRandom; const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(APreprocessor) then
    raise EArgumentNilException.Create(SPreprocessorMissing);
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create(SPakFilesMissing);
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create(SRandomMissing);
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FPreprocessor := APreprocessor;
  FPakFiles := APakFiles;
  FRandom := ARandom;
  FLumps := ALumps;
end;

function TEngineDynLightServices.NextByte: Integer;
begin
  Result := FRandom.NextWithIndex(FRandomIndex);
end;

function TEngineDynLightServices.ObjectForName(const AUpperName: string): Integer;
begin
  Result := Info_GetMobjNumForName(AUpperName);
end;

function TEngineDynLightServices.SpriteForName(const AUpperName: string): Integer;
begin
  Result := Info_CheckSpriteNumForName(AUpperName);
end;

function TEngineDynLightServices.StateCount: Integer;
begin
  Result := numstates;
end;

function TEngineDynLightServices.SpriteOf(AState: Integer): Integer;
begin
  Result := states[AState].sprite;
end;

function TEngineDynLightServices.FrameOf(AState: Integer): Integer;
begin
  Result := states[AState].frame and FF_FRAMEMASK;
end;

function TEngineDynLightServices.StatesOfObject(AObject: Integer): TArray<Integer>;
var
  LList: TDNumberList;
  LIndex: Integer;
begin
  Result := nil;
  if AObject < 0 then
    Exit;
  LList := Info_GetStatesForMobjInfo(AObject);
  try
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := LList[LIndex];
  finally
    LList.Free;
  end;
end;

function TEngineDynLightServices.HasLights(AState: Integer): Boolean;
begin
  Result := states[AState].dlights <> nil;
end;

procedure TEngineDynLightServices.CreateLights(AState: Integer);
begin
  states[AState].dlights := T2DNumberList.Create;
end;

procedure TEngineDynLightServices.RemoveLightsOfObject(AState, AObject: Integer);
var
  LIndex: Integer;
begin
  for LIndex := states[AState].dlights.Count - 1 downto 0 do
    if states[AState].dlights[LIndex].num1 = AObject then
      states[AState].dlights.Delete(LIndex);
end;

procedure TEngineDynLightServices.AddLight(AState, AObject, ALight: Integer);
begin
  states[AState].dlights.Add(AObject, ALight);
end;

function TEngineDynLightServices.WadLumpTexts(const AName: string): TArray<string>;
var
  LIndex: Integer;
begin
  // one text for each lump of that name, they are not joined
  Result := nil;
  for LIndex := 0 to FLumps.Count - 1 do
    if FLumps.NameOf(LIndex) = AName then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FLumps.TextOf(LIndex);
    end;
end;

function TEngineDynLightServices.PakTexts(const AFileName: string): TArray<string>;
begin
  Result := FPakFiles.Texts(AFileName);
end;

function TEngineDynLightServices.Filter(const AText: string): string;
begin
  Result := FPreprocessor.Preprocess(AText, False);
end;

end.
