{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the bytes of the archive from a stream            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.StreamSource;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Intf;

type
  /// <summary>
  ///   IWarSource on a TStream (a file, a memory stream). The original read the whole file at once; here the
  ///   archive asks for what it needs and the stream stays open as long as the source lives
  /// </summary>
  TWarStreamSource = class(TInterfacedObject, IWarSource)
  strict private
    FStream: TStream;
    FOwnsStream: Boolean;
  public
    /// <param name="AStream">The stream; it is freed with the source if AOwnsStream</param>
    constructor Create(AStream: TStream; AOwnsStream: Boolean);
    destructor Destroy; override;
    function GetSize: Int64;
    procedure ReadAt(AOffset: Int64; var ABuffer; ACount: Integer);
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarStreamSource }

constructor TWarStreamSource.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create(SWarStreamIsNil);
  FStream := AStream;
  FOwnsStream := AOwnsStream;
end;

destructor TWarStreamSource.Destroy;
begin
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

function TWarStreamSource.GetSize: Int64;
begin
  Result := FStream.Size;
end;

procedure TWarStreamSource.ReadAt(AOffset: Int64; var ABuffer; ACount: Integer);
begin
  if (AOffset < 0) or (ACount < 0) or (AOffset + ACount > FStream.Size) then
    raise EWarException.CreateFmt(SWarReadPastEnd, [ACount, AOffset, FStream.Size]);
  if ACount = 0 then
    Exit;
  FStream.Position := AOffset;
  FStream.ReadBuffer(ABuffer, ACount);
end;

end.
