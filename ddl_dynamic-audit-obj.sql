SET SERVEROUT ON
SET VERIFY OFF

SPO DDL_DYNAMIC_AUDIT_OBJ.log

PRO INITIANTING CREATION OF TABLES, INDEXES, TRIGGER AND PACKAGE
PRO

DEF OWNER = '&1'
DEF TS_DAT = '&2'
DEF TS_IDX = '&3'

PRO CREATE TABLE > MONIT_DML_LOG
PRO

CREATE TABLE "&&OWNER"."MONIT_DML_LOG"
(
   TIMESTAMP   DATE
 , SESSIONID   NUMBER(24)
 , USERNAME    VARCHAR2(30)
 , OWNER       VARCHAR2(30)
 , TAB         VARCHAR2(30)
 , COL         VARCHAR2(30)
 , OLD         VARCHAR2(2000)
 , NEW         VARCHAR2(2000)
 , DML         CHAR(1)
 , ORID        VARCHAR2(100)
 , BLK         CHAR(1)
)
TABLESPACE "&&TS_DAT"
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;
/

PRO CREATE INDEX > MONIT_DML_LOG_IDX_DT
PRO

CREATE INDEX "&&OWNER"."MONIT_DML_LOG_IDX_DT" ON "&&OWNER"."MONIT_DML_LOG"
(TIMESTAMP)
LOGGING
TABLESPACE "&&TS_IDX"
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

PRO CREATE INDEX > MONIT_DML_LOG_IDX_COL
PRO

CREATE INDEX "&&OWNER"."MONIT_DML_LOG_IDX_COL" ON "&&OWNER"."MONIT_DML_LOG"
(COL)
LOGGING
TABLESPACE "&&TS_IDX"
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

PRO CREATE INDEX > MONIT_DML_LOG_IDX_NVAL
PRO

CREATE INDEX "&&OWNER"."MONIT_DML_LOG_IDX_NVAL" ON "&&OWNER"."MONIT_DML_LOG"
(NEW)
LOGGING
TABLESPACE "&&TS_IDX"
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

PRO CREATE INDEX > MONIT_DML_LOG_IDX_OVAL
PRO

CREATE INDEX "&&OWNER"."MONIT_DML_LOG_IDX_OVAL" ON "&&OWNER"."MONIT_DML_LOG"
(OLD)
LOGGING
TABLESPACE "&&TS_IDX"
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

PRO CREATE INDEX > MONIT_DML_LOG_IDX_ORID
PRO

CREATE INDEX "&&OWNER"."MONIT_DML_LOG_IDX_ORID" ON "&&OWNER"."MONIT_DML_LOG"
(ORID)
LOGGING
TABLESPACE "&&TS_IDX"
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          200K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

PRO CREATE TRIGGER TRG_MONIT_DML_LOG FOR LOG TABLE PROTECTION
PRO

CREATE OR REPLACE TRIGGER "&&OWNER"."TRG_MONIT_DML_LOG"
   BEFORE UPDATE OR DELETE
   ON MONIT_DML_LOG
   FOR EACH ROW
   DISABLE
DECLARE
   V_TRANSACT    VARCHAR2(6) := '';
   E_DML_BLOCK   EXCEPTION;
BEGIN
   
   IF UPDATING
   THEN
      V_TRANSACT := 'UPDATE';
   ELSE
      V_TRANSACT := 'DELETE';
   END IF;

   IF (V_TRANSACT = 'UPDATE'
       OR V_TRANSACT = 'DELETE')
   THEN
      RAISE_APPLICATION_ERROR
      (
         -20002
       ,    CHR(10)
         || ' _____________________________'
         || CHR(10)
         || '|                             '
         || CHR(10)
         || '|      TRANSACTION CONTROL    '
         || CHR(10)
         || '|                             '
         || CHR(10)
         || '|       CHANGE NOT ALLOWED    '
         || CHR(10)
         || '|_____________________________'
         || CHR(10)
         || CHR(10)
      );
   END IF;
END;
/

PRO CHECK TRIGGER STATUS AND ENABLE IF VALID
PRO

DECLARE
   V_STATUS   VARCHAR2 (30);
BEGIN
   SELECT STATUS
     INTO V_STATUS
     FROM DBA_OBJECTS
    WHERE OWNER = '&&OWNER' AND OBJECT_NAME = 'TRG_MONIT_DML_LOG'
      AND OBJECT_TYPE = 'TRIGGER';

   IF V_STATUS = 'INVALID'
   THEN
      DBMS_OUTPUT.PUT_LINE ('TRIGGER STATUS IS :' || V_STATUS || '. PLEASE CHECK COMPILE ERRORS ');
   ELSE
      EXECUTE IMMEDIATE ('ALTER TRIGGER '|| '&&OWNER' ||'.TRG_MONIT_DML_LOG ENABLE');
      DBMS_OUTPUT.PUT_LINE ('TRIGGER '|| '&&OWNER' ||'.TRG_MONIT_DML_LOG ENABLED');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/

PRO CREATE PACKAGE SPEC
PRO

CREATE OR REPLACE PACKAGE "&&OWNER"."PKG_MONIT_ADML"
AS
   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN VARCHAR2
    , L_OLD   IN VARCHAR2
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   );

   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN DATE
    , L_OLD   IN DATE
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   );

   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN NUMBER
    , L_OLD   IN NUMBER
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   );
END;
/

PRO CREATE PACKAGE BODY
PRO

CREATE OR REPLACE PACKAGE BODY "&&OWNER"."PKG_MONIT_ADML"
AS
   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN VARCHAR2
    , L_OLD   IN VARCHAR2
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   )
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF (   L_NEW <> L_OLD
          OR (L_NEW IS NULL
              AND L_OLD IS NOT NULL)
          OR (L_NEW IS NOT NULL
              AND L_OLD IS NULL)
          )
      THEN
         INSERT INTO "&&OWNER"."MONIT_DML_LOG"
                     (
                        TIMESTAMP
                      , SESSIONID
                      , USERNAME
                      , OWNER
                      , TAB
                      , COL
                      , OLD
                      , NEW
                      , DML
                      , ORID
                      , BLK
                     )
              VALUES
                     (
                        L_TS
                      , SYS_CONTEXT( 'USERENV', 'SESSIONID')
                      , USER
                      , UPPER(L_OWNER)
                      , UPPER(L_TNAME)
                      , UPPER(L_CNAME)
                      , L_OLD
                      , L_NEW
                      , L_DML
                      , L_ORID
                      , L_BLK
                     );
                     COMMIT;
      END IF;
   END;

   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN DATE
    , L_OLD   IN DATE
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   )
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF (   L_NEW <> L_OLD
          OR (L_NEW IS NULL
              AND L_OLD IS NOT NULL)
          OR (L_NEW IS NOT NULL
              AND L_OLD IS NULL)
          )
      THEN
         INSERT INTO "&&OWNER"."MONIT_DML_LOG"
                     (
                        TIMESTAMP
                      , SESSIONID
                      , USERNAME
                      , OWNER
                      , TAB
                      , COL
                      , OLD
                      , NEW
                      , DML
                      , ORID
                      , BLK
                     )
              VALUES
                     (
                        L_TS
                      , SYS_CONTEXT( 'USERENV', 'SESSIONID')
                      , USER
                      , UPPER(L_OWNER)
                      , UPPER(L_TNAME)
                      , UPPER(L_CNAME)
                      , TO_CHAR( L_OLD, 'DD/MM/YYYY HH24:MI:SS')
                      , TO_CHAR( L_NEW, 'DD/MM/YYYY HH24:MI:SS')
                      , L_DML
                      , L_ORID
                      , L_BLK
                     );
                     COMMIT;
      END IF;
   END;

   PROCEDURE CHECK_VAL
   (
      L_TS    IN DATE
    , L_OWNER IN VARCHAR2
    , L_TNAME IN VARCHAR2
    , L_CNAME IN VARCHAR2
    , L_NEW   IN NUMBER
    , L_OLD   IN NUMBER
    , L_DML   IN CHAR
    , L_ORID  IN VARCHAR2
    , L_BLK   IN CHAR
   )
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF (   L_NEW <> L_OLD
          OR (L_NEW IS NULL
              AND L_OLD IS NOT NULL)
          OR (L_NEW IS NOT NULL
              AND L_OLD IS NULL)
          )
      THEN
         INSERT INTO "&&OWNER"."MONIT_DML_LOG"
                     (
                        TIMESTAMP
                      , SESSIONID
                      , USERNAME
                      , OWNER
                      , TAB
                      , COL
                      , OLD
                      , NEW
                      , DML
                      , ORID
                      , BLK
                     )
              VALUES
                     (
                        L_TS
                      , SYS_CONTEXT( 'USERENV', 'SESSIONID')
                      , USER
                      , UPPER(L_OWNER)
                      , UPPER(L_TNAME)
                      , UPPER(L_CNAME)
                      , L_OLD
                      , L_NEW
                      , L_DML
                      , L_ORID
                      , L_BLK
                     );
      END IF;
      COMMIT;
   END;
END PKG_MONIT_ADML;
/

PRO CREATING PUBLIC SYNONYM FOR PKG_MONIT_ADML
CREATE PUBLIC SYNONYM PKG_MONIT_ADML FOR "&&OWNER"."PKG_MONIT_ADML";
PRO
PRO IF NEEDED, CHECK COMMAND FOR GRANTING OTHER USERS BELLOW
PRO GRANT EXECUTE ON "&&OWNER"."PKG_MONIT_ADML" TO "<USER>";
PRO
PRO OBJECTS CREATED, PLEASE CHECK LOG FILE!

SPO OFF