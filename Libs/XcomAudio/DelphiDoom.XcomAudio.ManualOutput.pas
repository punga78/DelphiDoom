{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - an output that plays nowhere: the caller    }
{  asks for the samples (for the tests and for the programs without a device)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.ManualOutput;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomPcmOutput for tests: Open keeps a weak reference to the source and Pump asks it for the samples, as the
  ///   thread of a real device would. Without a device (AAvailable false) Open fails
  /// </summary>
  TXcomManualPcmOutput = class(TInterfacedObject, IXcomPcmOutput)
  strict private
    [weak] FSource: IXcomPcmSource;
    FOpen: Boolean;
    FAvailable: Boolean;
    FRate: Integer;
  public
    constructor Create(AAvailable: Boolean = True);
    function Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>The next ABytes bytes of samples (empty when the output is closed)</summary>
    function Pump(ABytes: Integer): TBytes;
    property Rate: Integer read FRate;
  end;

implementation

constructor TXcomManualPcmOutput.Create(AAvailable: Boolean);
begin
  inherited Create;
  FAvailable := AAvailable;
end;

function TXcomManualPcmOutput.Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
begin
  Result := False;
  if not FAvailable then
    Exit;
  FSource := ASource;
  FRate := ARate;
  FOpen := True;
  Result := True;
end;

procedure TXcomManualPcmOutput.Close;
begin
  FOpen := False;
  FSource := nil;
end;

function TXcomManualPcmOutput.IsOpen: Boolean;
begin
  Result := FOpen;
end;

function TXcomManualPcmOutput.Pump(ABytes: Integer): TBytes;
var
  LSource: IXcomPcmSource;
begin
  Result := nil;
  LSource := FSource;
  if (not FOpen) or (LSource = nil) then
    Exit;
  SetLength(Result, ABytes);
  LSource.Render(PByte(Result), ABytes);
end;

end.
