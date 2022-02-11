#include 'totvs.ch'

user function MT103FIM()

	local aArea     := GetArea()
	local cSeek     := xFilial( 'SE2' ) + SF1->( F1_FORNECE + F1_LOJA + F1_SERIE + F1_DOC )
	local nOperacao := ParamIxb[1]
	local nConfirma := ParamIxb[2]

	if cValToChar( nOperacao ) $ '34' .And. nConfirma == 1

		DbSelectArea( 'SE2' )
		DbSetOrder( 6 ) //E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO

		if DbSeek( cSeek)

			while cSeek == SE2->( E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM );
					.And. ! SE2->( Eof() )

				RecLock( 'SE2', .F. )

				SE2->E2_XCCAPRV := cCCAprv
				SE2->E2_CODAPRO := cCodApro

				SE2->( MsUnlock() )

				SE2->( DbSkip() )

			end

		end if

		RestArea( aArea )

	end if

return
