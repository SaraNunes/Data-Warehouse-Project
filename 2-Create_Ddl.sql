/* D_DateTime */

drop table D_DateTime;
drop sequence dateTime_seq;

CREATE SEQUENCE dateTime_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE D_DateTime(
					dateTimeID Integer NOT NULL,
					dateTime Date NOT NULL,
					dayName Char(10),
					dayOfWeek Integer,
					dayOfMonth Integer,
					dayOfYear Integer,
					weekOfYear Integer,
					monthName Char(10),
					monthOfYear Integer,
					quarterOfYear Integer,
					yearNumber Integer,
                    hourOfDay Integer,
                    minuteOfDay Integer,
                    CONSTRAINT PkDateTime_D
                    PRIMARY KEY (dateTimeID)
					);


-- create dim table

DROP TABLE D_Member;
drop sequence sq_member;

CREATE SEQUENCE sq_member START WITH 1 INCREMENT BY 1;
CREATE TABLE D_Member
(
  memberId NUMBER(6,0) CONSTRAINT memberPK PRIMARY KEY,
  memberNo NUMBER,
  initials char(4),
  "NAME" varchar2(50),
  address varchar2(50),
  zipCode number (4,0),
  age NUMBER(2,0),
  status VARCHAR2(50),
  validFrom date,
  validTo date,
  gender VARCHAR(20),
  club VARCHAR2(50)
);

DROP TABLE f_flight;
drop sequence sq_flight;

CREATE SEQUENCE sq_flight START WITH 1 INCREMENT BY 1;

CREATE TABLE f_flight
(
  plane_id CHAR(10) REFERENCES d_plane(planeId),
    datetimeid NUMBER REFERENCES d_datetime(dateTimeId),
    launch_meth_id NUMBER NOT NULL REFERENCES d_launch_method(launchMethId),
    club_id VARCHAR2(15) NOT NULL REFERENCES d_club(cludId),
  team_id NUMBER NOT NULL REFERENCES b_team(teamId),
  duration NUMBER NOT NULL);
  CONSTRAINT fFlightPK PRIMARY KEY (launch_meth_id,plane_id,club_id,team_id, datetimeid)
    );
    
drop table b_team;
drop sequence sq_bridgeta;

CREATE SEQUENCE sq_bridgeta START WITH 1 INCREMENT BY 1;
CREATE TABLE b_team
(
      teamId     NUMBER NOT NULL,
      memberId     NUMBER REFERENCES d_member(memberId),
	  weight      NUMBER NOT NULL constraint coCheckWeight CHECK (weight IN (1, 0.5)),
      CONSTRAINT bridge_mfPK PRIMARY KEY (teamId, memberId)
    );

-- club
	DROP TABLE d_club;
  DROP sequence sq_club;
  
  CREATE SEQUENCE sq_club START WITH 1 INCREMENT BY 1;
  CREATE TABLE d_club
    (
      clubId          NUMBER NOT NULL CONSTRAINT dClubPK PRIMARY KEY,
      name VARCHAR2(50) NOT NULL,
	  region_name VARCHAR2(50),
      address     VARCHAR2(50) NOT NULL,
      zip_code    INTEGER NOT NULL,
      valid_from  DATE NOT NULL,
      valid_to    DATE NOT NULL
    );
    
drop SEQUENCE sq_membership  ;
  drop TABLE f_membership ;
 
 CREATE SEQUENCE sq_membership START WITH 1 INCREMENT BY 1;
 
  CREATE TABLE f_membership
    (
      club_id    NUMBER NOT NULL REFERENCES d_club(clubId),
      member_id  NUMBER NOT NULL REFERENCES d_member(memberId),
      leave_date NUMBER REFERENCES d_DateTime(dateTimeId),
      join_date  NUMBER NOT NULL REFERENCES d_DateTime(dateTimeId),
      CONSTRAINT dMembershipPK PRIMARY KEY (club_id,member_id, leave_date, join_date)
    );
    
    
drop SEQUENCE sq_launch_method;
drop TABLE d_launch_method;

CREATE SEQUENCE sq_launch_method START WITH 1 INCREMENT BY 1;

CREATE TABLE d_launch_method
     (
      launchMethId         NUMBER NOT NULL CONSTRAINT launchMethodPK PRIMARY KEY,
      name       VARCHAR2(20) NOT NULL,
      cablebreak CHAR(1) DEFAULT 'N' NOT NULL CONSTRAINT ch_break CHECK(cablebreak IN ('Y','N'))
    );
    
drop table d_plane;
drop sequence sq_plane;
 
 CREATE SEQUENCE sq_plane START WITH 1 INCREMENT BY 1;
 CREATE TABLE d_plane( 
	planeId NUMBER NOT NULL CONSTRAINT planeId PRIMARY KEY,
    registration_no      VARCHAR2(10) NOT NULL,     
    competition_number  VARCHAR2(10) NOT NULL,
    valid_from          DATE NOT NULL,
    valid_to            DATE NOT NULL
    );

ALTER TABLE D_MEMBER MODIFY age NUMBER(4,0);
