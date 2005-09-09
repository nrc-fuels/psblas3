      SUBROUTINE DCOINCO(M,N,DESCRA,A,IA1,IA2,
     +  INFOA,IA,JA,LATOT,LIA1TOT,LIA2TOT,
     +  DESCRH,H,IH1,IH2,INFOH,IH,JH,WORK,LWORK,IERROR)

      IMPLICIT NONE                                                      
      INCLUDE  'psb_const.fh'
C     .. Scalar Arguments ..                                             
      INTEGER          LWORK, M, N, IERROR
      INTEGER          LATOT,LIA1TOT,LIA2TOT,IA,JA,IH,JH
C     .. Array Arguments ..                                              
      DOUBLE PRECISION A(*), H(*), WORK(LWORK)                     
      INTEGER          IA1(*), IA2(*), IH1(*), IH2(*),
     +  INFOA(*), INFOH(*)
      CHARACTER        DESCRA*11, DESCRH*11
      
C     .. Local scalars ..
      INTEGER I, J, NZH, nza
c     .. Local Arrays ..
      CHARACTER*20       NAME
      INTEGER            INT_VAL(5)

      NAME = 'DCOINCO\0'
      IERROR = 0
      CALL FCPSB_ERRACTIONSAVE(ERR_ACT)

      NZH      = INFOH(NNZ_)
      NZA      = INFOA(NNZ_)

      if ((nza+nzh).le.min(latot,lia1tot,lia2tot)) then 
C
C     In this case we are (hopefully) safe
C        
        
C     Insert Element in COO Format
        DO J = 1, NZH
          IF ((IH1(J).GE.IH).AND.(IH1(J).LT.IH+M).AND.
     $      (IH2(J).GE.JH).AND.(IH2(J).LT.JH+N)) THEN
C              If current element belongs to submatrix to insert
            nza      = nza + 1
            A(nza)   = H(J)
            IA1(nza) = IH1(J)+IA-IH
            IA2(nza) = IH2(J)+JA-JH
          ENDIF
        ENDDO
        
      else
        
C
C   Most likely will have to give up, but try anyway
C
C     Insert Element in COO Format
        DO J = 1, NZH
          IF ((IH1(J).GE.IH).AND.(IH1(J).LT.IH+M).AND.
     $      (IH2(J).GE.JH).AND.(IH2(J).LT.JH+N)) THEN
C              If current element belongs to submatrix to insert
            nza      = nza + 1
            
            IF ((nza.le.LATOT) .and.(nza.le.LIA1TOT)
     +        .and.(nza.le.LIA2TOT)) THEN
              A(nza)   = H(J)
              IA1(nza) = IH1(J)+IA-IH
              IA2(nza) = IH2(J)+JA-JH
            else
              IF (nza.GT.LATOT) THEN
                IERRV(1) = 10
                IERRV(2) = nza
              ELSE IF (nza.GT.LIA1TOT) THEN
                IERRV(1) = 20
                IERRV(2) = nza
              ELSE IF (nza.GT.LIA2TOT) THEN
                IERRV(1) = 30
                IERRV(2) = nza
              ENDIF
              RETURN
            endif
          ENDIF
        ENDDO
      endif
      infoa(nnz_) = nza

      return
      END
