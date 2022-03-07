#include 'totvs.ch'

user function tstwff580()

	u_WFFIN580( { '','','','01','01','','' } )


return

user function WFFIN580(aParam)

	local nTam := len( aParam )
	local cEmp := aParam[ nTam - 3 ]
	local cFil := aParam[ nTam - 2 ]

	if RpcSetEnv( cEmp, cFil )

		if LockByName("WFFIN580", .T., .F.)

			ProcWf()

			UnlockByName("WFFIN580", .T., .F., .F.)

		end if

	else

		ConOut( 'Não foi possível logar na Empresa/Filial ' + cEmp + '/' + cFil )

	end if



return

static function ProcWf()

	local cAlias := getNextAlias()

	If Select( cAlias ) <> 0

		( cAlias )->( DbCloseArea() )

	EndIf

	BeginSql alias cAlias
	
		%NOPARSER%
		
		SELECT 

		SM0.M0_CODIGO,SM0.M0_CODFIL,SM0.M0_NOMECOM,
		SE2.E2_FILIAL,SE2.E2_PREFIXO,SE2.E2_NUM,SE2.E2_PARCELA,SE2.R_E_C_N_O_ E2_RECNO,
		CTT.CTT_CUSTO,CTT.CTT_DESC01,
		SA2.A2_COD,SA2.A2_LOJA,SA2.A2_NREDUZ,
		SED.ED_CODIGO,SED.ED_DESCRIC,
		SE2.E2_VENCREA,SE2.E2_VLCRUZ,SE2.E2_TIPO,SX5.X5_DESCRI,
		USR.USR_NOME,USR.USR_EMAIL,USR.USR_CODIGO

		FROM %TABLE:SE2% SE2

		INNER JOIN %TABLE:CTT% CTT ON
		SE2.E2_FILIAL=CTT.CTT_FILIAL AND
		SE2.E2_XCCAPRV = CTT.CTT_CUSTO AND
		SE2.D_E_L_E_T_ = CTT.D_E_L_E_T_

		INNER JOIN %TABLE:SX5% SX5 
		ON SE2.E2_TIPO = SX5.X5_CHAVE

		INNER JOIN %TABLE:SA2% SA2 
		ON SE2.E2_FORNECE = SA2.A2_COD 
		AND SE2.E2_LOJA = SA2.A2_LOJA

		INNER JOIN SYS_COMPANY SM0 
		ON SE2.E2_FILIAL = SM0.M0_CODFIL

		INNER JOIN %TABLE:SED% SED 
		ON SE2.E2_FILIAL = SED.ED_FILIAL 
		AND SE2.E2_NATUREZ = SED.ED_CODIGO 
		AND SE2.D_E_L_E_T_ = SED.D_E_L_E_T_ 

		INNER JOIN %TABLE:FRP% FRP 
		ON SE2.E2_CODAPRO = FRP.FRP_COD 
		AND SE2.D_E_L_E_T_ = FRP.D_E_L_E_T_

		INNER JOIN SYS_USR USR 
		ON FRP.FRP_USER = USR.USR_ID 
		AND FRP.D_E_L_E_T_ = USR.D_E_L_E_T_

		WHERE SE2.%NOTDEL%
		AND SE2.E2_XWFSEND = 'F'
		AND SE2.E2_DATALIB = ''
		AND SE2.E2_STATLIB IN( '01','' ) 
		AND SM0.M0_CODIGO = %EXP:cEmpAnt% 
		AND SX5.X5_TABELA = '05'
	
	EndSql

	while ( cAlias)->( !Eof() )

		EnviaWf( cAlias )

		( cAlias )->( DbSkip() )

	end

	( cAlias )->( DbCloseArea() )

return

static function EnviaWf( cAlias )

	local oProcess   := TWFProcess():New( '000001' )
	local cHostWf    := AllTrim( GetMv( 'MV_HOSTWF' ) )
	local cHostLogin := AllTrim( GetMv( 'MV_HOSTLG' ) )
	local cMailId    := ''
	local cLoginId   := ''
	local nX         := 0
	local aAnexos    := {}
	local cSF1chv    := ( cAlias )->( E2_NUM + E2_PREFIXO + A2_COD + A2_LOJA )
	local cSE2chv    := ( cAlias )->( E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + A2_COD + A2_LOJA )
	local cFilEnt    := ( cAlias )->( E2_FILIAL )
	Local cExecSql   := ''
	Local nStatus    := 0

	Set(_SET_DATEFORMAT, 'mm/dd/yyyy')

	/** Aprovacao */

	oProcess:NewTask( 'APROVACAO', '\workflow\models\aprovacao.html' )

	oProcess:oHTML:ValByName( 'EMP_FIL_NOME'  , ( cAlias )->( AllTrim( M0_CODIGO ) + ' / ' + AllTrim( M0_CODFIL ) + ' / ' + AllTrim( M0_NOMECOM ) ) )
	oProcess:oHTML:ValByName( 'PRE_NUM_PARC'  , ( cAlias )->( AllTrim( E2_PREFIXO ) + ' / ' + AllTrim( E2_NUM ) + ' / ' + AllTrim( E2_PARCELA ) ) )
	oProcess:oHTML:ValByName( 'FORN_LOJ_NOME' , ( cAlias )->( AllTrim( A2_COD ) + ' / ' + AllTrim( A2_LOJA ) + ' / ' + AllTrim( A2_NREDUZ ) ) )
	oProcess:oHTML:ValByName( 'NAT_DESCR'     , ( cAlias )->( AllTrim( ED_CODIGO ) + ' / ' + AllTrim( ED_DESCRIC ) ) )
	oProcess:oHTML:ValByName( 'CC_NOME'       , ( cAlias )->( AllTrim( CTT_CUSTO ) + ' / ' + AllTrim( CTT_DESC01 ) ) )
	oProcess:oHTML:ValByName( 'VENCIMENTO'    , ( cAlias )->( StoD( E2_VENCREA ) ) )
	oProcess:oHTML:ValByName( 'VALOR'         , ( cAlias )->( 'R$ ' + Alltrim( Transform( E2_VLCRUZ, '@E 9,999,999,999,999.99' ) ) ) )
	oProcess:oHTML:ValByName( 'TIPO_DESCR'    , ( cAlias )->( AllTrim( E2_TIPO ) + ' / ' + AllTrim( X5_DESCRI ) ) )
	oProcess:oHTML:ValByName( 'RECNO'         , ( cAlias )->( E2_RECNO ) )
	oProcess:oHTML:ValByName( 'LOGIN'         , ( cAlias )->( USR_CODIGO ) )

	oProcess:bReturn  := 'U_WFRTF580'

	cMailId := oProcess:Start( '\workflow\tasks\')

	/** Login */

	oProcess:NewTask( 'LOGIN', '\workflow\models\login.html' )

	oProcess:oHTML:ValByName( 'LOGIN'            , ( cAlias )->( USR_CODIGO ) )
	oProcess:oHTML:ValByName( 'URL_WF_APROVACAO' , cHostWf + cMailId + '.htm' )

	cLoginId := oProcess:Start( '\workflow\tasks\')

	/** Email */

	oProcess:NewTask( 'EMAIL', '\workflow\models\email.html' )

	oProcess:oHtml:ValByName( 'LINK', cHostLogin + cLoginId + ".htm")

	oProcess:cSubject := 'Liberação de Pagamento'
	oProcess:cTo      := ( cAlias )->( USR_EMAIL )

	aAnexos := listAnexos( cSF1chv, cSE2chv, cFilEnt )

	for nX := 1 to len( aAnexos )

		oProcess:AttachFile( '\dirdoc\co' + cEmpAnt + '\shared\' + aAnexos[nX] )

	next nX

	cLoginId := oProcess:Start()


	cExecSql := " UPDATE " + RetSqlName( 'SE2' ) + " SET "
	cExecSql += " E2_XWFSEND = 'T' "
	cExecSql += " WHERE R_E_C_N_O_ = " + cValToChar( ( cAlias )->( E2_RECNO ) )

	nStatus := TCSqlExec( cExecSql )

	if nStatus < 0

		conout( 'TCSQLError() ' + TCSQLError())

	else

		ConOut( 'Comando executado com sucesso.' )

	end if

return

static function listAnexos( cSF1chv, cSE2chv, cFilEnt )

	local cAlias := getNextAlias()
	local aRet   := {}

	If Select( cAlias ) <> 0

		( cAlias )->( DbCloseArea() )

	EndIf

	BeginSql alias cAlias

		%NOPARSER%
		SELECT

		DISTINCT ACB.ACB_OBJETO
		
		FROM %TABLE:ACB% ACB

		INNER JOIN %TABLE:AC9% AC9
		  ON AC9.AC9_CODOBJ = ACB.ACB_CODOBJ
		  AND AC9.D_E_L_E_T_ = ACB.D_E_L_E_T_

		WHERE ACB.%NOTDEL%

		AND 
		(
			( AC9.AC9_FILENT = '01'
			AND AC9.AC9_ENTIDA = 'SF1'
			AND AC9.AC9_CODENT = %EXP:cSF1chv% )
			
			OR 
			
			( AC9.AC9_FILENT = '01'
			AND AC9.AC9_ENTIDA = 'SE2'
			AND AC9.AC9_CODENT = %EXP:cSE2chv% )
		)
	
	EndSql

	While ( cAlias )->(!EOF())

		aAdd( aRet,  ( cAlias )->( ACB_OBJETO ) )

		( cAlias )->(DbSkip())

	End

	( cAlias )->( DbCloseArea() )

return aRet

user function WFRTF580( oProcess )

	Local cRecno   := AllTrim( oProcess:oHtml:RetByName( 'RECNO'  ) )
	Local lLibera  := AllTrim( oProcess:oHtml:RetByName( 'LIBERA' ) ) == 'S'
	Local cLogin   := AllTrim( oProcess:oHtml:RetByName( 'LOGIN' ) )
	Local nStatus  := 0
	Local cExecSql := ''

	cExecSql := " UPDATE " + RetSqlName( 'SE2' ) + " SET "
	cExecSql += " E2_XWFSEND = 'T', "

	if lLibera

		cExecSql += " E2_STATLIB = '03', "
		cExecSql += " E2_DATALIB = '" + DtoS( Date() ) + "', "
		cExecSql += " E2_USUALIB = '" + cLogin + "' "

	else

		cExecSql += " E2_STATLIB = '04' "

	end if

	cExecSql += " WHERE R_E_C_N_O_ = " + cRecno

	nStatus := TCSqlExec( cExecSql )

	if nStatus < 0

		conout( 'TCSQLError() ' + TCSQLError())

	else

		ConOut( 'Comando executado com sucesso.' )

	end if

	oProcess:Finish()

return
