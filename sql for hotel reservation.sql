
CREATE DATABASE HOTE;
USE HOTE;
create table guest (
  guest_id int IDENTITY(1,1) primary key,
  guest_name varchar(30),
  guest_address varchar(50),
  phone_number varchar(20)
  );
  
create table reservation(
reserve_id int primary key,
guest_id int,
Checkin Date,
Checkout Date,
cost varchar(20),
no_guest int,

foreign key(guest_id) references guest
);
create table payment(
pay_no int primary key,
total int,
pay_method varchar(40),
statu varchar(40),
guest_id int,
foreign key(guest_id) references guest
);
create table roomm(
rno int ,
rtype varchar(50),
price varchar(20),
avail varchar(50),
guest_id int,
primary key (rno),
foreign key(guest_id) references guest
);
create table servic(
ser_id int IDENTITY(100,1) primary key,
ser_name varchar(50),
ser_price int,

);

create table ordr(
guest_id int,
ser_id int,
add_charge varchar(20),
foreign key (guest_id) references guest,
foreign key (ser_id) references servic,
primary key(guest_id,ser_id)
);

--samples for creating--
INSERT INTO guest ( guest_name, guest_address ,phone_number )
VALUES ( 'abel', 'addis', '1234567'),
       ('kebe', 'adama', '89101112'),
       ( 'tom', 'bishoftu', '7654321');
	
INSERT INTO reservation (reserve_id,Checkin ,Checkout ,t_payment ,no_guest , guest_id )
VALUES (101, '10-03-2016', '10-10-2016', '100.00', 20,1),
       (102, '10-04-2016', '10-09-2016', '150.00', 20,2),
       (103, '10-05-2016', '10-13-2016', '120.00', 20,3);

INSERT INTO roomm (rno ,rtype ,price ,avail ,guest_id )
VALUES (1004, '1bedroom', '200', 'available',null),
       (1005, '2bedroom', '300', 'occupied', null),
       (1006, 'familyroom', '400', 'available', null);
insert into servic (ser_id ,ser_name ,ser_price) 
values (901,'foodA',50),
       (902,'foodB',70),
	   (903,'coca',40);


--*****************manager views*******************************
CREATE VIEW guest_reservation_view AS
SELECT g.guest_name, r.rtype, res.Checkin, res.Checkout, res.cost
FROM guest g
JOIN reservation res ON g.guest_id = res.guest_id
JOIN roomm r ON r.guest_id = g.guest_id;
SELECT * FROM guest_reservation_view;


--*****************procedure for manager *******************************

CREATE PROCEDURE GetGuestServiceData
AS
BEGIN
    SET NOCOUNT ON;

    SELECT g.guest_name, s.ser_name, s.ser_price
    FROM guest g
    JOIN ordr o ON g.guest_id = o.guest_id
    JOIN servic s ON s.ser_id = o.ser_id;
END;
EXEC GetGuestServiceData;

--*****************user views*******************************

create view availabilityy as 
 select rno,rtype,price from roomm
where avail='available';
select * from availabilityy



--************************  Transactions  ***************************************

--for customer booking(reservation) 
begin transaction;
INSERT INTO guest ( guest_name, guest_address ,phone_number )
VALUES ('bel', 'addis', '4434567');
DECLARE @guest_id INT;
SET @guest_id = (
  SELECT ISNULL(MAX(guest_id), 0) 
  FROM guest
);
DECLARE @room_id INT;
SET @room_id = (
  SELECT TOP 1 rno
  FROM roomm
  WHERE avail = 'available'
  ORDER BY rno
);


if @room_id is Null
begin
   rollback;
   select 'their is no room ' as result;
   return;
end
DECLARE @reservation_id INT;
SET @reservation_id = (
  SELECT ISNULL(MAX(reserve_id), 0) + 1
  FROM reservation
);
declare @no_guest int;
set @no_guest =(select count(*) from reservation)+1

INSERT INTO reservation (reserve_id, guest_id, Checkin ,Checkout ,cost ,no_guest )
VALUES (@reservation_id,@guest_id,GETDATE(), '2023-09-24',null,@no_guest);
declare @chin date;
set @chin =getdate()
declare @chout date;
set @chout =(select checkout from reservation where reserve_id=@reservation_id)
declare @diff int;
set @diff =(SELECT DATEDIFF(day, @chout, @chin))
declare @totalpay int;
set @totalpay = (
select price from roomm where rno=@room_id)*@diff;

update reservation set cost=@totalpay where reserve_id=@reservation_id;

UPDATE roomm
SET avail = 'OCCUPIED',guest_id=@guest_id
WHERE rno = @room_id;
commit;

--for ordering drinks and food--
begin transaction;
INSERT INTO ordr (guest_id, ser_id, add_charge)
VALUES (2, 901, 50);
declare @gue_id int;
SET @gue_id = (
  SELECT ISNULL(MAX(guest_id), 0) 
  FROM ordr
);
declare @ser_id int;
SET @ser_id = (
  SELECT ISNULL(MAX(ser_id), 0) 
  FROM ordr
);
declare @charge_id int;
SET @charge_id = (select add_charge from ordr where guest_id=@gue_id and ser_id=@ser_id);

update reservation
set cost = cost + @charge_id
where guest_id = @gue_id;
commit;

--to extend checkout dates for user
begin transaction;
update reservation set checkout='2016-12-3' where guest_id=2;
commit;

--for making payment--
begin transaction;
DECLARE @payy_no INT;
SET @payy_no = (
  SELECT ISNULL(MAX(pay_no), 0) + 1
  FROM payment
);
insert into payment (pay_no,total,pay_method,statu,guest_id)
values (@payy_no,500,'cash','unfinished',2);
declare @gest_id int;
set @gest_id=(select guest_id from payment where pay_no=@payy_no)
declare @tot int;
set @tot =(select cost from reservation where guest_id=@gest_id);
declare @tot2 int;
set @tot2 =(select total from payment where pay_no=@payy_no)
declare @tprice int;
set @tprice = @tot-@tot2
update reservation set cost = @tprice where guest_id=@gest_id;
if @tprice>= 0
 begin
     update payment set statu='finished' where guest_id=2; 
	 return;
end

commit;

--for checkout(leave)--
begin transaction ;
declare @gust_id int;
set @gust_id =2
declare @romno int;
declare @stats varchar(30);
set @stats =(select statu from payment where guest_id=@gust_id)
if @stats ='unfinished'
 begin
  rollback;
  select 'first finish your payments' as result
  return;
 end
set @romno =(select rno from roomm where guest_id=@gust_id)
update roomm set guest_id=null,
                avail='available' where rno=@romno;
delete from ordr where guest_id=@gust_id;
delete from payment  where guest_id=@gust_id;
delete from reservation  where guest_id=@gust_id;
delete from guest  where guest_id=@gust_id;
commit;


 ----------------permissions, roles, and logins for manager, employee, and customer:---------------------
 -- Create a login for the hotel manager
CREATE LOGIN k WITH PASSWORD = '123';

-- Create a login for the hotel employee
CREATE LOGIN a WITH PASSWORD = '456';

-- Create a login for the customer
CREATE LOGIN  j WITH PASSWORD = '789';

CREATE USER k for login k;
CREATE USER a for login a;
CREATE USER j for login j;

----------------------------Create Users and Assign Roles:--------------
-- Create the role
CREATE ROLE ManagerRole; -- 1st step 
CREATE ROLE CustomerRole;
-- Create users
create role customer;
sp_addrolemember 'customer',k;
sp_addrolemember 'customer',a;
sp_addrolemember 'customer',j;

-------------------------------Grant Permissions for Manager:----------
-- Grant permissions to the guest table
GRANT SELECT, INSERT, UPDATE, DELETE ON guest TO ManagerRole;

-- Grant permissions to the room table
GRANT SELECT, INSERT, UPDATE, DELETE ON room TO ManagerRole;

-- Grant permissions to the servic table
GRANT SELECT, INSERT, UPDATE, DELETE ON servic TO ManagerRole;

-- Grant permissions to the payment table
GRANT SELECT, INSERT, UPDATE, DELETE ON payment TO ManagerRole;

-- Grant permissions to the Reservation table
GRANT SELECT, INSERT, UPDATE, DELETE ON reservation TO ManagerRole;

-- Grant permissions to the ordr table
GRANT SELECT, INSERT, UPDATE, DELETE ON ordr TO ManagerRole;


-------------------------------------Grant Permissions for Customer:--------------------------------
-- Grant permissions to the Guest table
GRANT SELECT, INSERT, UPDATE ON guest TO CustomerRole;

-- Grant permissions to the Reservation table
GRANT SELECT, INSERT, UPDATE ON Reservation TO CustomerRole;

-- Grant permissions to the BestFoodDrink table
GRANT SELECT ON servic TO CustomerRole;

-- Grant permissions to the Order table
GRANT SELECT, INSERT ON ordr TO CustomerRole;

-- Grant permissions to the room table
GRANT SELECT ON room TO CustomerRole;


-- Assign roles to the users
ALTER ROLE ManagerRole ADD MEMBER kebe;
ALTER ROLE CustomerRole ADD MEMBER john;






