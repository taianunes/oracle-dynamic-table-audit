# Oracle Dynamic Table Audit

## 1. Introduction

This repository contains the steps to create a set of Oracle PL/SQL objects
for auditing changes on table stored data and access control to DML commands.

The set of objects types are:

- TABLES:
  * *Store audit data and DML access control*
- PACKAGE:
  * *Checks changed data and creates log of it*
- PROCEDURE:
  * *Generates Custom Trigger DDL script*
- FUNCTION:
  * *Validates session DML permissions*

## 2. Installing

The installation scripts are designed to run on an Oracle Database.
Privileged database access is required during installation.

You're gonna need the listed grants:

```sql
GRANT CREATE TABLE TO <USER>;
GRANT CREATE PROCEDURE TO <USER>;
GRANT CREATE TRIGGER TO <USER>;
GRANT CREATE PUBLIC SYNONYM TO <USER>;
```

The instructions below work on Linux and similar operating systems.
Adjust them for other platforms.

### 2.1. Clone this repository

Clone the repository, for example

```shell
cd $HOME
git clone https://github.com/taianunes/oracle-dynamic-table-audit.git
```

or download and extract the ZIP file:

```shell
unzip oracle-dynamic-table-audit.zip
```

### 2.2. Change directory

```shell
cd $HOME/oracle-dynamic-table-audit
```

### 2.3. Execute DDL scripts

The installation scripts cover more than one feature, which are detailed:

#### 2.3.1. Package PKG_MONIT_ADML

This package is prepared to compare if field data has changed and insert a record
on table `MONIT_DML_LOG` if so. Also creates a trigger on this table do prevent `UPDATES` and `DELETES`.

```shell
sqlplus user/user_pwd@connect_string
@ddl_dynamic-audit-obj.sql <OWNER> <TABLESPACE_DATA> <TABLESPACE_INDEX>
```

#### 2.3.2. Access Control Objects

This script creates the following:

1. **TABLE `MONIT_DML_ACCESS`**
   * Permissions granted on each table.
   * Session origin configuration.
1. **TRIGGER `TRG_MONIT_DML_ACCESS`**
   * Prevent DML on access control table, by users that are not the table owner.
1. **FUNCTION `FNC_DML_ACCESS_CHECK`**
   * Checks if exists an entry on table `MONIT_DML_ACCESS` that allows current DML command.

```shell
sqlplus user/user_pwd@connect_string
@ddl_access_control_dml_obj.sql <OWNER> <TABLESPACE_DATA> <TABLESPACE_INDEX>
```

#### 2.3.3. Generate Trigger Procedure

This script creates a procedure that generates trigger DDL script using DBMS_OUTPUT, for the OWNER and TABLE informed.

```shell
sqlplus user/user_pwd@connect_string
@ddl_trigger_gen_procedure.sql <OWNER> <TABLESPACE_DATA> <TABLESPACE_INDEX>
```

*Note*: Oracle's `sqlldr` utility needs to be in `$PATH` for correct
loading of the Product Media (PM) and Sales History (SH) schemas.

### 2.4. Configuration and usage

It's required to insert and entry on `MONIT_DML_ACCESS` for each table that contains the trigger created by the procedure that was created.
Otherwise none DML will be allowed on target table for the moment you ENABLE that trigger.

```sql
-- An example of entry that allows any user to make DML and logs it.
--
-- For PERMISSIONS column, you need to set one to three letter as desired DML configuration
-- I = INSERT / U = UPDATE / D = DELETE
--
INSERT INTO MONIT_DML_ACCESS(ROW_ID,
							 USERNAME,
							 OSUSER,
							 MACHINE,
							 IP_ADDRESS,
							 PROGRAM,
							 VALID_ORDER,
							 OWNER,
							 TABLE_NAME,
							 PERMISSIONS,
							 LOG,
							 OBS)
					 VALUES ('1',
					 	     '%',
					 	     '%',
					 	     '%',
					 	     '%',
					 	     '%',
					 	     '1',
					 	     '<OWNER>',
					 	     '<TABLE>',
					 	     'IUD',
					 	     'Y',
					 	     'An entry that allows any user DML and logs it' );
COMMIT;

```

After configuring an entry, you can use script above to generate trigger script and enable it.

```sql
SET SERVEROUT ON
SET VERIFY OFF
EXEC PRC_GEN_TRIGGER_SCRIPT( P_OWNER => '<OWNER>', P_TABLE => '<TABLE>', P_LOG_ERROR => TRUE);
```
Set parameter as informed bellow:

* P_OWNER -> TRIGGER OWNER
* P_TABLE -> BASE TABLE FOR TRIGGER
* P_LOG_ERROR -> DEFAULT=TRUE, SET TO FALSE, TO GET A TRIGGER THAT NOT LOGS WHEN USER DML GETS BLOCKED.