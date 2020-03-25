-- ETL for the Dimension Member,   


-- extracts added, deleted and updated rows from the   
-- members table and also members who have birthday on the  
-- current date 

--create a table for the yesterday members, for tables that didn't exist 

DROP TABLE yesterdayTaMember;
CREATE TABLE yesterdayTaMember
(
  MEMBERNO	NUMBER(6,0),
  INITIALS	CHAR(4),
  "NAME"	VARCHAR2(50),
  ADDRESS	VARCHAR2(50),
  ZIPCODE	NUMBER(4,0),
  DATEBORN	DATE,
  DATEJOINED	DATE,
  DATELEFT	DATE,
  OWNSPLANEREG	CHAR(3),
  STATUSSTUDENT	CHAR(1),
  STATUSPILOT	CHAR(1),
  STATUSASCAT	CHAR(1),
  STATUSFULLCAT	CHAR(1),
  SEX	CHAR(1),
  CLUB	VARCHAR2(50)
);

/* in this table we will insert a copy of the source data of table member*/

INSERT INTO yesterdayTaMember(SELECT * FROM MyUser.TAMEMBER);

-- see all the data from the yesterday member

select * from YESTERDAYTAMEMBER;

/*do changes on Member table in original DWH*/

--change members' names and addresses 

update SARA.TAMEMBER set name = 'Karla  CHANGED' where name = 'Karla NEW';
update SARA.TAMEMBER set name = 'Clara  CHANGED ' where INITIALS='CLDA';
update SARA.TAMEMBER set Address = 'NEW  6000' where INITIALS = 'IDWI';

-- change members status 

update SARA.TAMEMBER set STATUSPILOT = 'Y' where INITIALS = 'PHNI';
update SARA.TAMEMBER set STATUSPILOT = 'Y' where INITIALS = 'FEPA';
update SARA.TAMEMBER set STATUSSTUDENT = 'N' where INITIALS = 'FEPE';

-- change members date left from the club

update SARA.TAMEMBER set DATELEFT = '24-apr-2018' where INITIALS = 'OSGR' ;
update SARA.TAMEMBER set DATELEFT = '24-apr-2018' where INITIALS = 'OSIB' ;
update SARA.TAMEMBER set DATELEFT = '24-apr-2018' where INITIALS = 'OSKH' ;
update SARA.TAMEMBER set DATELEFT = '24-apr-2018' where INITIALS = 'OSPA' ;

-- insert a new member into the table 

INSERT INTO SARA.Tamember VALUES(509, 'NAZZ', 'Nadina Zukova', 'Strandmollevej 8b, kolding', 6000, to_date('26-11-1977', 'DD-MM-YYYY'), to_date('17-04-2018', 'DD-MM-YYYY'), to_date(null, 'DD-MM-YYYY'), ' ', 'Y', 'N', 'N', 'N', 'F', 'Vejle');

-- delete a member from the member table 

DELEtE FROM SARA.TAMEMBER where INITIALS='NALL';

SELECT * FROM  SARA.TAMEMBER;

drop table DELTATABLEMEMBER;

-- create a delta table
-- this table will be for inserting the changed rows/Data 

CREATE TABLE deltaTableMember
(
  MEMBERNO	NUMBER(6,0),
  INITIALS	CHAR(4),
  "NAME"	VARCHAR2(50),
  ADDRESS	VARCHAR2(50),
  ZIPCODE	NUMBER(4,0),
  DATEBORN	DATE,
  DATEJOINED	DATE,
  DATELEFT	DATE,
  OWNSPLANEREG	CHAR(3),
  STATUSSTUDENT	CHAR(1),
  STATUSPILOT	CHAR(1),
  STATUSASCAT	CHAR(1),
  STATUSFULLCAT	CHAR(1),
  SEX	CHAR(1),
  CLUB	VARCHAR2(50),
  typeOfChange VARCHAR(50)
);
/* table for storing date of last extraction */
CREATE TABLE dateLastExtract
(
  tableName VARCHAR(250),
  dateExtract Date
);

-- insert the data that has been changed into the delta table member 

INSERT INTO DELTATABLEMEMBER 
(
    -- extract for added rows
	-- select the rows who were here in the delta member minus the ones in yesterday table to get the new rows

    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, 'add' AS typeOfChange
    FROM SARA.TAMEMBER
    WHERE memberno IN
    (
      SELECT memberno FROM SARA.TAMEMBER
      MINUS
      SELECT memberno FROM YESTERDAYTAMEMBER
    )
   
   
   UNION
    -- extract for deleted rows
	-- rows from yesterday minus the delta table to get the delete
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, 'deleted' AS typeOfChange 
    FROM yesterdayTaMember
    WHERE memberno IN
    (
      SELECT memberno FROM yesterdayTaMember
      MINUS
      SELECT memberno FROM SARA.TAMEMBER
    )
    UNION
    -- extract for changed rows
	-- rows from today rows minus rows from yesterday) - new rows)
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, 'changed row' AS typeOfChange FROM
    (
      SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB FROM
      (
        SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB FROM SARA.TAMEMBER
        MINUS
        SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB FROM yesterdayTaMember
      ) changes
      WHERE NOT changes.memberno IN
      (
        SELECT memberno FROM SARA.TAMEMBER
        MINUS
        SELECT memberno FROM yesterdayTaMember
      )
      minus
      SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB FROM SARA.TAMEMBER
      WHERE memberno IN
      (
        SELECT memberno FROM yesterdayTaMember
        MINUS
        SELECT memberno FROM SARA.TAMEMBER
      )
    )
    UNION
    -- members whose age changed between the extraction and the current 
    -- rows from today with dateBorn > date of last extract
	SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, 'change' AS typeOfChange
    FROM SARA.TAMEMBER 
    WHERE 
      DATEBORN<=sysdate 
      AND 
      DATEBORN > (SELECT Max(dateExtract) FROM datelastextract WHERE tablename = 'tamember'));
      
 select * from DELTATABLEMEMBER;
select * from DELTATABLEMEMBER where TYPEOFCHANGE='deleted' or TYPEOFCHANGE = 'changed row';
select * from SARA.TAMEMBER;
select COUNT  (*)FROM SARA.TAMEMBER;
select COUNT  (*)FROM YESTERDAYTAMEMBER;


/*------------- VALIDATION ----------*/
CREATE TABLE ErrorRemovedTaMember
(
  MEMBERNO	NUMBER(6,0),
  INITIALS	CHAR(4),
  "NAME"	VARCHAR2(50),
  ADDRESS	VARCHAR2(50),
  ZIPCODE	NUMBER(4,0),
  DATEBORN	DATE,
  DATEJOINED	DATE,
  DATELEFT	DATE,
  OWNSPLANEREG	CHAR(3),
  STATUSSTUDENT	CHAR(1),
  STATUSPILOT	CHAR(1),
  STATUSASCAT	CHAR(1),
  STATUSFULLCAT	CHAR(1),
  SEX	CHAR(1),
  CLUB	VARCHAR2(50),
  TYPEOFCHANGE VARCHAR(50)
);

Drop table ValidatedMember;
CREATE TABLE ValidatedMember
(
  MEMBERNO	NUMBER(6,0),
  INITIALS	CHAR(4),
  "NAME"	VARCHAR2(50),
  ADDRESS	VARCHAR2(50),
  ZIPCODE	NUMBER(4,0),
  DATEBORN	DATE,
  DATEJOINED	DATE,
  DATELEFT	DATE,
  OWNSPLANEREG	CHAR(3),
  STATUSSTUDENT	CHAR(1),
  STATUSPILOT	CHAR(1),
  STATUSASCAT	CHAR(1),
  STATUSFULLCAT	CHAR(1),
  SEX	CHAR(1),
  CLUB	VARCHAR2(50),
  TYPEOFCHANGE VARCHAR(50)
);

/* insert all not validated items into ErrorRemovedTaMember  from deltatabe(if runs every day), will diff,code for the first time*/
INSERT INTO ErrorRemovedTaMember
(
  SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE
  FROM
  (
    /* more Y than one */
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE
    FROM DELTATABLEMEMBER
    WHERE  regexp_count(statusstudent || statusPilot || statusAsCat || statusFullCat,  'Y') <> 1
    UNION
    /* repeating MEMBERNO */
    SELECT extractTable.MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE 
    FROM DELTATABLEMEMBER extractTable 
    JOIN 
    (
      SELECT MEMBERNO FROM
      (
        SELECT MEMBERNO, COUNT(*) AS repetions FROM DELTATABLEMEMBER
        GROUP BY MEMBERNO
      )
      where repetions>1
    ) repietingIDs 
    ON extractTable.MemberNo=repietingIDs.MEMBERNO
    UNION
    /* repeating INTIALS */ 
    SELECT MEMBERNO, extractTable.INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE 
    FROM DELTATABLEMEMBER extractTable 
    JOIN 
    (
      SELECT INITIALS FROM
      (
        SELECT INITIALS, COUNT(*) AS repetions FROM DELTATABLEMEMBER
        GROUP BY INITIALS
      )
      where repetions>1 -- or having instead of 2 select
    ) repietingINITIALSs 
    ON extractTable.INITIALS=repietingINITIALSs.INITIALS
    UNION
    /* not M or F */ 
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE  
    FROM DELTATABLEMEMBER 
    WHERE SEX<>'F' AND SEX<>'M'
    UNION
    /* select members which are assigned to nonexisting club */
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE  
    FROM DELTATABLEMEMBER 
    /* change to D_club when will be d_club implemented */
    WHERE CLUB NOT IN (SELECT mane FROM SARA.TACLUB)
    UNION
    /* dates */
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE  
    FROM DELTATABLEMEMBER
    WHERE DATEBORN>DATEJOINED OR DATEBORN>DATELEFT
    UNION
    
    /* zipcode check */
    SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE  
    FROM DELTATABLEMEMBER
    WHERE ZIPCODE<1000 OR ZIPCODE>9990
  )
);

select * from ErrorRemovedTaMember;

/* insert validated items into ValidatedMember table - basically, Deltamember table minus errorMembers */
INSERT INTO ValidatedMember
(
  SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATEJOINED, DATELEFT, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE 
  FROM 
  (
    SELECT * FROM DELTATABLEMEMBER
    WHERE datejoined<=dateleft OR dateLeft IS NULL
    MINUS
    SELECT * FROM ErrorRemovedTaMember
    WHERE datejoined<=dateleft OR dateLeft IS NULL
  )
  UNION
  SELECT MEMBERNO, INITIALS, "NAME", ADDRESS, ZIPCODE, DATEBORN, DATELEFT, DATEJOINED, OWNSPLANEREG, STATUSSTUDENT, STATUSPILOT, STATUSASCAT, STATUSFULLCAT, SEX, CLUB, TYPEOFCHANGE 
  FROM 
  (
    SELECT * FROM DELTATABLEMEMBER
    WHERE datejoined>dateleft AND dateleft IS NOT NULL
    MINUS
    SELECT * FROM ErrorRemovedTaMember
    WHERE datejoined>dateleft AND dateleft IS NOT NULL
  )
);

select * FROM VALIDATEDMEMBER;

/*transform validated members, add dates from/to, age, gender, status*/

drop table transformed_Member;
CREATE TABLE transformed_Member
(
  memberNo number (6,0),
  initials char(4),
  "NAME" varchar2(50),
  address varchar2(50),
   ZIPCODE	NUMBER(4,0),
   age NUMBER(4,0),
   status VARCHAR2(50),
   validFrom date,
  validTo date,
  gender VARCHAR(20),
  club VARCHAR2(50),
  typeofchange VARCHAR(50)
 
);

INSERT INTO transformed_Member
(
    SELECT  memberNo as  memberNo,
            INITIALS as initials,
            "NAME" as "NAME",
            ADDRESS as ADDRESS,
            ZIPCODE as ZIPCODE,
            floor(months_between(sysdate, dateborn) /12) AS AGE,
            case (STATUSSTUDENT || STATUSPILOT || STATUSASCAT || STATUSFULLCAT) 
              when 'YNNN' then 'student'
              when 'NYNN' then 'pilot'
              when 'NNYN' then 'ascat'
              when 'NNNY' then 'fullcat'
            end AS STATUS,
            DATEJOINED as VALIDFROM,
           COALESCE(DATELEFT, to_date('31-12-9999', 'DD-MM-YYYY')) AS VALIDTO, -- if the date left is null put this date
            case sex
                when 'M' then 'male'
                when 'F' then 'female'
                else   'undefined'
              end as GENDER,
            CLUB as CLUB,
            TYPEOFCHANGE as TYPEOFCHANGE
    FROM VALIDATEDMEMBER
);


/*added members*/
INSERT INTO D_MEMBER(memberId, memberNo,initials, "NAME", address, zipCode, age, status, validFrom, validTo, gender, club) 
  SELECT sq_member.nextVal as memberId, memberNo, initials, "NAME", address, zipCode, age, status, validFrom, validTo, gender, club 
  FROM transformed_Member
  WHERE typeofchange='add';

INSERT INTO D_MEMBER(memberId, memberNo,initials, "NAME", address, zipCode, age, status, validFrom, validTo, gender, club) 
  SELECT sq_member.nextVal as memberId, memberNo, initials, "NAME", address, zipCode, age, status, sysdate as validFrom, validTo, gender, club 
  FROM transformed_Member
  WHERE typeofchange='changed row';
  
  UPDATE D_Member
  SET validTo = sysdate 
  WHERE 
        validTo=to_date('31-12-9999', 'DD-MM-YYYY') 
    AND initials IN (SELECT initials from transformed_Member where typeofchange='changed row');

INSERT INTO D_MEMBER(memberId, memberNo,initials, "NAME", address, zipCode, age, status, validFrom, validTo, gender, club) 
  SELECT sq_member.nextVal as memberId, memberNo, initials, "NAME", address, zipCode, age, status, validFrom,  sysdate as validTo, gender, club 
  FROM transformed_Member
  WHERE typeofchange='deleted';


