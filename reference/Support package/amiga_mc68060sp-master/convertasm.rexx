/*
**-----------------------------------------------------------------------------
**  /\    |\     Silicon Department     
**  \_  o| \_ _  Software Entwicklung
**     \||  |_)|)   Copyright by Branko Mikic, 1996
** \__/||_/\_|     Released under CC-BY-NC-SA 4.0 license in 2016
** See      http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
**-----------------------------------------------------------------------------


	$VER: convertasm.rexx V1.0 (17.4.96)

	This script converts intel-based mnemonics into
	a Motorola syntax.It creates a new file with a '#?.m68'
	suffix in the actual directory.

		TEMPLATE:	rx convertasm.rexx [sourcefile]

	These are the conversions made:

	1.            # -> ; (used instead of * because of pre-processing directives)
	2.          mov -> move
	3.         movm -> movem
	4.          %d0 -> d0 (d0-d7/a0-a7/sp)
	5. short 0x1234 -> dc.b $1234
	6.            & -> #
	7. SET bla,1234 -> bla	equ	1234
	8. Global & Space Directives are commented out

	Don't expect speed because ARexx is still a run-time
	interpreter aproximatley the conversion needs a few minutes
	for ca.20000 lines of source code.But still better than to
	do it by your own or to play with a word processor :-)

	Written in ARexx by Branko Mikiç
	for Silicon Solution (C) 1996
*/

TRACE off
OPTIONS results
PARSE ARG infile

cr = '0A'X
xtimer = 0
label = ''

	IF infile = '' THEN EXIT 5
	OPEN(in,infile,R);
	outfile = infile'.m68'
	OPEN(out,'T:temp',W)
	say cr||'>>converting »'infile'« to »'outfile'«'||cr||'>>'.' = 100 lines converted.'
	
	DO WHILE(EOF(in)=0)

		x0 = READLN(in)
		PARSE VAR x0 mnemonic'#'comment

		IF mnemonic ~= '' THEN DO
			IF POS(':',mnemonic) ~= 0 THEN PARSE VAR mnemonic label':'mnemonic
	
			/*** converts mnemonics to motorola syntax. ***/
			IF POS('mov',mnemonic) ~= 0 THEN mnemonic = INSERT('e',mnemonic,POS('v',mnemonic),1)
			IF POS('short',mnemonic) ~= 0 THEN DO
				PARSE VAR mnemonic x2'short'x3
				mnemonic = x2'dc.b'x3
			END
			IF POS('long',mnemonic) ~= 0 THEN DO
				PARSE VAR mnemonic x2'long'x3
				mnemonic = x2'dc.l'x3
			END

			/*** comments space & global out. ***/
			IF POS('space',mnemonic) ~= 0 THEN mnemonic = ';'mnemonic
			IF POS('global',mnemonic) ~= 0 THEN mnemonic = ';'mnemonic


			/*** removes '%' in front of the registers ***/
			mnemonic = COMPRESS(mnemonic,'%')

			/*** converts c-string style hex values ***/
			DO WHILE POS('0x',mnemonic) ~= 0
					PARSE VAR mnemonic x1'0x'x2
					mnemonic=x1'$'x2
			END

			/*--- Replaces all & with # ---*/
			x1 = POS('&',mnemonic)
			IF x1 ~= 0 THEN DO
				mnemonic = DELSTR(mnemonic,x1,1)
				mnemonic = INSERT('#',mnemonic,x1-1,1)
			END


			/*--- SET to EQU ---*/
			IF POS('bset',mnemonic) = 0 THEN DO
				IF POS('set',mnemonic) ~= 0 THEN DO
					IF POS(',',mnemonic) ~= 0 THEN DO
						PARSE VAR mnemonic 'set'x2','x3
						x2 = COMPRESS(x2,'	 ,')
						x3 = COMPRESS(x3,'	 ,')
						mnemonic = x2'	equ	'x3'	'
					END
				END
			END

		END

		IF comment ~= '' THEN mnemonic = mnemonic';'comment

		IF label ~= '' THEN DO
			mnemonic = label':	'mnemonic
			label = ''
		END

		x0 = mnemonic
		WRITELN(out,x0);

		/* print dots **************************************/
		xtimer = xtimer + 1
		IF xtimer = 100 THEN DO
			ADDRESS COMMAND 'ECHO . NOLINE'
			xtimer = 0
		END

	END
	CLOSE(in);
	CLOSE(out);
	ADDRESS COMMAND 'COPY T:temp 'outfile
	ADDRESS COMMAND 'DELETE >NIL: T:temp'
	SAY cr||'>>file conversion completed.'
	EXIT 0

/************************************************************************/
