unit navex00;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, DBNavSch, Grids, DBGrids, DB, DBTables, StdCtrls, 
  Buttons;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    DBNavSearch1: TDBNavSearch;
    Table1: TTable;
    DataSource1: TDataSource;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

end.
