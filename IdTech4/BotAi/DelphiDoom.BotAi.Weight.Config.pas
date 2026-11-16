{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightConfig, a weight configuration               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): weightconfig_t and  }
{  FindFuzzyWeight of code\botlib\be_ai_weight.c. Based on the Quake III Arena }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Config;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Weight.Separator;

type
  /// <summary>
  ///   weightconfig_t: the named fuzzy weights of a file. The weights are numbered from 0 in the order
  ///   of the file; each has the first case of its switch (<c>firstseperator</c>).
  /// </summary>
  TBotWeightConfig = class
  strict private
    FFileName: AnsiString;
    FNames: TList<AnsiString>;
    FSeparators: TObjectList<TBotFuzzySeparator>;
    function GetCount: Integer;
    function GetName(const AIndex: Integer): AnsiString;
    function GetFirstSeparator(const AIndex: Integer): TBotFuzzySeparator;
  public
    constructor Create(const AFileName: AnsiString);
    destructor Destroy; override;
    /// <summary>Adds a weight; the configuration owns the separator</summary>
    procedure Add(const AName: AnsiString; const AFirstSeparator: TBotFuzzySeparator);
    /// <summary>FindFuzzyWeight: the number of the weight with the name, -1 if there is none</summary>
    function FindFuzzyWeight(const AName: AnsiString): Integer;
    /// <summary>numweights</summary>
    property Count: Integer read GetCount;
    property FileName: AnsiString read FFileName;
    property Names[const AIndex: Integer]: AnsiString read GetName;
    property FirstSeparator[const AIndex: Integer]: TBotFuzzySeparator read GetFirstSeparator;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Exceptions;

{ TBotWeightConfig }

constructor TBotWeightConfig.Create(const AFileName: AnsiString);
begin
  inherited Create;
  FFileName := AFileName;
  FNames := TList<AnsiString>.Create;
  FSeparators := TObjectList<TBotFuzzySeparator>.Create(True);
end;

destructor TBotWeightConfig.Destroy;
begin
  FSeparators.Free;
  FNames.Free;
  inherited Destroy;
end;

function TBotWeightConfig.GetCount: Integer;
begin
  Result := FNames.Count;
end;

function TBotWeightConfig.GetName(const AIndex: Integer): AnsiString;
begin
  if (AIndex < 0) or (AIndex >= FNames.Count) then
    raise EBotAiException.CreateFmt('weight %d does not exist', [AIndex]);
  Result := FNames[AIndex];
end;

function TBotWeightConfig.GetFirstSeparator(const AIndex: Integer): TBotFuzzySeparator;
begin
  if (AIndex < 0) or (AIndex >= FNames.Count) then
    raise EBotAiException.CreateFmt('weight %d does not exist', [AIndex]);
  Result := FSeparators[AIndex];
end;

procedure TBotWeightConfig.Add(const AName: AnsiString; const AFirstSeparator: TBotFuzzySeparator);
begin
  FNames.Add(AName);
  FSeparators.Add(AFirstSeparator);
end;

function TBotWeightConfig.FindFuzzyWeight(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FNames.Count - 1 do
  begin
    if FNames[LIndex] = AName then
      Exit(LIndex);
  end;
  Result := -1;
end;

end.
