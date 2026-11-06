{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MUSINFO library - the fakes of the game           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MusInfo.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Intf;

type
  /// <summary>
  ///   The rule of the stub that the harness of the golden file was linked with: a music exists
  ///   if its name starts with D_ and its number comes from the name; any other name gives -1.
  ///   It remembers the names it was asked for
  /// </summary>
  TFakeMusic = class(TInterfacedObject, IMusInfoMusicResolver)
  private
    FAsked: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    function MusicNumberFor(const AUpperName: string): Integer;
    class function NumberOf(const AName: string): Integer; static;
    property Asked: TList<string> read FAsked;
  end;

  /// <summary>The text of the lump, or no lump</summary>
  TFakeTextSource = class(TInterfacedObject, IMusInfoTextSource)
  private
    FPresent: Boolean;
    FText: string;
    FAskedName: string;
  public
    constructor Create(APresent: Boolean; const AText: string);
    function TryGetText(const AUpperName: string; out AText: string): Boolean;
    property AskedName: string read FAskedName;
  end;

  /// <summary>The warnings as they were written, with nothing added</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FWarnings: string;
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: string read FWarnings;
  end;

implementation

{ TFakeMusic }

constructor TFakeMusic.Create;
begin
  inherited Create;
  FAsked := TList<string>.Create;
end;

destructor TFakeMusic.Destroy;
begin
  FAsked.Free;
  inherited Destroy;
end;

class function TFakeMusic.NumberOf(const AName: string): Integer;
var
  LUpper: string;
  LIndex: Integer;
  LSum: Integer;
begin
  LUpper := AName;
  for LIndex := 1 to Length(LUpper) do
    if (LUpper[LIndex] >= 'a') and (LUpper[LIndex] <= 'z') then
      LUpper[LIndex] := Char(Ord(LUpper[LIndex]) - 32);
  if (Length(LUpper) >= 2) and (LUpper[1] = 'D') and (LUpper[2] = '_') then
  begin
    LSum := 0;
    for LIndex := 1 to Length(LUpper) do
      Inc(LSum, Ord(LUpper[LIndex]));
    Result := 1000 + Length(LUpper) * 100 + (LSum mod 97);
  end
  else
    Result := -1;
end;

function TFakeMusic.MusicNumberFor(const AUpperName: string): Integer;
begin
  FAsked.Add(AUpperName);
  Result := NumberOf(AUpperName);
end;

{ TFakeTextSource }

constructor TFakeTextSource.Create(APresent: Boolean; const AText: string);
begin
  inherited Create;
  FPresent := APresent;
  FText := AText;
end;

function TFakeTextSource.TryGetText(const AUpperName: string; out AText: string): Boolean;
begin
  FAskedName := AUpperName;
  Result := FPresent;
  if Result then
    AText := FText
  else
    AText := '';
end;

{ TFakeLog }

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings := FWarnings + AText;
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

end.
