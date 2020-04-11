-- Query for pretty formmat audit logs
  
  SELECT 
         DECODE (dl.dml,  'D', 'DELETE',  'I', 'INSERT',  'U', 'UPDATE') dml,
         dl.timestamp,
         DL.blk is_blocked,
         orid oracle_tab_rowid,
         dl.owner,
         dl.tab,
         LISTAGG (dl.col || '-> From: ' || dl.old || ' / To: ' || dl.new, CHR (10)) WITHIN GROUP (ORDER BY dl.col)
            dml_changes
    FROM monit_dml_log dl
   WHERE dl.timestamp > TRUNC (SYSDATE -1)
GROUP BY 
         dl.dml,
         dl.timestamp,
         DL.blk,
         orid,
         dl.owner,
         dl.tab
ORDER BY timestamp DESC;