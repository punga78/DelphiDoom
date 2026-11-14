{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - fakes of the drawing of the windows  }
{                                                                              }
{  The things the harness of the C++ of Doom 3 (Tools\Verifica\111) has in     }
{  its driver: files in memory, materials, the renderer that writes what it   }
{  is asked and the fonts made by a formula.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.DrawFakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.DeviceContext.Intf, DelphiDoom.Gui.Window.Keys, DelphiDoom.Gui.Cvars, DelphiDoom.Gui.Regs.Intf;

type
  /// <summary>The bits of a float in hexadecimal, as the harness writes them</summary>
  TGuiBits = class
  public
    class function Float(const AValue: Single): string; static;
    class function Vec4(const AValue: TIdVec4): string; static;
  end;

  /// <summary>The console variables of the harness: a window that sets one writes the line "host cvar set name value"</summary>
  TGuiHarnessCvars = class(TGuiCvarSet)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure SetString(const AName, AValue: AnsiString); override;
  end;

  /// <summary>idLangDict of the harness: it has no strings; a string id is reported and returned as it is</summary>
  TGuiHarnessLanguage = class(TInterfacedObject, IGuiLanguage)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    function GetString(const AText: AnsiString): AnsiString;
  end;

  /// <summary>The keys that are down (idKeyInput::IsDown): the scenarios set them</summary>
  TGuiHarnessKeys = class(TInterfacedObject, IGuiKeyState)
  strict private
    FDown: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetDown(const AKey: Integer; const AValue: Boolean);
    function IsDown(const AKey: Integer): Boolean;
  end;

  /// <summary>Files in memory: the names are in lower case with "/" (the driver of the harness does the same)</summary>
  TGuiHarnessFiles = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
    FClock: Int64;
    function Normalize(const AName: AnsiString): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const AName, AContent: AnsiString); overload;
    procedure Add(const AName: AnsiString; const ABytes: TBytes); overload;
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

  /// <summary>The three .dat files of a font (12, 24 and 48 points), made by the formula of the C++ driver</summary>
  TGuiHarnessFonts = class
  public
    /// <summary>The 20548 bytes of fontImage_N.dat for a point size</summary>
    class function Data(const APointSize: Integer): TBytes; static;
    /// <summary>fontImage_12.dat, _24 and _48 in a folder of the files</summary>
    class procedure AddSet(const AFiles: TGuiHarnessFiles; const AFolder: AnsiString); static;
  end;

  /// <summary>The images and the cinematic of the materials the scenarios name; lines "M name update t" go to the log</summary>
  TGuiHarnessMaterials = class(TInterfacedObject, IGuiMaterialLookup)
  strict private
    type
      TInfo = record
        Width: Integer;
        Height: Integer;
        Cinematic: Integer;
        Defaulted: Boolean;
      end;
    var
      FInfo: TDictionary<string, TInfo>;
      FMaterials: TDictionary<string, IGuiMaterial>;
      FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    destructor Destroy; override;
    procedure Clear;
    /// <summary>The size of the image and the cinematic of a material (16 by 16 and none by default)</summary>
    procedure SetInfo(const AName: AnsiString; const AWidth, AHeight, ACinematic: Integer; const ADefaulted: Boolean);
    function GetWidth(const AName: AnsiString): Integer;
    function GetHeight(const AName: AnsiString): Integer;
    function GetCinematic(const AName: AnsiString): Integer;
    function GetDefaulted(const AName: AnsiString): Boolean;
    procedure Report(const AText: string);
    function FindMaterial(const AName: AnsiString): IGuiMaterial;
  end;

  /// <summary>renderSystem as a list of lines: "C color" for SetColor and "Q material transformed x y z s t (four times)"</summary>
  TGuiHarnessSurface = class(TInterfacedObject, IGuiDeviceContext)
  strict private
    FLines: TStrings;
  public
    constructor Create(const ALines: TStrings);
    procedure SetColor(const AColor: TGuiColor); overload;
    procedure DrawHandlePic(const ARect: TGuiRect; const AAsset: Integer);
    procedure FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
    procedure DrawRect(const ARect: TGuiRect; const ASize: Single; const AColor: TGuiColor);
    procedure DrawText(const AX, AY, AScale: Single; const AColor: TGuiColor; const AText: AnsiString;
      const AAdjust: Single; const ALimit, AStyle: Integer);
    function TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    function TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    procedure SetColor(const AColor: TIdVec4); overload;
    procedure DrawStretchPic(const AQuad: TGuiQuad; const AMaterial: IGuiMaterial; const ATransformed: Boolean);
  end;

implementation

type
  TGuiHarnessMaterial = class(TInterfacedObject, IGuiMaterial)
  strict private
    FOwner: TGuiHarnessMaterials;
    FName: AnsiString;
  public
    constructor Create(const AOwner: TGuiHarnessMaterials; const AName: AnsiString);
    function GetName: AnsiString;
    function GetImageWidth: Integer;
    function GetImageHeight: Integer;
    function GetCinematicLength: Integer;
    procedure UpdateCinematic(const ATime: Integer);
    procedure ResetCinematicTime(const ATime: Integer);
    function IsDefaulted: Boolean;
    procedure SetGuiSort;
  end;

{ TGuiHarnessCvars }

constructor TGuiHarnessCvars.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiHarnessCvars.SetString(const AName, AValue: AnsiString);
begin
  FLines.Add('host cvar set ' + string(AName) + ' ' + string(AValue));
  inherited SetString(AName, AValue);
end;

{ TGuiHarnessLanguage }

constructor TGuiHarnessLanguage.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

function TGuiHarnessLanguage.GetString(const AText: AnsiString): AnsiString;
begin
  Result := AText;
  if (AText <> '') and (Copy(AText, 1, 5) = '#str_') then
    FLines.Add('W: Unknown string id ' + string(AText));
end;

{ TGuiHarnessKeys }

constructor TGuiHarnessKeys.Create;
begin
  inherited Create;
  FDown := TList<Integer>.Create;
end;

destructor TGuiHarnessKeys.Destroy;
begin
  FDown.Free;
  inherited Destroy;
end;

procedure TGuiHarnessKeys.Clear;
begin
  FDown.Clear;
end;

procedure TGuiHarnessKeys.SetDown(const AKey: Integer; const AValue: Boolean);
begin
  if AValue then
  begin
    if FDown.IndexOf(AKey) < 0 then
      FDown.Add(AKey);
  end
  else
    FDown.Remove(AKey);
end;

function TGuiHarnessKeys.IsDown(const AKey: Integer): Boolean;
begin
  Result := FDown.IndexOf(AKey) >= 0;
end;

{ TGuiBits }

class function TGuiBits.Float(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

class function TGuiBits.Vec4(const AValue: TIdVec4): string;
begin
  Result := Float(AValue.X) + ' ' + Float(AValue.Y) + ' ' + Float(AValue.Z) + ' ' + Float(AValue.W);
end;

{ TGuiHarnessFiles }

constructor TGuiHarnessFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TGuiHarnessFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TGuiHarnessFiles.Normalize(const AName: AnsiString): string;
begin
  Result := LowerCase(StringReplace(string(AName), '\', '/', [rfReplaceAll]));
end;

procedure TGuiHarnessFiles.Clear;
begin
  FFiles.Clear;
end;

procedure TGuiHarnessFiles.Add(const AName, AContent: AnsiString);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AContent));
  if Length(AContent) > 0 then
    Move(AContent[1], LBytes[0], Length(AContent));
  Add(AName, LBytes);
end;

procedure TGuiHarnessFiles.Add(const AName: AnsiString; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(Normalize(AName), ABytes);
end;

function TGuiHarnessFiles.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LBytes: TBytes;
begin
  Result := FFiles.TryGetValue(Normalize(AName), LBytes);
  if Result then
  begin
    AFile.Data := LBytes;
    AFile.FullPath := AName;
    Inc(FClock);
    AFile.Timestamp := 1000 + FClock;
  end;
end;

function TGuiHarnessFiles.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Add(AName, AData);
  Result := True;
end;

{ TGuiHarnessFonts }

class function TGuiHarnessFonts.Data(const APointSize: Integer): TBytes;
var
  LOffset: Integer;
  LIndex: Integer;
  LHeight, LTop, LBottom, LPitch, LSkip, LImageWidth, LImageHeight: Integer;
  LS, LT, LS2, LT2, LScale: Single;
  LShader: AnsiString;
  LName: AnsiString;

  procedure PutInt(const AValue: Integer);
  begin
    Move(AValue, Result[LOffset], 4);
    Inc(LOffset, 4);
  end;

  procedure PutFloat(const AValue: Single);
  begin
    Move(AValue, Result[LOffset], 4);
    Inc(LOffset, 4);
  end;

begin
  SetLength(Result, 256 * 80 + 4 + 64);
  FillChar(Result[0], Length(Result), 0);
  LOffset := 0;
  for LIndex := 0 to 255 do
  begin
    LHeight := 6 + APointSize div 4 + (LIndex mod 5);
    LTop := LHeight - 2 + (LIndex mod 3);
    LBottom := LIndex mod 2;
    LPitch := 8;
    LSkip := 4 + APointSize div 6 + (LIndex mod 7);
    LImageWidth := LSkip + 2;
    LImageHeight := LHeight + 1;
    LS := Single(LIndex mod 16) / 16.0;
    LT := Single(LIndex div 16) / 16.0;
    LS2 := LS + 0.0625;
    LT2 := LT + 0.0625;
    PutInt(LHeight);
    PutInt(LTop);
    PutInt(LBottom);
    PutInt(LPitch);
    PutInt(LSkip);
    PutInt(LImageWidth);
    PutInt(LImageHeight);
    PutFloat(LS);
    PutFloat(LT);
    PutFloat(LS2);
    PutFloat(LT2);
    PutInt(0);
    LShader := AnsiString(Format('xxxxxxg%d_%d', [APointSize, LIndex]));
    Move(LShader[1], Result[LOffset], Length(LShader));
    Inc(LOffset, 32);
  end;
  LScale := 48.0 / APointSize;
  PutFloat(LScale);
  LName := AnsiString(Format('fonts/english/fontImage_%d.dat', [APointSize]));
  Move(LName[1], Result[LOffset], Length(LName));
end;

class procedure TGuiHarnessFonts.AddSet(const AFiles: TGuiHarnessFiles; const AFolder: AnsiString);
begin
  AFiles.Add(AFolder + '/fontImage_12.dat', Data(12));
  AFiles.Add(AFolder + '/fontImage_24.dat', Data(24));
  AFiles.Add(AFolder + '/fontImage_48.dat', Data(48));
end;

{ TGuiHarnessMaterial }

constructor TGuiHarnessMaterial.Create(const AOwner: TGuiHarnessMaterials; const AName: AnsiString);
begin
  inherited Create;
  FOwner := AOwner;
  FName := AName;
end;

function TGuiHarnessMaterial.GetName: AnsiString;
begin
  Result := FName;
end;

function TGuiHarnessMaterial.GetImageWidth: Integer;
begin
  Result := FOwner.GetWidth(FName);
end;

function TGuiHarnessMaterial.GetImageHeight: Integer;
begin
  Result := FOwner.GetHeight(FName);
end;

function TGuiHarnessMaterial.GetCinematicLength: Integer;
begin
  Result := FOwner.GetCinematic(FName);
end;

procedure TGuiHarnessMaterial.UpdateCinematic(const ATime: Integer);
begin
  FOwner.Report(Format('M %s update %d', [string(FName), ATime]));
end;

procedure TGuiHarnessMaterial.ResetCinematicTime(const ATime: Integer);
begin
  FOwner.Report(Format('M %s reset %d', [string(FName), ATime]));
end;

function TGuiHarnessMaterial.IsDefaulted: Boolean;
begin
  Result := FOwner.GetDefaulted(FName);
end;

procedure TGuiHarnessMaterial.SetGuiSort;
begin
end;

{ TGuiHarnessMaterials }

constructor TGuiHarnessMaterials.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FInfo := TDictionary<string, TInfo>.Create;
  FMaterials := TDictionary<string, IGuiMaterial>.Create;
end;

destructor TGuiHarnessMaterials.Destroy;
begin
  FMaterials.Free;
  FInfo.Free;
  inherited Destroy;
end;

procedure TGuiHarnessMaterials.Clear;
begin
  FInfo.Clear;
end;

procedure TGuiHarnessMaterials.SetInfo(const AName: AnsiString; const AWidth, AHeight, ACinematic: Integer;
  const ADefaulted: Boolean);
var
  LInfo: TInfo;
begin
  LInfo.Width := AWidth;
  LInfo.Height := AHeight;
  LInfo.Cinematic := ACinematic;
  LInfo.Defaulted := ADefaulted;
  FInfo.AddOrSetValue(string(AName), LInfo);
end;

function TGuiHarnessMaterials.GetWidth(const AName: AnsiString): Integer;
var
  LInfo: TInfo;
begin
  if FInfo.TryGetValue(string(AName), LInfo) then
    Result := LInfo.Width
  else
    Result := 16;
end;

function TGuiHarnessMaterials.GetHeight(const AName: AnsiString): Integer;
var
  LInfo: TInfo;
begin
  if FInfo.TryGetValue(string(AName), LInfo) then
    Result := LInfo.Height
  else
    Result := 16;
end;

function TGuiHarnessMaterials.GetCinematic(const AName: AnsiString): Integer;
var
  LInfo: TInfo;
begin
  if FInfo.TryGetValue(string(AName), LInfo) then
    Result := LInfo.Cinematic
  else
    Result := 0;
end;

function TGuiHarnessMaterials.GetDefaulted(const AName: AnsiString): Boolean;
var
  LInfo: TInfo;
begin
  Result := FInfo.TryGetValue(string(AName), LInfo) and LInfo.Defaulted;
end;

procedure TGuiHarnessMaterials.Report(const AText: string);
begin
  FLines.Add(AText);
end;

function TGuiHarnessMaterials.FindMaterial(const AName: AnsiString): IGuiMaterial;
begin
  if not FMaterials.TryGetValue(string(AName), Result) then
  begin
    Result := TGuiHarnessMaterial.Create(Self, AName);
    FMaterials.Add(string(AName), Result);
  end;
end;

{ TGuiHarnessSurface }

constructor TGuiHarnessSurface.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TGuiHarnessSurface.SetColor(const AColor: TGuiColor);
begin
end;

procedure TGuiHarnessSurface.DrawHandlePic(const ARect: TGuiRect; const AAsset: Integer);
begin
end;

procedure TGuiHarnessSurface.FillRect(const ARect: TGuiRect; const AColor: TGuiColor);
begin
end;

procedure TGuiHarnessSurface.DrawRect(const ARect: TGuiRect; const ASize: Single; const AColor: TGuiColor);
begin
end;

procedure TGuiHarnessSurface.DrawText(const AX, AY, AScale: Single; const AColor: TGuiColor; const AText: AnsiString;
  const AAdjust: Single; const ALimit, AStyle: Integer);
begin
end;

function TGuiHarnessSurface.TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
begin
  Result := 0;
end;

function TGuiHarnessSurface.TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
begin
  Result := 0;
end;

procedure TGuiHarnessSurface.SetColor(const AColor: TIdVec4);
begin
  FLines.Add('C ' + TGuiBits.Vec4(AColor));
end;

procedure TGuiHarnessSurface.DrawStretchPic(const AQuad: TGuiQuad; const AMaterial: IGuiMaterial;
  const ATransformed: Boolean);
var
  LLine: string;
  LIndex: Integer;
begin
  if Assigned(AMaterial) then
    LLine := 'Q ' + string(AMaterial.GetName)
  else
    LLine := 'Q -';
  if ATransformed then
    LLine := LLine + ' 1'
  else
    LLine := LLine + ' 0';
  for LIndex := 0 to 3 do
    LLine := LLine + ' ' + TGuiBits.Float(AQuad[LIndex].Xyz.X) + ' ' + TGuiBits.Float(AQuad[LIndex].Xyz.Y) + ' ' +
      TGuiBits.Float(AQuad[LIndex].Xyz.Z) + ' ' + TGuiBits.Float(AQuad[LIndex].S) + ' ' +
      TGuiBits.Float(AQuad[LIndex].T);
  FLines.Add(LLine);
end;

end.
