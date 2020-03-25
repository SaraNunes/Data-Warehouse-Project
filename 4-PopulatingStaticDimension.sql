
--Populate the Date time dimension

--Declaring variables and initialize them
--to use in the begin-end procedure
--to populate all the dates once

--currentDate and endDate will be the interval of times
--intervals gotten from the queries:


CREATE OR REPLACE PROCEDURE insertDates
(
  StartDate D_DateTime.dateTime%TYPE,
  EndDate D_DateTime.dateTime%TYPE 
)
AS
  currentDate Date;
BEGIN
  currentDate := StartDate;
  WHILE currentDate <= EndDate
  LOOP
      INSERT INTO D_DateTime(DateTimeId, DATETIME, DAYNAME, DAYOFWEEK, DAYOFMONTH, DAYOFYEAR, WEEKOFYEAR, MONTHNAME, MONTHOFYEAR, QUARTEROFYEAR, YEARNUMBER, HOUROFDAY, MINUTEOFDAY)
      SELECT
              dateTime_seq.NEXTVAL as DateTimeId, 
              currentDate AS dateTime,
              TO_CHAR(currentDate,'Day','NLS_DATE_LANGUAGE=ENGLISH') as dayName,
              to_number(TO_CHAR(currentDate,'D')) AS dayOfWeek,
              to_number(TO_CHAR(currentDate,'DD')) AS dayOfMonth,
              to_number(TO_CHAR(currentDate,'DDD')) AS dayOfYear,
              to_number(TO_CHAR(currentDate+1,'IW')) AS weekOfYear,
              TO_CHAR(currentDate,'Month') AS monthName,
              to_number(TO_CHAR(currentDate,'MM')) AS monthOfYear,
              to_number((TO_CHAR(currentDate,'Q'))) AS quarterOfYear,
              to_number(TO_CHAR(currentDate,'YYYY')) AS yearNumber,
              to_number(TO_CHAR(currentDate,'HH24')) AS hourOfDay,
              to_number(TO_CHAR(currentDate,'MI')) AS minuteOfDay
      FROM DUAL;
      currentDate := currentDate + to_dsInterval('00 00:01:00');
  END LOOP;
END;
/

BEGIN
 insertDates(TO_DATE('01/01/2014 00:00','DD/MM/YYYY HH24:MI'), TO_DATE('01/01/2018 00:00','DD/MM/YYYY HH24:MI'));
END;
/