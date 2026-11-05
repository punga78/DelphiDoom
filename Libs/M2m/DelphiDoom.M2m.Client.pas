{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - the class that the engine uses                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Client;

interface

uses
  System.SysUtils,
  DelphiDoom.M2m.Intf;

type
  /// <summary>
  ///   Converts MIDI files to MUS without caring who implements IM2m: the
  ///   engine linked in the executable, a DLL or a fake of the tests
  /// </summary>
  TM2mClient = class
  private
    FM2m: IM2m;
  public
    constructor Create(const AM2m: IM2m);

    /// <exception cref="EM2mException">the data is not a MIDI file or does not fit in MUS</exception>
    function ConvertMidiToMus(const AMidi: Pointer; const ASize: Integer): TBytes; overload;
    function ConvertMidiToMus(const AMidi: TBytes): TBytes; overload;
  end;

implementation

const
  // The score of a MUS file is shorter than 64 KB, and the patches add 512 bytes at most
  FIRST_CAPACITY = 70000;

{ TM2mClient }

constructor TM2mClient.Create(const AM2m: IM2m);
begin
  inherited Create;
  if not Assigned(AM2m) then
    raise EM2mException.CreateCode(M2M_ERROR_ARGUMENT);
  FM2m := AM2m;
end;

function TM2mClient.ConvertMidiToMus(const AMidi: Pointer; const ASize: Integer): TBytes;
var
  LSize: Cardinal;
  LCode: Integer;
begin
  if not Assigned(AMidi) or (ASize <= 0) then
    raise EM2mException.CreateCode(M2M_ERROR_ARGUMENT);

  SetLength(Result, FIRST_CAPACITY);
  LCode := FM2m.ConvertMidiToMus(AMidi, Cardinal(ASize), @Result[0], Length(Result), LSize);
  if LCode = M2M_ERROR_BUFFER then
  begin
    // The result is longer than expected: LSize says how much it needs
    SetLength(Result, LSize);
    LCode := FM2m.ConvertMidiToMus(AMidi, Cardinal(ASize), @Result[0], Length(Result), LSize);
  end;
  if LCode <> M2M_OK then
    raise EM2mException.CreateCode(LCode);
  SetLength(Result, LSize);
end;

function TM2mClient.ConvertMidiToMus(const AMidi: TBytes): TBytes;
begin
  if Length(AMidi) = 0 then
    raise EM2mException.CreateCode(M2M_ERROR_ARGUMENT);
  Result := ConvertMidiToMus(@AMidi[0], Length(AMidi));
end;

end.
