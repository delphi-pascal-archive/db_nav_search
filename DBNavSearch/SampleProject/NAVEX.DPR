program navex;

uses
  Forms,
  navex00 in 'navex00.pas' {Form1};

{$R *.RES}

begin
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
