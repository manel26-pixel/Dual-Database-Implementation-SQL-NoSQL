//create Compte 
db.createCollection("Compte",
{
    validator: {
       $jsonSchema: {
          bsonType: "object",
          required: [
                "NumCompte",
                "dateOuverture",
                "etatCompte",
                "Solde",
                "NumAgence",
                "Client",
                "Operations",
                "Prets"
            ],
          properties: {
             NumCompte: { bsonType: "int"
                },
             dateOuverture: { bsonType: "date"
                },
             etatCompte: {
                enum: [
                        "Actif",
                        "Bloque"
                    ]
                },
             Solde: { 
                bsonType: [
                        "double",
                        "int"
                    ], 
                minimum: 0 // Allow 0 value
                },
             NumAgence: { bsonType: "int"
                },
             Client: {
                bsonType: "object",
                required: [
                        "numtel"
                    ],
                properties: {
                   NumClient: { bsonType: "int"
                        },
                   NomClient: { bsonType: "string"
                        },
                   TypeClient: {
                      enum: [
                                "Particulier",
                                "Entreprise"
                            ]
                        },
                   adresseClient: { bsonType: "string"
                        },
                   numtel: { bsonType: "string", pattern: "^(05|06|07)[0-9]{8}$"
                        },
                   email: {
                      bsonType: "string",
                      pattern: "^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$"
                        }
                    }
                },
             Operations: {
                bsonType: "array",
                items: {
                   bsonType: "object",
                   properties: {
                      NumOperation: { bsonType: "int"
                            },
                      natureOp: {
                         enum: [
                                    "Credit",
                                    "Debit"
                                ]
                            },
                      montantOp: { bsonType: "double"
                            },
                      dateOp: { bsonType: "date"
                            },
                      observation: { bsonType: "string"
                            },
                      NumCompte: { bsonType: "int"
                            }
                        }
                    }
                },
             Prets: {
                bsonType: "array",
                items: {
                   bsonType: "object",
                   properties: {
                      NumPret: { bsonType: "int"
                            },
                      montantOp: { bsonType: "double"
                            },
                      dateEffet: { bsonType: "date"
                            },
                      duree: { bsonType: "string"
                            },
                      typePret: {
                         enum: [
                                    "Vehicule",
                                    "Immobilier",
                                    "ANSEJ",
                                    "ANJEM"
                                ]
                            },
                      tauxInteret: { bsonType: "double"
                            },
                      montantEcheance: { bsonType: "double"
                            },
                      NumCompte: { bsonType: "int"
                            }
                        }
                    }
                }
            }
        }
    }
})
 
//create Agence
 db.createCollection("Agence",
{
    validator: {
       $jsonSchema: {
          bsonType: "object",
          required: [
                "NumAgence",
                "NomAgence",
                "adresseAgence",
                "categorie",
                "NumSucc"
            ],
          properties: {
             NumAgence: { bsonType: "int"
                },
             NomAgence: { bsonType: "string"
                },
             adresseAgence: { bsonType: "string"
                },
             categorie: {
                enum: [
                        "Principale",
                        "Secondaire"
                    ]
                },
             NumSucc: { bsonType: "int"
                }
            }
        }
    }
})
 
//Create Succursale
 db.createCollection("Succursale",
{
    validator: {
       $jsonSchema: {
          bsonType: "object",
          required: [
                "NumSucc",
                "NomSucc",
                "adresseSucc",
                "region",
                "Agences"
            ],
          properties: {
             NumSucc: { bsonType: "int"
                },
             NomSucc: { bsonType: "string"
                },
             adresseSucc: { bsonType: "string"
                },
             region: {
                enum: [
                        "Nord",
                        "Sud",
                        "Est",
                        "Ouest"
                    ]
                },
             Agences: {
                bsonType: "array",
                items: { bsonType: "int"
                    }
                }
            }
        }
    }
})
 
//requetes insertion  Succursale
 db.Succursale.insertMany([
    {
       NumSucc: 1,
       NomSucc: "Succursale Nord",
       adresseSucc: "123 Main St, North",
       region: "Nord",
       Agences: [
            101,
            102,
            103,
            104,
            105
        ]
    },
    {
       NumSucc: 2,
       NomSucc: "Succursale Sud",
       adresseSucc: "456 South Ave, South",
       region: "Sud",
       Agences: [
            106,
            107,
            108,
            109,
            110
        ]
    },
    {
       NumSucc: 3,
       NomSucc: "Succursale Est",
       adresseSucc: "789 East Blvd, East",
       region: "Est",
       Agences: [
            111,
            112,
            113,
            114,
            115
        ]
    },
    {
       NumSucc: 4,
       NomSucc: "Succursale Ouest",
       adresseSucc: "987 West Rd, West",
       region: "Ouest",
       Agences: [
            116,
            117,
            118,
            119,
            120
        ]
    },
    {
       NumSucc: 5,
       NomSucc: "Succursale Central",
       adresseSucc: "246 Nord St, Nord",
       region: "Nord",
       Agences: [
            121,
            122,
            123,
            124,
            125
        ]
    },
    {
       NumSucc: 6,
       NomSucc: "Succursale Coast",
       adresseSucc: "135 Nord Rd, Nord",
       region: "Nord",
       Agences: [
            126,
            127,
            128,
            129,
            130
        ]
    }
])
 
//requetes insertion  Agence
 db.Agence.insertMany([
    {
       NumAgence: 101,
       NomAgence: "Agence Nord 101",
       adresseAgence: "Rue Ahmed Zabana, Oran",
       categorie: "Principale",
       NumSucc: 1
    },
    {
       NumAgence: 102,
       NomAgence: "Agence Nord 102",
       adresseAgence: "Avenue Khemisti, Algiers",
       categorie: "Secondaire",
       NumSucc: 1
    },
    {
       NumAgence: 103,
       NomAgence: "Agence Nord 103",
       adresseAgence: "Boulevard Benyoucef Benkhedda, Tizi Ouzou",
       categorie: "Principale",
       NumSucc: 1
    },
    {
       NumAgence: 104,
       NomAgence: "Agence Nord 104",
       adresseAgence: "Rue Didouche Mourad, Constantine",
       categorie: "Secondaire",
       NumSucc: 1
    },
    {
       NumAgence: 105,
       NomAgence: "Agence Nord 105",
       adresseAgence: "Avenue Hassiba Ben Bouali, Oran",
       categorie: "Principale",
       NumSucc: 1
    },
    {
       NumAgence: 106,
       NomAgence: "Agence Sud 106",
       adresseAgence: "Avenue des Martyrs, Tamanrasset",
       categorie: "Principale",
       NumSucc: 2
    },
    {
       NumAgence: 107,
       NomAgence: "Agence Sud 107",
       adresseAgence: "Boulevard Colonel Amirouche, Tindouf",
       categorie: "Secondaire",
       NumSucc: 2
    },
    {
       NumAgence: 108,
       NomAgence: "Agence Sud 108",
       adresseAgence: "Rue Emir Abdelkader, Ghardaia",
       categorie: "Principale",
       NumSucc: 2
    },
    {
       NumAgence: 109,
       NomAgence: "Agence Sud 109",
       adresseAgence: "Avenue Frantz Fanon, Adrar",
       categorie: "Secondaire",
       NumSucc: 2
    },
    {
       NumAgence: 110,
       NomAgence: "Agence Sud 110",
       adresseAgence: "Avenue du 1er Novembre 1954, Tamanrasset",
       categorie: "Principale",
       NumSucc: 2
    },
    {
       NumAgence: 111,
       NomAgence: "Agence Est 111",
       adresseAgence: "Boulevard Pasteur, Annaba",
       categorie: "Principale",
       NumSucc: 3
    },
    {
       NumAgence: 112,
       NomAgence: "Agence Est 112",
       adresseAgence: "Rue Larbi Ben M'hidi, Constantine",
       categorie: "Secondaire",
       NumSucc: 3
    },
    {
       NumAgence: 113,
       NomAgence: "Agence Est 113",
       adresseAgence: "Boulevard Benyoucef Benkhedda, Tizi Ouzou",
       categorie: "Principale",
       NumSucc: 3
    },
    {
       NumAgence: 114,
       NomAgence: "Agence Est 114",
       adresseAgence: "Avenue Boualem Saïdani, Batna",
       categorie: "Secondaire",
       NumSucc: 3
    },
    {
       NumAgence: 115,
       NomAgence: "Agence Est 115",
       adresseAgence: "Boulevard Mohamed Boudiaf, Jijel",
       categorie: "Principale",
       NumSucc: 3
    },
    {
       NumAgence: 116,
       NomAgence: "Agence Ouest 116",
       adresseAgence: "Rue Larbi Tebessi, Oran",
       categorie: "Principale",
       NumSucc: 4
    },
    {
       NumAgence: 117,
       NomAgence: "Agence Ouest 117",
       adresseAgence: "Avenue du 1er Novembre 1954, Tlemcen",
       categorie: "Secondaire",
       NumSucc: 4
    },
    {
       NumAgence: 118,
       NomAgence: "Agence Ouest 118",
       adresseAgence: "Avenue Hassiba Ben Bouali, Mostaganem",
       categorie: "Principale",
       NumSucc: 4
    },
    {
       NumAgence: 119,
       NomAgence: "Agence Ouest 119",
       adresseAgence: "Rue du 8 Mai 1945, Sidi Bel Abbès",
       categorie: "Secondaire",
       NumSucc: 4
    },
    {
       NumAgence: 120,
       NomAgence: "Agence Ouest 120",
       adresseAgence: "Boulevard Colonel Amirouche, Relizane",
       categorie: "Principale",
       NumSucc: 4
    },
    {
       NumAgence: 121,
       NomAgence: "Agence Nord 121",
       adresseAgence: "Rue Didouche Mourad, Oran",
       categorie: "Principale",
       NumSucc: 5
    },
    {
       NumAgence: 122,
       NomAgence: "Agence Nord 122",
       adresseAgence: "Boulevard Krim Belkacem, Mostaganem",
       categorie: "Secondaire",
       NumSucc: 5
    },
    {
       NumAgence: 123,
       NomAgence: "Agence Nord 123",
       adresseAgence: "Rue Emir Abdelkader, Tlemcen",
       categorie: "Principale",
       NumSucc: 5
    },
    {
       NumAgence: 124,
       NomAgence: "Agence Nord 124",
       adresseAgence: "Avenue Ben M'hidi, Sidi Bel Abbès",
       categorie: "Secondaire",
       NumSucc: 5
    },
    {
       NumAgence: 125,
       NomAgence: "Agence Nord 125",
       adresseAgence: "Rue Ibn Badis, Tiaret",
       categorie: "Principale",
       NumSucc: 5
    },
    {
       NumAgence: 126,
       NomAgence: "Agence Nord 126",
       adresseAgence: "Rue Colonel Amirouche, Tizi Ouzou",
       categorie: "Secondaire",
       NumSucc: 6
    },
    {
       NumAgence: 127,
       NomAgence: "Agence Nord 127",
       adresseAgence: "Boulevard Krim Belkacem, Béjaïa",
       categorie: "Principale",
       NumSucc: 6
    },
    {
       NumAgence: 128,
       NomAgence: "Agence Nord 128",
       adresseAgence: "Rue Hacène Khelifa, Annaba",
       categorie: "Secondaire",
       NumSucc: 6
    },
    {
       NumAgence: 129,
       NomAgence: "Agence Nord 129",
       adresseAgence: "Avenue Houari Boumediene, Skikda",
       categorie: "Principale",
       NumSucc: 6
    },
    {
       NumAgence: 130,
       NomAgence: "Agence Nord 130",
       adresseAgence: "Rue Frantz Fanon, Constantine",
       categorie: "Secondaire",
       NumSucc: 6
    }
])
 
//requetes insertion  Compte
 db.Compte.insertMany([
    {
       NumCompte: 6,
       dateOuverture: new Date("2019-05-15"),
       etatCompte: "Actif",
       Solde: 5000.5,
       NumAgence: 101,
       Client: {
          NumClient: 123,
          NomClient: "John Doe",
          TypeClient: "Particulier",
          adresseClient: "123 Main St",
          numtel: "0512345678",
          email: "john@example.com"
        },
       Operations: [
            {
             NumOperation: 20041,
             natureOp: "Credit",
             montantOp: 2000.5,
             dateOp: new Date("2022-03-20"),
             observation: "Deposit",
             NumCompte: 6
            },
            {
             NumOperation: 20062,
             natureOp: "Debit",
             montantOp: 1000.5,
             dateOp: new Date("2022-03-25"),
             observation: "Withdrawal",
             NumCompte: 6
            }
        ],
       Prets: [
            {
             NumPret: 10011,
             montantOp: 10000.5,
             dateEffet: new Date("2023-01-10"),
             duree: "24 mois",
             typePret: "Immobilier",
             tauxInteret: 5.5,
             montantEcheance: 500.5,
             NumCompte: 6
            },
            {
             NumPret: 10032,
             montantOp: 8000.5,
             dateEffet: new Date("2022-08-15"),
             duree: "12 mois",
             typePret: "Vehicule",
             tauxInteret: 6.8,
             montantEcheance: 600.5,
             NumCompte: 6
            }
        ]
    },
    {
       NumCompte: 2,
       dateOuverture: new Date("2020-08-10"),
       etatCompte: "Actif",
       Solde: 3000.5,
       NumAgence: 101,
       Client: {
          NumClient: 124,
          NomClient: "Jane Smith",
          TypeClient: "Particulier",
          adresseClient: "456 Oak St",
          numtel: "0612345678",
          email: "jane@example.com"
        },
       Operations: [
            {
             NumOperation: 20032,
             natureOp: "Credit",
             montantOp: 2000.5,
             dateOp: new Date("2022-03-20"),
             observation: "Deposit",
             NumCompte: 1
            },
            {
             NumOperation: 20023,
             natureOp: "Debit",
             montantOp: 1000.5,
             dateOp: new Date("2022-03-25"),
             observation: "Withdrawal",
             NumCompte: 1
            }
        ],
       Prets: [
            {
             NumPret: 10039,
             montantOp: 12000.5,
             dateEffet: new Date("2023-04-15"),
             duree: "36 mois",
             typePret: "Immobilier",
             tauxInteret: 5.8,
             montantEcheance: 400.5,
             NumCompte: 2
            }
        ]
    },
    {
       NumCompte: 3,
       dateOuverture: new Date("2020-08-10"),
       etatCompte: "Actif",
       Solde: 5000.5,
       NumAgence: 101,
       Client: {
          NumClient: 124,
          NomClient: "Jane Smith",
          TypeClient: "Particulier",
          adresseClient: "456 Oak St",
          numtel: "0612345678",
          email: "jane@example.com"
        },
       Operations: [
            {
             NumOperation: 2009,
             natureOp: "Credit",
             montantOp: 1500.5,
             dateOp: new Date("2023-05-20"),
             observation: "Deposit",
             NumCompte: 3
            },
            {
             NumOperation: 20041,
             natureOp: "Debit",
             montantOp: 700.5,
             dateOp: new Date("2023-06-02"),
             observation: "Withdrawal",
             NumCompte: 3
            }
        ],
       Prets: [
            {
             NumPret: 1009,
             montantOp: 10000.5,
             dateEffet: new Date("2023-01-10"),
             duree: "24 mois",
             typePret: "Immobilier",
             tauxInteret: 5.5,
             montantEcheance: 500.5,
             NumCompte: 3
            },
            {
             NumPret: 10098,
             montantOp: 8000.5,
             dateEffet: new Date("2022-08-15"),
             duree: "12 mois",
             typePret: "Vehicule",
             tauxInteret: 6.8,
             montantEcheance: 600.5,
             NumCompte: 3
            }
        ]
    },
    {
       NumCompte: 5,
       dateOuverture: new Date("2018-10-25"),
       etatCompte: "Actif",
       Solde: 7000.5,
       NumAgence: 101,
       Client: {
          NumClient: 125,
          NomClient: "Alice Johnson",
          TypeClient: "Particulier",
          adresseClient: "789 Pine St",
          numtel: "0712345678",
          email: "alice@example.com"
        },
       Operations: [
            {
             NumOperation: 2005,
             natureOp: "Credit",
             montantOp: 3000.5,
             dateOp: new Date("2022-09-10"),
             observation: "Deposit",
             NumCompte: 5
            },
            {
             NumOperation: 2006,
             natureOp: "Debit",
             montantOp: 2000.5,
             dateOp: new Date("2022-09-20"),
             observation: "Withdrawal",
             NumCompte: 5
            }
        ],
       Prets: [
            {
             NumPret: 1004,
             montantOp: 15000.5,
             dateEffet: new Date("2023-08-05"),
             duree: "48 mois",
             typePret: "Immobilier",
             tauxInteret: 4.5,
             montantEcheance: 550.5,
             NumCompte: 5
            }
        ]
    },
    {
       NumCompte: 4,
       dateOuverture: new Date("2019-03-15"),
       etatCompte: "Actif",
       Solde: 4000.5,
       NumAgence: 101,
       Client: {
          NumClient: 126,
          NomClient: "Michael Brown",
          TypeClient: "Particulier",
          adresseClient: "101 Elm St",
          numtel: "0512345679",
          email: "michael@example.com"
        },
       Operations: [
            {
             NumOperation: 2007,
             natureOp: "Credit",
             montantOp: 2500.5,
             dateOp: new Date("2022-12-05"),
             observation: "Deposit",
             NumCompte: 4
            },
            {
             NumOperation: 2008,
             natureOp: "Debit",
             montantOp: 1000.5,
             dateOp: new Date("2022-12-10"),
             observation: "Withdrawal",
             NumCompte: 4
            }
        ],
       Prets: [
            {
             NumPret: 1005,
             montantOp: 10000.5,
             dateEffet: new Date("2023-11-15"),
             duree: "24 mois",
             typePret: "Vehicule",
             tauxInteret: 6.8,
             montantEcheance: 500.5,
             NumCompte: 4
            }
        ]
    },
    {
        "NumCompte": 1,
        "dateOuverture": ISODate("2023-05-20"),
        "etatCompte": "Actif",
        "Solde": 10000.5,
        "NumAgence": 101,
        "Client": {
            "NumClient": 12345,
            "NomClient": "John Doe",
            "TypeClient": "Particulier",
            "adresseClient": "123 Main Street",
            "numtel": "0512345678",
            "email": "john@example.com"
        },
        "Operations": [
            {
                "NumOperation": 1001,
                "natureOp": "Credit",
                "montantOp": 5000.5,
                "dateOp": ISODate("2023-05-20"),
                "observation": "Initial deposit",
                "NumCompte": 1
            }
        ],
        "Prets": [
            {
                "NumPret": 2001,
                "montantOp": 20000.5,
                "dateEffet": ISODate("2023-05-25"),
                "duree": "36 months",
                "typePret": "Immobilier",
                "tauxInteret": 5.5,
                "montantEcheance": 800.5,
                "NumCompte": 1
            }
        ]
    },
    {
        "NumCompte": 7,
        "dateOuverture": ISODate("2023-06-10"),
        "etatCompte": "Actif",
        "Solde": 15000.1,
        "NumAgence": 102,
        "Client": {
            "NumClient": 67890,
            "NomClient": "Alice Smith",
            "TypeClient": "Particulier",
            "adresseClient": "456 Oak Street",
            "numtel": "0612345678",
            "email": "alice@example.com"
        },
        "Operations": [
            {
                "NumOperation": 1002,
                "natureOp": "Credit",
                "montantOp": 7000.1,
                "dateOp": ISODate("2023-06-10"),
                "observation": "Initial deposit",
                "NumCompte": 7
            }
        ],
        "Prets": [
            {
                "NumPret": 2002,
                "montantOp": 25000.1,
                "dateEffet": ISODate("2023-06-15"),
                "duree": "48 months",
                "typePret": "Vehicule",
                "tauxInteret": 6.1,
                "montantEcheance": 1000.1,
                "NumCompte": 7
            }
        ]
    },
    {
        "NumCompte": 8,
        "dateOuverture": ISODate("2023-07-05"),
        "etatCompte": "Actif",
        "Solde": 20000.2,
        "NumAgence": 103,
        "Client": {
            "NumClient": 24680,
            "NomClient": "Bob Johnson",
            "TypeClient": "Particulier",
            "adresseClient": "789 Pine Street",
            "numtel": "0712345678",
            "email": "bob@example.com"
        },
        "Operations": [
            {
                "NumOperation": 1042,
                "natureOp": "Credit",
                "montantOp": 10000.2,
                "dateOp": ISODate("2023-07-05"),
                "observation": "Initial deposit",
                "NumCompte": 8
            }
        ],
        "Prets": [
            {
                "NumPret": 203,
                "montantOp": 30000.3,
                "dateEffet": ISODate("2023-07-10"),
                "duree": "60 months",
                "typePret": "Immobilier",
                "tauxInteret": 7.2,
                "montantEcheance": 1200.3,
                "NumCompte": 8
            }
        ]
    },
    {
       NumCompte: 9,
       dateOuverture: new Date("2019-05-15"),
       etatCompte: "Actif",
       Solde: 0.0,
       NumAgence: 105,
       Client: {
          NumClient: 123,
          NomClient: "John Doe",
          TypeClient: "Entreprise",
          adresseClient: "123 Main St",
          numtel: "0512345678",
          email: "john@example.com"
        },
       Operations: [
            {
             NumOperation: 2024,
             natureOp: "Credit",
             montantOp: 2000.5,
             dateOp: new Date("2022-03-20"),
             observation: "Deposit",
             NumCompte: 9
            },
            {
             NumOperation: 2062,
             natureOp: "Debit",
             montantOp: 1000.5,
             dateOp: new Date("2022-03-25"),
             observation: "Withdrawal",
             NumCompte: 9
            }
        ],
       Prets: [
            {
             NumPret: 1011,
             montantOp: 10000.5,
             dateEffet: new Date("2023-01-10"),
             duree: "24 mois",
             typePret: "ANSEJ",
             tauxInteret: 5.5,
             montantEcheance: 500.5,
             NumCompte: 9
            },
            {
             NumPret: 1032,
             montantOp: 8000.5,
             dateEffet: new Date("2022-08-15"),
             duree: "12 mois",
             typePret: "ANSEJ",
             tauxInteret: 6.8,
             montantEcheance: 600.5,
             NumCompte: 9
            }
        ]
    },
    {
       NumCompte: 10,
       dateOuverture: new Date("2015-05-15"),
       etatCompte: "Bloque",
       Solde: 0.0,
       NumAgence: 102,
       Client: {
          NumClient: 133,
          NomClient: "LEE Doe",
          TypeClient: "Entreprise",
          adresseClient: "123 Main St",
          numtel: "0512945878",
          email: "alee@example.com"
        },
       Operations: [
            {
             NumOperation: 20324,
             natureOp: "Credit",
             montantOp: 2000.5,
             dateOp: new Date("2022-03-20"),
             observation: "Deposit",
             NumCompte: 10
            },
            {
             NumOperation: 2062,
             natureOp: "Debit",
             montantOp: 1000.5,
             dateOp: new Date("2022-03-25"),
             observation: "Withdrawal",
             NumCompte: 10
            }
        ],
       Prets: [
            {
             NumPret: 2334,
             montantOp: 10000.5,
             dateEffet: new Date("2023-01-10"),
             duree: "24 mois",
             typePret: "ANSEJ",
             tauxInteret: 5.5,
             montantEcheance: 500.5,
             NumCompte: 10
            },
            {
             NumPret: 1032,
             montantOp: 8000.5,
             dateEffet: new Date("2022-08-15"),
             duree: "12 mois",
             typePret: "ANSEJ",
             tauxInteret: 6.8,
             montantEcheance: 600.5,
             NumCompte: 10
            }
        ]
    }
])
 
 function generatePhoneNumber() {
     const prefixes = ['05', '06', '07'
    ];
     const prefix = prefixes[Math.floor(Math.random() * prefixes.length)
    ];
     const remainingDigits = Math.random().toString().slice(2,
    10);
     return prefix + remainingDigits;
}
 function generateRandomAddress() {
     const addresses = [
        "Algiers",
        "Oran",
        "Constantine",
        "Tizi Ouzou",
        "Annaba",
        "Batna",
        "Tlemcen",
        "Sétif",
        "Béjaïa",
        "Blida",
        "Chlef",
        "Sidi Bel Abbès",
        "Biskra",
        "Tébessa",
        "El Oued",
        "Skikda",
        "Tiaret",
        "Béchar",
        "Guelma",
        "Khenchela",
        "Souk Ahras",
        "Tindouf",
        "El Bayadh",
        "M'Sila",
        "Ouargla",
        "Saida",
        "Illizi",
        "Bordj Bou Arréridj",
        "Boumerdès",
        "El Tarf",
        "Tissemsilt",
        "Khenchela",
        "Relizane"
    ];
     return addresses[Math.floor(Math.random() * addresses.length)
    ];
}
 
 function generateRandomDate(start, end) {
     return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}
 const sampleData = [];
 for (let i = 0; i < 90; i++) {
     const numCompte = 3000 + i;
     const dateOuverture = generateRandomDate(new Date(2015,
    0,
    1), new Date(2024,
    11,
    31));
     const dateCouverture = new Date(dateOuverture.getTime() - Math.random() * (365 * 24 * 60 * 60 * 1000));
     const dateEffet = new Date(dateCouverture.getTime() + Math.random() * (365 * 24 * 60 * 60 * 1000));
     const phoneNumber = generatePhoneNumber();
 
     const client = {
         NumClient: 1000 + Math.floor(Math.random() * 100), 
         NomClient: generateRandomAddress(), 
         TypeClient: Math.random() < 0.5 ? "Particulier": "Entreprise",
         adresseClient: generateRandomAddress(),
         numtel: phoneNumber,
         email: `client${i
        }@example.com`
    };
 
     const operations = [];
     const numOperations = Math.floor(Math.random() * 3) + 0;
     for (let j = 0; j < numOperations; j++) {
         const numOperation = j + i+1000;
         const natureOp = Math.random() < 0.5 ? "Credit": "Debit";
         const montantOp = parseFloat(((Math.floor(Math.random() * 1000) + Math.random()) + 0.1).toFixed(2)); 
         const dateOp = generateRandomDate(new Date(2015,
        0,
        1), new Date(2024,
        11,
        31));
         const observation = `Operation ${numOperation
        }`;
 
         operations.push({
             NumOperation: numOperation,
             natureOp: natureOp,
             montantOp: montantOp,
             dateOp: dateOp,
             observation: observation,
             NumCompte: numCompte
        });
    }
 
     const prets = [];
     const numPrets = Math.floor(Math.random() * 3)+0;  
     for (let k = 0; k < numPrets; k++) {
         const numPret = k + i+1000;
         const montantPret = parseFloat(((Math.floor(Math.random() * 1000) + Math.random()) + 0.1).toFixed(2)); 
         const dateEffetPret = generateRandomDate(dateEffet, new Date(2024,
        11,
        31));
         const duree = Math.floor(Math.random() * 5) + 1 + " years";
         const typePret = [
            "Vehicule",
            "Immobilier",
            "ANSEJ",
            "ANJEM"
        ][Math.floor(Math.random() * 4)
        ];
         const tauxInteret =  parseFloat((Math.floor(Math.random() * 10) + Math.random()).toFixed(2));
         const montantEcheance =parseFloat(((Math.floor(Math.random() * 1000) + Math.random()) + 0.1).toFixed(2)); 
         prets.push({
             NumPret: numPret,
             montantOp: montantPret,
             dateEffet: dateEffetPret,
             duree: duree,
             typePret: typePret,
             tauxInteret: tauxInteret,
             montantEcheance: montantEcheance,
             NumCompte: numCompte
        });
    }
 
     const numAgence = Math.floor(Math.random() * 30) + 101; 
 
     sampleData.push({
         NumCompte: numCompte,
         dateOuverture: dateOuverture,
         etatCompte: "Actif",
         Solde: parseFloat((Math.random() * 5000).toFixed(1)),
         NumAgence: numAgence,
         Client: client,
         Operations: operations,
         Prets: prets
    });
}
 db.Compte.insertMany(sampleData);
 
