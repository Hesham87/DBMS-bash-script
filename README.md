# DBMS-using-bash-script
# Project README

## Features

### Create Table
- You can create a table with the following data types:
  - `int`
  - `char`
  - `date`
- You can add constraints to columns, such as:
  - `primary_key`
  - `not_null`
  - `unique`
- **Warning**: A warning will be issued if no primary key is selected, but the table will still be created.

#### Example:
```sql
create table employees(
    id int(100) primary_key,
    name char(100) not_null,
    birth_date date,
    ssn int(100) unique,
    salary int(100000)
);
```

### Select from Table
- You can select columns from a table and apply arithmetic operations on them.
- You can also execute arithmetic expressions without specifying a table.
- **Note**: You can only select from one table at a time (joins are not implemented yet).
- **Note**: Any string or date must be placed between double quotes "".

**Important:** Avoid inserting placing a null ("") in the where clause as this will not show any data.
**Important:** Arithmatic operations on a field containing null. will treat null as a 0. This issue will be solved soon.
**Important:** If a string field has only the word "False" case sensitive with no spaces before or after it will result in it not being show in the output of the select statement. This issue will be solved soon.

#### Examples:
```sql
select * from employees where salary > 5000 and birth_date > "1993-05-11";

select salary*1.2 from employees where salary*1.2 < (salary + 400);

select id, birth_date from employees;

select 5*90, 100/2;

select id from employees where name="Hesham";
```
- **Note**: Strings and dates must be enclosed in double quotes (`"`).

### Update Table
- You can update rows in a table.

#### Example:
```sql
update employees set salary = salary*1.2 where birth_date > "1996-05-11";
```

### Insert into Table
- You can insert values into a table.
- **Note**: The attributes being inserted must be specified after the table name.

#### Example:
```sql
insert into employees(id, name) values(29, "Hesham");
```

### Drop
- You can drop tables and databases.

#### Examples:
```sql
drop database work;

drop table employees;
```

### Show
- You can view tables and databases.

#### Examples:
```sql
SHOW database;

SHOW table;
```

### Delete
- You can delete rows from a table.

#### Example:
```sql
delete from employees where salary*2 > (salary + 700);
```

