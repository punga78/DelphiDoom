unit m_defs;
// stub of the harness: M_SaveDefaults in the trace
interface
procedure M_SaveDefaults;
implementation
uses harness_menu, DelphiDoom.Tests.Greed.MenuScenarios;
procedure M_SaveDefaults;
begin
  HTrace.Add(MENU_TRACE_SAVE_SETTINGS);
end;
end.
