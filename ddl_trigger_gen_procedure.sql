PRO CREATE PROCEDURE THAT GENERATES CUSTOM TRIGGER DDL

CREATE OR REPLACE PROCEDURE PRC_GEN_TRIGGER_SCRIPT (P_OWNER       IN VARCHAR2,
                                                    P_TABLE       IN VARCHAR2,
                                                    P_LOG_ERROR   IN BOOLEAN DEFAULT TRUE)
IS
   V_TRG_TEXT   VARCHAR2 (32000);

   CURSOR C_TABLE
   IS
      SELECT TABLE_NAME, OWNER
        FROM DBA_TABLES
       WHERE TABLE_NAME = UPPER (P_TABLE) AND OWNER = UPPER (P_OWNER);

   CURSOR C_COLUMN
   IS
      SELECT COLUMN_NAME
        FROM DBA_TAB_COLUMNS
       WHERE TABLE_NAME = UPPER (P_TABLE) AND OWNER = UPPER (P_OWNER);

BEGIN
   FOR R IN C_TABLE
   LOOP
      V_TRG_TEXT := 'CREATE OR REPLACE TRIGGER '|| UPPER(P_OWNER) ||'.TRG_AUD_' || R.TABLE_NAME || CHR (10);
      V_TRG_TEXT := V_TRG_TEXT || ' AFTER INSERT OR UPDATE OR DELETE ON '|| UPPER(P_OWNER) || '.' || R.TABLE_NAME || CHR (10);
      V_TRG_TEXT := V_TRG_TEXT || 'FOR EACH ROW' || CHR (10) || ' DISABLE ';
      V_TRG_TEXT :=
            V_TRG_TEXT
         || 'DECLARE '
         || 'V_TRANSACT CHAR(1);'
         || CHR (10)
         || 'V_SYSDATE DATE :=SYSDATE;'
         || CHR (10)
         || ' V_BLK CHAR := ''N''; '
         || CHR (10)
         || 'PROCEDURE PRC_CALL_PKG'
         || CHR (10)
         || 'IS'
         || CHR (10)
         || 'BEGIN'
         || CHR (10);

      FOR I IN C_COLUMN
      LOOP
         V_TRG_TEXT :=
               V_TRG_TEXT
            || 'PKG_MONIT_ADML.CHECK_VAL( V_SYSDATE,'''
            || R.OWNER
            || ''', '''
            || R.TABLE_NAME
            || ''', '''
            || I.COLUMN_NAME
            || ''', '
            || ':NEW.'
            || I.COLUMN_NAME
            || ', :OLD.'
            || I.COLUMN_NAME
            || ', V_TRANSACT, :OLD.ROWID, V_BLK);'
            || CHR (10);
      END LOOP;

      V_TRG_TEXT := V_TRG_TEXT || 'END;' || CHR (10) || 'BEGIN' || CHR (10);
      V_TRG_TEXT :=
            V_TRG_TEXT
         || 'IF UPDATING   THEN V_TRANSACT := ''U'';'
         || CHR (10)
         || 'ELSIF INSERTING THEN V_TRANSACT := ''I'';'
         || CHR (10)
         || 'ELSE V_TRANSACT := ''D'';'
         || CHR (10)
         || 'END IF;'
         || CHR (10);

      V_TRG_TEXT :=
         V_TRG_TEXT || 'IF FNC_DML_ACCESS_CHECK (''' || P_OWNER || ''', ''' || P_TABLE || ''', V_TRANSACT) THEN PRC_CALL_PKG;';

      IF P_LOG_ERROR
      THEN
         V_TRG_TEXT :=
               V_TRG_TEXT
            || 'ELSE V_BLK := ''Y''; '
            || CHR (10)
            || 'PRC_CALL_PKG;'
            || CHR (10)
            || 'RAISE_APPLICATION_ERROR (-20001,''TRANSACTION NOT ALLOWED, PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR.'');';
      END IF;

      V_TRG_TEXT :=
            V_TRG_TEXT
         || 'END IF;'
         || CHR (10)
         || CHR (10)
         || 'EXCEPTION WHEN OTHERS'
         || CHR (10)
         || 'THEN'
         || CHR (10)
         || 'DBMS_OUTPUT.PUT_LINE (''-------SQLERRM-------------'');'
         || CHR (10)
         || 'DBMS_OUTPUT.PUT_LINE (SQLERRM);'
         || CHR (10)
         || 'DBMS_OUTPUT.PUT_LINE (''-------FORMAT_ERROR_STACK--'');'
         || CHR (10)
         || 'DBMS_OUTPUT.PUT_LINE (DBMS_UTILITY.FORMAT_ERROR_STACK);'
         || CHR (10)
         || 'DBMS_OUTPUT.PUT_LINE ('' '');'
         || CHR (10)
         || 'RAISE;'
         || CHR (10)
         || 'END;'
         || CHR (10)
         || '/';

      BEGIN
         DBMS_OUTPUT.PUT_LINE (V_TRG_TEXT || CHR (10) || CHR (10));
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE (V_TRG_TEXT);
      END;
   END LOOP;
END;
/

PRO AFTER CREATION, YOU CAN EXEC THE PROCEDURE TO GENERATE TRIGGER CODE ON DBMS_OUTPUT
PRO EXEC PRC_GEN_TRIGGER_SCRIPT( P_OWNER => '<OWNER>', P_TABLE => '<TABLE>', P_LOG_ERROR => TRUE)
PRO PARMETER DEFINITION:
PRO P_OWNER -> TRIGGER OWNER
PRO P_TABLE -> BASE TABLE FOR TRIGGER
PRO P_LOG_ERROR -> DEFAULT=TRUE, SET TO FALSE, TO GET A TRIGGER THAT NOT LOGS WHEN USER DML GETS BLOCKED.
