{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the factory of the network of Quake III           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.EntityStateCodec,
  DelphiDoom.Net.Q3.PlayerStateCodec, DelphiDoom.Net.Q3.Netchan;

type
  /// <summary>
  ///   The one place that knows the concrete classes of the network of Quake III. The caller owns every
  ///   object that is not an interface
  /// </summary>
  TQ3NetFactory = class
  public
    /// <summary>
    ///   The coder of the messages (msgHuff). Building it takes a moment (it learns 1.1 million bytes): make
    ///   one for the program and give it to every message
    /// </summary>
    class function CreateMessageHuffman: IQ3HuffmanCoder; static;
    class function CreateMessage(const ACoder: IQ3HuffmanCoder; const ALog: ILog = nil): TQ3Message; static;
    class function CreateEntityStateTable: IQ3NetFieldTable; static;
    class function CreatePlayerStateTable: IQ3NetFieldTable; static;
    class function CreateEntityStateCodec: TQ3EntityStateCodec; static;
    class function CreatePlayerStateCodec: TQ3PlayerStateCodec; static;
    class function CreateNetchan(const ATransport: IQ3NetTransport; const ALog: ILog = nil): TQ3Netchan; static;
  end;

implementation

uses
  DelphiDoom.Net.Q3.MessageHuffman, DelphiDoom.Net.Q3.NetFieldTable;

{ TQ3NetFactory }

class function TQ3NetFactory.CreateMessageHuffman: IQ3HuffmanCoder;
begin
  Result := TQ3MessageHuffman.Create;
end;

class function TQ3NetFactory.CreateMessage(const ACoder: IQ3HuffmanCoder; const ALog: ILog): TQ3Message;
begin
  Result := TQ3Message.Create(ACoder, ALog);
end;

class function TQ3NetFactory.CreateEntityStateTable: IQ3NetFieldTable;
begin
  Result := TQ3NetFieldTable.CreateEntityState;
end;

class function TQ3NetFactory.CreatePlayerStateTable: IQ3NetFieldTable;
begin
  Result := TQ3NetFieldTable.CreatePlayerState;
end;

class function TQ3NetFactory.CreateEntityStateCodec: TQ3EntityStateCodec;
begin
  Result := TQ3EntityStateCodec.Create(CreateEntityStateTable);
end;

class function TQ3NetFactory.CreatePlayerStateCodec: TQ3PlayerStateCodec;
begin
  Result := TQ3PlayerStateCodec.Create(CreatePlayerStateTable);
end;

class function TQ3NetFactory.CreateNetchan(const ATransport: IQ3NetTransport; const ALog: ILog): TQ3Netchan;
begin
  Result := TQ3Netchan.Create(ATransport, ALog);
end;

end.
