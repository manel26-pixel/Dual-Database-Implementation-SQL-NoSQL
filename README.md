# Dual-Database-Implementation-SQL-NoSQL
This repository showcases the implementation of a database use case using both relational (SQL) and non-relational (NoSQL) approaches. 

## 📁 Content Overview


Here's a clean, short `README.md` style entry based on the script you shared — summarizing **TP6** and the new **Operations & Loans Insertion + Queries** script.

---

## MongoDB_QUERY

### Title: Advanced Object-Relational Features in Oracle SQL

This lab focuses on object-relational modeling and manipulation using Oracle SQL, covering:

* Creation and manipulation of **object types**, **nested tables**, and **REFs**
* Use of **custom data types** like `toperation` and `tpret`
* Establishing **1\:N** and **1:1** object relationships between accounts, operations, and loans
* Populating accounts with sample **banking operations** (credit/debit)
* Inserting **loan contracts (prêts)** and linking them to the accounts via object references
* Using **`INSERT INTO TABLE (SELECT nested_table_column FROM ...)`** to populate nested tables
* Executing **complex queries** involving navigation through object references (e.g. `p.Num_cmpt.Num_Ag.Num_Ag`)
* Filtering by attributes such as agency, client type, or year using SQL functions like `EXTRACT(YEAR FROM date)`

---

## SQL_QUERY

### Title: Banking Operations and Loans: Bulk Insertions and Object-Nested Queries

This script enhances the object-relational database with:

* Bulk **insertion of operations** (30+ debit/credit transactions) using object constructors
* Association of each `operation` with its corresponding `compte` through object `REF`s and nested tables
* Insertion of multiple **loan contracts (`pret`)**, associated with bank accounts across different agencies and clients
* Queries that:

  * List accounts by agency and client type
  * Retrieve loans by branch/succursale
  * Calculate total credited amounts for a given year and account
  * Display full object-navigation from `pret` to `client` via `compte`

---

## 👩‍💻 Authors

* **Ferchichi Manel**
* **Hadjimi Lilia**
  
---

## 🛠️ Technologies Used 

* **Oracle SQL**
* **PL/SQL**
* **Object Types & Nested Tables**
* **REF Datatypes**
* **Object Constructors (e.g., `toperation(...)`)**
* **Advanced SQL Queries** using object attribute navigation
* **SQL Developer or SQL\*Plus** for execution and testing

