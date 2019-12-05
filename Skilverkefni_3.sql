use ProgressTracker_V6;
/*
1:
	Skrifið stored procedure: StudentListJSon() sem notar cursor til að breyta vensluðum gögnum í JSon string.
	JSon-formuð gögnin eru listi af objectum.
	OBS: StudentListJSon skilar texta sem þið hafið formað.

	Niðurstöðurnar ættu að líta einhvern vegin svona út:

	[
		  {"first_name": "Guðrún", "last_name": "Ólafsdóttir", "date_of_birth": "1999-03-31"},
		  {"first_name": "Andri Freyr", "last_name": "Kjartansson", "date_of_birth": "2000-11-01"},
		  {"first_name": "Tinna Líf", "last_name": "Björnsson", "date_of_birth": "1998-08-14"},
		  {"first_name": "Magni Þór", "last_name": "Sigurðsson", "date_of_birth": "2000-05-27"},
		  {"first_name": "Rheza Már", "last_name": "Hamid-Davíðs", "date_of_birth": "2001-09-17"},
		  {"first_name": "Hadría Gná", "last_name": "Schmidt", "date_of_birth": "1999-07-29"},
		  {"first_name": "Jasmín Rós", "last_name": "Stefánsdóttir", "date_of_birth": "1996-02-29"}
	]
*/

drop procedure if exists StudentListJSon;
delimiter $$
create procedure StudentListJSon()
begin
	declare first_name varchar(55);
    declare last_name varchar(55);
	declare date_of_birth date;
    declare student_json text;
	declare done int default false;
	declare ACursor cursor 
		for select firstName,lastName, dob from Students;
	declare continue handler for not found set done = true;
    set student_json = '[';
	open ACursor;
	read_loop: loop
		fetch ACursor into first_name,last_name,date_of_birth;
		if done then
		  leave read_loop;
		end if;
		set student_json = concat(student_json,'{"first_name" : "',first_name,'", "last_name" : "',
								  last_name,'", "date_of_birth" : "',date_of_birth,'"},');
	end loop;
    select trim(trailing ',' from student_json) into student_json;
	set student_json = concat(student_json,']');
	close ACursor;
    select student_json;
END $$
delimiter ;
-- call StudentListJSon();


/*
	2:
	Skrifið nú SingleStudentJSon()þannig að nemandinn innihaldi nú lista af þeim áföngum sem hann hefur tekið.
	Śé nemandinn enn við nám þá koma þeir áfangar líka með.
	ATH: setjið nemandann sem object.
	Líkleg niðurstaða:

	{
		"student_id": "1",
		"first_name": "Guðrún",
		"last_name": "Ólafsdóttir",
		"date_of_birth": "1999-03-31",
		"courses" :[
		  {"course_number": "STÆ103","course_credits": "5","status": "pass"},
		  {"course_number": "EÐL103","course_credits": "5","status": "pass"},
		  {"course_number": "STÆ203","course_credits": "5","status": "pass"},
		  {"course_number": "EÐL203","course_credits": "5","status": "pass"},
		  {"course_number": "STÆ303","course_credits": "5","status": "pass"},
		  {"course_number": "GSF2A3U","course_credits": "5","status": "pass"},
		  {"course_number": "FOR3G3U","course_credits": "5","status": "pass"},
		  {"course_number": "GSF2B3U","course_credits": "5","status": "pass"},
		  {"course_number": "GSF3B3U","course_credits": "5","status": "fail"},
		  {"course_number": "FOR3D3U","course_credits": "5","status": "fail"}
		]
	}
*/


drop procedure if exists SingleStudentJSon;
delimiter $$

create procedure SingleStudentJSon(varStudentID int)
begin
	declare student_id int;
	declare first_name varchar(55);
    declare last_name varchar(55);
	declare date_of_birth date;
    declare the_student text;
    declare course_number char(10);
    declare course_credits tinyint(4);
    declare student_passed tinyint(1);
    
	declare done int default false;
	declare BCursor cursor 
		for select courses.courseNumber,courses.courseCredits,registration.passed
			from courses join registration join students
			where registration.coursenumber = courses.coursenumber
            and students.studentid = registration.studentid
            and students.studentID = varStudentID;
	declare continue handler for not found set done = true;

    select students.studentID,students.firstName,students.lastName,students.dob into student_ID,first_name,last_name,date_of_birth from students where students.studentID = varStudentID;
    
	set the_student = '{';
    set the_student = concat(the_student,'"student_id" : "',student_id,'", "first_name" : "',first_name,
							 '", "last_name" : "',last_name,'", "date_of_birth" : "',date_of_birth,'",');
    set the_student = concat(the_student,'"courses" : [');
	
    open BCursor;
	read_loop: loop
		fetch BCursor into course_number,course_credits,student_passed;
		if done then
		  leave read_loop;
		end if;
		set the_student = concat(the_student,'{"course_number": "',course_number,'",',
										     '"course_credits": "',course_credits,'",',
                                             '"student_passed": "',student_passed,'"},');
	end loop;

	select trim(trailing ',' from the_student) into the_student;
	set the_student = concat(the_student,']}');
    
	close BCursor;
    
    select the_student;
end $$
delimiter ;
-- call SingleStudentJSon(1);


/*
	3:
	Skrifið stored procedure: SemesterInfoJSon() sem birtir uplýsingar um ákveðið semester.
	Semestrið inniheldur lista af nemendum sem eru /hafa verið á þessu semestri.
	Og að sjálfsögðu eru gögnin á JSon formi!

	Gæti litið út einhvern veginn svona(hérna var semesterID 8 notað á original gögnin:
	[
		{"student_id": "1", "first_name": "Guðrún", "last_name": "Ólafsdóttir", "courses_taken": "2"},
		{"student_id": "2", "first_name": "Andri Freyr", "last_name": "Kjartansson", "courses_taken": "1"},
		{"student_id": "5", "first_name": "Rheza Már", "last_name": "Hamid-Davíðs", "courses_taken": "2"},
		{"student_id": "6", "first_name": "Hadríra Gná", "last_name": "Schmidt", "courses_taken": "2"}
	]
*/


drop procedure if exists SemesterInfoJSon;
delimiter $$
create procedure SemesterInfoJSon(varSemesterID int)
begin
	declare student_id int(11);
	declare first_name varchar(55);
    declare last_name varchar(55);
    declare courses_taken int;
    declare student_json text;
	declare done int default false;
	declare ACursor cursor 
		for select distinct Students.studentID,Students.firstName,Students.lastName,
        count(registration.courseNumber)
        from semesters join registration join Students
        where students.studentID = registration.studentID
        and semesters.semesterID = registration.semesterID
        and semesters.semesterID = varSemesterID
        group by students.studentID;
	declare continue handler for not found set done = true;
    set student_json = '[';
	open ACursor;
	read_loop: loop
		fetch ACursor into student_id,first_name,last_name,courses_taken;
		if done then
		  leave read_loop;
		end if;
		set student_json = concat(student_json,'{"student_id" : "',student_id,'", "first_name" : "',first_name,'", "last_name" : "',
								  last_name,'", "courses_taken" : "',courses_taken,'"},');
	end loop;
    select trim(trailing ',' from student_json) into student_json;
	set student_json = concat(student_json,']');
	close ACursor;
    select student_json;
END $$
delimiter ;
-- call SemesterInfoJSon(10);


-- ACHTUNG:  2 og 3 nota líka cursor!