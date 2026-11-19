{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - a collision world for the    }
{  clip: the manager with the models of Tests\Data\Collision\Doom3\room.cm     }
{  (the model "worldMap" is a room) and the clip built on it                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.ClipRig;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Collision.Intf, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.Clip;

type
  /// <summary>The printer of the clip: every line is written to a list as the clip harness writes it (PRINT, WARNING, ERROR)</summary>
  TD3ClipTestPrinter = class(TInterfacedObject, ID3GamePrinter)
  strict private
    FLines: TStrings;
    function Trimmed(const AText: AnsiString): string;
  public
    constructor Create(const ALines: TStrings);
    /// <summary>Where the lines go from now on</summary>
    property Lines: TStrings read FLines write FLines;
    procedure Printf(const AText: AnsiString);
    procedure Warning(const AText: AnsiString);
    procedure Error(const AText: AnsiString);
  end;

  /// <summary>
  ///   The collision manager with the room and a clip on it (not initialised: <c>Clip.Init</c> builds the sectors). The
  ///   entities of the game that uses the clip must be freed before the clip: free the game first, then this.
  /// </summary>
  TD3ClipWorld = class
  strict private
    FManager: ICollisionModelManager;
    FPrinter: ID3GamePrinter;
    FPrinterObject: TD3ClipTestPrinter;
    FClip: TD3Clip;
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>What the clip printed (until <c>PrintTo</c>)</summary>
    property Lines: TStringList read FLines;
    /// <summary>Sends the lines the clip prints to another list</summary>
    procedure PrintTo(const ALines: TStrings);
    property Manager: ICollisionModelManager read FManager;
    property Clip: TD3Clip read FClip;
  end;

implementation

uses
  DelphiDoom.Collision.Factory, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Collision.Support;

{ TD3ClipTestPrinter }

constructor TD3ClipTestPrinter.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

function TD3ClipTestPrinter.Trimmed(const AText: AnsiString): string;
begin
  Result := string(AText);
  while (Length(Result) > 0) and (Result[Length(Result)] = #10) do
    Delete(Result, Length(Result), 1);
end;

procedure TD3ClipTestPrinter.Printf(const AText: AnsiString);
begin
  FLines.Add('PRINT ' + Trimmed(AText));
end;

procedure TD3ClipTestPrinter.Warning(const AText: AnsiString);
begin
  FLines.Add('WARNING ' + Trimmed(AText));
end;

procedure TD3ClipTestPrinter.Error(const AText: AnsiString);
begin
  FLines.Add('ERROR ' + Trimmed(AText));
end;

{ TD3ClipWorld }

constructor TD3ClipWorld.Create;
var
  LStream: TFileStream;
begin
  inherited Create;
  FLines := TStringList.Create;
  FManager := TCollisionFactory.CreateManager(CreateDoom3Catalog, nil);
  LStream := TFileStream.Create(TTestFiles.DataFile('Collision', 'Doom3\room.cm'), fmOpenRead or fmShareDenyWrite);
  try
    FManager.LoadModelFile(LStream, 0);
  finally
    LStream.Free;
  end;
  FPrinterObject := TD3ClipTestPrinter.Create(FLines);
  FPrinter := FPrinterObject;
  FClip := TD3Clip.Create(FManager, nil, FPrinter);
end;

procedure TD3ClipWorld.PrintTo(const ALines: TStrings);
begin
  FPrinterObject.Lines := ALines;
end;

destructor TD3ClipWorld.Destroy;
begin
  FClip.Free;
  FPrinter := nil;
  FManager := nil;
  FLines.Free;
  inherited Destroy;
end;

end.
