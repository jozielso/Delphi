program RB_FIELD;

uses
  Vcl.Forms,
  P_RB_FIELD in 'P_RB_FIELD.pas' {frmPrincipal},
  DMGERAL in 'DMGERAL.pas' {DM: TDataModule},
  FException in 'FException.pas' {ExceptionDialog};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
