{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the parser of GLDEFS and LIGHTDEF     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Parser;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Tokens, DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   The parser of the light definitions (the old SC_DoParceDynamicLight). It reads the text
  ///   twice, as the old code did: the first time for the definitions of the lights, which
  ///   go to the registry; the second time, line by line, for the "object" and "frame" lines,
  ///   which go to the binder. A light is added when the word after its properties is read: a
  ///   light that is the last thing of a text is lost (a defect of the old code, kept)
  /// </summary>
  TDynLightParser = class(TInterfacedObject, IDynLightParser)
  private
    FServices: TDynLightParserServices;
    FLog: ILog;
    FMapCoefficient: Double;
    procedure Warn(const AFormat: string; const AArguments: array of const);
    procedure ListText(const AText: string);
    function ReadProperty(AScanner: TScriptScanner; AToken: TDynLightToken;
      var ALight: TDynLightDefinition): Boolean;
    function ReadLights(AScanner: TScriptScanner): Boolean;
    procedure ReadObjectLine(AScanner: TScriptScanner; const ALine: string; ALineIndex: Integer;
      var AObject: Integer; var AObjectName: string);
    procedure ReadFrameLine(AScanner: TScriptScanner; const ALine: string; ALineIndex: Integer;
      AObject: Integer; const AObjectName: string);
    procedure BindFrames(AScanner: TScriptScanner; const AText: string);
  public
    /// <param name="AServices">Everything but the context has to be there</param>
    /// <param name="ALog">May be nil</param>
    /// <param name="AMapCoefficient">
    ///   The size and the offset of a light are divided by it: 1 for the software renderer and
    ///   128 for OpenGL (MAP_COEFF)
    /// </param>
    constructor Create(const AServices: TDynLightParserServices; const ALog: ILog;
      AMapCoefficient: Double);
    procedure Parse(const AText: string);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings;

const
  SMustBeServed = 'TDynLightParser needs a registry, a random source, resolvers and a binder';

function FirstWord(const AText: string): string;
var
  LPosition: Integer;
begin
  // up to the first space; a tab does not end the word
  LPosition := Pos(' ', AText);
  if LPosition = 0 then
    Result := AText
  else
    Result := Copy(AText, 1, LPosition - 1);
end;

{ TDynLightParser }

constructor TDynLightParser.Create(const AServices: TDynLightParserServices; const ALog: ILog;
  AMapCoefficient: Double);
begin
  inherited Create;
  if not (Assigned(AServices.Registry) and Assigned(AServices.Random) and
    Assigned(AServices.Objects) and Assigned(AServices.Sprites) and Assigned(AServices.Binder)) then
    raise EArgumentNilException.Create(SMustBeServed);
  FServices := AServices;
  FLog := ALog;
  FMapCoefficient := AMapCoefficient;
end;

procedure TDynLightParser.Warn(const AFormat: string; const AArguments: array of const);
begin
  if Assigned(FLog) then
    FLog.Warning(Format(AFormat, AArguments));
end;

procedure TDynLightParser.ListText(const AText: string);
var
  LLines: TArray<string>;
  LIndex: Integer;
begin
  if not Assigned(FLog) then
    Exit;
  FLog.Info('--------'#13#10);
  FLog.Info('SC_ParceDynamicLight(): Parsing light definitions'#13#10);
  LLines := TScannerStrings.SplitLines(AText);
  for LIndex := 0 to High(LLines) do
    FLog.Info(Format('%.6d: %s'#13#10, [LIndex + 1, LLines[LIndex]]));
  FLog.Info('--------'#13#10);
end;

function TDynLightParser.ReadProperty(AScanner: TScriptScanner; AToken: TDynLightToken;
  var ALight: TDynLightDefinition): Boolean;
begin
  Result := True;
  case AToken of
    TDynLightToken.Color:
      begin
        AScanner.MustGetFloat;
        ALight.R1 := AScanner.AsFloat;
        ALight.R2 := ALight.R1;
        AScanner.MustGetFloat;
        ALight.G1 := AScanner.AsFloat;
        ALight.G2 := ALight.G1;
        AScanner.MustGetFloat;
        ALight.B1 := AScanner.AsFloat;
        ALight.B2 := ALight.B1;
      end;
    TDynLightToken.SecondaryColor:
      begin
        AScanner.MustGetFloat;
        ALight.R2 := AScanner.AsFloat;
        AScanner.MustGetFloat;
        ALight.G2 := AScanner.AsFloat;
        AScanner.MustGetFloat;
        ALight.B2 := AScanner.AsFloat;
      end;
    TDynLightToken.Size:
      begin
        AScanner.MustGetInteger;
        ALight.Size1 := AScanner.AsInteger / FMapCoefficient;
        ALight.Size2 := ALight.Size1;
      end;
    TDynLightToken.SecondarySize:
      begin
        AScanner.MustGetInteger;
        ALight.Size2 := AScanner.AsInteger / FMapCoefficient;
      end;
    TDynLightToken.Interval:
      begin
        AScanner.MustGetFloat;
        if AScanner.AsFloat > 0.0 then
          ALight.Interval := Round(1 / AScanner.AsFloat * DYNLIGHT_FRACUNIT * DYNLIGHT_TICRATE);
      end;
    TDynLightToken.ColorInterval:
      begin
        AScanner.MustGetFloat;
        if AScanner.AsFloat > 0.0 then
          ALight.ColorInterval := Round(1 / AScanner.AsFloat * DYNLIGHT_FRACUNIT * DYNLIGHT_TICRATE);
      end;
    TDynLightToken.Chance:
      begin
        AScanner.MustGetFloat;
        ALight.Chance := Round(AScanner.AsFloat * 255);
        if ALight.Chance < 0 then
          ALight.Chance := 0
        else if ALight.Chance > 255 then
          ALight.Chance := 255;
      end;
    TDynLightToken.ColorChance:
      begin
        AScanner.MustGetFloat;
        ALight.ColorChance := Round(AScanner.AsFloat * 255);
        if ALight.ColorChance < 0 then
          ALight.ColorChance := 0
        else if ALight.ColorChance > 255 then
          ALight.ColorChance := 255;
      end;
    TDynLightToken.Offset:
      begin
        AScanner.MustGetInteger;
        ALight.OffsetX1 := AScanner.AsInteger / FMapCoefficient;
        ALight.OffsetX2 := ALight.OffsetX1;
        AScanner.MustGetInteger;
        ALight.OffsetY1 := AScanner.AsInteger / FMapCoefficient;
        ALight.OffsetY2 := ALight.OffsetY1;
        AScanner.MustGetInteger;
        ALight.OffsetZ1 := AScanner.AsInteger / FMapCoefficient;
        ALight.OffsetZ2 := ALight.OffsetZ1;
      end;
    TDynLightToken.SecondaryOffset:
      begin
        AScanner.MustGetInteger;
        ALight.OffsetX2 := AScanner.AsInteger / FMapCoefficient;
        AScanner.MustGetInteger;
        ALight.OffsetY2 := AScanner.AsInteger / FMapCoefficient;
        AScanner.MustGetInteger;
        ALight.OffsetZ2 := AScanner.AsInteger / FMapCoefficient;
      end;
    TDynLightToken.RandomOffset:
      ALight.RandomOffset := True;
  else
    // not a property: the light is finished
    Result := False;
  end;
end;

function TDynLightParser.ReadLights(AScanner: TScriptScanner): Boolean;
var
  LToken: TDynLightToken;
  LLight: TDynLightDefinition;
  LHigh: Integer;
  LLow: Integer;
begin
  Result := False;
  while AScanner.GetString do
  begin
    LToken := TDynLightTokens.Classify(TScannerStrings.UpperAscii(AScanner.AsString));
    case LToken of
      TDynLightToken.PointLight, TDynLightToken.FlickerLight, TDynLightToken.PulseLight:
        begin
          LLight := Default(TDynLightDefinition);
          case LToken of
            TDynLightToken.PointLight:
              LLight.Kind := TDynLightKind.Point;
            TDynLightToken.FlickerLight:
              LLight.Kind := TDynLightKind.Flicker;
          else
            LLight.Kind := TDynLightKind.Pulse;
          end;
          LHigh := FServices.Random.NextByte;
          LLow := FServices.Random.NextByte;
          LLight.RandomSeed := LHigh * 256 + LLow;
          if not AScanner.GetString then
          begin
            Warn('SC_ParceDynamicLight(): Token expected at line %d'#13#10, [AScanner.Line]);
            Break;
          end;
          LLight.Name := Copy(TScannerStrings.UpperAscii(AScanner.AsString), 1, DYNLIGHT_NAME_LENGTH);

          while AScanner.GetString do
          begin
            LToken := TDynLightTokens.Classify(TScannerStrings.UpperAscii(AScanner.AsString));
            if not ReadProperty(AScanner, LToken, LLight) then
            begin
              FServices.Registry.Add(LLight);
              AScanner.UnGet;
              Break;
            end;
          end;
        end;
      TDynLightToken.ObjectKeyword:
        Result := True;
    end;
  end;
end;

procedure TDynLightParser.ReadObjectLine(AScanner: TScriptScanner; const ALine: string;
  ALineIndex: Integer; var AObject: Integer; var AObjectName: string);
begin
  AScanner.SetText(ALine);
  AScanner.MustGetString;
  AScanner.MustGetString;
  AObjectName := AScanner.AsString;
  if AObjectName = '-1' then
  begin
    AObject := -1;
    AObjectName := '';
  end
  else
  begin
    AObject := FServices.Objects.ObjectForName(AObjectName);
    if AObject < 0 then
    begin
      // the line number of this message starts at 0, like the old one
      Warn('SC_ParceDynamicLight(): Unknown object "%s" at line %d'#13#10, [AObjectName, ALineIndex]);
      AObjectName := '';
    end;
  end;
end;

procedure TDynLightParser.ReadFrameLine(AScanner: TScriptScanner; const ALine: string;
  ALineIndex: Integer; AObject: Integer; const AObjectName: string);
var
  LToken2: string;
  LToken3: string;
  LToken4: string;
  LSpriteName: string;
  LLight: Integer;
  LSprite: Integer;
  LFrame: Integer;
  LHasFrame: Boolean;
begin
  AScanner.SetText(ALine);
  // when a word is missing the one before stays, as in the old code
  AScanner.MustGetString;
  AScanner.MustGetString;
  LToken2 := AScanner.AsString;
  AScanner.MustGetString;
  LToken3 := AScanner.AsString;
  AScanner.MustGetString;
  LToken4 := AScanner.AsString;

  if LToken3 <> 'LIGHT' then
  begin
    Warn('SC_ParceDynamicLight(): Unknown token %s at line %d'#13#10, [LToken3, ALineIndex + 1]);
    Exit;
  end;
  LLight := FServices.Registry.Find(LToken4);
  if LLight < 0 then
  begin
    Warn('SC_ParceDynamicLight(): Unknown light %s at line %d'#13#10, [LToken4, ALineIndex + 1]);
    Exit;
  end;
  if Length(LToken2) < 4 then
  begin
    Warn('SC_ParceDynamicLight(): Unknown sprite %s at line %d'#13#10, [LToken2, ALineIndex + 1]);
    Exit;
  end;
  LSpriteName := Copy(LToken2, 1, 4);
  LSprite := FServices.Sprites.SpriteForName(LSpriteName);
  if LSprite < 0 then
  begin
    Warn('SC_ParceDynamicLight(): Unknown sprite %s at line %d'#13#10, [LSpriteName, ALineIndex + 1]);
    Exit;
  end;

  LHasFrame := Length(LToken2) > 4;
  LFrame := 0;
  if LHasFrame then
    LFrame := Ord(LToken2[5]) - Ord('A');
  if not FServices.Binder.Bind(AObject, LSprite, LFrame, LHasFrame, LLight) then
  begin
    if AObject < 0 then
      Warn('SC_ParceDynamicLight(): Can not determine light owner, line %d: "%s",'#13#10,
        [ALineIndex + 1, ALine])
    else
      Warn('SC_ParceDynamicLight(): Can not determine light for object "%s", line %d: "%s",'#13#10,
        [AObjectName, ALineIndex + 1, ALine]);
  end;
end;

procedure TDynLightParser.BindFrames(AScanner: TScriptScanner; const AText: string);
var
  LLines: TArray<string>;
  LIndex: Integer;
  LLine: string;
  LObject: Integer;
  LObjectName: string;
begin
  LObject := -1;
  LObjectName := '';
  LLines := TScannerStrings.SplitLines(AText);
  for LIndex := 0 to High(LLines) do
  begin
    LLine := TScannerStrings.UpperAscii(TScannerStrings.Trim(LLines[LIndex]));
    if FirstWord(LLine) = 'OBJECT' then
      ReadObjectLine(AScanner, LLine, LIndex, LObject, LObjectName)
    else if FirstWord(LLine) = 'FRAME' then
      ReadFrameLine(AScanner, LLine, LIndex, LObject, LObjectName);
  end;
end;

procedure TDynLightParser.Parse(const AText: string);
var
  LScanner: TScriptScanner;
  LObjectsFound: Boolean;
begin
  if Assigned(FServices.Context) and FServices.Context.IsDeveloperMode then
    ListText(AText);

  LScanner := TScriptScanner.Create(AText, FLog);
  try
    LObjectsFound := ReadLights(LScanner);
    FServices.Binder.BeginScript;
    // the frames: one simplified pass on the lines, as the old code did
    if LObjectsFound then
      BindFrames(LScanner, AText);
  finally
    LScanner.Free;
  end;
end;

end.
