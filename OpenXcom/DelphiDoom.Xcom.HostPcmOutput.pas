{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the sound output of the game on the one of the host     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostPcmOutput;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.GameHost.Audio.Intf;

type
  /// <summary>
  ///   IXcomPcmOutput on the sound output of Libs\GameHost (waveOut). The mixer of the game is asked through a
  ///   bridge that does not keep it alive (the mixer owns its output, not the other way round): when the mixer is
  ///   gone the output plays silence until it is closed
  /// </summary>
  TXcomHostPcmOutput = class(TInterfacedObject, IXcomPcmOutput)
  strict private
    FOutput: IGameHostPcmOutput;
    FBridge: IGameHostPcmSource;
  public
    constructor Create(const AOutput: IGameHostPcmOutput);
    destructor Destroy; override;
    function Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
  end;

implementation

type
  /// <summary>The source the host output asks: the mixer of the game, by a weak reference</summary>
  TXcomHostPcmBridge = class(TInterfacedObject, IGameHostPcmSource)
  strict private
    [weak] FSource: IXcomPcmSource;
  public
    constructor Create(const ASource: IXcomPcmSource);
    procedure Render(ABuffer: PByte; AByteCount: Integer);
  end;

{ TXcomHostPcmBridge }

constructor TXcomHostPcmBridge.Create(const ASource: IXcomPcmSource);
begin
  inherited Create;
  FSource := ASource;
end;

procedure TXcomHostPcmBridge.Render(ABuffer: PByte; AByteCount: Integer);
var
  LSource: IXcomPcmSource;
begin
  // a strong reference for the time of the call: this is the thread of the output
  LSource := FSource;
  if LSource <> nil then
    LSource.Render(ABuffer, AByteCount)
  else
    FillChar(ABuffer^, AByteCount, 0);
end;

{ TXcomHostPcmOutput }

constructor TXcomHostPcmOutput.Create(const AOutput: IGameHostPcmOutput);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  FOutput := AOutput;
end;

destructor TXcomHostPcmOutput.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TXcomHostPcmOutput.Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
begin
  if FOutput.IsOpen then
    Exit(True);
  // the host output does not keep its source alive: the bridge lives here until Close
  FBridge := TXcomHostPcmBridge.Create(ASource);
  Result := FOutput.Open(ARate, FBridge);
  if not Result then
    FBridge := nil;
end;

procedure TXcomHostPcmOutput.Close;
begin
  if Assigned(FOutput) then
    FOutput.Close;
  FBridge := nil;
end;

function TXcomHostPcmOutput.IsOpen: Boolean;
begin
  Result := FOutput.IsOpen;
end;

end.
