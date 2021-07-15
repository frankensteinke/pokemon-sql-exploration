DROP TABLE Pokemon
DROP TABLE Types
DROP TABLE PokemonTypes

USE Pokedex
GO

--
-- create tables
--

CREATE TABLE Pokemon (
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PokedexId INT NOT NULL,
    Name NVARCHAR(255) NOT NULL,
    HP INT NOT NULL,
    Attack INT NOT NULL,
    Defense INT NOT NULL, 
    SpAttack INT NOT NULL,
    SpDefense INT NOT NULL,
    Speed INT NOT NULL
)

CREATE TABLE Types (
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL
)

CREATE TABLE PokemonTypes (
    PokemonId INT NOT NULL,
    TypeId INT NOT NULL
)

GO

--
-- read json data set
--

DECLARE @JSON VARCHAR(MAX)

SELECT @JSON = BulkColumn
FROM OPENROWSET 
(BULK '.\pokedex.json', SINGLE_CLOB) 
AS j

SELECT ISJSON(@JSON) 
If (ISJSON(@JSON)=1)

CREATE TABLE TempPokemon (
    Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PokedexId INT NOT NULL,
    Name NVARCHAR(255) NOT NULL,
    HP INT NOT NULL,
    Attack INT NOT NULL,
    Defense INT NOT NULL, 
    SpAttack INT NOT NULL,
    SpDefense INT NOT NULL,
    Speed INT NOT NULL,
    TypeName VARCHAR(255) NOT NULL
)

--
-- populate temp table
--

INSERT INTO TempPokemon
SELECT PokedexId, Name, HP, Attack, Defense, SpAttack, SpDefense, Speed, TypeName
FROM OPENJSON (@JSON)
WITH (
    PokedexId VARCHAR(7) '$.id',
    Name VARCHAR(255) '$.name.english',
    HP INT '$.base.HP',
    Attack INT '$.base.Attack',
    Defense INT '$.base.Defense',
    SpAttack INT '$.base."Sp. Attack"',
    SpDefense INT '$.base."Sp. Defense"',
    Speed INT '$.base.Speed',
    TypesJson NVARCHAR(MAX) '$.type' AS JSON
)
CROSS APPLY OPENJSON(TypesJson) WITH (
    TypeName VARCHAR(255) '$'
)

-- 
-- populate real tables
--

INSERT INTO Types (Name)
SELECT DISTINCT TypeName FROM TempPokemon

INSERT INTO PokemonTypes (PokemonId, TypeId)
SELECT TempPokemon.PokedexId, Types.Id
  FROM TempPokemon
  RIGHT JOIN Types on TempPokemon.TypeName = Types.Name

INSERT INTO Pokemon
SELECT DISTINCT PokedexId, Name, HP, Attack, SpAttack, Defense, SpDefense, Speed
    FROM TempPokemon

--
-- clean up
--

DROP Table TempPokemon