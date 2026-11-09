{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - fakes for the MODELDEF parser  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.DefinitionFakes;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Definition.Types,
  DelphiDoom.Models.Definition.Intf;

type
  /// <summary>A log that keeps the text of every warning as it was given</summary>
  TModelsFakeLog = class(TInterfacedObject, ILog)
  strict private
    FWarnings: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TStringList read FWarnings;
  end;

  /// <summary>
  ///   A sink that writes a line for every call; a model or a texture with a name it already has
  ///   gives the old index (as gld_AddModel and gld_AddModelTexture do)
  /// </summary>
  TModelsFakeDefinitionSink = class(TInterfacedObject, IModelDefinitionSink)
  strict private
    FLines: TStringList;
    FModels: TStringList;
    FTextures: TStringList;
    class function Bits(const AValue: Single): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    function AddModel(const AItem: TModelDefinitionItem): Integer;
    function AddTexture(const AName: string): Integer;
    procedure AddState(const AState: TModelDefinitionState);
    property Lines: TStringList read FLines;
  end;

  /// <summary>Three states: S_NULL (0), S_PLAY (1) and S_PLAY_RUN1 (2)</summary>
  TModelsFakeDefinitionLookup = class(TInterfacedObject, IModelDefinitionLookup)
  public
    function FindState(const AName: string): Integer;
  end;

implementation

{ TModelsFakeLog }

constructor TModelsFakeLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TModelsFakeLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TModelsFakeLog.Info(const AText: string);
begin
end;

procedure TModelsFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TModelsFakeLog.DevWarning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TModelsFakeLog.Error(const AText: string);
begin
  FWarnings.Add(AText);
end;

{ TModelsFakeDefinitionSink }

constructor TModelsFakeDefinitionSink.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FModels := TStringList.Create;
  FTextures := TStringList.Create;
end;

destructor TModelsFakeDefinitionSink.Destroy;
begin
  FTextures.Free;
  FModels.Free;
  FLines.Free;
  inherited Destroy;
end;

class function TModelsFakeDefinitionSink.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

function TModelsFakeDefinitionSink.AddModel(const AItem: TModelDefinitionItem): Integer;
var
  LMerge: string;
  LIndex: Integer;
begin
  LMerge := '';
  for LIndex := 0 to High(AItem.FrameMerge) do
    LMerge := LMerge + AItem.FrameMerge[LIndex] + ';';
  Result := FModels.IndexOf(AItem.Name);
  FLines.Add(Format('M %s|%s|%s %s %s|%s %s %s|%s -> %d', [AItem.Name, AItem.Proc,
    Bits(AItem.XOffset), Bits(AItem.YOffset), Bits(AItem.ZOffset),
    Bits(AItem.XScale), Bits(AItem.YScale), Bits(AItem.ZScale), LMerge, Result]));
  if Result < 0 then
    Result := FModels.Add(AItem.Name);
end;

function TModelsFakeDefinitionSink.AddTexture(const AName: string): Integer;
begin
  Result := FTextures.IndexOf(AName);
  if Result < 0 then
    Result := FTextures.Add(AName);
  FLines.Add(Format('T %s -> %d', [AName, Result]));
end;

procedure TModelsFakeDefinitionSink.AddState(const AState: TModelDefinitionState);
begin
  FLines.Add(Format('S %d|%d|%d|%d|%d|%d|%s', [AState.ModelIndex, AState.Texture, AState.StartFrame,
    AState.EndFrame, AState.NextFrame, AState.State, Bits(AState.Transparency)]));
end;

{ TModelsFakeDefinitionLookup }

function TModelsFakeDefinitionLookup.FindState(const AName: string): Integer;
begin
  if AName = 'S_NULL' then
    Result := 0
  else if AName = 'S_PLAY' then
    Result := 1
  else if AName = 'S_PLAY_RUN1' then
    Result := 2
  else
    Result := -1;
end;

end.
