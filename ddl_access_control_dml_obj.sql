SET SERVEROUT ON
SET VERIFY OFF

SPO DDL_ACCESS_CONTROL_DML_OBJ.log

PRO INITIANTING CREATION OF TABLES, TRIGGER, FUNCTION AND PROCEDURE
PRO
DEF OWNER = '&1'
DEF TS_DAT = '&2'

PRO CREATING TABLE MONIT_DML_ACCESS
PRO
CREATE TABLE "&&OWNER"."MONIT_DML_ACCESS"
(
  ROW_ID       NUMBER                           NOT NULL,
  USERNAME     VARCHAR2(30 BYTE)                NOT NULL,
  OSUSER       VARCHAR2(30 BYTE)                NOT NULL,
  MACHINE      VARCHAR2(64 BYTE)                NOT NULL,
  IP_ADDRESS   VARCHAR2(15 BYTE)                NOT NULL,
  PROGRAM      VARCHAR2(48 BYTE)                NOT NULL,
  VALID_ORDER  NUMBER(3)                        NOT NULL,
  OWNER        VARCHAR2(60 BYTE)                NOT NULL,
  TABLE_NAME   VARCHAR2(128 BYTE)               NOT NULL,
  PERMISSIONS  CHAR(3 BYTE)                     NOT NULL,  
  LOG          CHAR(3 BYTE)        DEFAULT 'Y'  NOT NULL,  
  OBS          VARCHAR2(200 BYTE)               NOT NULL
)
TABLESPACE "&&TS_DAT"
RESULT_CACHE (MODE DEFAULT)
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
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

PRO IF NEEDED, CHECK COMMAND FOR GRANTING OTHER USERS BELLOW
PRO GRANT SELECT ON "&&OWNER"."MONIT_DML_ACCESS" TO "<USER>";
PRO
PRO CREATING TRIGGER TO PROTECT DML ON ACCESS TABLE
PRO
CREATE OR REPLACE TRIGGER "&&OWNER"."TRG_MONIT_DML_ACCESS"
   BEFORE UPDATE OR DELETE OR INSERT
   ON "&&OWNER"."MONIT_DML_ACCESS"
   FOR EACH ROW
   DISABLE
DECLARE

BEGIN
   
  IF NOT SYS_CONTEXT ('USERENV', 'SESSION_USER') = '&&OWNER'
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
    WHERE OWNER = '&&OWNER' AND OBJECT_NAME = 'TRG_MONIT_DML_ACCESS'
      AND OBJECT_TYPE = 'TRIGGER';

   IF V_STATUS = 'INVALID'
   THEN
      DBMS_OUTPUT.PUT_LINE ('TRIGGER STATUS IS :' || V_STATUS || '. PLEASE CHECK COMPILE ERRORS ');
   ELSE
      EXECUTE IMMEDIATE ('ALTER TRIGGER '|| '&&OWNER' ||'.TRG_MONIT_DML_ACCESS ENABLE');
      DBMS_OUTPUT.PUT_LINE ('TRIGGER '|| '&&OWNER' ||'.TRG_MONIT_DML_ACCESS ENABLED');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/

PRO CREATING FUNCTION FNC_DML_ACCESS_CHECK
PRO
CREATE OR REPLACE FUNCTION "&&OWNER"."FNC_DML_ACCESS_CHECK" (P_OWNER      IN VARCHAR2,
                                                             P_TABLE      IN VARCHAR2,
                                                             P_TRANSACT   IN CHAR,
                                                             P_LOG        OUT CHAR)
IS
   V_ID           NUMBER;
   V_LOG          CHAR := 'N';
   V_IP_ADDRESS   VARCHAR2 (15) := SYS_CONTEXT ('USERENV', 'IP_ADDRESS');
   V_MACHINE      VARCHAR2 (64) := SYS_CONTEXT ('USERENV', 'HOST');
   V_OSUSER       VARCHAR2 (30) := SYS_CONTEXT ('USERENV', 'OS_USER');
   V_PROGRAM      VARCHAR2 (48);
   V_SESSION_ID   NUMBER := SYS_CONTEXT ('USERENV', 'SESSIONID');
   V_USERNAME     VARCHAR2 (30) := SYS_CONTEXT ('USERENV', 'SESSION_USER');
BEGIN
   -- GET SESSION INFO
   SELECT PROGRAM
     INTO V_PROGRAM
     FROM V$SESSION
    WHERE     AUDSID = V_SESSION_ID
          AND NVL (MACHINE, '0') = NVL (SYS_CONTEXT ('USERENV', 'HOST'), '0')
          AND NVL (TERMINAL, '0') = NVL (SYS_CONTEXT ('USERENV', 'TERMINAL'), '0')
          AND TYPE <> 'BACKGROUND'
          AND ROWNUM < 2;

   BEGIN
      SELECT ROW_ID, LOG
        INTO V_ID, V_LOG
        FROM (  SELECT ROW_ID, LOG
                  FROM "&&OWNER"."MONIT_DML_ACCESS"
                 WHERE     (UPPER (V_PROGRAM) LIKE UPPER (PROGRAM) OR (PROGRAM = '%' AND V_PROGRAM IS NULL))
                       AND (UPPER (V_MACHINE) LIKE UPPER (MACHINE) OR (MACHINE = '%' AND V_MACHINE IS NULL))
                       AND (UPPER (V_USERNAME) LIKE UPPER (USERNAME) OR (USERNAME = '%' AND V_USERNAME IS NULL))
                       AND (UPPER (V_OSUSER) LIKE UPPER (OSUSER) OR (OSUSER = '%' AND V_OSUSER IS NULL))
                       AND (UPPER (V_IP_ADDRESS) LIKE UPPER (IP_ADDRESS) OR (IP_ADDRESS = '%' AND V_IP_ADDRESS IS NULL))
                       AND OWNER = P_OWNER
                       AND TABLE_NAME = P_TABLE
                       AND UPPER (PERMISSIONS) LIKE '%' || UPPER (P_TRANSACT) || '%'
              ORDER BY VALID_ORDER)
       WHERE ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 'F';
   END;

   RETURN TRUE;
EXCEPTION
   WHEN OTHERS
   THEN
            DBMS_OUTPUT.PUT_LINE ('-------SQLERRM-------------');
            DBMS_OUTPUT.PUT_LINE (SQLERRM);
            DBMS_OUTPUT.PUT_LINE ('-------FORMAT_ERROR_STACK--');
            DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_ERROR_STACK);
            DBMS_OUTPUT.PUT_LINE (' ');
      RETURN FALSE;
END;
/

PRO CREATING PUBLIC SYNONYM FOR FNC_DML_ACCESS_CHECK
CREATE PUBLIC SYNONYM FNC_DML_ACCESS_CHECK FOR "&&OWNER"."FNC_DML_ACCESS_CHECK";
PRO
PRO IF NEEDED, CHECK COMMAND FOR GRANTING OTHER USERS BELLOW
PRO GRANT EXECUTE ON "&&OWNER"."FNC_DML_ACCESS_CHECK" TO "<USER>";
PRO
PRO OBJECTS CREATED, PLEASE CHECK LOG FILE!

SPO OFF