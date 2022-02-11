#Include 'Rwmake.ch'

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºPrograma  ³ CADSZB   ºAutor  ³ Pedro Augusto      º Data ³  Dez/2015   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Programa responsavel por cadastrar a amarracao de          º±±
±±º          ³ NatureZB X Aprovadores                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ REPSOL                                                     º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function CADSZB()
	If !AliasInDic("SZB",.t.)
		Return
	EndIf
	If Select('SZB') == 0
		ChkFile('SZB')
	EndIf
	
	cCadastro := 'Cadastro de Natureza x aprovadores'
	aRotina := {  { "Pesquisar" ,"AxPesqui" , 0 , 1 } , ;
	{ "VisualiZBr","U_ManSZB(2,cCadastro)", 0 , 2 } , ;
	{ "Incluir"   ,"U_ManSZB(3,cCadastro)", 0 , 3 } , ;
	{ "Altera"    ,"U_ManSZB(4,cCadastro)", 0 , 4 } , ;
	{ "Excluir"   ,"U_ManSZB(5,cCadastro)", 0 , 5 } }
	
	SZB->( DbSetOrder(1) )
	
	mBrowse(,,,,"SZB")
	
	Return
	
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºPrograma  ³ ManSZB ºAutor  ³Pedro Augusto         º Data ³ Dez/2015    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Processamento do Programa.                                 º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function ManSZB(nOpcx, cCadastro)
	Local aArea   := GetArea()
	Local cCampos := 'ZB_NATUREZ/ZB_DESCRI'
	Local nQ		:= 0
//	Local cCampos := 'ZB_NATUREZ'
	Private cCodigo := IIF( Inclui, CriaVar('ZB_NATUREZ'  	) , SZB->ZB_NATUREZ )
	//Private cDescri := IIF( Inclui, CriaVar('ZB_DESCRI'		) , SZB->ZB_DESCRI  )
	Private xOpcx   := nOpcx
	
	cTitulo := cCadastro
	
	SX3->( DbSetOrder(1), DbSeek('SZB') )
	
	aHeader := {}
	aGets   := {}
	nUsado  := 0
	
	While !SX3->( Eof() ) .And. SX3->X3_ARQUIVO == "SZB"
		
		If X3Uso(SX3->X3_USADO) .AND. cNivel >= SX3->X3_NIVEL .And.!Trim(SX3->X3_CAMPO)$cCampos
			nUsado := nUsado + 1
			Aadd( aGets, AllTrim(SX3->X3_CAMPO) )
			AADD(aHeader,{TRIM(SX3->X3_TITULO),SX3->X3_CAMPO,;
			SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,SX3->X3_VALID,;
			SX3->X3_USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
		Endif
		
		SX3->( DbSkip() )
		
	EndDo
	
	aCols := {}
	
	If !Inclui
		
		SZB->( DbSetOrder(1), DbSeek(xFilial('SZB')+cCodigo) )
		
		While !SZB->( Eof() ) .And. SZB->( ZB_FILIAL+ZB_NATUREZ ) == xFilial('SZB')+cCodigo
			
			Aadd(aCols, Array(nUsado+1))
			For nQ :=1 To nUsado
				aCols[Len(aCols),nQ] := FieldGet(FieldPos(aHeader[nQ,2]))
			Next
			aCols[Len(aCols),nUsado + 1] := .F.
			SZB->( DbSkip() )
			
		EndDo
		
	EndIf
	
	If Len(aCols) == 0
		AADD(aCols,Array(nUsado+1))
		For nQ := 1 To nUsado
			aCols[Len(aCols),nQ] := CriaVar(aHeader[nQ][2])
		Next
		aCols[Len(aCols),nUsado+1] := .F.
	EndIf
	
	aColsDel := aClone( aCols )
	aGets    := Array(0)
	cLinhaOk := ".t."
	cTudoOk  := ".t."
	aR       := {}
	aC       := {}
	aCGD:={45,05,160,360}
	aTELA:={125,0,450,730}
	
	//+--------------------------------------------------------------+
	//¦ Chamada da Modelo2                                           ¦
	//+--------------------------------------------------------------+
	                                                            
	AADD(aC,{"cCodigo"  ,{16,10} , "Tipo"      ,"@!","U_MANSZBd()",'SED',IIF(Inclui, .t., .f.)})
	//AADD(aC,{"cDescri"  ,{16,95} , "Descrição" ,"@!",".t.",Nil,.f.})
	
	If Modelo2(cTitulo,aC,aR,aCGD,nOpcx,cLinhaOk,cTudoOk,,,,999,aTELA)
		MANSZBb(nOpcx)
	EndIf
	
	RestArea( aArea )
	
	Return
	
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºFuncao    ³ MANSZBb  ºAutor  ³Pedro Augusto       º Data ³ Dez/2015    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Efetua as AtualiZBcoes.                                    º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function MANSZBb(nOpcx)
	Local cBusca, xp, xk, cExec
	SZB->( DbSetOrder(1) )

	If nOpcx == 3 .Or. nOpcx == 4 .Or. nOpcx == 5
		
		cExec := " UPDATE "+RetSqlName("SZB")+" SET D_E_L_E_T_ = '*' "
		cExec += " WHERE ZB_FILIAL = '"+xFilial('SZB')+"' "
		cExec += " AND   ZB_NATUREZ = '"+cCodigo+"' "
		cExec += " AND   D_E_L_E_T_ = ' ' "
		
		TcSqlExec( cExec )
		
		If nOpcx <> 5
			For xp := 1 To Len(aCols)
				If !aCols[xp][Len(aHeader)+1]
					RecLock("SZB",.t.)
					For xk := 1 To Len(aHeader)
						Field->&(aHeader[xk][2]) := aCols[xp][xk]
					Next
					SZB->ZB_NATUREZ := cCodigo
				//	SZB->ZB_DESCRI := cDescri
					MsUnlock()
				Endif
			Next
		EndIf
		
	EndIf
	
	Return
	
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºFuncao    ³ MANSZBd ºAutor  ³Pedro Augusto        º Data ³ Dez/2015    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Valida se o codigo de processo ja existe.                  º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function MANSZBd()
	Local lRet := .t.
	If xOpcx == 3
		If SZB->( DbSetOrder(1), DbSeek( xFilial('SZB')+cCodigo ) )
			Aviso("JA EXISTE","O tipo de compra ja existe!",;
			{"&Fechar"},3,"Informação já Existente",,;
			"PCOLOCK")	    
			lRet := .f.
		EndIf
	EndIf
	
	Return( lRet )