	SUBROUTINE LCCBND ( clat, clon, imd, jmd, dx, dy, glat, glon )

	REAL 		clat, clon, dx, dy, glat(*), glon(*)
	INTEGER		imd, jmd
C*
	INCLUDE		'GEMPRM.PRM'
C*
        PARAMETER       ( IMM = 301, JMM = 301, IMJMF = IMM*JMM-JMM/2 )
C*
	REAL		khlo(JMM), khho(JMM)
C       , glat(IMJMF), glon(IMJMF)
C*
C*
        INTEGER         imjmk
        DOUBLE PRECISION delta, wbd, sbd
C-----------------------------------------------------------------------
C
C*             Now compute the domain
C

	       delta = dx / ( 111111. * cos ( clat * DTR ) ) / 2.0

               imjmk = imd*jmd-jmd/2
               wbd   = -(float(imd)-1.)*delta
               sbd   = (-(float(jmd)-1.)/2.)*delta
               tpho  = clat*DTR
               wb    = wbd*DTR
               sb    = sbd*DTR
               dlm   = delta*DTR
               dph   = delta*DTR
               tdlm  = dlm + dlm
               tdph  = dph + dph
               stpho = sin(tpho)
               ctpho = cos(tpho)

               DO j = 1, jmd
                  khlo(j) = imd*(j-1)-(j-1)/2+1
                  khho(j) = imd*j-j/2
               END DO

               tph = sb - dph

               DO j = 1, jmd
                  khl = khlo(j)
                  khh = khho(j)

                  tlm  = wb-tdlm+mod(j+1,2)*dlm
                  tph  = tph + dph
                  stph = sin(tph)
                  ctph = cos(tph)

                  DO k = khl, khh
                     tlm = tlm+tdlm
                     sph = ctpho*stph+stpho*ctph*cos(tlm)
                     glat(k) = asin(sph)
                     clm = ctph*cos(tlm)/(cos(glat(k))*ctpho)
     +                  -tan(glat(k))*tan(tpho)

                     if (clm.gt.1.) clm = 1.
                     fact = 1.
                     if (tlm.gt.0.) fact = -1.

                     glon(k) = (-clon*DTR+fact*acos(clm))/DTR

                     if (glon(k) .lt. 0)    glon(k) = glon(k) + 360.
                     if (glon(k) .gt. 360.) glon(k) = glon(k) - 360.
                     if (glon(k) .lt. 180.) glon(k) = - glon(k)
                     if (glon(k) .gt. 180.) glon(k) = 360.0 - glon(k)

                     glat(k) = glat(k) / DTR
                  END DO
               END DO

C                write( *, '(A4,F6.2,A,F7.2,A,F6.2)')
C     +            'lcc/',clat,';',clon,';',clat
C 
C                write(*, '(F6.2,A,F7.2,A,F6.2,A,F7.2)')
C     +            glat(1),';',glon(1),';',glat(imjmk),';',glon(imjmk)


C
	RETURN
C*
	END
