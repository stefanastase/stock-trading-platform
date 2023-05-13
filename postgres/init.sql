CREATE TABLE IF NOT EXISTS clients (
    "ID" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "ClientID" character varying(128) COLLATE pg_catalog."default" NOT NULL,
    "ClientSecret" character varying(256) COLLATE pg_catalog."default" NOT NULL,
    "IsAdmin" boolean NOT NULL,
    CONSTRAINT clients_pkey PRIMARY KEY ("ID"),
    CONSTRAINT "ClientID" UNIQUE ("ClientID")
);

CREATE TABLE IF NOT EXISTS blacklist (
    "token" character varying(256) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "token" UNIQUE ("token") 
);

CREATE DATABASE portfolios;

CREATE DATABASE orders;

\connect orders

CREATE TABLE IF NOT EXISTS placed (
    "ID" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 1000 CACHE 1 ),
    "ClientID" character varying(128) COLLATE pg_catalog."default" NOT NULL,
    "Symbol" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "Type" character(1) COLLATE pg_catalog."default" NOT NULL,
    "Quantity" integer  NOT NULL,
    "Price" real NOT NULL,
    "PlacedAt" timestamp NOT NULL,
    CONSTRAINT placed_pkey PRIMARY KEY ("ID")
);

CREATE INDEX placed_symbol
ON placed("Symbol");

CREATE INDEX placed_client
ON placed("ClientID");

CREATE TABLE IF NOT EXISTS executed(
    "ID" integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 1000 CACHE 1 ),
    "ClientID" character varying(128) COLLATE pg_catalog."default" NOT NULL,
    "Symbol" character varying(10) COLLATE pg_catalog."default" NOT NULL,
    "Type" character(1) COLLATE pg_catalog."default" NOT NULL,
    "Quantity" integer  NOT NULL,
    "Price" real NOT NULL,
    "ExecutedAt" timestamp NOT NULL,
    CONSTRAINT executed_pkey PRIMARY KEY ("ID")
);

CREATE INDEX executed_symbol
ON executed("Symbol");

CREATE INDEX executed_client
ON executed("ClientID");