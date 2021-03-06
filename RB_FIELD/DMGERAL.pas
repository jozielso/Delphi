unit DMGERAL;

interface

uses
  System.SysUtils, System.Classes, Data.DBXFirebird, Data.DB, Data.SqlExpr,
  Data.FMTBcd, Datasnap.DBClient, Datasnap.Provider;

type
  TDM = class(TDataModule)
    conexao: TSQLConnection;
    qTabela: TSQLQuery;
    pTabela: TDataSetProvider;
    cdsTabela: TClientDataSet;
    dsTabela: TDataSource;
    cdsTabelaTABELA: TStringField;
    cdsTabelaCAMPO: TStringField;
    cdsTabelaTIPO: TStringField;
    qRBFIELD: TSQLQuery;
    cdsRBFIELD: TClientDataSet;
    dsRBFIELD: TDataSource;
    qCombo: TSQLQuery;
    pCombo: TDataSetProvider;
    cdsCombo: TClientDataSet;
    dsCombo: TDataSource;
    cdsComboTABELA: TStringField;
    cdsRBFIELDTABLE_NAME: TStringField;
    cdsRBFIELDFIELD_NAME: TStringField;
    cdsRBFIELDFIELD_ALIAS: TStringField;
    cdsRBFIELDDATATYPE: TStringField;
    cdsRBFIELDSELECTABLE: TStringField;
    cdsRBFIELDSEARCHABLE: TStringField;
    cdsRBFIELDSORTABLE: TStringField;
    cdsRBFIELDAUTOSEARCH: TStringField;
    cdsRBFIELDMANDATORY: TStringField;
    pRBFIELD_T: TDataSetProvider;
    cdsRBFIELD_T: TClientDataSet;
    dsRBFIELD_T: TDataSource;
    qRBFIELD_T: TSQLQuery;
    cdsRBFIELD_TTABLE_NAME: TStringField;
    cdsRBFIELD_TFIELD_NAME: TStringField;
    cdsRBFIELD_TFIELD_ALIAS: TStringField;
    cdsRBFIELD_TDATATYPE: TStringField;
    cdsRBFIELD_TSELECTABLE: TStringField;
    cdsRBFIELD_TSEARCHABLE: TStringField;
    cdsRBFIELD_TSORTABLE: TStringField;
    cdsRBFIELD_TAUTOSEARCH: TStringField;
    cdsRBFIELD_TMANDATORY: TStringField;
    qRBFIELDTABLE_NAME: TStringField;
    qRBFIELDFIELD_NAME: TStringField;
    qRBFIELDFIELD_ALIAS: TStringField;
    qRBFIELDDATATYPE: TStringField;
    qRBFIELDSELECTABLE: TStringField;
    qRBFIELDSEARCHABLE: TStringField;
    qRBFIELDSORTABLE: TStringField;
    qRBFIELDAUTOSEARCH: TStringField;
    qRBFIELDMANDATORY: TStringField;
    qRBTAB: TSQLQuery;
    pRBTAB: TDataSetProvider;
    cdsRBTAB: TClientDataSet;
    qTMP: TSQLQuery;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DM: TDM;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
