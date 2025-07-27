-- Création de SQL3_TBS
CREATE TABLESPACE SQL3_TBS
DATAFILE 'C:\TBS_SQL3.dat' SIZE 100M
AUTOEXTEND ON ONLINE;


-- Création de SQL3_TempTBS
CREATE TEMPORARY TABLESPACE SQL3_TempTBS
TEMPFILE 'C:\TempTBS_SQL3.dat' SIZE 100M
AUTOEXTEND ON;




-- Création de l'utilisateur SQL3
CREATE USER C##user_SQL3 IDENTIFIED BY project DEFAULT TABLESPACE SQL3_TBS TEMPORARY TABLESPACE SQL3_TempTBS;

-- Accorder tous les privilèges à l'utilisateur SQL3
GRANT ALL PRIVILEGES TO C##user_SQL3;

--creation de types abstraits
--le type Tnom
create type Tnom as object(
    nomf varchar(15),
    prenom varchar(20)
);
/


create type Tadresse as object(
    
    Num number,
    ville varchar(20),
    Rue varchar(20)
   
);
/


create type Tsuccursale as object(
      Num_succ number,
      Nom_succ varchar(20),
      addresse_succ Tadresse,
      Region varchar(20)
      
);
/

 create type Tagence as object(
     Num_Ag number,
     Nom_Ag varchar(20),
     adresse_Ag Tadresse,
     Num_succ ref Tsuccursale,
     Categorie varchar(20) 
 );
 /
create type t_set_ref_agences as table of ref Tagence;
/
alter type Tsuccursale add attribute agence_succursale t_set_ref_agences cascade;
/

create type Tcompte;
/

create type Tclient as object (
     Num_client number,
     Nom_client varchar(20),
     Type_client varchar(13),
     adresse_client Tadresse,
     Num_tel number,
     Email varchar(20),
     Num_cmpt ref Tcompte
          
);   
/ 



create or replace type Tcompte as object (
     Num_cmpt number,
     date_ouv DATE,
     Etat_compt varchar(10),
     Num_client ref Tclient,
     Num_Ag ref Tagence,
     Solde double precision
      );
/  
create type t_set_ref_compte as table of ref Tcompte;
/
Alter type Tagence add attribute agence_compte t_set_ref_compte cascade;
/


 
create type Toperation as object (
     Num_op number,
     Nature_op varchar(10),
     Date_op DATE,
     Montant_op double precision,
     Num_cmpt ref Tcompte,  
     Observation varchar(20)
);
/
create type T_set_ref_operations as table of ref Toperation;
/
/

ALTER TYPE Tcompte ADD ATTRIBUTE operation_compte T_set_ref_operations cascade;
/




create type Tpret as object (
    Num_pret number,
    Duree varchar(25),
    Date_efectuer DATE,
    Montant_pret double precision,
    Type_pret varchar(20),
    Taux_interet double precision,
    Num_cmpt ref Tcompte ,
    Montant_ech double precision

);
/

create type t_set_ref_pret as table of ref Tpret;
/
alter type Tcompte add attribute pret_compte t_set_ref_pret cascade;
/

--creation des tables 
create table Succursale of Tsuccursale (primary key (Num_succ), 
CONSTRAINT check_region CHECK (Region IN ('Nord', 'Sud', 'Est', 'Ouest')))
nested table agence_succursale store as table_ref_agances;

create table Agence of Tagence( primary key (Num_Ag),
 FOREIGN key(Num_succ) references Succursale,
 CONSTRAINT check_categorie CHECK (Categorie IN ('Principale', 'Secondaire')))
nested table  agence_compte store as table_ref_comptes;

create  table Client of Tclient(primary key (Num_client),CONSTRAINT check_type_client CHECK (Type_client IN ('Particulier', 'Entreprise')));


CREATE TABLE Compte OF Tcompte (
    PRIMARY KEY(Num_cmpt),
    FOREIGN KEY(Num_client) REFERENCES Client,
    FOREIGN KEY(Num_Ag) REFERENCES Agence,
    CONSTRAINT check_EtatCMPT CHECK (Etat_compt IN ('Actif', 'Bloquer')),
    CONSTRAINT check_Solde CHECK (Solde >= 0)
)
nested table operation_compte store as table_ref_operations,
nested table pret_compte store as table_ref_prets;

CREATE OR REPLACE TRIGGER check_date_ouverture
BEFORE INSERT OR UPDATE ON Compte
FOR EACH ROW
BEGIN
    IF :NEW.date_ouv < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'La date d''ouverture doit être postérieure ou égale à la date actuelle.');
    END IF;
END;
/


create table Operation of Toperation(primary key (Num_op), 
FOREIGN key(Num_cmpt) references Compte, CONSTRAINT check_NatureOp CHECK (Nature_op IN ('Credit', 'Debit')));



CREATE OR REPLACE TRIGGER check_date_operation
BEFORE INSERT ON Operation
FOR EACH ROW
BEGIN
    IF :NEW.Date_op < SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'La date de l''opération doit être postérieure ou égale à la date actuelle.');
    END IF;
END;
/

  create table Pret of Tpret(primary key(Num_pret),
   FOREIGN key(Num_cmpt) references Compte,
    CONSTRAINT check_type_pret CHECK (Type_pret IN ('Vehicule', 'Immobilier','ANSEJ','ANJEM'))
   );

CREATE OR REPLACE TRIGGER check_date_effect
   BEFORE INSERT ON Pret
    FOR EACH ROW
    BEGIN
       IF :NEW.Date_efectuer < SYSDATE THEN
           RAISE_APPLICATION_ERROR(-20001, 'La date de l''effet du prêt doit être postérieure ou égale à la date actuelle.');
        END IF;
    END;
   /





--les methodes PL/SQL

alter type Tagence add member function Nombre_Prets_Par_Agence return number cascade;
-- la methode 1
CREATE OR REPLACE TYPE BODY Tagence AS 
    MEMBER FUNCTION Nombre_Prets_Par_Agence RETURN NUMBER 
   
    IS
        total_prets NUMBER := 0;
    BEGIN
        -- Boucle sur chaque agence
        FOR agence_rec IN (SELECT Num_Ag FROM Agence) LOOP
            -- Recherche du nombre de prêts pour l'agence actuelle
            SELECT COUNT(*)
            INTO total_prets
            FROM Pret p
            JOIN Compte c ON p.Num_cmpt = REF(c)
            WHERE c.Num_Ag = agence_rec.Num_Ag;

            -- Ajout du nombre de prêts pour l'agence actuelle au total
            total_prets := total_prets + nombre_prets;
        END LOOP;

        -- Retourner le total des prêts pour toutes les agences
        RETURN total_prets;
    END;
END;
/


 
--methode 2:
alter type Tsuccursale add member function Nombre_Prets_Par_Agence  return number cascade;


   CREATE OR REPLACE TYPE BODY Tsuccursale AS
    MEMBER FUNCTION Nombre_Agences_Principales RETURN NUMBER
    IS
        total_agences INTEGER := 0;
    BEGIN
        -- Compte le nombre d'agences principales pour la succursale actuelle
        SELECT COUNT(*)
        INTO total_agences
        FROM Agence
        WHERE NumSucc = REF(self).Num_succ
        AND Categorie = 'Principale';

        -- Retourne le nombre total d'agences principales pour la succursale
        RETURN total_agences;
    END;
END;
/
--la methode 4
alter type Tagence add member function Agences_Secondaires_Avec_Pret_ANSEJ return number cascade;

CREATE OR REPLACE TYPE BODY Tagence AS 
    MEMBER FUNCTION Agences_Secondaires_Avec_Pret_ANSEJ RETURN NUMBER 
    IS
      
        total_agences INTEGER := 0;
    BEGIN
        -- Compter le nombre d'agences secondaires avec au moins un prêt ANSEJ
        SELECT COUNT(*)
        INTO total_agences
        FROM Agence a, Compte c, Pret p, Succursale s
        WHERE a.Num_Ag = c.Num_Ag
        AND c.Num_cmpt = p.Num_cmpt
        AND a.Num_succ = s.Num_succ
        AND a.Categorie = 'Secondaire'
        AND p.Type_pret = 'ANSEJ';

        -- Retourner le nombre d'agences secondaires avec au moins un prêt ANSEJ
        RETURN total_agences;
    END;
END;
/



--la methode 3

alter type Tagence add member function Montant_Global_Prets_Par_Agence return number cascade;
CREATE OR REPLACE TYPE BODY Tagence AS 
    MEMBER FUNCTION Montant_Global_Prets_Par_Agence RETURN NUMBER 
    IS
  
        montant_global NUMBER := 0;
    BEGIN
        -- Calcul du montant global des prêts pour une agence donnée
        SELECT SUM(p.Montant_pret)
        INTO montant_global
        FROM Pret p
        JOIN Compte c ON p.Num_cmpt = REF(c)
        JOIN Agence a ON c.Num_Ag = REF(a)
        WHERE a.Num_Ag = self.Num_Ag
        AND p.Date_efectuer >= TO_DATE('2020-01-01', 'YYYY-MM-DD')
        AND p.Date_efectuer < TO_DATE('2024-01-01', 'YYYY-MM-DD');

        -- Retour du montant global des prêts
        RETURN montant_global;
    END;
END;
/

--les insertions

INSERT INTO Succursale values(
    Tsuccursale(001,'SuccusrsaleNord',Tadresse(001,'Alger','1600 didouch'),'Nord',t_set_ref_agences())
    );
    commit ;

INSERT INTO Succursale values(
    Tsuccursale(002,'SuccusrsaleEst',Tadresse(002,'Constantine','2500 bekera'),'Est', t_set_ref_agences())
);
commit;

INSERT INTO Succursale values(
    Tsuccursale(003,'SuccusrsaleOuest',Tadresse(003,'Oran','3100 Akid'),'Ouest', t_set_ref_agences())
);
commit;
INSERT INTO Succursale values(
    Tsuccursale(004,'SuccusrsaleNord',Tadresse(005,'Alger','1600 cheraga'),'Nord', t_set_ref_agences())
);
commit;
INSERT INTO Succursale values(
    Tsuccursale(005,'SuccusrsaleSud',Tadresse(005,'Tamenraset','3100 Akid'),'Sud', t_set_ref_agences())
);
commit;
INSERT INTO Succursale values(
    Tsuccursale(006,'SuccusrsaleEst',Tadresse(006,'Annaba','2300 Badji-mokhtar'),'Est', t_set_ref_agences())
);
commit;


--num succ 1..6
INSERT INTO Agence VALUES (Tagence(001,
'BNA',Tadresse(001,'Alger','Didouch Mourad'), 
(select ref(s) from succursale s where s.Num_succ=001),'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=001));
commit;

--ajouter la ref de l'agence dans la table 
INSERT INTO Agence VALUES (Tagence(002,'BADR',Tadresse(002,'Constantine','Gue constantine'),
 (select ref(s) from succursale s where s.Num_succ=002),
'Principale',t_set_ref_compte()));

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=002)
values ((select ref(a) from Agence a where a.Num_Ag=002));
commit;

INSERT INTO Agence VALUES (Tagence(003,
'BH',Tadresse(003,'Constantine','Bekera'), 
(select ref(s) from succursale s where s.Num_succ=002),'Secondaire',t_set_ref_compte()));

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=002)
values ((select ref(a) from Agence a where a.Num_Ag=003));
commit;


INSERT INTO Agence VALUES (Tagence(004,'CNEP-Banque',Tadresse(004,
'Annaba','El marsoum'), (select ref(s) from succursale s where s.Num_succ=006),
'Secondaire',t_set_ref_compte()));
commit;

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=004));
commit;

INSERT INTO Agence VALUES (Tagence(005,'BDL',
Tadresse(005,'Alger','Ouled fayet'), 
(select ref(s) from succursale s where s.Num_succ=001), 
'Principale',t_set_ref_compte()));
commit;

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=005));
commit;

INSERT INTO Agence VALUES (Tagence(006,'AL BARAKA',
Tadresse(006,'Alger','cheraga'),
 (select ref(s) from succursale s where s.Num_succ=001),
 'Secondaire',t_set_ref_compte()));
commit;
 insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=006));
commit;

INSERT INTO Agence VALUES (Tagence(007,
'AL BARAKA',Tadresse(007,'Oran','Akid lotfi'), 
(select ref(s) from succursale s where s.Num_succ=003),
'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=003)
values ((select ref(a) from Agence a where a.Num_Ag=007));
commit;



INSERT INTO Agence VALUES (Tagence(008,'AL BARAKA',
Tadresse(008,'Alger','Hydra'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Secondaire',t_set_ref_compte()));
commit;

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=008));
commit;


INSERT INTO Agence VALUES (Tagence(009,
'AL BARAKA',Tadresse(009,'Alger','Beb zoura'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=009));
commit;

INSERT INTO Agence VALUES (Tagence(010,
'AL BARAKA',Tadresse(010,'Annaba','Beb el oued'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=010));
commit;


INSERT INTO Agence VALUES (Tagence(011,'CITIBANK',
Tadresse(011,'Tamenraset','ouled tlayet'), 
(select ref(s) from succursale s where s.Num_succ=005),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=005)
values ((select ref(a) from Agence a where a.Num_Ag=011));
commit;




INSERT INTO Agence VALUES (Tagence(012,
'AL BARAKA',Tadresse(012,'Annaba','Beb jdida'), 
(select ref(s) from succursale s where s.Num_succ=006),
'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=012));
commit;


INSERT INTO Agence VALUES (Tagence(013,'AL BARAKA',
Tadresse(013,'Annaba','Ain tlila'), 
(select ref(s) from succursale s where s.Num_succ=006),
'Principale',t_set_ref_compte()));

commit;

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=013));

commit;
INSERT INTO Agence VALUES (Tagence(014,
'ABC ',Tadresse(014,'Alger','Rouiba'), 
(select ref(s) from succursale s where s.Num_succ=005),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=005)
values ((select ref(a) from Agence a where a.Num_Ag=014));

commit;
INSERT INTO Agence VALUES (Tagence(015,
'ABC ',Tadresse(015,'Alger','Dar el bida'), 
(select ref(s) from succursale s where s.Num_succ=005),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=005)
values ((select ref(a) from Agence a where a.Num_Ag=015));

commit;
INSERT INTO Agence VALUES (Tagence(016,
'ABC ',Tadresse(016,'Alger','Reghaya'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=016));

commit;
INSERT INTO Agence VALUES (Tagence(017,
'ABC ',Tadresse(017,'Alger','Bainem'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=017));

commit;

INSERT INTO Agence VALUES (Tagence(018,
'NatixisALGERIE',Tadresse(018,'Oran',
' Larbi Ben Mhidi'),
 (select ref(s) from succursale s where s.Num_succ=003),
 'Principale',t_set_ref_compte()));
commit;

 insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=003)
values ((select ref(a) from Agence a where a.Num_Ag=018));

commit;





INSERT INTO Agence VALUES (Tagence(019,
'NatixisALGERIE',Tadresse(019,'Oran','Rue Ibn Sina'), 
(select ref(s) from succursale s where s.Num_succ=003),
'Secondaire',t_set_ref_compte()));
commit;

insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=003)
values ((select ref(a) from Agence a where a.Num_Ag=019));
commit;


INSERT INTO Agence VALUES (Tagence(020,
'BNA',Tadresse(020,'Constantine','Abane Ramdane'),
 (select ref(s) from succursale s where s.Num_succ=002),
 'Principale',t_set_ref_compte()));
commit;
 insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=002)
values ((select ref(a) from Agence a where a.Num_Ag=020));
commit;

INSERT INTO Agence VALUES (Tagence(021,
'NatixisALGERIE',Tadresse(021,'Tamenraset','Rue Indépendance '),
 (select ref(s) from succursale s where s.Num_succ=005),
 'Principale',t_set_ref_compte()));
 commit;

 insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=005)
values ((select ref(a) from Agence a where a.Num_Ag=021));
commit;

INSERT INTO Agence VALUES (Tagence(022,
'BNA',Tadresse(022,'Annaba','Didouch Mourad'), 
(select ref(s) from succursale s where s.Num_succ=006),
'Principale',t_set_ref_compte()));
commit;
 insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=022));
commit;

INSERT INTO Agence VALUES (Tagence(023,'El BARAKA',
Tadresse(023,'Annaba','Didouch Mourad'),
 (select ref(s) from succursale s where s.Num_succ=006),
 'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=023));
commit;

INSERT INTO Agence VALUES (Tagence(024,
'EL BARAKA',Tadresse(024,'Annaba','Didouch Mourad'), 
(select ref(s) from succursale s where s.Num_succ=006),
'Secondaire',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=006)
values ((select ref(a) from Agence a where a.Num_Ag=024));
commit;
INSERT INTO Agence VALUES (Tagence(025,'BNA',
Tadresse(025,'Alger','Oued reman'), 
(select ref(s) from succursale s where s.Num_succ=001),
'Principale',t_set_ref_compte()));
commit;
insert into table (select s.agence_succursale
                    from succursale s 
					where  s.Num_succ=001)
values ((select ref(a) from Agence a where a.Num_Ag=025));
commit;




INSERT into client values(tclient(15201,'Zeyani',
'Particulier',tadresse('04','alger','Hussin dey'),0559561288,'zeyani15@gmail.com',NUll));


INSERT into compte values(tcompte(1010000001,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15201),
(select ref(a) from agence a where a.Num_Ag=004),1500,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000001)
where c.Num_client=15201;



INSERT into client values(tclient(15202,'Ziad',
'Particulier',tadresse('05','alger','Hussin dey'),0559561388,'ziado@gmail.com',NUll));

INSERT into compte values(tcompte(1010000002,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15202),
(select ref(a) from agence a where a.Num_Ag=004),1530,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000002)
where c.Num_client=15202;


INSERT into client values(tclient(15203,'Hani',
'Particulier',tadresse('06','oran','Akid'),0553361388,'hanyy@gmail.com',NUll));

INSERT into compte values(tcompte(1010000003,to_date('18/06/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15203),
(select ref(a) from agence a where a.Num_Ag=011),130,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000003)
where c.Num_client=15203;



INSERT into client values(tclient(15204,'Nesrin',
'Particulier',tadresse('07','oran','Akid'),0753361388,'nessbn@gmail.com',NUll));

INSERT into compte values(tcompte(1010000004,to_date('17/06/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15204),
(select ref(a) from agence a where a.Num_Ag=011),13330,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000004)
where c.Num_client=15204;



INSERT into client values(tclient(15205,'Amir',
'Entreprise',tadresse('08','Annaba','benioutrin'),0763361388,'Amir20@gmail.com',NUll));

INSERT into compte values(tcompte(1010000005,to_date('17/06/2024'),'Bloquer',
(select ref(c) from client c where c.Num_client=15205),
(select ref(a) from agence a where a.Num_Ag=008),1390,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000005)
where c.Num_client=15205;


INSERT into client values(tclient(15206,'Lina',
'Entreprise',tadresse('09','Constantine','bekera'),0763354888,'Linouch21@gmail.com',NUll));

INSERT into compte values(tcompte(1010000006,to_date('17/06/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15206),
(select ref(a) from agence a where a.Num_Ag=008),90,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000006)
where c.Num_client=15206;


INSERT into client values(tclient(15207,'Nedal',
'Entreprise',tadresse('10','Constantine','bekera'),0663354888,'nedalbazi@gmail.com',NUll));

INSERT into compte values(tcompte(1010000007,to_date('17/06/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15207),
(select ref(a) from agence a where a.Num_Ag=010),12345,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000007)
where c.Num_client=15207;


INSERT into client values(tclient(15208,'Nadir',
'Entreprise',tadresse('11','tamenraset','RUE1'),0645354888,'nedalbazi@gmail.com',NUll));

INSERT into compte values(tcompte(1010000008,to_date('17/06/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15208),
(select ref(a) from agence a where a.Num_Ag=011),12345,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000008)
where c.Num_client=15208;


INSERT into client values(tclient(15209,'Badi',
'Entreprise',tadresse('12','Alger','Ouled fayet'),0645354088,'badiinail@gmail.com',NUll));

INSERT into compte values(tcompte(1010000009,to_date('20/05/2024'),'Bloquer',
(select ref(c) from client c where c.Num_client=15209),
(select ref(a) from agence a where a.Num_Ag=011),000,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000009)
where c.Num_client=15209;

INSERT into client values(tclient(15210,'Nourhan',
'Particulier',tadresse('14','Alger','Cheraga'),0645359088,'nour@gmail.com',NUll));

INSERT into compte values(tcompte(1010000010,to_date('21/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15210),
(select ref(a) from agence a where a.Num_Ag=001),4000,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000010)
where c.Num_client=15210;


INSERT into client values(tclient(15211,'Racim',
'Particulier',tadresse('15','Oran','arbi ben mhidi'),0645359098,'Racim@gmail.com',NUll));

INSERT into compte values(tcompte(1010000011,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15211),
(select ref(a) from agence a where a.Num_Ag=010),87600,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000011)
where c.Num_client=15211;



INSERT into client values(tclient(15212,'Maria',
'Particulier',tadresse('16','Oran','arbi ben mhidi'),0685359098,'Maria@gmail.com',NUll));

INSERT into compte values(tcompte(1010000012,to_date('20/05/2024'),'Bloquer',
(select ref(c) from client c where c.Num_client=15212),
(select ref(a) from agence a where a.Num_Ag=011),8600,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000012)
where c.Num_client=15212;


INSERT into client values(tclient(15213,'Lilia',
'Particulier',tadresse('17','Alger','ouled fayet'),0688059098,'Lilia20@gmail.com',NUll));

INSERT into compte values(tcompte(1010000013,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15213),
(select ref(a) from agence a where a.Num_Ag=001),10000,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000013)
where c.Num_client=15213;


INSERT into client values(tclient(15214,'Leyla',
'Particulier',tadresse('18','Alger','Achour'),0608059098,'Leyla12@gmail.com',NUll));

INSERT into compte values(tcompte(1010000014,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15214),
(select ref(a) from agence a where a.Num_Ag=009),10900,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000014)
where c.Num_client=15214;


INSERT into client values(tclient(15215,'Samara',
'Entreprise',tadresse('19','Tamneraset','Rue4'),0508059998,'Smarara@gmail.com',NUll));

INSERT into compte values(tcompte(1010000015,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15215),
(select ref(a) from agence a where a.Num_Ag=019),1090,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000015)
where c.Num_client=15215;

INSERT into client values(tclient(15216,'Rafik',
'Entreprise',tadresse('20','Annaba','Rue5'),0528059998,'Saadi@gmail.com',NUll));

INSERT into compte values(tcompte(1010000016,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15216),
(select ref(a) from agence a where a.Num_Ag=020),10904,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000016)
where c.Num_client=15216;



INSERT into client values(tclient(15217,'Kouthar',
'Entreprise',tadresse('21','Annaba','Rue6'),0528645329,'Hadji@gmail.com',NUll));

INSERT into compte values(tcompte(1010000017,to_date('17/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15217),
(select ref(a) from agence a where a.Num_Ag=020),10108,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000017)
where c.Num_client=15217;


INSERT into client values(tclient(15218,'Manar',
'Entreprise',tadresse('22','Annaba','Rue7'),0521645329,'manar23@gmail.com',NUll));

INSERT into compte values(tcompte(1010000018,to_date('20/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15218),
(select ref(a) from agence a where a.Num_Ag=025),1108,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000018)
where c.Num_client=15218;



INSERT into client values(tclient(15219,'Yasmine',
'Particulier',tadresse('23','Alger','Rue8'),0521645329,'Yasou23@gmail.com',NUll));

INSERT into compte values(tcompte(1010000019,to_date('19/05/2024'),'Bloquer',
(select ref(c) from client c where c.Num_client=15219),
(select ref(a) from agence a where a.Num_Ag=023),23608,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000019)
where c.Num_client=15219;


INSERT into client values(tclient(15220,'Younes',
'Particulier',tadresse('24','Alger','Hydra'),0621645329,'Younes@gmail.com',NUll));

INSERT into compte values(tcompte(1010000020,to_date('20/05/2024'),'Bloquer',
(select ref(c) from client c where c.Num_client=15220),
(select ref(a) from agence a where a.Num_Ag=004),20608,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000020)
where c.Num_client=15220;

INSERT into client values(tclient(15221,'Mourad',
'Particulier',tadresse('24','Alger','Alger centre'),06216405009,'moradhadji@gmail.com',NUll));

INSERT into compte values(tcompte(1010000021,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15221),
(select ref(a) from agence a where a.Num_Ag=014),80690,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000021)
where c.Num_client=15221;

INSERT into client values(tclient(15222,'Kader',
'Particulier',tadresse('24','Alger','Alger centre'),06296405009,'Kaderhadji@gmail.com',NUll));

INSERT into compte values(tcompte(1010000022,to_date('19/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15222),
(select ref(a) from agence a where a.Num_Ag=015),1690,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000022)
where c.Num_client=15222;


INSERT into client values(tclient(15223,'Nassim',
'Particulier',tadresse('24','Alger','Ain naadja'),05496405009,'Kaderhadji@gmail.com',NUll));

INSERT into compte values(tcompte(1010000023,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15223),
(select ref(a) from agence a where a.Num_Ag=016),16907,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000023)
where c.Num_client=15223;


INSERT into client values(tclient(15224,'Nassima',
'Particulier',tadresse('25','Alger','Rouiba'),05496405009,'Nassima@gmail.com',NUll));

INSERT into compte values(tcompte(1010000024,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15224),
(select ref(a) from agence a where a.Num_Ag=017),16927,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000024)
where c.Num_client=15224;


INSERT into client values(tclient(15225,'Faiza',
'Entreprise',tadresse('26','Tamanraset','Rue faida'),05896405009,'Faizapro@gmail.com',NUll));

INSERT into compte values(tcompte(1010000025,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15225),
(select ref(a) from agence a where a.Num_Ag=018),16427,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000025)
where c.Num_client=15225;


INSERT into client values(tclient(15226,'Nada',
'Particulier',tadresse('26','Constantine','bekera'),07496405009,'Nadabrasi@gmail.com',NUll));

INSERT into compte values(tcompte(1010000026,to_date('18/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15226),
(select ref(a) from agence a where a.Num_Ag=018),16927,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000026)
where c.Num_client=15226;

INSERT into client values(tclient(15227,'Karima',
'Particulier',tadresse('26','Oran','rue houari1'),05496405009,'Karimaperso@gmail.com',NUll));

INSERT into compte values(tcompte(1010000027,to_date('17/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15227),
(select ref(a) from agence a where a.Num_Ag=021),1697,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000027)
where c.Num_client=15227;



INSERT into client values(tclient(15228,'Ikram',
'Particulier',tadresse('27','Alger','beb zouar'),06496405008,'Ikramperso@gmail.com',NUll));

INSERT into compte values(tcompte(1010000028,to_date('17/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15228),
(select ref(a) from agence a where a.Num_Ag=020),1647,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000028)
where c.Num_client=15228;


INSERT into client values(tclient(15229,'Asma',
'Particulier',tadresse('28','Oran','rue houari1'),05496405009,'sabri@gmail.com',NUll));

INSERT into compte values(tcompte(1010000029,to_date('17/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15229),
(select ref(a) from agence a where a.Num_Ag=021),1697,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000029)
where c.Num_client=15229;

INSERT into client values(tclient(15230,'Manel',
'Particulier',tadresse('29','Alger','Draria'),05496405009,'Ferchichi@gmail.com',NUll));

INSERT into compte values(tcompte(1010000030,to_date('17/05/2024'),'Actif',
(select ref(c) from client c where c.Num_client=15230),
(select ref(a) from agence a where a.Num_Ag=004),16927,T_set_ref_operations(), t_set_ref_pret()));

update client c set c. Num_cmpt=(select ref(com) from compte com where com.Num_cmpt=1010000030)
where c.Num_client=15230;




INSERT INTO operation VALUES (toperation(1,'Credit',  TO_DATE('20/05/2024'),200, (SELECT REF(com) FROM
 compte com WHERE com.Num_cmpt = 1010000001),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000001)
values ((select ref(op) from operation op where op.Num_op=1));

INSERT INTO operation VALUES (toperation(2,'Credit',  TO_DATE('21/05/2024'),400, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000001),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000001)
values ((select ref(op) from operation op where op.Num_op=1));

INSERT INTO operation VALUES (toperation(3,'Debit',  TO_DATE('18/05/2024'), 50, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000002),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000002)
values ((select ref(op) from operation op where op.Num_op=3));

INSERT INTO operation VALUES (toperation(4,'Credit',  TO_DATE('17/05/2024'),119, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000003),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000003)
values ((select ref(op) from operation op where op.Num_op=4));

INSERT INTO operation VALUES (toperation(5,'Debit',  TO_DATE('20/05/2024'),20, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000003),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000003)
values ((select ref(op) from operation op where op.Num_op=5));


INSERT INTO operation VALUES (toperation(6,'Debit',  TO_DATE('18/05/2024'),200, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000005),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000005)
values ((select ref(op) from operation op where op.Num_op=6));

INSERT INTO operation VALUES (toperation(7,'Credit',  TO_DATE('18/05/2024'),450, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000005),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000005)
values ((select ref(op) from operation op where op.Num_op=7));

INSERT INTO operation VALUES (toperation(8,'Credit',  TO_DATE('18/05/2024'),40, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000010),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000010)
values ((select ref(op) from operation op where op.Num_op=8));

INSERT INTO operation VALUES (toperation(9,'Credit',  TO_DATE('17/05/2024'),480, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000010),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000010)
values ((select ref(op) from operation op where op.Num_op=9));


INSERT INTO operation VALUES (toperation(10,'Credit',  TO_DATE('18/05/2024'),1000, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000011),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000011)
values ((select ref(op) from operation op where op.Num_op=8));

INSERT INTO operation VALUES (toperation(11,'Debit',  TO_DATE('17/05/2024'),480, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000012),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000012)
values ((select ref(op) from operation op where op.Num_op=11));

INSERT INTO operation VALUES (toperation(12,'Debit',  TO_DATE('17/05/2024'),80, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000012),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000012)
values ((select ref(op) from operation op where op.Num_op=12));

INSERT INTO operation VALUES (toperation(13,'Credit',  TO_DATE('18/05/2024'),80, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000013),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000013)
values ((select ref(op) from operation op where op.Num_op=13));

INSERT INTO operation VALUES (toperation(14,'Credit',  TO_DATE('17/05/2024'),870, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000013),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000013)
values ((select ref(op) from operation op where op.Num_op=14));


INSERT INTO operation VALUES (toperation(15,'Debiit',  TO_DATE('17/05/2024'),90, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000013),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000013)
values ((select ref(op) from operation op where op.Num_op=15));



INSERT INTO operation VALUES (toperation(16,'Credit',  TO_DATE('17/05/2024'),870, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000018),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000018)
values ((select ref(op) from operation op where op.Num_op=16));

INSERT INTO operation VALUES (toperation(17,'Credit',  TO_DATE('17/05/2024'),770, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000014),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000014)
values ((select ref(op) from operation op where op.Num_op=17));

INSERT INTO operation VALUES (toperation(18,'Credit',  TO_DATE('19/05/2024'),087, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000014),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000014)
values ((select ref(op) from operation op where op.Num_op=18));


INSERT INTO operation VALUES (toperation(19,'Debit',  TO_DATE('17/05/2024'),087, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000020),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000020)
values ((select ref(op) from operation op where op.Num_op=19));


INSERT INTO operation VALUES (toperation( 20,'Debit',  TO_DATE('17/05/2024'),07, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000020),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000020)
values ((select ref(op) from operation op where op.Num_op=20));


INSERT INTO operation VALUES (toperation( 21,'Debit',  TO_DATE('17/05/2024'),123, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000022),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000022)
values ((select ref(op) from operation op where op.Num_op=21));



INSERT INTO operation VALUES (toperation( 22,'Credit',  TO_DATE('18/05/2024'),129, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000022),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000022)
values ((select ref(op) from operation op where op.Num_op=22));



INSERT INTO operation VALUES (toperation( 23,'Debit',  TO_DATE('17/05/2024'),7653, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000024),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000024)
values ((select ref(op) from operation op where op.Num_op=23));


INSERT INTO operation VALUES (toperation( 24,'Debit',  TO_DATE('19/05/2024'),765, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000024),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000024)
values ((select ref(op) from operation op where op.Num_op=24));


INSERT INTO operation VALUES (toperation( 25,'Credit',  TO_DATE('17/05/2024'),69, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000024),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000024)
values ((select ref(op) from operation op where op.Num_op=25));

INSERT INTO operation VALUES (toperation( 26,'Credit',  TO_DATE('17/05/2024'),99, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000023),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000023)
values ((select ref(op) from operation op where op.Num_op=26));

INSERT INTO operation VALUES (toperation( 27,'Credit',  TO_DATE('17/05/2024'),019, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000023),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000023)
values ((select ref(op) from operation op where op.Num_op=27));


INSERT INTO operation VALUES (toperation( 28,'Debit',  TO_DATE('17/05/2024'),019, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000023),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000023)
values ((select ref(op) from operation op where op.Num_op=28));


INSERT INTO operation VALUES (toperation( 29,'Debit',  TO_DATE('17/05/2024'),019, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000023),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000023)
values ((select ref(op) from operation op where op.Num_op=29));



INSERT INTO operation VALUES (toperation( 30,'Credit',  TO_DATE('17/05/2024'),229, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt = 1010000025),'valide'));
insert into table (select c.operation_compte
                    from compte c 
					where  c.Num_cmpt=1010000025)
values ((select ref(op) from operation op where op.Num_op=30));


---inserer un pret 
--------------------compte1
INSERT into pret values(tpret(1,'1min',
to_date('19/05/2024'),100,'Vehicule',10,(select ref(com) from compte com where com.Num_cmpt=1010000001),150));

INSERT INTO pret VALUES (tpret(2,'2min',  TO_DATE('20/05/2024'), 200,'Immobilier',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=  1010000001) ,250));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt= 1010000001)
                                        
values ((select ref(p) from pret p where p.Num_pret=1));
insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000001)
values ((select ref(p) from pret p where p.Num_pret=2));



INSERT into pret values(tpret(3,'5min',
to_date('16/05/2024'),103,'ANSEJ',10,(select ref(com) from compte com where com.Num_cmpt=1010000002),139));

INSERT INTO pret VALUES (tpret(4,'5min',  TO_DATE('17/05/2024'), 200,'Immobilier',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=  1010000002) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt= 1010000002)
values ((select ref(p) from pret p where p.Num_pret=3));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000002)
values ((select ref(p) from pret p where p.Num_pret=4));


INSERT into pret values(tpret(5,'5min',
to_date('16/05/2024'),234,'ANSEJ',10,(select ref(com) from compte com where com.Num_cmpt=1010000003),255));

INSERT INTO pret VALUES (tpret(6,'5min',  TO_DATE('18/05/2024'), 199,'ANSEJ',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=  1010000004) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt= 1010000003)
values ((select ref(p) from pret p where p.Num_pret=5));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000004)
values ((select ref(p) from pret p where p.Num_pret=6));

INSERT into pret values(tpret(7,'15min',
to_date('16/05/2024'),235,'Vehicule',11,(select ref(com) from compte com where com.Num_cmpt=1010000005),265));

INSERT INTO pret VALUES (tpret(8,'10min',  TO_DATE('17/05/2024'), 199,'ANSEJ',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=  1010000007) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt= 1010000005)
values ((select ref(p) from pret p where p.Num_pret=7));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000007)
values ((select ref(p) from pret p where p.Num_pret=8));

INSERT into pret values(tpret(9,'20min',
to_date('16/05/2024'),450,'Vehicule',14,(select ref(com) from compte com where com.Num_cmpt=1010000008),465));

INSERT INTO pret VALUES (tpret(10,'30min',  TO_DATE('17/05/2024'), 199,'ANSEJ',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=  1010000009) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt= 1010000008)
values ((select ref(p) from pret p where p.Num_pret=9));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000009)
values ((select ref(p) from pret p where p.Num_pret=10));

INSERT into pret values(tpret(11,'25min',
to_date('16/05/2024'),5500,'Immobilier',14,(select ref(com) from compte com where com.Num_cmpt=1010000010),7650));

INSERT INTO pret VALUES (tpret(12,'35min',  TO_DATE('17/05/2024'), 199,'Vehicule',
 12, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000010) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000010)
values ((select ref(p) from pret p where p.Num_pret=11));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000010)
values ((select ref(p) from pret p where p.Num_pret=12));


INSERT into pret values(tpret(13,'35min',
to_date('17/05/2024'),5510,'Immobilier',10,(select ref(com) from compte com where com.Num_cmpt=1010000011),7652));

INSERT INTO pret VALUES (tpret(14,'45min',  TO_DATE('17/05/2024'), 167,'Vehicule',
 10, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000012) ,270));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000011)
values ((select ref(p) from pret p where p.Num_pret=13));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000012)
values ((select ref(p) from pret p where p.Num_pret=14));


INSERT into pret values(tpret(15,'35min',
to_date('20/05/2024'),5810,'Immobilier',40,(select ref(com) from compte com where com.Num_cmpt=1010000011),7052));

INSERT INTO pret VALUES (tpret(16,'45min',  TO_DATE('22/05/2024'), 1698,'Immobilier',
 10, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000012) ,2700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000013)
values ((select ref(p) from pret p where p.Num_pret=15));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000014)
values ((select ref(p) from pret p where p.Num_pret=16));


INSERT into pret values(tpret(17,'1h',
to_date('21/05/2024'),3456,'Immobilier',40,(select ref(com) from compte com where com.Num_cmpt=1010000013),7052));

INSERT INTO pret VALUES (tpret(18,'50min',  TO_DATE('22/05/2024'), 9698,'Vehicule',
 10, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000014) ,10700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000013)
values ((select ref(p) from pret p where p.Num_pret=17));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000014)
values ((select ref(p) from pret p where p.Num_pret=18));


INSERT into pret values(tpret(19,'20min',
to_date('21/05/2024'),3456,'Vehicule',50,(select ref(com) from compte com where com.Num_cmpt=1010000015),8052));

INSERT INTO pret VALUES (tpret(20,'50min',  TO_DATE('22/05/2024'), 7698,'Vehicule',
 30, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000016) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000015)
values ((select ref(p) from pret p where p.Num_pret=19));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000016)
values ((select ref(p) from pret p where p.Num_pret=20));



INSERT into pret values(tpret(21,'20min',
to_date('21/05/2024'),5456,'ANSEJ',50,(select ref(com) from compte com where com.Num_cmpt=1010000017),8052));

INSERT INTO pret VALUES (tpret(22,'10min',  TO_DATE('22/05/2024'), 7698,'ANSEJ',
 30, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000018) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000017)
values ((select ref(p) from pret p where p.Num_pret=21));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000018)
values ((select ref(p) from pret p where p.Num_pret=22));

INSERT into pret values(tpret(23,'25min',
to_date('16/05/2024'),1056,'ANSEJ',50,(select ref(com) from compte com where com.Num_cmpt=1010000019),9052));

INSERT INTO pret VALUES (tpret(24,'15min',  TO_DATE('17/05/2024'), 7698,'ANSEJ',
 30, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000020) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000019)
values ((select ref(p) from pret p where p.Num_pret=23));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000020)
values ((select ref(p) from pret p where p.Num_pret=24));



INSERT into pret values(tpret(25,'25min',
to_date('16/05/2024'),506,'ANSEJ',40,(select ref(com) from compte com where com.Num_cmpt=1010000021),9052));

INSERT INTO pret VALUES (tpret(26,'15min',  TO_DATE('17/05/2024'), 7698,'ANSEJ',
 30, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000022) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000021)
values ((select ref(p) from pret p where p.Num_pret=25));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000022)
values ((select ref(p) from pret p where p.Num_pret=26));



INSERT into pret values(tpret(27,'23min',
to_date('16/05/2024'),606,'Immobilier',45,(select ref(com) from compte com where com.Num_cmpt=1010000023),1052));

INSERT INTO pret VALUES (tpret(28,'28min',  TO_DATE('17/05/2024'), 7698,'Immobilier',
 35, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000024) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000023)
values ((select ref(p) from pret p where p.Num_pret=27));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000024)
values ((select ref(p) from pret p where p.Num_pret=28));



INSERT into pret values(tpret(29,'33min',
to_date('16/05/2024'),1606,'Immobilier',45,(select ref(com) from compte com where com.Num_cmpt=1010000025),6752));

INSERT INTO pret VALUES (tpret(30,'48min',  TO_DATE('17/05/2024'), 9098,'Immobilier',
 35, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000026) ,7700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000025)
values ((select ref(p) from pret p where p.Num_pret=29));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000026)
values ((select ref(p) from pret p where p.Num_pret=30));



INSERT into pret values(tpret(31,'33min',
to_date('16/05/2024'),4606,'Immobilier',45,(select ref(com) from compte com where com.Num_cmpt=1010000027),6752));

INSERT INTO pret VALUES (tpret(32,'48min',  TO_DATE('17/05/2024'), 9098,'Vehicule',
 35, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000028) ,8700));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000027)
values ((select ref(p) from pret p where p.Num_pret=31));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000028)
values ((select ref(p) from pret p where p.Num_pret=32));



INSERT into pret values(tpret(33,'33min',
to_date('17/05/2024'),4306,'Immobilier',55,(select ref(com) from compte com where com.Num_cmpt=1010000029),6752));

INSERT INTO pret VALUES (tpret(34,'48min',  TO_DATE('17/05/2024'), 342,'Vehicule',
 45, (SELECT REF(com) FROM compte com WHERE com.Num_cmpt=1010000030) ,987));
                                                         
insert into table (select c.pret_compte 
                    from compte c 
					where  c.Num_cmpt=1010000029)
values ((select ref(p) from pret p where p.Num_pret=33));

insert into table (select c.pret_compte 
                    from compte c    
					where  c.Num_cmpt=1010000030)
values ((select ref(p) from pret p where p.Num_pret=34));









SELECT c.Num_cmpt
FROM Compte c, Agence a, Client cl
WHERE c.Num_Ag = REF(a)
AND a.Num_Ag = 008
AND c.Num_client = REF(cl)
AND cl.Type_client = 'Entreprise';





SELECT p.Num_pret, p.Num_cmpt.Num_Ag.Num_Ag, p.Num_cmpt.Num_cmpt, p.Montant_pret
FROM Pret p, Compte c, Agence a, Succursale s
WHERE p.Num_cmpt = REF(c)
AND c.Num_Ag = REF(a)
AND a.Num_succ = REF(s)
AND s.Num_succ = 005;


SELECT SUM(o.Montant_op)
FROM Operation o, Compte c
WHERE o.Num_cmpt = REF(c)
AND c.Num_cmpt =1010000022 
AND o.Nature_op = 'Credit'
AND EXTRACT(YEAR FROM o.Date_op) = 2024;



SELECT p.Num_pret, p.Num_cmpt.Num_Ag.Num_Ag, p.Num_cmpt.Num_cmpt, p.Num_cmpt.Num_client.Num_client, p.Montant_pret
FROM Pret p
WHERE p.Montant_pret > 0;
