--
-- PostgreSQL database cluster dump
--

-- Started on 2026-09-16 22:31:44

\restrict b7HJLzSZBvjn6rdYjiEE9uhzYv1EX82BHgYs52bNyoDXwg3520S1OYhMIiXQ0NY

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;

--
-- User Configurations
--








\unrestrict b7HJLzSZBvjn6rdYjiEE9uhzYv1EX82BHgYs52bNyoDXwg3520S1OYhMIiXQ0NY

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict hlqKqxD4muBl69rJdEiPD0kyIjg8f5ZQSOzdgbuPSizwF5csLsQRPunhMSwDK9C

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-09-16 22:31:44

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2026-09-16 22:31:45

--
-- PostgreSQL database dump complete
--

\unrestrict hlqKqxD4muBl69rJdEiPD0kyIjg8f5ZQSOzdgbuPSizwF5csLsQRPunhMSwDK9C

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict gzHpgdGIOObDZ2qZUgqIhAGXq3C8Dq4ZUycaEV2dCNKqeP5GIoZ7AU6nwt0nNzV

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-09-16 22:31:45

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 16386)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5095 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 16522)
-- Name: contracts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contracts (
    id integer NOT NULL,
    cafeicultor_id uuid,
    apicultor_id uuid,
    status character varying(50) DEFAULT 'PENDENTE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    quantidade_colmeias integer DEFAULT 0,
    valor_total numeric(10,2) DEFAULT 0.00,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contracts OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16521)
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contracts_id_seq OWNER TO postgres;

--
-- TOC entry 5096 (class 0 OID 0)
-- Dependencies: 223
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contracts_id_seq OWNED BY public.contracts.id;


--
-- TOC entry 222 (class 1259 OID 16501)
-- Name: productivity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.productivity_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    contract_id uuid NOT NULL,
    log_date date NOT NULL,
    estimated_yield numeric(10,2),
    actual_yield numeric(10,2),
    notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.productivity_logs OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16443)
-- Name: properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.properties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(150) NOT NULL,
    type character varying(20) NOT NULL,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    area_size numeric(10,2),
    address_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT properties_type_check CHECK (((type)::text = ANY ((ARRAY['FAZENDA'::character varying, 'APIARIO'::character varying])::text[])))
);


ALTER TABLE public.properties OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16424)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    phone character varying(20),
    document character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    location character varying(150),
    total_colmeias integer DEFAULT 0,
    preco_por_colmeia numeric(10,2) DEFAULT 50.00,
    latitude numeric(10,8),
    longitude numeric(10,8),
    city character varying(100),
    state character varying(5),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['CAFEICULTOR'::character varying, 'APICULTOR'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 4914 (class 2604 OID 16525)
-- Name: contracts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contracts ALTER COLUMN id SET DEFAULT nextval('public.contracts_id_seq'::regclass);


--
-- TOC entry 5089 (class 0 OID 16522)
-- Dependencies: 224
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.contracts (id, cafeicultor_id, apicultor_id, status, created_at, quantidade_colmeias, valor_total, updated_at) FROM stdin;
7	e6762a8d-fac7-4419-9d33-eaa6dd90760c	e905cd59-a956-49b2-8cb0-0955d2c7497e	FINALIZADO	2026-09-14 23:27:46.062666	10	700.00	2026-09-15 22:00:44.295612
10	e6762a8d-fac7-4419-9d33-eaa6dd90760c	ef97a049-64e7-4f3c-86d3-22a44dfe9e99	RECUSADO	2026-09-15 23:14:15.02152	0	0.00	2026-09-15 23:18:55.585938
14	e6762a8d-fac7-4419-9d33-eaa6dd90760c	ef97a049-64e7-4f3c-86d3-22a44dfe9e99	FINALIZADO	2026-09-16 19:26:45.361751	105	5250.00	2026-09-16 20:18:33.69124
16	e6762a8d-fac7-4419-9d33-eaa6dd90760c	e905cd59-a956-49b2-8cb0-0955d2c7497e	FINALIZADO	2026-09-16 21:45:21.75393	205	14350.00	2026-09-16 21:50:16.282912
17	e6762a8d-fac7-4419-9d33-eaa6dd90760c	e905cd59-a956-49b2-8cb0-0955d2c7497e	FINALIZADO	2026-09-16 22:11:26.237039	91	6370.00	2026-09-16 22:15:00.520435
\.


--
-- TOC entry 5087 (class 0 OID 16501)
-- Dependencies: 222
-- Data for Name: productivity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.productivity_logs (id, contract_id, log_date, estimated_yield, actual_yield, notes, created_at) FROM stdin;
\.


--
-- TOC entry 5086 (class 0 OID 16443)
-- Dependencies: 221
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.properties (id, user_id, name, type, latitude, longitude, area_size, address_notes, created_at) FROM stdin;
\.


--
-- TOC entry 5085 (class 0 OID 16424)
-- Dependencies: 220
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, full_name, email, password_hash, role, phone, document, created_at, location, total_colmeias, preco_por_colmeia, latitude, longitude, city, state) FROM stdin;
e6762a8d-fac7-4419-9d33-eaa6dd90760c	João (Fazenda Esperança)	joao@fazenda.com.br	123456	CAFEICULTOR	\N	\N	2026-09-11 21:41:39.404328-03	Morungaba, SP	0	50.00	\N	\N	\N	\N
e905cd59-a956-49b2-8cb0-0955d2c7497e	Pedro	pedro@abelha.com.br	654321	APICULTOR	\N	\N	2026-09-12 16:59:08.823911-03	Amparo, SP	346	70.00	-22.70110000	-46.76470000	Amparo	SP
ef97a049-64e7-4f3c-86d3-22a44dfe9e99	Laryssa	laryssa@beemovie.com.br	1234567	APICULTOR	\N	\N	2026-09-12 21:52:13.807439-03	Mogi Mirim SP	457	90.00	-22.43320000	-46.95990000	Mogi Mirim	SP
\.


--
-- TOC entry 5097 (class 0 OID 0)
-- Dependencies: 223
-- Name: contracts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.contracts_id_seq', 17, true);


--
-- TOC entry 4934 (class 2606 OID 16530)
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- TOC entry 4932 (class 2606 OID 16512)
-- Name: productivity_logs productivity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productivity_logs
    ADD CONSTRAINT productivity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4930 (class 2606 OID 16458)
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- TOC entry 4923 (class 2606 OID 16442)
-- Name: users users_document_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_document_key UNIQUE (document);


--
-- TOC entry 4925 (class 2606 OID 16440)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 4927 (class 2606 OID 16438)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4928 (class 1259 OID 16518)
-- Name: idx_properties_coords; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_properties_coords ON public.properties USING btree (latitude, longitude);


--
-- TOC entry 4936 (class 2606 OID 16536)
-- Name: contracts contracts_apicultor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_apicultor_id_fkey FOREIGN KEY (apicultor_id) REFERENCES public.users(id);


--
-- TOC entry 4937 (class 2606 OID 16531)
-- Name: contracts contracts_cafeicultor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_cafeicultor_id_fkey FOREIGN KEY (cafeicultor_id) REFERENCES public.users(id);


--
-- TOC entry 4935 (class 2606 OID 16459)
-- Name: properties properties_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2026-09-16 22:31:46

--
-- PostgreSQL database dump complete
--

\unrestrict gzHpgdGIOObDZ2qZUgqIhAGXq3C8Dq4ZUycaEV2dCNKqeP5GIoZ7AU6nwt0nNzV

-- Completed on 2026-09-16 22:31:46

--
-- PostgreSQL database cluster dump complete
--

