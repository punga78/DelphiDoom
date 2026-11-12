unit sprites;
// stub of the harness: ActivationSound belongs to another part of the port, here it is a call in the log
interface
uses r_public_h;
procedure ActivationSound(const sp: Pscaleobj_t);
implementation
uses r_conten, calllog, DelphiDoom.Tests.Greed.EventScenarios;
procedure ActivationSound(const sp: Pscaleobj_t);
begin
  Calls.AddCall(EVENT_CALL_ACTIVATION, [(NativeInt(sp) - NativeInt(@scaleobjlist[0])) div SizeOf(scaleobj_t)]);
end;
end.
