--Queries to insert fake data to use in the NOT FOUND ERROR EXCEPTION
-- and to simulate dimensions that we didnt populate
DROP TABLE TAFLIGHTS_ALL;
DROP TABLE TAFLIGHTS_TEMP1;
DROP TABLE TAFLIGHTS_TEMP2;
DROP TABLE TAFLIGHTS_YESTERDAY;
DROP TABLE TAFLIGHTS_INVALID;

--We create a temporary table with the flights from vejle and add a new column with the club name
CREATE TABLE TAFLIGHTS_TEMP1 
AS 
SELECT * FROM SARA.taflightsvejle
;

ALTER TABLE TAFLIGHTS_TEMP1 
ADD (CLUBNAME varchar(50) 
);
 
UPDATE TAFLIGHTS_TEMP1 SET CLUBNAME='Vejle';

--We do the same now with the flights from the other club
CREATE TABLE TAFLIGHTS_TEMP2 
AS 
SELECT * FROM SARA.TAFLIGHTSSG70
;

ALTER TABLE TAFLIGHTS_TEMP2 
ADD (CLUBNAME varchar(50) 
);
 
UPDATE TAFLIGHTS_TEMP1 SET CLUBNAME='SG_70';

--We merge all the flights from the existing flight tables into one,
-- for ease of handling and clearer data queries
CREATE TABLE TAFLIGHTS_ALL 
AS
SELECT * FROM TAFLIGHTS_TEMP1 
UNION 
SELECT * FROM TAFLIGHTS_TEMP2
;

CREATE TABLE TAFLIGHTS_YESTERDAY
AS
SELECT * FROM TAFLIGHTS_ALL 
WHERE 1=0; --This is used to create an empty 'container table'

--We create a table to store all the invalid flights, in case we might need to use them in future analysis
CREATE TABLE TAFLIGHTS_INVALID
AS 
SELECT * FROM TAFLIGHTS_ALL
WHERE 1=0
;

----------------------------------------------------------------------------
--We start off by setting the right/agreed upon format of the date 
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS';

--A bit of cleaning up of the tables that are not going to be used anymore on that day
DROP TABLE TAFLIGHTS_TEMP1;
DROP TABLE TAFLIGHTS_TEMP2;
DROP TABLE TAFLIGHTS_ALL;

--Create the tables with all the information from the current day from the two clubs
--We create a temporary table with the flights from vejle and add a new column with the club name
CREATE TABLE TAFLIGHTS_TEMP1 
AS 
SELECT * FROM SARA.TAFLIGHTSVEJLE
;

ALTER TABLE TAFLIGHTS_TEMP1 
ADD (CLUBNAME varchar(50) 
);
 
UPDATE TAFLIGHTS_TEMP1 SET CLUBNAME='Vejle';

--We do the same now with the flights from the other club
CREATE TABLE TAFLIGHTS_TEMP2 
AS 
SELECT * FROM SARA.TAFLIGHTSSG70
;

ALTER TABLE TAFLIGHTS_TEMP2 
ADD (CLUBNAME varchar(50) 
);
 
UPDATE TAFLIGHTS_TEMP1 SET CLUBNAME='SG_70';

--We merge all the flights from the existing flight tables into one,
-- for ease of handling and clearer data queries
CREATE TABLE TAFLIGHTS_ALL 
AS
SELECT * FROM TAFLIGHTS_TEMP1 
UNION 
SELECT * FROM TAFLIGHTS_TEMP2
;


--We check which new flights did we have today and store them in a separate table
DROP TABLE TAFLIGHTS_NEW;

CREATE TABLE TAFLIGHTS_NEW 
AS
SELECT * FROM TAFLIGHTS_ALL
MINUS
SELECT * FROM TAFLIGHTS_YESTERDAY
;

--Validation of the data 
    
    --we check all the new flights for validity
    BEGIN

        FOR record IN 
        (SELECT * FROM TAFLIGHTS_NEW)
        
        LOOP
            --We check if the launch/ landing time are valid  
            IF (record.LAUNCHTIME > CURRENT_DATE OR 
                record.LANDINGTIME > CURRENT_DATE OR 
                record.LANDINGTIME <= record.LAUNCHTIME) 
            THEN 
            INSERT INTO TAFLIGHTS_INVALID VALUES record; 
            END IF;    

            --Because all records are done after 2014, we can validate the flight accordingly
            IF (EXTRACT(YEAR FROM record.LAUNCHTIME) < 2014) OR
                (EXTRACT(YEAR FROM record.LANDINGTIME) < 2014)
            THEN 
            INSERT INTO TAFLIGHTS_INVALID VALUES record; 
            END IF; 

            --We check the length of the planeregistration and launchtypes
            IF (LENGTH(record.PLANEREGISTRATION) <> 3)
            THEN 
            INSERT INTO TAFLIGHTS_INVALID VALUES record;
            END IF;

            --We check the length of the pilots initials
            IF (LENGTH(record.PILOT1INIT) <> 4) OR 
                (LENGTH(record.PILOT2INIT) <> 4) 
            then
            INSERT INTO TAFLIGHTS_INVALID VALUES record;
            END IF; 
            
            --We check if the pilots have the same initials
            UPDATE TAFLIGHTS_NEW 
            SET PILOT2INIT = NULL 
            WHERE (record.PILOT2INIT <> NULL AND 
                   record.PILOT1INIT = record.PILOT2INIT);
            
            --We check the length of the launch method
            IF(LENGTH(record.LAUNCHAEROTOW) <> 1) OR 
              (LENGTH(record.LAUNCHWINCH) <> 1) OR
              (LENGTH(record.LAUNCHSELFLAUNCH) <> 1) OR
              (LENGTH(record.CABLEBREAK) <> 1)
            THEN
            INSERT INTO TAFLIGHTS_INVALID VALUES record;
            END IF; 

            --We check the amount of km flown 
            --We chose to limit the max amount of km to 999, 
            --even though the data type for this attribute is NUMBER(4,0)
            --because probably one flight can not cover a longer distance than 999km
            IF (record.CROSSCOUNTRYKM < 0 OR
                record.CROSSCOUNTRYKM > 999 )
            THEN
            INSERT INTO TAFLIGHTS_INVALID VALUES record;
            END IF; 

        END LOOP; 
        
    
        
        --We need to remove all the invalid flights from the TAFLIGHTS_NEW table
        --and create a table that will hold the valid flights from today

        
    COMMIT;
    END;
/

-- TAKE THE INVALID ROWS 
 CREATE TABLE TAFLIGHTS_VALID 
        AS 
        SELECT * FROM TAFLIGHTS_NEW
        MINUS
        SELECT * FROM TAFLIGHTS_INVALID;

--We need to create the table that will hold the transformed flights
DROP TABLE TAFLIGHTS_TRANSFORMED; 

CREATE TABLE TAFLIGHTS_TRANSFORMED(
  LAUNCHTIME	DATE,
  LANDINGTIME	DATE,
  PLANEREGISTRATION	CHAR(5),
  PILOT1INIT	CHAR(4),
  PILOT2INIT	CHAR(4),
  launch_method VARCHAR2(50),
  CABLEBREAK	VARCHAR2(3),
  CROSSCOUNTRYKM	NUMBER(4,0),
  clubname VARCHAR2(50),
  duration NUMBER
);

--COPY THE VALIDATED DATA INTO THE TRANSFORMED TABLE   
INSERT INTO TAFLIGHTS_TRANSFORMED 
(
  SELECT Launchtime as Launchtime,
          LandingTime as LandingTime,
              (SELECT 'OY' || PLANEREGISTRATION FROM DUAL) as PLANEREGISTRATION,
              PILOT1INIT as PILOT1INIT,
              PILOT2INIT as PILOT2INIT,
              case (LAUNCHAEROTOW || LAUNCHWINCH || LAUNCHSELFLAUNCH) 
                when 'YNN' then 'LAUNCHAEROTOW'
                when 'NYN' then 'LAUNCHWINCH'
                when 'NNY' then 'LAUNCHSELFLAUNCH'
              end AS launch_method,
              case CABLEBREAK
                  when 'Y' then 'yes'
                  when 'N' then 'no'
                end as CABLEBREAK,
            CROSSCOUNTRYKM AS CROSSCOUNTRYKM,
              clubname AS CLUBNAME, 
        extract(minute from (LANDINGTIME - LAUNCHTIME) day to second) as duration
      FROM TAFLIGHTS_VALID
);

--DECLARE THE VALUES WE WILL USE IN THE LOOPS
DECLARE
  Member1ID number;
  Member2ID number;
  TimeID D_dateTime.dateTimeID%TYPE;
  plane_id number;
  weight number;
  club_id number;
  LAUNCH_METH_ID NUMBER;
  
  
BEGIN
  FOR ROW IN (select * from TAFLIGHTS_TRANSFORMED)
  LOOP
   BEGIN
   --dimension plane for testing, since we didn't populate all the dimensions for flights we will just populate plane for testing
            SELECT PLANEID INTO PLANE_ID FROM D_PLANE
            WHERE REGISTRATION_NO = ROW.PLANEREGISTRATION;
           EXCEPTION
          WHEN NO_DATA_FOUND THEN
         select planeid into plane_id from d_plane where registration_no ='-1';
        END;
		
		BEGIN
            SELECT clubid INTO club_id FROM d_club
            WHERE name = row.clubname FETCH First 1 rows only;
			EXCEPTION
          WHEN NO_DATA_FOUND THEN
         select clubid into club_id from d_club where NAME ='-1-1';
           
        END;
		
		begin
      select launchmethid into launch_meth_id from d_launch_method 
        where name = row.LAUNCH_METHOD and cablebreak = row.cablebreak;
		--we havent populated the d_launch_method so we just inserted a fake one manually
          EXCEPTION
        When NO_DATA_FOUND THEN 
          select launchmethid into launch_meth_id from d_launch_method where name='-1-1';
      end;
	  
        
      SELECT dateTimeID INTO TimeID  FROM D_DateTime WHERE D_DateTime.dateTime=to_date(ROUND(ROW.LaunchTime, 'MI')); 
      IF ROW.PILOT2INIT IS NOT NULL THEN 
      --IF THERE ARE TWO PILOTS
        BEGIN
        --SEARCH THE MEMBER ID IN THE MEMEBER DIMENSION WITH THE SAME INITIALS 
          SELECT memberid INTO Member1ID  FROM D_Member WHERE D_Member.initials=ROW.PILOT1INIT FETCH First 1 rows only; /* it would take the first, not the one which was active when the flight was made */
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
         select memberid into member1id from d_member where initials='-1-1' FETCH First 1 rows only;
         END;
         --SEARCH FOR THE MEMBER 2 WITH THE SAME INITIALS
         BEGIN
          SELECT memberId INTO Member2ID  FROM D_Member WHERE initials=ROW.PILOT2INIT FETCH First 1 rows only; 
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
         select memberid into member2id from d_member where initials='-1-2' FETCH First 1 rows only;
         end;
         BEGIN
           --insert all the transformed and validated values to the bridge table
          INSERT INTO b_team(teamid, memberid, weight) VALUES(sq_bridgeta.nextval, member1id, 0.5 ); 
          INSERT INTO b_team(teamid, memberid, weight) VALUES(sq_bridgeta.nextval, member2id, 0.5 );
        END;
      ELSE
      --if there IS only one pilot
        BEGIN
        --SEARCH THE MEMBER ID IN THE MEMEBER DIMENSION WITH THE SAME INITIALS 
          SELECT memberid INTO member1id  FROM D_member WHERE initials=ROW.PILOT1INIT;
          EXCEPTION
        WHEN NO_DATA_FOUND THEN
		--IF NO MEMBER WAS FOUND MATCH THE BRIDGE TABLE WITH A FAKE MEMBER 
         select memberid into member1id from d_member where initials='-1';
          INSERT INTO b_team(teamid, memberid, weight) VALUES(sq_bridgeta.NEXTVAL, member1id, 1 );
        
        END;
      END IF;
      INSERT INTO F_Flight(PLANE_ID,  dateTimeID, launch_meth_id, club_id, team_Id, duration) values(PLANE_ID, TimeID, launch_meth_id ,club_id, sq_bridgeta.CURRVAL, ROW.DURATION);
    END LOOP;
    COMMIT;
END;

    
        
        