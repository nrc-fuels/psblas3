C
C             Parallel Sparse BLAS  v2.0
C   (C) Copyright 2006 Salvatore Filippone    University of Rome Tor Vergata
C                      Alfredo Buttari        University of Rome Tor Vergata
C
C Redistribution and use in source and binary forms, with or without
C modification, are permitted provided that the following conditions
C are met:
C   1. Redistributions of source code must retain the above copyright
C      notice, this list of conditions and the following disclaimer.
C   2. Redistributions in binary form must reproduce the above copyright
C      notice, this list of conditions, and the following disclaimer in the
C      documentation and/or other materials provided with the distribution.
C   3. The name of the PSBLAS group or the names of its contributors may
C      not be used to endorse or promote products derived from this
C      software without specific written permission.
C
C THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
C ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
C TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
C PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE PSBLAS GROUP OR ITS CONTRIBUTORS
C BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
C CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
C SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
C INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
C CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
C ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
C POSSIBILITY OF SUCH DAMAGE.
C
C 
c     
c     What if a wrong DESCRA is passed?
c     
c     
*     
*     
      SUBROUTINE DCSRMM(TRANSA,M,K,N,ALPHA,DESCRA,AR,
     *     JA,IA,B,LDB,BETA,C,LDC,WORK,LWORK,IERROR)
C     
C     
C     .. Scalar Arguments ..
      DOUBLE PRECISION  ALPHA, BETA
      INTEGER           K, LDB, LDC, M, N, LWORK,IERROR
      CHARACTER         TRANSA
C     .. Array Arguments ..
      DOUBLE PRECISION  AR(*), B(LDB,*), C(LDC,*),  WORK(*)
      INTEGER           IA(*), JA(*)
      CHARACTER         DESCRA*11
C     .. Local Scalars ..
      INTEGER           I, J, K4
      CHARACTER         DIAG, TRANS
c     .. Local Arrays ..
      CHARACTER*20       NAME
      INTEGER            INT_VAL(5)

C     .. External Subroutines ..
      EXTERNAL          DCSRMV
C     .. Executable Statements ..
C     
C     
      NAME = 'DCSRMM\0'
      IERROR = 0
      CALL FCPSB_ERRACTIONSAVE(ERR_ACT)
C     
      IF (DESCRA(1:1).EQ.'G') TRANS = TRANSA
      IF (DESCRA(1:1).EQ.'S' .AND. DESCRA(2:2).EQ.'U') TRANS = 'U'
      IF (DESCRA(1:1).EQ.'S' .AND. DESCRA(2:2).EQ.'L') TRANS = 'L'
c     
c     Does DSRMV manage this case too? <????????????????????????????
c     
      IF (DESCRA(1:1).EQ.'D') THEN
         IF (DESCRA(3:3).EQ.'U') THEN
            DO 40 I = 1, K
               DO 20 J = 1, M
                  C(J,I) = BETA*C(J,I) + ALPHA*B(J,I)
 20            CONTINUE
 40         CONTINUE
         ELSE
            DO 80 I = 1, K
               DO 60 J = 1, M
                  C(J,I) = BETA*C(J,I) + ALPHA*AR(J)*B(J,I)
 60            CONTINUE
 80         CONTINUE
         END IF
         RETURN
      END IF
C     
      IF (DESCRA(3:3).EQ.'N') DIAG = 'N'
      IF (DESCRA(3:3).EQ.'U') DIAG = 'U'
C     
C     C = A*B  OR C=A'*B
C     
C     
      NB = 4
      K4 = MOD(K,NB)
      SELECT CASE(K4)
      CASE(1)
         IF (K==1) THEN
            CALL DCSRMV(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,B(1,1),
     +           BETA,C(1,1),WORK,LWORK,IERROR)
         ELSE 
            CALL DCSRMV2(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,
     +           B(1,1),LDB,BETA,C(1,1),LDC,WORK,LWORK,IERROR)
            CALL DCSRMV3(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,
     +           B(1,3),LDB,BETA,C(1,3),LDC,WORK,LWORK,IERROR)
            K4 = K4 + 4 
         ENDIF
      CASE(2)
         CALL DCSRMV2(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,
     +        B(1,1),LDB,BETA,C(1,1),LDC,WORK,LWORK,IERROR)
      CASE(3)
         CALL DCSRMV3(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,
     +        B(1,1),LDB,BETA,C(1,1),LDC,WORK,LWORK,IERROR)
      END SELECT

      IF(IERROR.NE.0) THEN
         INT_VAL(1)=IERROR
         CALL FCPSB_ERRPUSH(4012,NAME,INT_VAL)
         GOTO 9999
      END IF

      DO I=K4+1,K,NB
         CALL DCSRMV4(TRANS,DIAG,M,N,ALPHA,AR,JA,IA,
     +        B(1,I),LDB,BETA,C(1,I),LDC,WORK,LWORK,IERROR)
      ENDDO
      IF(IERROR.NE.0) THEN
         INT_VAL(1)=IERROR
         CALL FCPSB_ERRPUSH(4012,NAME,INT_VAL)
         GOTO 9999
      END IF

      CALL FCPSB_ERRACTIONRESTORE(ERR_ACT)
      RETURN

 9999 CONTINUE
      CALL FCPSB_ERRACTIONRESTORE(ERR_ACT)

      IF ( ERR_ACT .NE. 0 ) THEN 
         CALL FCPSB_SERROR()
         RETURN
      ENDIF

      RETURN
      END