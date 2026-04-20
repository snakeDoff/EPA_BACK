--
-- PostgreSQL database dump
--

\restrict USbLq8dH2YmfvmmvSRGzNPGZTbqHzmQlWIqrkuvPgTve9rhrrRx32gzqkfQgF7y

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: attestation_commissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attestation_commissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attestation_period_id uuid NOT NULL,
    department_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying NOT NULL,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_attestation_commissions_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'formed'::character varying, 'completed'::character varying])::text[])))
);


ALTER TABLE public.attestation_commissions OWNER TO postgres;

--
-- Name: attestation_criteria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attestation_criteria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(500) NOT NULL,
    description text,
    evaluation_type character varying(50) NOT NULL,
    max_score numeric(6,2),
    unit_label character varying(100),
    checked_by_student boolean DEFAULT false NOT NULL,
    checked_by_supervisor boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_attestation_criteria_checked_by_someone CHECK ((checked_by_student OR checked_by_supervisor)),
    CONSTRAINT chk_attestation_criteria_evaluation_type CHECK (((evaluation_type)::text = ANY ((ARRAY['score'::character varying, 'boolean'::character varying, 'count'::character varying])::text[]))),
    CONSTRAINT chk_attestation_criteria_max_score_non_negative CHECK (((max_score IS NULL) OR (max_score >= (0)::numeric))),
    CONSTRAINT chk_attestation_criteria_score_requires_max_score CHECK (((((evaluation_type)::text = 'score'::text) AND (max_score IS NOT NULL)) OR ((evaluation_type)::text = ANY ((ARRAY['boolean'::character varying, 'count'::character varying])::text[]))))
);


ALTER TABLE public.attestation_criteria OWNER TO postgres;

--
-- Name: attestation_criterion_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attestation_criterion_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    period_type character varying(50) NOT NULL,
    program_duration_years integer NOT NULL,
    course integer NOT NULL,
    season character varying(20) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_criterion_templates_course_positive CHECK ((course >= 1)),
    CONSTRAINT chk_criterion_templates_period_type CHECK (((period_type)::text = ANY ((ARRAY['attestation'::character varying, 'department_seminar'::character varying])::text[]))),
    CONSTRAINT chk_criterion_templates_program_duration CHECK ((program_duration_years = ANY (ARRAY[3, 4]))),
    CONSTRAINT chk_criterion_templates_season CHECK (((season)::text = ANY ((ARRAY['spring'::character varying, 'autumn'::character varying])::text[])))
);


ALTER TABLE public.attestation_criterion_templates OWNER TO postgres;

--
-- Name: attestation_periods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attestation_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    year integer NOT NULL,
    season character varying(20) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_attestation_periods_dates CHECK ((start_date <= end_date)),
    CONSTRAINT chk_attestation_periods_season CHECK (((season)::text = ANY ((ARRAY['spring'::character varying, 'autumn'::character varying])::text[]))),
    CONSTRAINT chk_attestation_periods_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'active'::character varying, 'completed'::character varying, 'archived'::character varying])::text[]))),
    CONSTRAINT chk_attestation_periods_type CHECK (((type)::text = ANY ((ARRAY['attestation'::character varying, 'department_seminar'::character varying])::text[]))),
    CONSTRAINT chk_attestation_periods_year CHECK ((year >= 2000))
);


ALTER TABLE public.attestation_periods OWNER TO postgres;

--
-- Name: commission_member_criterion_evaluations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.commission_member_criterion_evaluations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_evaluation_id uuid CONSTRAINT commission_member_criterion_evalu_member_evaluation_id_not_null NOT NULL,
    student_attestation_criterion_id uuid CONSTRAINT commission_member_criterion_student_attestation_criter_not_null NOT NULL,
    evaluation_type character varying(50) CONSTRAINT commission_member_criterion_evaluation_evaluation_type_not_null NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    score_value numeric(6,2),
    boolean_value boolean,
    count_value integer,
    comment text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_member_crit_evals_count_nonneg CHECK (((count_value IS NULL) OR (count_value >= 0))),
    CONSTRAINT chk_member_crit_evals_score_nonneg CHECK (((score_value IS NULL) OR (score_value >= (0)::numeric))),
    CONSTRAINT chk_member_crit_evals_type CHECK (((evaluation_type)::text = ANY ((ARRAY['score'::character varying, 'boolean'::character varying, 'count'::character varying])::text[])))
);


ALTER TABLE public.commission_member_criterion_evaluations OWNER TO postgres;

--
-- Name: commission_member_evaluations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.commission_member_evaluations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_attestation_id uuid NOT NULL,
    commission_member_id uuid NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying NOT NULL,
    overall_comment text,
    overall_recommendation character varying(50),
    submitted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_member_evals_recommendation CHECK (((overall_recommendation IS NULL) OR ((overall_recommendation)::text = ANY ((ARRAY['passed'::character varying, 'passed_conditionally'::character varying, 'revision_required'::character varying, 'not_passed'::character varying])::text[])))),
    CONSTRAINT chk_member_evals_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'submitted'::character varying])::text[])))
);


ALTER TABLE public.commission_member_evaluations OWNER TO postgres;

--
-- Name: commission_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.commission_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    commission_id uuid NOT NULL,
    staff_member_id uuid NOT NULL,
    role_in_commission character varying(50) NOT NULL,
    membership_type character varying(50) NOT NULL,
    is_voting_member boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_commission_members_membership_type CHECK (((membership_type)::text = ANY ((ARRAY['mandatory'::character varying, 'additional'::character varying])::text[]))),
    CONSTRAINT chk_commission_members_role CHECK (((role_in_commission)::text = ANY ((ARRAY['chair'::character varying, 'deputy_chair'::character varying, 'member'::character varying, 'secretary'::character varying])::text[])))
);


ALTER TABLE public.commission_members OWNER TO postgres;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    short_name character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: education_programs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.education_programs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(500) NOT NULL,
    short_name character varying(255),
    duration_years smallint NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_education_programs_duration CHECK ((duration_years = ANY (ARRAY[3, 4])))
);


ALTER TABLE public.education_programs OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: staff_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    department_id uuid,
    last_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    position_title character varying(255),
    academic_degree character varying(255),
    academic_title character varying(255),
    regalia_text text,
    email character varying(255),
    phone character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    can_be_commission_member boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.staff_members OWNER TO postgres;

--
-- Name: student_attestation_criteria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_attestation_criteria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    student_attestation_id uuid NOT NULL,
    template_criterion_id uuid NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(500) NOT NULL,
    description text,
    evaluation_type character varying(50) NOT NULL,
    max_score numeric(6,2),
    unit_label character varying(100),
    checked_by_student boolean DEFAULT false NOT NULL,
    checked_by_supervisor boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    CONSTRAINT chk_student_attestation_criteria_checked_by_someone CHECK ((checked_by_student OR checked_by_supervisor)),
    CONSTRAINT chk_student_attestation_criteria_evaluation_type CHECK (((evaluation_type)::text = ANY ((ARRAY['score'::character varying, 'boolean'::character varying, 'count'::character varying])::text[]))),
    CONSTRAINT chk_student_attestation_criteria_max_score_non_negative CHECK (((max_score IS NULL) OR (max_score >= (0)::numeric))),
    CONSTRAINT chk_student_attestation_criteria_score_requires_max_score CHECK (((((evaluation_type)::text = 'score'::text) AND (max_score IS NOT NULL)) OR ((evaluation_type)::text = ANY ((ARRAY['boolean'::character varying, 'count'::character varying])::text[]))))
);


ALTER TABLE public.student_attestation_criteria OWNER TO postgres;

--
-- Name: student_attestations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_attestations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attestation_period_id uuid NOT NULL,
    student_id uuid NOT NULL,
    department_id uuid NOT NULL,
    supervisor_user_id uuid,
    criterion_template_id uuid NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying NOT NULL,
    is_admitted boolean DEFAULT false NOT NULL,
    admission_comment text,
    debt_note text,
    final_decision character varying(50),
    final_comment text,
    result_sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    commission_id uuid,
    CONSTRAINT chk_student_attestations_final_decision CHECK (((final_decision IS NULL) OR ((final_decision)::text = ANY ((ARRAY['passed'::character varying, 'passed_conditionally'::character varying, 'revision_required'::character varying, 'not_passed'::character varying])::text[])))),
    CONSTRAINT chk_student_attestations_status CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'admitted'::character varying, 'ready_for_commission'::character varying, 'scheduled'::character varying, 'attested'::character varying, 'result_sent'::character varying])::text[])))
);


ALTER TABLE public.student_attestations OWNER TO postgres;

--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    last_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    email character varying(255),
    admission_year integer,
    course integer NOT NULL,
    funding_type character varying(100),
    specialty character varying(255),
    academic_status character varying(100) NOT NULL,
    department_id uuid NOT NULL,
    supervisor_user_id uuid,
    supervisor_name_raw character varying(255),
    dissertation_topic text,
    status_change_reason text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    education_program_id uuid,
    education_program_raw character varying(500),
    CONSTRAINT chk_students_admission_year CHECK (((admission_year IS NULL) OR (admission_year >= 2000))),
    CONSTRAINT chk_students_course_positive CHECK ((course >= 1))
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    department_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255),
    last_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    middle_name character varying(100),
    is_active boolean DEFAULT true NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
0008_member_eval
\.


--
-- Data for Name: attestation_commissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attestation_commissions (id, attestation_period_id, department_id, name, status, notes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attestation_criteria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attestation_criteria (id, template_id, code, name, description, evaluation_type, max_score, unit_label, checked_by_student, checked_by_supervisor, sort_order, is_active, created_at, updated_at) FROM stdin;
f7a09587-ddb6-4c62-b0e1-06cf6a27482b	eb24af64-936a-4032-99b3-5b0cbe8901f3	c01	Актуальность исследования	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bc10c54b-240a-480d-b7c3-3f784fc14e83	eb24af64-936a-4032-99b3-5b0cbe8901f3	c02	Научная гипотеза (центральная идея исследования)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
26be1943-4477-419b-aacf-ce75ce1171f3	eb24af64-936a-4032-99b3-5b0cbe8901f3	c03	Степень разработанности научной задачи	\N	score	3.00	баллы	t	f	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
5a2ef429-330b-4662-9b12-c6a89ba5b34d	eb24af64-936a-4032-99b3-5b0cbe8901f3	c04	Постановка научной задачи	\N	score	3.00	баллы	f	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
364bae08-75fa-4aa2-9dc6-4b1a815e1a32	eb24af64-936a-4032-99b3-5b0cbe8901f3	c05	Цель исследования	\N	score	3.00	баллы	f	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
0e7989db-3e9c-499d-a67d-baad3f72c2bf	eb24af64-936a-4032-99b3-5b0cbe8901f3	c06	Задачи исследования	\N	score	3.00	баллы	f	t	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
90f0faca-6beb-4662-9d1b-2d87cb9090d7	eb24af64-936a-4032-99b3-5b0cbe8901f3	c07	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e9e58bb0-5cd6-4127-ab4c-cc623f7c3312	eb24af64-936a-4032-99b3-5b0cbe8901f3	c08	Объект исследования	\N	boolean	\N	да/нет	f	t	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
998f43c8-e747-49e2-a809-16ad46af4a79	eb24af64-936a-4032-99b3-5b0cbe8901f3	c09	Предмет исследования	\N	boolean	\N	да/нет	f	t	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
23dc3d85-1e90-4c61-a629-c8986bf4544a	eb24af64-936a-4032-99b3-5b0cbe8901f3	c10	Методология и методы исследования	\N	boolean	\N	да/нет	f	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9b074c56-c8da-4944-a299-e02f9dcadcbc	eb24af64-936a-4032-99b3-5b0cbe8901f3	c11	Планируемая научная новизна	\N	boolean	\N	да/нет	f	t	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bd54ba19-221a-41fa-ba80-ece7db1c27f5	eb24af64-936a-4032-99b3-5b0cbe8901f3	c12	Планируемая научная ценность	\N	boolean	\N	да/нет	f	t	12	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
3391cd85-377b-429d-bab0-a1de90b7adbf	eb24af64-936a-4032-99b3-5b0cbe8901f3	c13	Research Proposal	\N	boolean	\N	да/нет	t	f	13	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
cd244ff6-c853-420f-98fe-66ce51a034d7	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
59661eec-2289-4325-b42b-33a6a8a81f5c	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
71c3829d-35a8-431e-b7d9-b213f94b5669	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f6437630-e26f-439f-9771-2cbe58821abd	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c04	Планируемая научная новизна	\N	score	3.00	баллы	t	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
3c396ca7-77d3-485f-9829-d42e03087823	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c05	Планируемая научная ценность	\N	score	3.00	баллы	t	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
befd9128-0480-48fb-8f57-784436e3ecaa	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ea230d88-60b9-4dfb-ab16-808601a036de	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
013b8807-eaa8-42b3-ae63-0b1a24a39a31	cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	c08	Готовность текста диссертации (минимум 10%)	\N	boolean	\N	да/нет	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e6c1b90e-751c-41fa-ad81-b2810872bd70	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
6521f01b-6665-46f1-b0b9-3ca3cec4a66b	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
06f21a55-7cf5-4fc0-88be-6f7b12797d49	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
0602b1aa-dedb-42e5-9ca2-90963bebbbe6	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f1862b11-fc3d-4f45-b30d-84fbcb5bb6b5	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d6141c4f-054f-475b-ad97-5fc28de84c43	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
62a7e24a-84e8-40b3-8757-6579a8b2efcd	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
72e32cc4-8b6f-4011-9694-ff60685a6e48	ac509c82-3ca5-4c3f-bcb0-80e339bd713d	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
17d12800-d1a3-47f0-af8d-fd3a38a913ed	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ceee267d-8e94-4c33-b1bb-8fe40b4ea7a1	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
5ac0161e-16a0-466f-b8da-e3c2364b70e3	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b75ac725-488f-4752-b7d4-38bc57bb03ba	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
be4b0cd1-afd2-4af8-9b4e-71a2cf5d7444	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
2a7c2e8b-d188-4b8e-be8c-3305b62710b7	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
64091787-bd6a-48e8-a3b4-943912723946	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
0ba50b95-7cfd-469d-9223-c1e64e4b5815	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
52ae6107-b99a-4f9f-ae78-2e94be1d5535	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c09	Готовность текста диссертации (минимум 30%)	\N	boolean	\N	да/нет	t	f	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d1d292b6-1b91-4539-96fd-7bddd92d1af0	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c10	Практическая ценность	\N	score	3.00	баллы	t	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1b2df0f7-829c-43dc-b744-452fb92201d4	81822c61-c92e-40e5-bfd9-ebae92cde3ed	c11	Готовность текста диссертации (минимум 50%)	\N	boolean	\N	да/нет	t	f	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d31f5197-b3fb-4b52-867e-003d866356d7	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c01	Актуальность исследования	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
95b8ec6f-de5a-47f0-91fd-0bbf80329156	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c02	Научная гипотеза (центральная идея исследования)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e5c9d7f5-de71-4cbc-bbb0-26e6b317da5a	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c03	Степень разработанности научной задачи	\N	score	3.00	баллы	t	f	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ec7842f8-23c1-4f19-80ab-a04153710fae	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c04	Постановка научной задачи	\N	score	3.00	баллы	f	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ccc33f9c-0f39-4f51-8b1f-e63c28123949	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c05	Цель исследования	\N	score	3.00	баллы	f	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
523d489c-914c-4fea-b35e-ff9ba9bc8a0d	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c06	Задачи исследования	\N	score	3.00	баллы	f	t	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
862aceb1-008c-430f-942c-d47edabed91e	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c07	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bac9afc0-4fd9-487b-af2c-709a8f630c49	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c08	Объект исследования	\N	boolean	\N	да/нет	f	t	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
12efabf2-1f5f-45bc-8bca-a0ad568ceadf	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c09	Предмет исследования	\N	boolean	\N	да/нет	f	t	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b40d96e3-318f-49cb-96e8-89d566d8ee18	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c10	Методология и методы исследования	\N	boolean	\N	да/нет	f	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bd690c69-e7e8-475c-9ed7-d1c72ace25d0	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c11	Планируемая научная новизна	\N	boolean	\N	да/нет	f	t	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
15e3d14f-a731-4ce7-8123-f53d5893a74c	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c12	Планируемая научная ценность	\N	boolean	\N	да/нет	f	t	12	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
c0fb461f-4c3e-4be2-85ad-a474d81e3b57	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c13	Research Proposal	\N	boolean	\N	да/нет	t	f	13	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
84d2b817-5769-4981-8d04-255a98b8e35e	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c14	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	14	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e32c00b2-e678-4016-ba17-b19fd0fdaf80	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c15	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	15	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a5f92b01-54bb-40cc-8b97-4546c05b94c1	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c16	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	16	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
8fcf1130-3a90-4623-ab3a-f1622f7d195d	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c17	Практическая ценность	\N	score	3.00	баллы	t	t	17	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
319a6a49-af35-47a1-85b4-eeb676e31490	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c18	Готовность текста диссертации (минимум 80%)	\N	boolean	\N	да/нет	t	f	18	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
8afe5c37-6369-4ce1-b67d-7f096741f059	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c19	Содержание автореферата	\N	score	3.00	баллы	t	t	19	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
47a92ef5-9b6e-407b-bf0b-925a9f8122e4	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c20	Заключение организации	\N	boolean	\N	да/нет	t	f	20	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9f1b672f-1f26-4c17-b172-82502ca9fcc6	a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	c21	Дата предзащиты	\N	boolean	\N	да/нет	t	t	21	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1b3855ba-5cad-49bd-8a37-7cd559a7b08a	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c01	Актуальность исследования	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b74eb686-fa44-4a3f-bfff-f01c6a89c5e5	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c02	Научная гипотеза (центральная идея исследования)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f2e680b2-79e8-4622-abae-bd2bc74ace52	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c03	Степень разработанности научной задачи	\N	score	3.00	баллы	t	f	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
dc6852ef-588b-418a-9ea5-36f84ab33cbf	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c04	Постановка научной задачи	\N	score	3.00	баллы	f	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9e5623d9-c3ca-4e5d-967e-84ad80e7410c	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c05	Цель исследования	\N	score	3.00	баллы	f	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
c5df3b93-0271-47f0-b4cb-c431440dced1	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c06	Задачи исследования	\N	score	3.00	баллы	f	t	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d2477b4b-05f2-4157-a5b3-4ac65eded4fa	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c07	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
7d4edfd6-b343-488e-a171-386c731370e4	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c08	Объект исследования	\N	boolean	\N	да/нет	f	t	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b25d7b93-3df3-49e8-95f3-6278af93b0f1	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c09	Предмет исследования	\N	boolean	\N	да/нет	f	t	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ddd71dc1-a388-4985-81b3-41a7b902c904	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c10	Методология и методы исследования	\N	boolean	\N	да/нет	f	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f13fee3a-df14-4614-995e-408286828cb7	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c11	Планируемая научная новизна	\N	boolean	\N	да/нет	f	t	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
48fa8a71-392c-4a1e-9d1f-422ad5465112	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c12	Планируемая научная ценность	\N	boolean	\N	да/нет	f	t	12	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
20f913fa-2a2d-4058-8552-6cf37d2d3e54	e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	c13	Research Proposal	\N	boolean	\N	да/нет	t	f	13	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
aa3bb2fe-9b90-4537-9ff6-71d2c038d3cf	6592513b-2b5b-4163-9e47-21ac287c2f69	c01	Введение в диссертационное исследование (см. п. 7.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1e8c1a35-854d-46a7-9577-bca437f2ef3c	6592513b-2b5b-4163-9e47-21ac287c2f69	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
36cbc8df-e0b4-4e61-84f0-a75d573f68a4	6592513b-2b5b-4163-9e47-21ac287c2f69	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
818c808c-44de-41e3-8196-9c63950eaa85	6592513b-2b5b-4163-9e47-21ac287c2f69	c04	Планируемая научная новизна	\N	score	3.00	баллы	t	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
c146ad30-637e-48b1-89f7-f2aa30e94169	6592513b-2b5b-4163-9e47-21ac287c2f69	c05	Планируемая научная ценность	\N	score	3.00	баллы	t	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
83f935b7-7c00-4c47-a1ce-f9c262ece5b9	6592513b-2b5b-4163-9e47-21ac287c2f69	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
51f7dbb6-5372-4c51-a540-217fbbc534e9	6592513b-2b5b-4163-9e47-21ac287c2f69	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
89fb9b2b-030f-4948-8776-c1920440069d	6592513b-2b5b-4163-9e47-21ac287c2f69	c08	Готовность текста диссертации (минимум 10%)	\N	boolean	\N	да/нет	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
4ce3c826-c9eb-40d0-b3cd-1217d0c8ea1b	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
2e3caad0-6e63-46e2-9cc8-bdd175384c54	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b4255d4a-6081-4d0e-b09d-4a201490f665	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
59010b99-378a-46cf-808b-adeeda29f0a2	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e4e50867-2a59-4f32-91b6-190017900604	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a7755143-c370-4627-9cdd-df2e5171c8b0	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d9ee3151-a254-46f6-9ec3-eec6bf45556c	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a412da24-f6eb-46c5-ae6d-4a95dc20502d	90970bdb-cb6e-456a-963a-db2cd1c6e85b	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
2d623d29-d967-431c-a426-dc86bc445ad4	7e7d6851-70eb-4632-918d-73646eece265	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
0b40d76b-f339-42e0-81c4-eeb7adf0014f	7e7d6851-70eb-4632-918d-73646eece265	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
00e175bd-0f46-4001-bc73-653426545921	7e7d6851-70eb-4632-918d-73646eece265	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
8ed784f8-bc7c-46dd-87ba-dc007ed55e0b	7e7d6851-70eb-4632-918d-73646eece265	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
cd45b604-6fd7-452b-924c-644b9ebfb84f	7e7d6851-70eb-4632-918d-73646eece265	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
89d0fdf0-59be-4219-9373-3de420445a66	7e7d6851-70eb-4632-918d-73646eece265	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b6815eab-3660-4e8b-adbd-66af57867e40	7e7d6851-70eb-4632-918d-73646eece265	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
604dddd6-13e3-47bd-aaa9-9bf32b6274d5	7e7d6851-70eb-4632-918d-73646eece265	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
31a9ec21-b019-4b19-bc34-37f59880b522	7e7d6851-70eb-4632-918d-73646eece265	c09	Готовность текста диссертации (минимум 30%)	\N	boolean	\N	да/нет	t	f	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e7cf32c4-fb59-4066-8dd0-98c9367d2953	7e7d6851-70eb-4632-918d-73646eece265	c10	Практическая ценность	\N	score	3.00	баллы	t	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
6d2fbf53-abe7-4a40-8571-06bf99642469	7e7d6851-70eb-4632-918d-73646eece265	c11	Готовность текста диссертации (минимум 30%)	\N	boolean	\N	да/нет	t	f	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
67ba3a39-cb9a-4662-bb33-8fde893db7eb	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9090bd1c-e7ee-46b5-abf5-a9f8c66f6090	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1c0f34d1-1fc9-4f2e-a64b-bfb19fbc9344	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
d95386d2-cdf4-455a-94d1-2e1ced261f21	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f3bad9ad-3b0c-4dfe-8ab1-8f94695c7765	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
188213ff-c400-4c8a-8131-62faee999b42	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
5b1bdd8a-6f55-4338-ab96-11092814a1e3	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bec28c5d-5648-4c06-80f4-7f02a43345ee	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
3efc210d-12fd-4eb1-a8c8-4e6ac16e1cf4	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c09	Готовность текста диссертации (минимум 30%)	\N	boolean	\N	да/нет	t	f	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
dcbd33d9-4b00-4ba6-bdbf-8ff913811522	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c10	Практическая ценность	\N	score	3.00	баллы	t	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
403a16c1-5835-4f5f-a54d-94aa38dcda2f	015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	c11	Готовность текста диссертации (минимум 50%)	\N	boolean	\N	да/нет	t	f	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
63642e7e-9f00-43c3-bcc1-798305f0979d	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c01	Введение в диссертационное исследование (см. п. 6.1)	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b2e7da17-b8a9-4c19-8079-489fc4c96518	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c02	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9e3e601f-01b2-4f1c-a51c-ebda04b8e894	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c03	Основные полученные научные результаты по диссертации	\N	score	3.00	баллы	t	t	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
71de4cd0-d920-4889-98a4-13c4a49ab7c5	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c04	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
3f8f2d78-7319-42fa-be6f-2fbc5a20f2bb	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c05	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1fae89b1-96fd-4e76-93fc-1c220953d742	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c06	Research Proposal	\N	score	3.00	баллы	t	f	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
14ebcc9b-580c-446d-8504-00252358de53	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c07	Публикация с аффилиацией НИУ ВШЭ	\N	count	\N	шт.	t	f	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a9e41a34-3f40-4279-9c3e-c9eecc62a225	4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	c08	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
10816a7b-8769-4db8-96ba-5d26c3880b7f	1eeccde8-0a26-460a-901e-9c5d898189ac	c01	Актуальность исследования	\N	score	3.00	баллы	t	t	1	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
bfe2f8bf-ed2a-4402-b684-8b3de0806012	1eeccde8-0a26-460a-901e-9c5d898189ac	c02	Научная гипотеза (центральная идея исследования)	\N	score	3.00	баллы	t	t	2	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
44c210fb-98d8-47ce-a8a9-15f4afce8023	1eeccde8-0a26-460a-901e-9c5d898189ac	c03	Степень разработанности научной задачи	\N	score	3.00	баллы	t	f	3	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
8a63db0f-a8fa-4d3e-ae17-837033252676	1eeccde8-0a26-460a-901e-9c5d898189ac	c04	Постановка научной задачи	\N	score	3.00	баллы	f	t	4	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
68f3e350-e298-4252-aedc-f4f747ec793f	1eeccde8-0a26-460a-901e-9c5d898189ac	c05	Цель исследования	\N	score	3.00	баллы	f	t	5	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
cb22d5cd-ba64-42c8-b593-057b95d94e0f	1eeccde8-0a26-460a-901e-9c5d898189ac	c06	Задачи исследования	\N	score	3.00	баллы	f	t	6	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
9daaa370-9c95-48b9-8e8d-4404761930e5	1eeccde8-0a26-460a-901e-9c5d898189ac	c07	Структура исследования (этапы)	\N	score	3.00	баллы	t	t	7	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
6d16c67a-c676-429e-9b89-b1f5f6144c92	1eeccde8-0a26-460a-901e-9c5d898189ac	c08	Объект исследования	\N	boolean	\N	да/нет	f	t	8	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
2e786739-f888-40f0-8675-f75aa0e07102	1eeccde8-0a26-460a-901e-9c5d898189ac	c09	Предмет исследования	\N	boolean	\N	да/нет	f	t	9	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
43c265ca-9792-43c0-8fb6-7d4e7a04a1bb	1eeccde8-0a26-460a-901e-9c5d898189ac	c10	Методология и методы исследования	\N	boolean	\N	да/нет	f	t	10	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
076e95aa-71e9-45db-8722-9e70c2206a15	1eeccde8-0a26-460a-901e-9c5d898189ac	c11	Планируемая научная новизна	\N	boolean	\N	да/нет	f	t	11	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ca46d4c2-57b0-40ec-abee-a02d17925ca8	1eeccde8-0a26-460a-901e-9c5d898189ac	c12	Планируемая научная ценность	\N	boolean	\N	да/нет	f	t	12	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
b1bf85df-b7a1-448e-bd11-b14368cbae48	1eeccde8-0a26-460a-901e-9c5d898189ac	c13	Research Proposal	\N	boolean	\N	да/нет	t	f	13	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
07812bb6-7cc2-4421-9927-df48bce8cdc7	1eeccde8-0a26-460a-901e-9c5d898189ac	c14	Научные публикации: полное библиографическое описание с указанием списков НИУ ВШЭ	\N	count	\N	шт. по каждой категории	t	f	14	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a1b08c03-c009-413c-a65e-7a2ea6a7689b	1eeccde8-0a26-460a-901e-9c5d898189ac	c15	Научный доклад (тезисы, описание) / публикация в материалах конференции	\N	count	\N	шт. по каждой категории	t	f	15	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
517950fc-051b-4d68-80f6-53aa6726431c	1eeccde8-0a26-460a-901e-9c5d898189ac	c16	Научные семинары, конференции, симпозиумы и т.п. (участие с докладом)	\N	count	\N	шт. по каждому пункту	t	f	16	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
f11d1133-76df-4e08-abfd-9283e3b65527	1eeccde8-0a26-460a-901e-9c5d898189ac	c17	Практическая ценность	\N	score	3.00	баллы	t	t	17	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
5b9b08ff-93bf-4fbf-b474-0a364043a443	1eeccde8-0a26-460a-901e-9c5d898189ac	c18	Готовность текста диссертации (минимум 80%)	\N	boolean	\N	да/нет	t	f	18	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
aa0213c0-00cb-466b-92dd-630022dec793	1eeccde8-0a26-460a-901e-9c5d898189ac	c19	Содержание автореферата	\N	score	3.00	баллы	t	t	19	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
8c446c5e-2a84-4f26-bdcd-e747b11cec14	1eeccde8-0a26-460a-901e-9c5d898189ac	c20	Заключение организации	\N	boolean	\N	да/нет	t	f	20	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
c126cbe2-d623-402e-8d9b-d69adfad13b6	1eeccde8-0a26-460a-901e-9c5d898189ac	c21	Дата предзащиты	\N	boolean	\N	да/нет	t	t	21	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
\.


--
-- Data for Name: attestation_criterion_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attestation_criterion_templates (id, name, period_type, program_duration_years, course, season, is_active, created_at, updated_at) FROM stdin;
eb24af64-936a-4032-99b3-5b0cbe8901f3	3 года / 1 курс / весна	attestation	3	1	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
cda1b2ca-bbfe-4046-b28b-fb363f1a68b8	3 года / 1 курс / осень	attestation	3	1	autumn	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
ac509c82-3ca5-4c3f-bcb0-80e339bd713d	3 года / 2 курс / весна	attestation	3	2	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
81822c61-c92e-40e5-bfd9-ebae92cde3ed	3 года / 2 курс / осень	attestation	3	2	autumn	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
a24ea4d6-fbe1-4cb3-9cb1-12ae9a0c514f	3 года / 3 курс / весна	attestation	3	3	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
e4a06329-3e33-4ef8-bf54-0bcd48bd6e54	4 года / 1 курс / весна	attestation	4	1	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
6592513b-2b5b-4163-9e47-21ac287c2f69	4 года / 1 курс / осень	attestation	4	1	autumn	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
90970bdb-cb6e-456a-963a-db2cd1c6e85b	4 года / 2 курс / весна	attestation	4	2	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
7e7d6851-70eb-4632-918d-73646eece265	4 года / 2 курс / осень	attestation	4	2	autumn	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
015a6b9f-e8ba-4ac3-90e5-dfbbbf702a5c	4 года / 3 курс / весна	attestation	4	3	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
4f98f9ae-9565-4f9f-9d9b-4fe8e30732ac	4 года / 3 курс / осень	attestation	4	3	autumn	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
1eeccde8-0a26-460a-901e-9c5d898189ac	4 года / 4 курс / весна	attestation	4	4	spring	t	2026-03-21 02:23:07.669243+03	2026-03-21 02:23:07.669243+03
\.


--
-- Data for Name: attestation_periods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attestation_periods (id, title, type, year, season, start_date, end_date, status, created_by, created_at, updated_at) FROM stdin;
f7492acd-1e28-4ced-95a5-4c17f2faa89e	Промежуточная аттестация, весна 2026	attestation	2026	spring	2026-04-01	2026-05-31	draft	\N	2026-03-21 02:07:13.169385+03	2026-03-21 02:07:13.169385+03
aa5863da-e192-405a-ad33-f3dc2716cbcb	Промежуточная аттестация, осень 2025	attestation	2022	autumn	2025-11-01	2025-12-31	completed	\N	2026-03-21 02:08:26.384868+03	2026-03-21 02:08:26.384868+03
ce2c1ce2-707f-493f-bd83-da40499a0444	Промежуточная аттестация, осень 2025	attestation	2025	autumn	2025-11-01	2025-12-31	completed	\N	2026-03-21 02:08:36.161331+03	2026-03-21 02:08:36.161331+03
\.


--
-- Data for Name: commission_member_criterion_evaluations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.commission_member_criterion_evaluations (id, member_evaluation_id, student_attestation_criterion_id, evaluation_type, sort_order, score_value, boolean_value, count_value, comment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: commission_member_evaluations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.commission_member_evaluations (id, student_attestation_id, commission_member_id, status, overall_comment, overall_recommendation, submitted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: commission_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.commission_members (id, commission_id, staff_member_id, role_in_commission, membership_type, is_voting_member, sort_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (id, name, short_name, is_active, created_at, updated_at) FROM stdin;
5f9cad36-8039-4f00-bbde-ffd562d4ad42	лаборатория вычислительной физики	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
eae424ef-a2bc-40ee-b123-d7c26f87a067	М Аспирантура	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	департамент прикладной математики	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
13602113-fdee-4912-8329-134fe89ffd88	базовая кафедра квантовой оптики и телекоммуникаций ЗАО"Сконтел"	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e3a042ed-2cc9-4755-bbda-bdd594886618	департамент электронной инженерии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	департамент компьютерной инженерии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d8943a07-6ded-46a4-bd9f-06467c9bd094	кафедра компьютерной безопасности	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ff22115c-b406-4a1f-8b2d-b0c70580865f	Международный центр анализа и выбора решений	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4a26e5f6-c3d5-4775-9048-c7cbab744ba1	Международная лаборатория суперкомпьютерного атомистического моделирования и многомасштабного анализа	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
624986ad-1eb4-4539-b566-b4104811ed24	базовая кафедра "Прикладные информационно-коммуникационные средства и системы" (ПИКСиС) федерального государственного бюджетного учреждения науки Вычи	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
08c0b1b0-df06-4d91-84c5-3966397f00ef	международная лаборатория физики элементарных частиц	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
60824b94-83d7-416a-8cc7-a676cd223c91	базовая кафедра информационно-аналитических систем ЗАО "ЕС-лизинг"	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
729d68af-687e-4c7c-9966-0dc64b246395	научно-учебная лаборатория телекоммуникационных систем	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f29d5814-6ef7-42da-8569-538ccc3c0b24	кафедра информационной безопасности киберфизических систем	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3c2dac42-42d2-4ef8-9c4e-ea69c8e2c0a2	М Научная лаборатория Интернета вещей и киберфизических сист1D42	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
499b7bdf-ec63-475c-be90-153786d71e64	департамент программной инженерии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
\.


--
-- Data for Name: education_programs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.education_programs (id, name, short_name, duration_years, is_active, created_at, updated_at) FROM stdin;
5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ	\N	3	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность	\N	3	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния	\N	4	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии	\N	3	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
79b0a241-93a3-49a3-9dd5-34281cc39c6c	Физика элементарных частиц	\N	4	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи	\N	4	t	2026-03-21 01:13:45.616848+03	2026-03-21 01:13:45.616848+03
531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах	\N	4	t	2026-03-21 01:39:20.981726+03	2026-03-21 01:39:20.981726+03
6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования	\N	3	t	2026-03-21 01:41:11.914934+03	2026-03-21 01:41:11.914934+03
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, code, name, description, is_active, created_at, updated_at) FROM stdin;
34cc2977-a701-4652-84db-a71c02eb1593	administrator	Администратор	Полный доступ к системе	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
1c8eeb77-51f2-42cf-aa7f-df1efef88cee	academic_director	Академический директор	Управляет процессом аттестации	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
491f0cff-8226-4b5a-8bc4-a4f2ff4ed4a8	manager	Менеджер	Сопровождает процесс и импортирует студентов	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
c316a60d-f477-4fe5-95f6-5e6f67ce2a3b	department_head	Руководитель подразделения	Руководитель департамента	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
693ca6de-efc3-49ce-a55e-27e6f4af9816	expert	Эксперт	Формирует и сопровождает комиссии	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
eb6b6dec-c9b0-44ba-bc4b-6641effc06d9	secretary	Секретарь	Организует заседания и протоколирование	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
a9a6ae4b-9237-48c9-adf7-f91d34d06333	commission_member	Член комиссии	Оценивает аспирантов	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
276e1911-4243-42a0-9f71-90b853e65b89	supervisor	Научный руководитель	Работает с аспирантами	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
c9543ca4-9271-48d3-9b66-5fbe1926eb5f	student	Аспирант	Участник аттестации	t	2026-03-21 00:22:45.56492+03	2026-03-21 00:22:45.56492+03
\.


--
-- Data for Name: staff_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_members (id, user_id, department_id, last_name, first_name, middle_name, position_title, academic_degree, academic_title, regalia_text, email, phone, is_active, can_be_commission_member, created_at, updated_at) FROM stdin;
fce38c33-4288-4bf2-952a-be7d16448e2e	\N	\N	Иванов	Иван	Иванович	Профессор	д.ф.-м.н.	профессор	д.ф.-м.н., профессор	ivanov@example.com	+79990000000	t	t	2026-03-21 10:53:13.467174+03	2026-03-21 10:53:13.467174+03
\.


--
-- Data for Name: student_attestation_criteria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_attestation_criteria (id, created_at, student_attestation_id, template_criterion_id, code, name, description, evaluation_type, max_score, unit_label, checked_by_student, checked_by_supervisor, sort_order) FROM stdin;
\.


--
-- Data for Name: student_attestations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_attestations (id, attestation_period_id, student_id, department_id, supervisor_user_id, criterion_template_id, status, is_admitted, admission_comment, debt_note, final_decision, final_comment, result_sent_at, created_at, updated_at, commission_id) FROM stdin;
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (id, user_id, last_name, first_name, middle_name, email, admission_year, course, funding_type, specialty, academic_status, department_id, supervisor_user_id, supervisor_name_raw, dissertation_topic, status_change_reason, is_active, created_at, updated_at, education_program_id, education_program_raw) FROM stdin;
0d99da19-9073-4b1a-b64e-fc18d3f3fde2	\N	Антонов	Дмитрий	Андреевич	\N	2024	1	Места с оплатой стоимости обучения на договорной основе	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	5f9cad36-8039-4f00-bbde-ffd562d4ad42	\N	Щур Лев Николаевич	Эволюционные пространственно-распределенные игры с самосогласованными взаимодействиями	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
dc121806-c7c2-4318-b32f-ca2e13f11f30	668d28b4-14e7-4296-95a9-c9ecf27bae61	Буутай	Павел	Николаевич	buutay.p@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
f91c5a61-7f5a-44a1-9405-3090d674b096	e0594942-202d-4832-9e8b-0828ff81d905	Глуховцев	Павел	Игоревич	pi.glukhovtsev@hse.ru	2025	1	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
a6aa75f5-02c7-48a4-ae1f-af7f6bbda940	a69f4709-6530-4ae8-bd8c-3bfa49e50cc1	Измайлов	Рамиль	Ильдарович	rizmajlov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
dfa5c2f1-44b3-457e-a6ae-88ce567e67a4	04205e4f-bc82-4e8e-a8e7-9b2371cac029	Назарьин	Артем	Игоревич	ai.nazarin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
92f9be6d-b6d1-4568-9ee9-4297ae430250	35c23f03-3dad-4fe6-a4bd-7ddaadba055c	Пикуль	Александр	Сергеевич	pikul.a@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
82ce6e66-3a42-443a-bd32-6217b9269cc9	b96f0ac9-430f-40b2-8190-7c0ad7b5e2a0	Рогожин	Платон	Дмитриевич	progozhin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	1.3.15 Физика атомных ядер и элементарных частиц, физика высоких энергий	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	79b0a241-93a3-49a3-9dd5-34281cc39c6c	Физика элементарных частиц
79e78a4d-bd97-4135-960d-2716172a72f6	078ce397-1239-4c77-beac-367801223425	Гаврилов	Дмитрий	Сергеевич	dgavrilov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	1.3.15 Физика атомных ядер и элементарных частиц, физика высоких энергий	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	79b0a241-93a3-49a3-9dd5-34281cc39c6c	Физика элементарных частиц
9e518e81-e5b7-4b0e-ba25-9745f28b337f	51305486-d601-4d6e-9ede-ab24bbe6e8f8	Кунинец	Артем	Андреевич	kuninets.a@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
4eff2580-7bb6-4e38-b177-19c52270b2fb	\N	Мусабаев	Равиль	Рафикович	\N	2021	1	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	\N	\N	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
b15a0045-4660-4cc2-8ea2-8b02477e4bfa	\N	Симонов	Никита	Олегович	\N	2021	1	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Квазистационарная динамика в тонких сверхпроводящих пленках под воздействием высокочастотного поля и детектирование фотонов среднего инфракрасного диапазона	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
186b0bca-ae09-43b8-8244-1e8da2418fd9	\N	Кузин	Алексей	Юрьевич	\N	2021	1	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	\N	\N	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
0e474f8c-20e0-4786-a782-2ad1d82766f1	\N	Нугманов	Артур	Маратович	\N	2021	1	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Разработка и исследование эффективных алгоритмов и протоколов лёгкой криптографии	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
82be6401-2192-4614-a28a-927ae9e5cf06	\N	Рахимова	Диана	Равшан Кизи	\N	2021	1	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Восков Леонид Сергеевич	Исследование и разработка метода сокращения времени процесса проектирования моделей машинного обучения для оконечных устройств Интернета вещей	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
fecca54b-6af9-4497-9e8f-ec9d29152185	\N	Стецкевич	Артемий	Максимович	\N	2023	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Петросянц Константин Орестович	Разработка макромодели операционного усилителя с учетом теплового и радиационного воздействия	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
614ecdde-4f2f-4032-b533-944c794b5d75	\N	Дарханов	Евгений	Владленович	\N	2023	1	Места, обеспеченные государственным финансированием	1.3.8 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бондаренко Геннадий Германович	Разработка устойчивых электропроводящих графен-серебряных чернил для технологий печатной электроники	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
f0526636-f9dc-403f-8503-93d4630e3a71	\N	Петриев	Дмитрий	Николаевич	\N	2021	1	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Сухов Андрей Михайлович	Иерархическая маршрутизация, обеспечивающая сверхмалые задержки для туманных технологий	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
88d2c19e-1fd7-4e95-b8be-b2e589e51481	\N	Белых	Мария	Владимировна	\N	2021	1	Места, обеспеченные государственным финансированием	05.13.01 Системный анализ, управление и обработка инфоpмации (4 года)	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Разработка эффективных алгоритмов распознавания объектов железнодорожной инфраструктуры	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
e921a1c4-1a74-47c6-aacb-fef63c8de27e	\N	Фонарева	Алиса	Вадимовна	\N	2022	1	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Гайдуков Роман Константинович	Математическое моделирование растворения-осаждения при обтекании раствором малых неровностей на поверхности при больших числах Рейнольдса	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
0f8d5002-6ed1-40ea-9f82-8fb473553a1a	\N	Авдеенков	Владимир	Александрович	\N	\N	1	Места, обеспеченные государственным финансированием	2.2.10 Метрология и метрологическое обеспечение	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	\N	\N	Прочее	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
f62cfa25-891c-47a8-860a-4e5a2f252cd0	\N	Семенов	Андрей	Андреевич	\N	2022	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сатанин Аркадий Михайлович	\N	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
c4b85f9d-c059-43a0-b506-befd78f7bbd3	\N	Бараников	Максим	Геннадьевич	\N	2022	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Восков Леонид Сергеевич	Исследование и разработка методов машинного обучения для вычислений на граничных устройствах интернета-вещей	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
fdecd677-7b73-46b1-9e74-ab99e531de11	\N	Полетаев	Михаил	Константинович	\N	2023	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Разработка и исследование методов безопасного совместного доступа к большим данным	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
e007c271-566a-433e-a0aa-98437d92e30d	\N	Головня	Максим	Сергеевич	\N	2023	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Евсютин Олег Олегович	Защита визуальной информации, отображаемой на мониторах и дисплеях автоматизированных рабочих мест и распечатанной на бумажных носителях, с использованием стеганографии	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
40550cc7-1464-41b3-a162-7cb7c7f3d05c	\N	Цой	Марк	Олегович	\N	2023	1	Места, обеспеченные государственным финансированием	2.3.2 Вычислительные системы и их элементы	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Старых Владимир Александрович	Разработка и анализ алгоритмов систем доверенной загрузки компьютера	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
4571c5d6-4983-4fc3-8fbf-0c242b876a4f	\N	Елютин	Вадим	Владимирович	\N	2024	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Лубашевский Игорь Алексеевич	Теплоперенос в живой ткани, контролируемый распределенной саморегуляцией периферийной кровеносной системы со сложной иерархической организацией и нелинейной динамикой	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
599270a5-39ab-46dc-83c4-e799fcc8480e	\N	Лупашко	Роман	Владимирович	\N	2024	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Построение минимальных форм для обфусцированных арифметических алгоритмов	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
ecd8a5a9-902b-47b4-a8ba-4fa2ada30dc7	\N	Бахтин	Павел	Денисович	\N	2020	1	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	\N	\N	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
490a287f-06bf-4aae-a1da-433eabdfd9ff	\N	Титов	Александр	Юрьевич	\N	2022	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Методы обнаружения аномального трафика вещей Актуальность темы диссертационного исследования.	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
c798e150-a1ff-41d5-aa4f-4952ea99b934	0b175853-d521-4c3c-9530-21b8cd1582a7	Тихонов	Руслан	Александрович	tikhonov.r@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
9842e500-9f9d-4eef-a556-8bc608ad8e68	21cd79bf-40a5-4ba4-840f-30a1fea92137	Львов	Андрей	Валерьевич	alvov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
f77eb5b8-9f0f-4d4d-b54a-1ffff3c38a8a	6318b483-1d92-4123-aecc-ce7c81a4a65b	Севрюков	Дмитрий	Олегович	sevriukov.d@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
22c518b2-51e3-4acd-92c7-adada6513f77	7f3651d9-9840-450b-ae7b-b9ea81bac8c4	Ивашенцева	Ирина	Владимировна	ivashentseva.i@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
aca58648-a0ec-4b76-975d-34f9dea4383b	49e6c3e9-f3f3-44e2-9cb0-84a13bc5c478	Махмудов	Тимур	Назимович	makhmudov.t@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
28f03ec7-59b1-46dd-b791-892e458043f3	39225ba0-434a-44ed-b94f-833577f7fcdf	Бондарева	Полина	Игоревна	pbondareva@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
5ed82386-ad37-4af7-8261-b31612ce4f1a	3c77705c-7104-4889-b13d-ae848b2abf76	Лыжин	Илья	Григорьевич	ilyzhin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
77179898-cd97-4d3d-a73e-520337b987dd	\N	Белосевич	Всеволод	Васильевич	\N	2020	1	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Гольцман Григорий Наумович	Рамановский спектрометр на чипе для экспресс диагностики вирусных заболеваний	Прочее	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
2aef0588-04f3-4550-9173-359d4390fb82	\N	Щербаченко	Андрей	Александрович	\N	2023	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Методы синтеза и анализа стойкости постквантовых криптоcистем, основанных на решётках	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
eab3fba6-c4af-4c55-921c-eec891ef7c41	cd2a7faa-0ffc-48a6-82b6-79d29208dc0c	Демидов	Иван	Дмитриевич	demidov.i@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
cf66c7da-4fb6-4ae2-9366-445c064df95f	57d4ed2b-3ce0-4b18-8711-0dd291f2b9d3	Хазбулатов	Артур	Тимурович	khazbulatov.a@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
66826440-243a-4673-a1ed-915d5a6d7768	e9fadfd1-9a60-44c3-92f7-b8a3f808e91f	Добрина	Дарина	Николаевна	dobrina.d@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
38e80058-bc0d-471e-8e02-92681d5dd1ab	b51351d4-8d07-40d9-bcb1-afcc7fa0f795	Никитин	Богдан	Сергеевич	bnikitin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
576038d3-74ff-48bd-b498-7563ebf511ed	fb301a49-0ae0-4a25-9935-2b4114e150f4	Гафурова	Даниэлла	Рафиковна	dgafurova@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
801a2f60-99a7-4f19-bbe1-4b644e6b6673	bce0a8c7-ece9-41bc-ad2a-cdac285d6700	Чашкин	Леонид	Борисович	lchashkin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
8d19b8cb-8c0a-4ff9-9ac3-c22d596e3c2d	366cc3db-2132-45b0-ba16-8fd74e3672f3	Андрианова	Анна	Ивановна	ai.andrianova@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
5c70a2f6-3598-4b6b-8a8f-6c5b547aeb1d	\N	Коваев	Санал	Баатрович	\N	2020	1	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	\N	\N	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
0d6f4388-71a1-43f6-8d7f-114a85443889	ec81e681-7274-4b5e-8e67-9f09f92d6e9e	Романов	Леонид	Андреевич	lromanov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
b4990059-c998-4b8b-80e4-1fe5b7d3642b	47f8bb24-e7bd-4b71-a916-253da3e913fe	Смирнов	Феликс	Александрович	fsmirnov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
cc2b9e2c-8612-46a1-a83a-b648f02c0eb7	accced22-f429-4036-9445-598daeedab8f	Жигалов	Михаил	Андреевич	ma.zhigalov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
ead82e5d-7cd0-45c8-9d0c-faa6347ba410	0e8205d3-f1e4-48fc-ba8e-845893e92d00	Пискунова	Анастасия	Михайловна	azayakina@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
f0239a4f-13c0-483f-98fe-35bb38e9b94a	fbf01f3c-af72-45df-b166-5fb27177cc67	Балескин	Виталий	Андреевич	vbaleskin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
3863f40e-a891-47c4-baa4-bead7663aeae	1f118e86-d828-4156-9ce5-1e13e50d7f01	Терегулов	Тимур	Рафаэльевич	teregulov.t@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
bf52918a-e307-4c72-898a-d091029bafad	dd12ab49-a88e-4ff4-bed3-53c317cbc437	Шмелев	Алексей	Валерьевич	avshmelev@hse.ru	2025	1	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
f17c89a2-1060-4cbc-a711-13168c73d9f1	067de1a4-845c-472e-ab4c-9f2dc707110e	Солдатов	Алексей	Валерьевич	av.soldatov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
2bf91ae7-4a04-45d9-9d00-c612cb7e993d	656c5ead-3d8c-47f6-ac24-8d3decc821b2	Черницин	Игорь	Александрович	iachernitcin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
8552a738-1359-45b3-ad52-7fce00e590d6	\N	Ландер	Леонид	Борисович	\N	2024	1	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Королев Павел Сергеевич	Разработка метода управления надежностью радиотехнических устройств с учетом качества технологического процесса	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
de4c541c-d176-4b70-81b7-ec5c7e40d464	edbaefaa-87b2-44df-b9ee-cbeeeed89697	Котов	Феодосий	Игоревич	fkotov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
18fdd9f8-f024-4ae4-96f2-0dfef786908c	\N	Косырев	Михаил	Ильич	\N	2024	1	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Методы поточного шифрования при передачи данных в системах реального времени	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
6f41bdf9-48ec-471a-8afc-8560fd5b6583	6e17791f-d950-46ed-880d-573b9264f340	Васильева	Виктория	Александровна	vavasileva@hse.ru	2025	1	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
e9e132b4-54a5-4a73-8912-4291ad094782	ac90e7de-7a19-4d7f-82b4-1d8b705e1b34	Люткин	Дмитрий	Алексеевич	d.lyutkin@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
330340a1-2540-4b93-9f7c-32a66910515e	d300fa5d-0067-43c6-becd-f40410c1e61f	Гурский	Анатолий	Сергеевич	agurskii@hse.ru	2025	1	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
cbe13b06-62fa-4fc1-ba50-cc01d766d1de	9f8301ac-ff6c-4d85-af36-357558e4f068	Ефремов	Алексей	Максимович	efremov.a@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
194eb7a7-8cae-4ac8-b211-598e9247e026	4360f575-6088-456d-82fd-72c0bfc31af9	Кувшинов	Алексей	Владимирович	akuvshinov@hse.ru	2025	1	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
216da239-260e-4eaf-9ec1-32ebe183cf13	\N	Трунин	Петр	Алексеевич	\N	2022	1	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Каперко Алексей Федорович	Исследование и разработка физических и математических моделей многокомпонентных тактильных датчиков для очувствления робототехнических устройств	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
32cd4434-1a0e-4355-9b19-9e8c05ba24dd	\N	Нуруллин	Роман	Юрьевич	\N	2020	1	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	\N	\N	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
848d0238-1968-4b80-ab7b-0fd75d335fb4	\N	Шубин	Матвей	Игоревич	\N	2020	1	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	\N	\N	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
d1bdef54-8d6c-45bb-8bf3-10bb903ee746	\N	Маршуд	Баха	-	\N	2025	1	По межправительственным соглашениям	2.3.1 Системный анализ, управление и обработка информации	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
704de4f2-79a6-40cb-9d82-31b441e3f39f	\N	Локон Амескита	Руфино Арольдо	-	\N	2025	1	По межправительственным соглашениям	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	\N	\N	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
ed97ac89-61e8-4180-b81b-bdc270f6eb11	\N	Аль-Онаизан	Мохаммад Хассан Али	-	\N	2023	1	По межправительственным соглашениям	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Вагов Алексей Вячеславович	Микроскопические исследования вихрей в многозонных и топологических сверхпроводниках	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
a8a1778e-afd8-4729-b1c5-26f67522d2de	4e8043d7-bcbe-4347-a77f-85c21d664700	Суховерхова	Диана	Дмитриевна	dsukhoverkhova@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	АА	5f9cad36-8039-4f00-bbde-ffd562d4ad42	\N	Щур Лев Николаевич	Извлечение свойств фазовых переходов первого и второго рода с применением методов машинного обучения	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
f329ed73-8246-4e67-b6c7-ef86a9975aae	0352128d-aa28-4fa8-a8a8-37975bb5a3b2	Душенин	Родион	Николаевич	dushenin.r.n@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	ЕТМА	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Старых Владимир Александрович	Разработка и исследование решения, основанного на технологии блокчейн, для обеспечения прозрачного и эффективного управления товарами на складе	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
f7f801cd-3ed9-4612-9e8c-9b5f7c539085	3a10650c-cc82-436f-b474-4748a4cc4b95	Зубкова	Александра	Ильинична	azubkova@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	ЕТМА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Харитонов Игорь Анатольевич	Разработка методик создания цифровых двойников средствами TCAD и SPICE моделирования для аналого-цифровых ИС, работающих в условиях воздействия внешних факторов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
8f7a7a72-7dcc-4204-8121-f7fd38631588	0dc084de-a19d-4418-83ae-ba5de9fa409e	Ткачев	Даниил	Сергеевич	dtkachev@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	ЕТМА	ff22115c-b406-4a1f-8b2d-b0c70580865f	\N	Алескеров Фуад Таги оглы	Новые индексы центральности, учитывающие групповые влияния, параметры вершин и веса ребер	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
7e246de5-6afd-4b23-9955-a5cbc2068e0e	799579a7-6504-4dfb-9b3c-9ca564e522cd	Мазур	Дарья	Александровна	dmazur@hse.ru	2024	2	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	ЕТМА	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Будков Юрий Алексеевич	Моделирование двойного электрического слоя на границе металл-электролит в рамках теории самосогласованного поля	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
f61b89ca-a528-4d42-b96d-f3b4a7d5adf7	d90dde7a-a9b5-4a43-92f1-1b9f123b0492	Пашковская	Валерия	Дмитриевна	vpashkovskaia@hse.ru	2024	2	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	ЕТМА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Васенко Андрей Сергеевич	Неравновесная динамика вихрей в сверхпроводящих тонких пленках	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
887eb613-5cc9-4c92-96f2-41412c642d07	dbee448c-525f-4aa9-94e5-3721be83afee	Каграманян	Давид	Геворгович	dkagramanyan@hse.ru	2024	2	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	ЕТМА	5f9cad36-8039-4f00-bbde-ffd562d4ad42	\N	Щур Лев Николаевич	Применение методов машинного обучения для исследования свойств композитных материалов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
ec51c8a0-b8a7-4a97-b330-19b0063f7ee7	a1c4465f-d094-4b9a-b17e-7978d835100a	Глушак	Артём	Андреевич	aglushak@hse.ru	2024	2	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	ЕТМА	4a26e5f6-c3d5-4775-9048-c7cbab744ba1	\N	Смирнов Григорий Сергеевич	Многомасштабные модели диффузии и адсорбции в слоистых пластинчатых минералах	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
9a83bcdc-97fe-4d86-83e3-e9d80b450eda	\N	Горчавкина	Анастасия	Александровна	\N	2021	2	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	624986ad-1eb4-4539-b566-b4104811ed24	\N	Сатанин Аркадий Михайлович	Динамические процессы с сверхпроводящем квантовом нейроне с джозефсоновским переходом	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
c454888c-fe0e-44b9-8746-3c0fa6084b6a	\N	Кузнецов	Николай	Сергеевич	\N	2021	2	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белова Мария Владимировна	Интегрируемость и разрешимость нелинейных осцилляторов с полиномиальным затуханием	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
907dd1e1-eb26-403d-9b7c-cc2e4b422b0e	\N	Алексухин	Василий	Игоревич	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Лубенец Елена Рубеновна	Модель оптимального проектирования реализации квантовых гейтов на основе формализма обобщенных векторов Блоха	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
ce671b8f-5ecb-4374-a03d-768dbaf95752	\N	Рахимов	Руслан	Маратович	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Иванов Илья Александрович	Метод топологического проектирования электронных средств с учётом требований по контролепригодности	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
b2a388b4-d925-4902-b715-851a4daee0c7	\N	Леоненко	Алексей	Игоревич	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Разработка методов и алгоритмов конструирования систем машинного обучения для обработки текстовых данных	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
1a9c398c-1426-4d5d-b132-9395eafe118b	\N	Федотов	Георгий	Андреевич	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Конструирование алгоритмов глубокого обучения для обнаружения дипфейков	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
b49dc930-f032-4e21-b4b5-b42a1e1348b6	\N	Горбунов	Иван	Игоревич	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Исследование применения крупных нейронных сетей для анализа звуковых данных	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
bfd554e6-1e24-4825-b6f8-66c8c334375a	\N	Жамкова	Инна	Михайловна	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Разработка эффективных алгоритмов диспетчирования производственных процессов промышленного предприятия	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
6fa233f9-3282-445a-8e9c-2c77efe681cb	\N	Мотайленко	Илья	Александрович	\N	2022	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Методы визуализации результатов суперкомпьютерного моделирования и машинного обучения	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
76bfe77a-532d-418d-ac2a-505480f26565	\N	Ковалев	Даниил	Юрьевич	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Метод формальной верификации программного обеспечения, используемого на ранних этапах загрузки системы	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
7e2a26ae-9d4e-4888-863c-b1259192d064	c189f6a1-387d-450b-9cfc-4abfabff627c	Маринин	Никита	Денисович	marinin.n.d@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Исследование методов обнаружения угроз в 5G-сетях с использованием искусственного интеллекта для IoT-устройств	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
8906cbdd-4980-4623-8e33-1e9ce2ecd283	c1e54bc7-50e4-4dfc-b602-6a95f524b06c	Наумов	Виктор	Владимирович	naumov.v.v@hse.ru	2024	2	Места, обеспеченные государственным финансированием	1.3.15 Физика атомных ядер и элементарных частиц, физика высоких энергий	Нет	08c0b1b0-df06-4d91-84c5-3966397f00ef	\N	Аушев Тагир Абдул-Хамидович	Теоретико-числовые задачи, возникающие в связи с исследованиями в квантовой теории поля на решётке	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	79b0a241-93a3-49a3-9dd5-34281cc39c6c	Физика элементарных частиц
034c30c1-30c9-483f-b50a-2bd436374d31	4e4258fa-2b32-4332-befc-17dfb3c643f8	Муфазалова	Алена	Олеговна	mufazalova.a.o@hse.ru	2024	2	Места, обеспеченные государственным финансированием	1.3.15 Физика атомных ядер и элементарных частиц, физика высоких энергий	Нет	08c0b1b0-df06-4d91-84c5-3966397f00ef	\N	Пахлов Павел Николаевич	Первое измерение абсолютных вероятностей распада Ωc бариона на основе данных экспериментов Belle и Belle-II	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	79b0a241-93a3-49a3-9dd5-34281cc39c6c	Физика элементарных частиц
bfec3a7d-18b9-496d-99eb-408203657791	de19a4d9-4979-4e02-b9b3-73019fd6e077	Доборщук	Владимир	Владимирович	doborschuk.v.v@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Модели передачи сигнала с оптимизацией маршрутов в неназемных сетях связи с применением технологий обучения с подкреплением	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
cd4564bc-d182-4646-ba66-4be820e57970	593f35a4-8185-4174-86f0-d34f2dd887dc	Чимитдоржиев	Нимбу	Баирович	chimitdorzhiev.n.b@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Разработка и исследование методов противодействия мошенничеству на основе глубокого обучения	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
fe47f520-73ce-4b9f-80de-f69b56b5d5b6	c1b76561-e334-40fd-bb39-11edb3e06779	Бобров	Кирилл	Романович	bobrov.k.r@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Разработка и исследование методов защиты информационных каналов беспилотных летательных аппаратов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
39480c77-20a6-4128-8fdf-92e7112a5926	\N	Загвоздина	Ксения	Олеговна	\N	2020	2	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Буровский Евгений Андреевич	Моделирование сложных течений жидкости	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
60d306f6-7eb8-45e2-b88e-3a3363a01531	0f6ff278-d8f1-453e-9ff6-129063586764	Кобцев	Данил	Максимович	dkobtsev@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Ковалюк Вадим Викторович	Управляемый интегрально-оптический гейт слияния со сверхпроводниковыми однофотонными детекторами для квантового вычислителя на фотонах	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4c51e0a0-fc5f-42d9-94ac-cb9c6b8da164	\N	Горбачев	Сергей	Алексеевич	\N	2022	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Трансформация технологии беспроводной сети и беспроводного доступа	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
6e721e22-aa7c-4dc9-961c-1a60dc3447ee	0dda161c-2097-42d5-8ccd-93099a267883	Ерофеева	Анастасия	Романовна	aerofeeva@hse.ru	2024	2	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бондаренко Геннадий Германович	Получение и исследование структуры, фазового состава и физико-химических свойств наноматериалов на основе металлооксидных соединений с высокой сенсорной чувствительностью к активным газам	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
5312ff76-0170-43c4-8a1f-64cc8d503ea2	50f377a0-d51a-4848-bf90-096deacc6742	Ромашихин	Михаил	Юрьевич	romashikhin.m.y@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Романов Александр Юрьевич	Автоматизация проектирования сетей на кристалле с помощью мульти-ПЛИС комплексов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
a33e0d63-75fa-4ac7-8579-86445c20983c	ee4d2239-55fd-4535-8a5b-7aa4e378bc95	Тутаев	Идар	Анзорович	tutaev.i.a@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	60824b94-83d7-416a-8cc7-a676cd223c91	\N	Позин Борис Аронович	Методика автоматизированного динамического тестирования безопасности исполняемого кода веб-приложения в рамках жизненного цикла разработки безопасного программного обеспечения	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
1206c2d1-c23e-4535-a13e-2b08dd691f1e	03d37926-7c62-47ae-8504-c3b4885b1f3b	Коробок	Михаил	Алексеевич	korobok.m.a@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Львов Борис Глебович	Исследование и разработка метода целенаправленного инновационного проектирования источников питания электрической энергии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
3815d72b-96b2-49c1-9a5a-8df2ee9413e3	c45a242e-844a-420b-96ec-e78ce6799ff6	Дырченкова	Юлия	Александровна	dyrchenkova.y.a@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Восков Леонид Сергеевич	Исследование и разработка методов повышения энергоэффективности в низкоскоростных сетях спутникового интернета вещей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
15834d7c-0b02-4a8a-8ba3-5c33def6cbf8	\N	Черемисов	Константин	Аркадьевич	\N	2022	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Разработка и исследование систем группового дистанционного мониторинга	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b8ef1798-116c-4160-abb5-f3a9f750347d	\N	Бахмутский	Михаил	Витальевич	\N	2023	2	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Нефедов Сергей Игоревич	Разработка и исследование нейрокомпьютерных алгоритмов обработки видеоданных для эндодиагностических информационных систем	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
9e742337-8fa2-4386-99a5-d401a10e781f	\N	Прутьянов	Виктор	Владимирович	\N	2023	2	Места, обеспеченные государственным финансированием	2.3.2 Вычислительные системы и их элементы	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Романов Александр Юрьевич	Разработка методов аппаратной реализации детектирования и сопоставления локальных признаков изображений	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
4158d64c-538c-48b8-802d-08c2a5b31c7a	d7633a37-3ac4-451a-83d5-5c757026c1ee	Семичаснов	Илья	Владимирович	isemichasnov@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Система моделирования компьютерных симуляций с применением промптинжиниринга на основе генеративно-нейросетевых технологий	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
3117fe2f-a6ed-453e-8d0a-5ddf8fd8b1f4	85e18513-1b5e-4576-babf-4d68c4ee45e7	Марычева	Светлана	Олеговна	smikhaylova@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Данилов Владимир Григорьевич	Асимптотические решения начальных и краевых задач с дискретными аргументами	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
9936955a-91b1-41ef-a977-1ab6216fc635	b3673547-f4b5-4930-8b9b-ba33cbd6cdd6	Волох	Андрей	Игоревич	volokh.a.i@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Разработка интеграционного модуля для бесперебойного взаимодействия информационных систем государственных предприятий с использованием технологии искусственного интеллекта	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
3e3b159f-62cc-4308-a07d-73210d4058d8	c8917b05-b915-4e7c-bb5c-929c8cd7743a	Егоров	Дмитрий	Сергеевич	dsegorov@hse.ru	2024	2	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	ff22115c-b406-4a1f-8b2d-b0c70580865f	\N	Алескеров Фуад Таги оглы	Сетевой анализ продовольственной безопасности	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
34366275-d55b-45b0-987d-746e5c6553a6	ffce2c25-6209-4d52-a66a-516bef83cb58	Ушаков	Вадим	Михайлович	ushakov.v.m@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Разработка методов оценки качества высокочастотных каналов связи с использованием искусственного интеллекта	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
a650e9fb-1a1f-40d4-9cae-dc9400ec8f35	\N	Савочкин	Владислав	Валерьевич	\N	2020	2	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Харитонов Игорь Анатольевич	Разработка и исследование макромоделей моделей радиационно и температуро стойких биполярных и биполярно-полевых операционных усилителей	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
df715642-07aa-4e3c-a948-f47e2e8f2c05	c79608ed-4ac5-42f1-a29f-15f615738d2f	Мочалов	Иван	Сергеевич	mochalov.i.s@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Топоркова Анна Станиславовна	Исследование и разработка методов и средств автоматизированного взаимодействия с веб-ресурсами	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
1d2db62e-4a6c-47fa-aa8b-f0e2f87f7391	0d2aa3ac-e2e6-4358-81f4-6582c3def86c	Цветков	Вячеслав	Эдуардович	vtsvetkov@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Королев Павел Сергеевич	Разработка метода дифференциальной оценки влияния внешних воздействующих факторов на прогнозируемый уровень надежности радиоэлектронной аппаратуры	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
52dc2768-b918-4093-a1e4-c042bd21fbb3	c000c72b-add0-4dcc-80eb-9cb20d5fb780	Ленву	Султан	Александрович	lenvu.s.a@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Иванов Илья Александрович	Метод проектирования беспроводных децентрализованных самоорганизующихся сетей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
1fa170fd-6af8-4b4d-96d7-67a2c2d8530f	09feb343-31aa-46ad-a555-6981762d101d	Калягин	Александр	Витальевич	avkalyagin@hse.ru	2023	3	Места, обеспеченные государственным финансированием	\N	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Полесский Сергей Николаевич	Разработка методики сопровождения спутниковых радионавигационных сигналов в сложной помеховой обстановке	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
3284ce71-d27f-47c5-a510-5b3cb0f944f5	57435f10-1fbb-46e0-a4a1-d386ce4c4b90	Веденский	Денис	Станиславович	vedenskiy.d.s@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Разработка аналитической системы рекомендации, прогнозирования и мониторинга деятельности студентов в высших учебных заведениях	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
0e0ec923-dae8-4256-ab21-23be492d343d	d43511d7-dae0-40e6-b2df-5f0ba37fe037	Кононова	Наталья	Алексеевна	nakononova@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Вагов Алексей Вячеславович	Моделирование гибридных структур для сверхпроводящей наноэлектроники	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4b99830e-a80d-4593-a5b8-48a6f9e61858	38c69e2d-c029-48e9-ab4e-79cacaf6a92d	Ищенко	Анна	Романовна	aischenko@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белова Мария Владимировна	Проблема Пуанкаре и интегрируемость осцилляторов с трением, линейно зависящим от скорости	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
13fc6d57-6538-4308-b83c-95ed7be1634e	9cfb520a-d9c9-4910-88d6-154c53f7037c	Якубов	Вячеслав	Юсупович	yakubov.v.y@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Нейросетевые модели генерации речи из текста с заданными параметрами, обучаемые на больших объемах данных русской речи	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
33099b27-a20f-4df0-bd5b-749e90321a0b	e02bea0f-73bf-48c4-a35b-3ee286daf320	Лясковский	Алексей	Дмитриевич	liaskovskii.a.d@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Иванов Илья Александрович	Методы проектирования систем позиционирования внутри помещений с использованием инерциальных систем	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
01eb4f7b-e400-4f3d-8edb-d996d0358f9b	d9e44b42-0ea1-497c-b3a6-9fd2eda9400d	Уркунов	Айвар	Кайратович	urkunov.a.k@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Королев Павел Сергеевич	Разработка методики прогнозирования надежности функциональных узлов в широком диапазоне температур эксплуатации	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
595206d9-0804-4094-8724-fe5bb0eb9bd4	943b9c16-1034-44b3-9d22-15e4f831acd6	Литвиненко	Алексей	Михайлович	am.litvinenko@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Старых Владимир Александрович	Анализ, исследование, разработка компонент защиты информационных систем на основе микросервисных архитектур от критических уязвимостей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
ba8f398a-edbf-4d8f-8288-dab2461506c7	a0fb7d3c-6325-4f2a-8f1f-3914e1386189	Сиротинский	Никита	Вадимович	sirotinskiy.n.v@hse.ru	2024	2	Места, обеспеченные государственным финансированием	\N	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Нейросетевые методы синтеза речи и обнаружения речевых обманных образов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
9b15aaf3-a5b6-4acb-9f48-a96f9c81869a	\N	Яруллин	Артур	Рустемович	\N	2020	2	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бограчёв Даниил Александрович	Анализ и прогнозирование деградации активного электрода аккумуляторов с помощью нейронных сетей	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
51982b8e-1143-41ba-a39f-2a40f822df91	1278eb85-2213-4e27-acc2-8012d68e4b52	Никитин	Георгий	Эдуардович	nikitin.g.e@hse.ru	2024	2	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Восков Леонид Сергеевич	Разработка системы аутентификации на базе технологии блокчейн для спутниковых коммуникационных сетей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
be6daa10-d87f-46b9-a407-b4fb2a6bf0a8	\N	Анишин	Максим	Николаевич	\N	2020	2	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Грачев Николай Николаевич	Разработка и исследование методов реализации вторичного радиоканала для повышения эффективности использования частотного ресурса	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
fbe69c31-fd60-427f-960f-24def5e3f065	\N	Воронова	Виктория	Александровна	\N	2020	2	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Разработка и анализ моделей и алгоритмов распределения однорангового контента в беспроводных сетях с использованием систем машинного обучения	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
09f3f560-18ae-49ad-b2b3-f0ec18e861e5	\N	Иванов	Айсиэн	Анатольевич	\N	2020	2	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Стукач Олег Владимирович	Повышение энергоэффективности многоэтажных жилых зданий на основе системы связанных автоматических регуляторов теплового напора теплоносителя, оптимальных по критерию учёта динамики изменения погодных условий	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
1fa2ca5d-cf02-4374-beae-56fb8c94e686	d5a53965-a2de-481b-985f-c0808524208e	Халифех	Кифах	\N	khalifekh.k@hse.ru	2024	2	По межправительственным соглашениям	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Афанасьев Валерий Николаевич	Оптимальное управление БПЛА в задаче слежения при действии неконтролируемых возмущений на основе дифференциальных игр	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
d79bd080-7883-42fd-84bb-06cb70407915	ddf93c63-c764-4d90-830d-240ea8ab9b5c	Нурмаматов	Нуриддинжон	Рахматжон угли	nurmamatov.n.r@hse.ru	2024	2	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Шураков Александр Сергеевич	Разработка спектрально эффективных средств модуляции для систем терагерцовой связи	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
46e97843-2590-4eb6-ace7-f801d8acde40	\N	Вафула	Бена Масимбо	-	\N	2024	2	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	eae424ef-a2bc-40ee-b123-d7c26f87a067	\N	Кучерявый Евгений Андреевич	Разработка методов совместной передачи информации и энергии в беспроводных сетях миллиметрового диапазона с применением искусственного интеллекта	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
669605f0-9748-42bc-aa16-99a8a9c79dcc	\N	Рашаида	Эмад Ф С	-	\N	2023	2	По межправительственным соглашениям	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Евсютин Олег Олегович	Обнаружение Deepfake с использованием мультимодальных подходов	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
eb946a74-35bf-4d9f-90ea-980b1cc7ab86	10de52a8-07be-4782-9c06-4b7a7572056a	Степанянц	Виталий	Гургенович	vg.stepanyants@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	АА	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Романов Александр Юрьевич	Автоматизация проектирования систем подключенного и беспилотного транспорта	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
0895a989-3aa7-4529-bb2f-4d574f77f6a4	\N	Джанашиа	Кристина	Малхазовна	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Евсютин Олег Олегович	Алгоритмы встраивания цифровых водяных знаков в изображения с повышенной устойчивостью к искажениям	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
7b4f0479-8507-45e3-add9-e7e1bd2ad580	\N	Комарова	Марина	Александровна	\N	2021	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Смирнов Григорий Сергеевич	Атомистическое моделирование дефектов кристаллической решетки ОЦК металлов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
d834e5eb-e5d0-427f-85c1-559122fc99e5	9a480a59-9053-4816-a82e-6d244dec9dea	Румянцева	София	Васильевна	srumyanceva@hse.ru	2023	3	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	ЕТМА	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Новикова Елена Михайловна	Методы квазиклассического приближения для разностных и дифференциальных уравнений	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
37e4d967-f9a8-4009-9f46-0ce7dea1a3db	cb959407-ae40-4bf3-b2b2-270f37abe259	Венедиктов	Илия	Олегович	iovenediktov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	ЕТМА	13602113-fdee-4912-8329-134fe89ffd88	\N	Ковалюк Вадим Викторович	Исследование механизмов разрешения числа фотонов в интегрально-оптическом исполнении	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4f73895e-ef83-4244-9019-1802668cefc2	95602f76-6dad-4f6b-b103-dff7915b60ce	Святодух	Сергей	Сергеевич	ssvyatodukh@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	ЕТМА	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Исследование фундаментальных ограничений быстродействия сверхпроводниковых однофотонных детекторов на основе микрополосок нитрида ниобия.	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
0dd11bac-2e00-4eda-8024-7aa91e5f5272	\N	Рахель	Марк	Анатольевич	\N	2022	3	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	ЕТМА	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Данилов Владимир Григорьевич	Точная асимптотика фундаментальных решений начально-краевых задач для нестрого параболических уравнений с малым параметром	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
02c682ac-62c1-49af-88af-7e781b555df3	\N	Файзуллина	Камилла	Наилевна	\N	2022	3	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	ЕТМА	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Щур Лев Николаевич	Численное исследование спиновых моделей на динамических структурах	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
5bb4bdde-83c6-4986-942d-6550df36ade0	\N	Белявский	Дмитрий	Алексеевич	\N	2021	3	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Кабанов Артем Сергеевич	Построение центра управления сетевой безопасностью на основе моделей выявления критичных привилегий и оценки рисков	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
e643147c-c171-4b88-84b4-ba1366e7ee61	\N	Рогачева	Ольга	Алексеевна	\N	2021	3	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Исследование по разработке и анализу математических моделей средств защиты информации	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
a78a049c-c810-4ac7-b744-dca1c868fd4b	\N	Содномай	Амгалан	Булатович	\N	2021	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Чулкова Галина Меркурьевна	Разработка фотонных-интегральных схем для квантовых коммуникаций	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
1cc3f618-7124-4e42-967f-5b833fcbe4c7	\N	Секретёв	Александр	Александрович	\N	2021	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Состояния Флоке и спектр квазичастиц в сверхпроводниках в высокочастотном поле	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
c44c2a48-8054-48f3-809c-8a78821a7df8	\N	Хокшанов	Наран	Саналович	\N	2021	3	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Стукач Олег Владимирович	Автоматизация управления антеннами на основе статистических параметров сети базовых станций	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
433a9f9c-cdf3-486b-92b1-bb847ee5dfcf	\N	Воднев	Александр	Андреевич	\N	2021	3	Места, обеспеченные государственным финансированием	05.13.01 Системный анализ, управление и обработка инфоpмации (4 года)	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Разработка и исследование алгоритмов декодирования на базе Суперкодов.	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
4c44a408-cbc1-4c4d-8ec0-cf5dbe17caad	\N	Денисов	Михаил	Владимирович	\N	2021	3	Места, обеспеченные государственным финансированием	05.13.05 Элементы и устройства вычислительной техники и систем управления	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Каперко Алексей Федорович	Разработка и исследование моделей и алгоритмов обработки информации для магниторезистивных устройств преобразователей перемещений	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
455a8134-92ef-4bb5-8657-06d5bbc224bd	f076f9a9-7f17-4b43-9961-bd4020e7dc05	Лекомцев	Никита	Владимирович	nlekomtsev@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пугач Наталия Григорьевна	Теоретическое исследование эффекта близости в структуре сверхпроводник-хиральный магнетик	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
74444da8-452d-4f66-93d8-c295c2676f91	f3931502-45d9-4262-8020-52d706ab2a09	Рзаев	Эдвард	Рамизович	erzaev@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Романов Александр Юрьевич	Исследование циркулянтных топологий для проектирования сетей на кристалле	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
fae8b6f2-29bd-4d07-8bfd-4b3421372d66	692b42ca-4ef3-4815-b248-e79c8701d797	Хлынов	Павел	Антонович	pakhlynov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Самбурский Лев Михайлович	Разработка компактных SPICE-моделей силовых полупроводниковых приборов с учётом разброса температурно-зависимых параметров	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b02213f7-2a91-4d64-ba0c-b7b7ca2fb6ea	8bd9e1f2-3d5a-4246-a66b-caa9dbaeb202	Солдатенкова	Мария	Дмитриевна	msoldatenkova@hse.ru	2023	3	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Чулкова Галина Меркурьевна	Исследование фундаментальных ограничений сверхпроводниковых однофотонных детекторов на основе разупорядоченных сверхпроводниковых микрополосок NbN нитрида ниобия.	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
5a66f74b-fd97-4f75-8f07-1bc6bcc9dcab	6bb6b9b8-9684-4f7c-afc2-7315922ef572	Буров	Никита	Андреевич	nburov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	1.2.2 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Гайдуков Роман Константинович	Математическое моделирование обтекания неровных поверхностей дисперсионными средами с фазовым переходом	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	5fb04a80-375c-4a31-b253-ef99f699be7b	Математическое моделирование, численные методы и комплексы программ
0d79d054-52bc-447a-8c2e-0a4fc924632f	8b6ef1c7-8f74-4b29-8cfd-12518608e6ec	Дубельщиков	Александр	Александрович	adubelschikov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Магид Евгений Аркадьевич	Разработка системы IoT датчиков для использования агентами гетерогенного роя БЛА и построения единой сети обмена данными с целью улучшения информированности оператора и удобства управления	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
8959bc6f-e002-4ffa-b8bb-786389bc8708	721dec2b-4138-468d-a852-3cff8717a185	Казачков	Алексей	Олегович	aokazachkov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Петросянц Константин Орестович	Разработка и исследование SPICE-моделей гибридных СВЧ модулей на основе GaN транзисторов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
06a47cad-1e85-4ddf-83c4-397add1e2332	61320c02-4bff-495b-a4fe-e17b6404c4c5	Серебренников	Дмитрий	Александрович	daserebyannikov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Белов Александр Владимирович	Разработка моделей и алгоритмов для проектирования интеллектуальных систем энергоменеджмента промышленных предприятий	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
01fc6975-25cd-4303-b9b6-8781a1f49f9c	\N	Федотов	Артем	Владимирович	\N	2021	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Самбурский Лев Михайлович	Исследование структурных и электрофизических свойств пленок поликристаллического кремния для создания малогабаритных резисторов	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
5db6ecc6-0e6a-4044-af40-81dbe091f238	\N	Смирнов	Иван	Андреевич	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Исследование защищенности беспроводных сетей пятого и шестого поколения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
006b5cad-0312-41e3-a321-2507a0f34ace	\N	Аванесян	Нина	Левоновна	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Чеповский Андрей Михайлович	Разработка методов анализа информации пользователей социальных сетей	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
33f64fcb-369e-46ea-b840-8c77286142df	\N	Зунин	Владимир	Викторович	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.7 Компьютерное моделирование и автоматизация проектирования	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Романов Александр Юрьевич	Методы и алгоритмы ускорения проектирования цифровых схем с использованием машинного обучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
5056dbdf-c42f-4271-a1bc-38c26f22cba8	\N	Федоров	Никита	Геннадьевич	\N	2022	3	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Стукач Олег Владимирович	Создание общедомового погодозависимого автоматического регулятора тепловой энергии	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4082a082-3f0f-4c52-93be-46e29827fad7	\N	Степанов	Михаил	Андреевич	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Сластников Сергей Александрович	Проектирование и разработка системы цифрового профиля	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
e7af0803-3d2c-40bf-9346-678fc9af1c38	\N	Попов	Владимир	Александрович	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Чеповский Александр Андреевич	Построение цифровых профилей Telegram-каналов на основе сетей взаимодействующих объектов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
989898d2-97c0-4387-8a12-0848d2b039c7	f0361522-bb0f-4a2b-877c-be8ea5cea04d	Зиннуров	Булат	Дамирович	bzinnurov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	\N	Нет	4a26e5f6-c3d5-4775-9048-c7cbab744ba1	\N	Смирнов Григорий Сергеевич	Моделирование нанопористых сред методами молекулярной динамики и машинного обучения	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
088ad54a-ca56-4658-8643-2be891f6537e	87026f63-1644-4539-b884-dbd9b91b4e23	Федоров	Сергей	Андреевич	safedorov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Истратов Анатолий Юрьевич	Разработка алгоритма выделения шаблонов в журналах сообщений вычислительных систем для выявления отклонений от стандартных нормативов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
5adc0e40-e992-44b2-9ca6-25cd1a2c64b6	9a110c9f-bfe6-4f3a-989e-a0f2544e0dac	Ковалев	Иван	Андреевич	i.kovalev@hse.ru	2023	3	Места, обеспеченные государственным финансированием	\N	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Вагов Алексей Вячеславович	Исследование перехода между сверхпроводимостью I и II рода в материалах с сильной связью и параметрами порядка разной природы и симметрии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
fa3428a5-5011-45f0-966f-2aa46c6135e8	58ac24be-f152-487b-8267-b8f53f35256c	Краюшкин	Денис	Владиславович	dvkrayushkin@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Чеповский Андрей Михайлович	Разработка и исследование методов и алгоритмов для защиты данных в масштабируемых медицинских информационных системах, предназначенных для работы с радиологическими изображениями	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
6d8cf0b3-79d5-498b-b814-5fa5ba8e078a	28ef5f30-6469-4231-bf4a-d4939d6b6593	Сербаев	Вадим	Русланович	vrserbaev@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.3.6 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Исследование возможности практического применения деревьев Веркла для обеспечение безопасного хранения данных в распределенных реестрах	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
91af14c3-b20f-49ae-93d0-718d5b11f53b	\N	Радкевич	Евгения	Витальевна	\N	2022	3	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Полесский Сергей Николаевич	Исследование проблемы проведения ускоренных испытаний на надежность радиоэлектронных средств с использованием многофакторного форсированного режима	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
234f263b-89b4-4b98-b2da-13cbcf9ef7ad	\N	Чурбанов	Роман	Рамисович	\N	2022	3	Места, обеспеченные государственным финансированием	2.3.1 Системный анализ, управление и обработка информации	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Четвериков Виктор Михайлович	Многофакторная математическая модель оценки стоимости рынка недвижимости	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
49824206-3d39-4866-b520-dc05067c3dfa	\N	Иванов	Артём	Игоревич	\N	2018	3	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Клышинский Эдуард Станиславович	Разработка структуры универсальной памяти для использования программными системами искусственного интеллекта	Прочее	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
ed4688a9-1046-45ee-951b-1fe9fdf95854	610cb0c7-1ccf-46a9-99b5-86af57e78858	Бахшалиев	Руслан	Мухтарович	rmbakhshaliev@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Разработка и исследование оптической системы наведения и формирования полезного сигнала для классического и квантового каналов связи малых космических аппаратов типа «Кубсат» в применении с наземными приемными станциями	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
da353cf3-5491-42a0-a68c-8a8e1db11f81	5cbd1260-28ff-4db1-9ca0-916e3c9be773	Винокуров	Юрий	Андреевич	yavinokurov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кофанов Юрий Николаевич	Разработка метода виртуальных испытаний бортовой электронной аппаратуры	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4585b898-097a-48e7-9b33-4e1fa619f27f	6dc4ccb6-a8a3-4f39-ae02-c0657a47bcc0	Левашов	Сергей	Дмитриевич	slevashov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Разработка модели и инструментальных методов оценки прозрачности атмосферы для задач квантовой и классической лазерной связи с использованием как собственных орбитальных и наземных инструментов, так и общедоступных данных ДЗЗ	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
122fa2b3-1013-4848-b5d8-d30f9a778600	\N	Кузнецов	Артём	Алексеевич	\N	2019	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Ихсанов Ренат Шамильевич	Фотоэмиссия и электронный транспорт в солнечных элементах на основе плазмонных наночастиц	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
109c4089-0b3a-440e-8710-26c55d16cd8f	\N	Скуратов	Максим	Игоревич	\N	2020	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пугач Наталия Григорьевна	Теоретическая разработка элементной базы для сверхпроводящих квантовых устройств	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
735974a0-1076-4b8f-aab1-bd99c62f51bd	94d78893-2eeb-477d-b161-b98290e6da09	Кузнецов	Антон	Гаврилович	ag.kuznetsov@hse.ru	2023	3	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Тумковский Сергей Ростиславович	Исследование влияния эффекта электризации на полупроводниковую электронную компонентную базу	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b726630f-ed06-4189-9cc3-76c7fa79275a	\N	Михайлов	Денис	Алексеевич	\N	2021	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	\N	\N	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
219bc853-11e2-4dd6-b19d-3548e5dbe635	\N	Руссак	Дмитрий	Александрович	\N	2020	3	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Кабанов Артем Сергеевич	Подходы к построению оптимальных алгоритмов создания коррелирующих правил и обработки инцидентов информационной безопасности при организации работы Security Operations Center	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
466a6c74-4d76-4d18-a780-6fe4ab949a99	\N	Конышев	Юрий	Викторович	\N	2020	3	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Квантово-оптическая интегральная микросхема для вибронного бозонного сэмплинга	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
9aa73ee9-2bac-4187-b471-52af0cf0815f	\N	Фомин	Денис	Бониславович	\N	2020	3	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Нестеренко Алексей Юрьевич	Построение нелинейных биективных преобразований для построения алгоритмов защиты конфиденциальности данных в недоверенных средах	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
a54a22ed-e2f0-44dd-b9f8-2d003b19a972	\N	Шаниязов	Ростислав	Ринатович	\N	2020	3	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Защищённые вычисления в системах обработки и хранения информации	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
6ec65d01-f4c7-42a7-b381-420f9e95723a	\N	Дай	Тунхуа	-	\N	2023	3	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	729d68af-687e-4c7c-9966-0dc64b246395	\N	Хоров Евгений Михайлович	Разработка и исследование методов детекции свойств объектов с помощью сигналов беспроводной связи	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
9a3cebf8-da75-4d5e-ac30-a773bcd6f1d4	\N	Сулейман	Эхаб	-	\N	2023	3	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Повышение безопасности физического уровня в телекоммуникационных системах с использованием БПЛА с помощью методов машинного обучения	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
a3350131-f59e-4289-b85d-ba338e1ac5f6	\N	Даюб	Али	-	\N	2023	3	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Развитие и методы исследования по интеграции вычислительных технологий на краю сети и машинного обучения с целью повышения эффективности приложений Интернета вещей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
523a2af2-90db-4842-9845-5fad3758d337	\N	Беликов	Иван	Игоревич	\N	2021	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	АА	13602113-fdee-4912-8329-134fe89ffd88	\N	Шураков Александр Сергеевич	Разработка терагерцовых интегральных устройств с диэлектрическими волноводами на базе Si и GaAs	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
7ec1c304-6810-4999-93f4-f51a008e8a5e	\N	Морозов	Владимир	Игоревич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	АА	f29d5814-6ef7-42da-8569-538ccc3c0b24	\N	Евсютин Олег Олегович	Разработка алгоритмов повышения эффективности квантового распределения ключей для магистральных линий сверхбольшой протяженности	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
3b2751fb-dad8-4393-a7a0-f2e1cef13164	\N	Шеин	Кирилл	Вячеславович	\N	2021	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Гайдученко Игорь Андреевич	Исследование нового поколения квантовых детекторов и источников одиночных фотонов на основе двумерных Ван-дер-Ваальс структур	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b09fb2a9-adc6-4e8f-9dc5-837c4fcec09a	e8128334-1a06-4f89-9258-411de4db0920	Андреев	Владислав	Сергеевич	vsandreev@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	АА	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Детектирование люминесценции синглетного кислорода в фотосенсибилизированных биологических объектов на основе время-коррелированного счета одиночных фотонов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
57746c9c-8447-4d7e-bf10-a429c804a338	395bc909-e516-461f-9d28-ff0ef0a188f9	Саматов	Михаил	Рустамович	msamatov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Васенко Андрей Сергеевич	Исследование влияния структуры межзёренных границ на свойства перовскита CsPbBr3 для солнечных элементов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
10f477b2-3324-4ad5-aec4-7d9a574b7b11	e477411e-ee98-4a07-802f-a6d309a23fc6	Седых	Ксения	Олеговна	ksedykh@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	АА	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Планарная ловушка с волоконным интерфейсом и сверхпроводниковыми однофотонными детекторами для масштабируемого квантового компьютера на ионах	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
fb08d814-a40a-409c-a31c-57c51eac8f8f	\N	Пресняков	Семен	Андреевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.07 Антенны, СВЧ устройства и их технологии	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кравченко Наталья Павловна	Исследование и разработка замедляющих систем для приборов и устройств терагерцового диапазона	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
76f171b6-1833-4be3-83b0-deb807b8a305	\N	Миколаенко	Вадим	Витальевич	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	АА	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Аксенов Сергей Алексеевич	Методика исследования деформационного поведения сверхпластических материалов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
fb695c3b-6034-4e8e-a856-f0593151c1b4	\N	Долуденко	Илья	Михайлович	\N	2018	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бондаренко Геннадий Германович	Исследование формирования, структуры и физических свойств нанопроволок сложного состава	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
31497404-7530-4423-bc3d-442bb2c3e25f	\N	Карабасов	Тайржан	\N	\N	2020	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	АА	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Васенко Андрей Сергеевич	Исследование сверхпроводящего диодного эффекта в гибридных структурах сверхпроводник/ топологический изолятор	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
455fa1b9-5003-4067-8469-a08667b0c0dc	\N	Тимохин	Илья	Сергеевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	f29d5814-6ef7-42da-8569-538ccc3c0b24	\N	Иванов Федор Ильич	Специальные конструкции каскадных кодов на базе полярных	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
3c2f6efb-4bd8-4663-bb6d-5bb05395a1a5	\N	Фокина	Алина	Игоревна	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Чеповский Андрей Михайлович	Разработка методик анализа текстов противоправной тематики средствами корпусной лингвистики	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
5e06ef31-1ca8-4f5d-ac3f-99965c7dc7dd	\N	Башкевич	Степан	Владимирович	\N	2021	4	Места, обеспеченные государственным финансированием	05.12.07 Антенны, СВЧ устройства и их технологии	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Елизаров Андрей Альбертович	Исследование частотно-селективных устройств на метаматериалах для систем радиочастотной идентификации	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
f8285dc9-8359-4b8b-9f90-af1a5a26aebb	\N	Гневанов	Михаил	Владимирович	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Карпова Ирина Петровна	Разработка методов, алгоритмов и моделей для защиты  ERP-системы от сетевых атак	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
b20d836e-ae8d-414a-a777-e8dc9a2c0ff5	\N	Вовк	Николай	Александрович	\N	2021	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Смирнов Константин Владимирович	Разработка и исследование сверхпроводникового однофотонного детектора  для фотонных интегральных схем.	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
d525923e-1220-41b8-aec6-551be25e4a8e	\N	Рудавин	Никита	Владимирович	\N	2021	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Ожегов Роман Викторович	Методы синхронизации опорных частот, компенсации искажений поляризации и калибровки параметров в устройствах квантового распределения ключей	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b3329de9-592c-41e4-9d54-c71215a3a416	\N	Трефилов	Даниил	Олегович	\N	2021	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Ожегов Роман Викторович	Неидеальное приготовление состояний в квантовом распределении ключа	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
40fef73c-8eea-49db-ab8d-58a5c767eb8a	\N	Косинов	Артемий	Николаевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пожидаев Евгений Димитриевич	Разработка методов защиты мощных МОП транзисторов от воздействии электростатических разрядов	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
f2039a91-eaea-4f8e-9901-3485964b209a	\N	Дуплинский	Алексей	Валерьевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Чулкова Галина Меркурьевна	Разработка и исследование системы компенсации рассогласования поляризационных систем отсчёта для спутникового оптического канала квантового распределения ключей	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b1566da2-8c76-40c5-968d-c6bcd8f6fff7	\N	Ильин	Александр	Дмитриевич	\N	2021	4	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Восков Леонид Сергеевич	Разработка и исследование методов повышения энергетической эффективности граничных устройств в сети IoT	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
112910e8-c4bd-4e68-be06-eed1c315e16b	\N	Хомутов	Евгений	Васильевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Щур Владимир Львович	Методы машинного обучения в задачах популяционной геномики	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
136eedd5-fed2-4743-849f-e89080dfcd4d	\N	Чухно	Андрей	Борисович	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Рожков Михаил Иванович	Оценка вероятностей наступления событий при реализации случайных подстановок из подмножеств специального вида	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
bfa24eb3-e9a9-4bdb-a7c9-e9c920c7e93d	\N	Просвиров	Владислав	Анатольевич	\N	2021	4	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Разработка методов моделирования радиоканалов в сетях 5G/6G с использованием машинного обучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
77018e8d-8a41-4fae-a550-c45a3083a695	\N	Хайров	Эмиль	Маратович	\N	2021	4	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Разработка и анализ моделей обслуживания трафика в миллиметровых и терагерцовых сетях 5G/6G на пакетном уровне	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
767729f6-1746-41ec-a703-3c904ba51f07	\N	Фролов	Степан	Иванович	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ (4 года)	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кофанов Юрий Николаевич	Разработка методики моделирования тепловых процессов в радиоэлектронной аппаратуре с обеспечением повышенной надёжности на ранних этапах проектирования	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
404af190-0f34-43f0-81d9-6b1f1fff799d	\N	Гаража	Илья	Андреевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.01 Системный анализ, управление и обработка инфоpмации (4 года)	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Афанасьев Валерий Николаевич	Разработка методов управления нелинейными неопределенными динамическими объектами (Дифференциальные игры в задачах построения гарантирующего управления нелинейными динамическими объектами)	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
a51e0d13-308b-42a8-991e-ba4a4d358370	491a13e3-a627-48b5-89d3-004f21a9eccf	Бубнова	Мария	Андреевна	mbubnova@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Разработка и исследование алгоритмов постквантовой криптографии	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
d54d53e4-3458-4789-8252-8aff987cf75c	3957de6b-e99a-4d46-b9c7-e1fd9eeccefc	Шарапов	Александр	Рауилович	arsharapov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Крук Евгений Аврамович	Разработка метода анализа данных с использованием кодов, исправляющих ошибки в метрике 11	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
cc107b86-3bca-4af6-b230-df3144517d36	8819c290-93b3-45f3-9ef3-cc92d66488ae	Борисов	Вячеслав	Дмитриевич	vdborisov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Данилов Владимир Григорьевич	Моделирование полевой эмиссии из катода малых размеров	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
70dbb6cd-49d4-4eaa-a6f6-6ad3761ecb15	1144cc4d-07ef-488a-9f58-ab7333a28d64	Селезнёв	Дмитрий	Владимирович	dseleznyov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пугач Наталия Григорьевна	Равновесные микроволновые свойства гибридных слоистых структур, состоящих из сверхпроводника в контакте с магнитным материалом	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
04ae2404-93d7-4e72-b9d1-7fecefeec206	fb501b82-16cb-466d-85c2-0f613971fd05	Титченко	Анастасия	Николаевна	alyubchak@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Гайдученко Игорь Андреевич	Разработка on-chip спектрометра терагерцового диапазона на основе фотонных интегральных схем	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
56592e50-cf61-4aac-b0d9-8194598c1776	ed8dd5f9-c74f-4739-8e9b-d17620c84eb9	Икренников	Максим	Сергеевич	mikrennikov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.13 Радиотехника, в том системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Нефедов Сергей Игоревич	разработка, исследование и оптимизация методов обнаружения сигнала сейсмической активности в системах геодинамического контроля горных пород	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
38952c4e-9b42-43b8-a1b7-29f6c43321ae	\N	Гуравова	Анастасия	Владимировна	\N	2018	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Васенко Андрей Сергеевич	Исследование диссипативных токов в Джозефсоновских контактах с ферромагнитной прослойкой	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
65e91630-de44-47b4-a334-0d324c0a2f9f	\N	Зимина	Екатерина	Юрьевна	\N	2017	4	Места, обеспеченные государственным финансированием	05.13.12 Системы автоматизации проектирования	Нет	60824b94-83d7-416a-8cc7-a676cd223c91	\N	Шмид Александр Викторович	Исследование методов кластеризации кардиологической информации	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
f438a2e6-e811-4bfa-bcae-58cac9f03edc	\N	Ломакин	Андрей	Игоревич	\N	2020	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Исследование энергетической релаксации в неупорядоченных металлических плёнках	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
bed8959a-8f73-4bf9-bac5-c7ef2811d9ea	\N	Гуськова	Мария	Сергеевна	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	624986ad-1eb4-4539-b566-b4104811ed24	\N	Щур Лев Николаевич	Моделирование движения капли в ограниченной геометрии	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
b84dd5aa-9253-4313-8a59-2f503266b221	f4161062-8cb1-41da-b1ea-591924139d3b	Заводиленко	Владимир	Владимирович	vzavodilenko@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Ожегов Роман Викторович	Оптимизация параметров рабочей гетероструктуры InGaAs/InP однофотонного лавинного фотодиода в стробированном детекторе одиночных фотонов ближнего инфракрасного диапазона	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
591435b5-244f-4c42-a4e1-2b7f46a523dc	48bd79cb-e485-49df-adb5-1fa8738251b0	Сыропятов	Александр	Анатольевич	asyropyatov@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.10 Метрология и метрологическое обеспечение	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Нефедов Сергей Игоревич	Разработка и исследование системы автоматизированного замера объема сыпучих материалов на складах	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
ea649fb6-453a-4308-b7e3-605523cbdce3	241014d1-f549-487a-9664-f57ce19c98b9	Филяев	Александр	Александрович	afilyaev@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Ожегов Роман Викторович	Исследование влияния негативных эффектов в полупроводниковых структурах на временное разрешение детекторов одиночных фотонов ближнего ИК диапазона на базе однофотонных лавинных фотодиодов	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
3774446f-49cb-478b-8464-967e917da0ed	\N	Покровская	Ольга	Дмитриевна	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	624986ad-1eb4-4539-b566-b4104811ed24	\N	Щур Лев Николаевич	Магнитные свойства вспененных структур	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
ce34e71c-6735-45bd-a0ee-4185a6cdfe9b	\N	Абрамешин	Дмитрий	Андреевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пожидаев Евгений Димитриевич	Исследование влияния процессов накопления заряда в композитных полимерных диэлектриках на бортовую электронику космических аппаратов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
a33d7208-9beb-4bcf-946f-49a5b52b6045	\N	Скуридин	Андрей	Андреевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.07 Антенны, СВЧ устройства и их технологии	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Елизаров Андрей Альбертович	Исследование микроволновых частотно-селективных устройств на основе грибовидных метаматериалов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
4a439250-c657-4f2f-9579-eb381b5dc28f	\N	Касаткин	Александр	Дмитриевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.07 Антенны, СВЧ устройства и их технологии	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кравченко Наталья Павловна	Исследование дисперсии резонансных замедляющих систем с пролетным каналом заполненным плазмой	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
5cd5b1e0-b3ee-4968-91e2-fd30190e7c51	\N	Фадеева	Марина	Александровна	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	624986ad-1eb4-4539-b566-b4104811ed24	\N	Щур Лев Николаевич	Исследование алгоритмов моделирования методом Монте-Карло	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
6afa6210-7401-4037-86a4-dd9a8d9bfdc8	\N	Полищук	Фёдор	Сергеевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Саенко Владимир Степанович	Исследование и разработка метода ускорения анализа массивов данных на основе механизма секционирования	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
c72219f4-f536-4558-a1c7-1df5b26b5d7f	\N	Малахов	Станислав	Сергеевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Рожков Михаил Иванович	Методы построения MDS матриц над конечными полями для криптографических положений	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
08574b7a-b1e5-45f3-b487-7d24ba285e71	\N	Чукарин	Марк	Игоревич	\N	2018	4	Места, обеспеченные государственным финансированием	05.11.15 Метрология и метрологическое обеспечение	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Юрин Александр Игоревич	Разработка и исследование системы неинвазивного мониторинга параметров крови	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
1cded00e-0443-4d06-9009-64e6c8e9ebf7	\N	Новиков	Роман	Сергеевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	60824b94-83d7-416a-8cc7-a676cd223c91	\N	Позин Борис Аронович	Разработка методов и алгоритмов обнаружения маркеров нарушения углеводного обмена по ЭКГ при удаленном скрининге населения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
429bdcd0-65ec-439a-aa92-a37caae00031	\N	Яговцев	Владимир	Олегович	\N	2018	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пугач Наталия Григорьевна	Теоретическое исследование обратного эффекта близости в структурах сверхпроводник-ферромагнетик	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
f9a6a556-ee5d-4eae-b158-04d6b7a0691d	\N	Драчев	Григорий	Александрович	\N	2019	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Истратов Анатолий Юрьевич	Разработка системы цифровой инвентаризации с использованием алгоритмов интеллектуальной обработки информации	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
36153cfa-5bb7-4d9c-8233-19876aec8186	\N	Епифанов	Никита	Андреевич	\N	2018	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бондаренко Геннадий Германович	Исследование влияния мощного пучково-плазменного воздействия на структуру и структурно-фазовое состояние сплавов алюминия, меди и железа	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
4ba7f3b0-467e-4a6a-8c21-15ffafb4c27a	\N	Малашина	Анастасия	Геннадьевна	\N	2019	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Исследование информационных характеристик естественных языков в связи с разработкой методов оценки защищенных информационных систем	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
9112a5fc-f681-4c06-a88f-e50c504b3e8f	\N	Татунов	Сергей	Юрьевич	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Полесский Сергей Николаевич	Разработка методики проектирования комплектов ЗИП территориально-распределенных электронных средств с использованием метода имитационного моделирования	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
bef30500-036b-456f-b00b-838cd3ec8886	\N	Шибаев	Роман	Владимирович	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Полесский Сергей Николаевич	Разработка модели оценки надежности топологий сетей доступа с использованием технологии виртуализации	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
24e78bfa-f8b2-466e-b792-27430fc26f3b	\N	Панов	Дмитрий	Вячеславович	\N	2019	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Бондаренко Геннадий Германович	Получение гомогенных и гетерогенных металлических нанопроволок методом матричного синтеза, исследование кинетики их роста, структуры и физических свойств	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
c63fbbe3-5927-4e9e-bbbf-e86076551d2e	\N	Лаврухин	Илья	Романович	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.07 Антенны, СВЧ устройства и их технологии	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Елизаров Андрей Альбертович	Исследование электродинамических параметров частотно-селективных СВЧ устройств на гибких печатных платах	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
b15e5418-f9ed-4cb7-931a-aa623ac11669	\N	Астафьев	Антон	Викторович	\N	2019	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Тамеев Алексей Раисович	Исследование и разработка метода измерения квантового выхода фотогенерации в материалах солнечной энергетики	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
2a796dab-0489-4762-b8d5-18238faae0d7	\N	Агапов	Илья	Игоревич	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Саенко Владимир Степанович	Исследование и разработка метода повышения устойчивости полимерных диэлектриков бортовой радиоэлектронной аппаратуры космических аппаратов к возникновению электростатических разрядов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
12000f9e-c2a7-4fc6-b9bd-8ddcb7c5025f	\N	Новиков	Константин	Викторович	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Полесский Сергей Николаевич	Разработка методики сквозного проектирования маршрутизаторов для беспроводных сенсорных сетей для отслеживания технического состояния линий электропередач	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
6e75f79b-9aaa-4b14-98cd-e3feb85897dd	\N	Гайдамака	Анна	Александровна	\N	2020	4	Места, обеспеченные государственным финансированием	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	3c2dac42-42d2-4ef8-9c4e-ea69c8e2c0a2	\N	Кучерявый Евгений Андреевич	Разработка моделей и методов планирования ресурсов беспроводной сети шестого поколения с применением алгоритмов машинного обучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
6fbeebf1-f9f0-425a-b167-ab5bafff8466	\N	Булеков	Александр	Александрович	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Вагов Алексей Вячеславович	Методы квазиклассического приближения и осреднения для спиновых кластеров	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
811e7142-0ded-4865-a057-0da1f8d7e738	\N	Джонов	Азамат	Темурмаликович	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	499b7bdf-ec63-475c-be90-153786d71e64	\N	Авдошин Сергей Михайлович	Разработка модели и алгоритмов повышения эффективности работы для систем распределённого реестра	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
65556ad8-7a73-4cf7-a01e-f0a63b7951da	\N	Старостенко	Владимир	Игоревич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.12 Системы автоматизации проектирования	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Старых Владимир Александрович	Автоматизация проектирования систем автоматического управления в базисе гетерогенных архитектур	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
aabc1140-51cc-40d1-a3ff-ea869fd92533	\N	Тырышкина	Евгения	Сергеевна	\N	2018	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Саенко Владимир Степанович	Исследование и разработка метода ускорения операции соединения распределенных массивов данных по заданному критерию	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
0ccdf6ae-0de8-4ca5-946c-0e5e3e42e138	\N	Матюшкин	Яков	Евгеньевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Экспериментальное исследование асимметричных полевых транзисторов на основе графена и углеродных нанотрубок для поляризационно-чувствительного детектирования терагерцового излучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
5a453199-393b-41cb-995e-8df49316c4f1	\N	Ашмарин	Валентин	Александрович	\N	2019	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Тютнев Андрей Павлович	Исследование кинетики проводимости диэлектриков радиоэлектронных средств космических аппаратов при длительном вакуумировании	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
19c5f14a-49e9-4ba7-b96b-11799cfa6eb8	\N	Тарарушкин	Евгений	Викторович	\N	2019	4	Места, обеспеченные государственным финансированием	01.04.07 Физика конденсированного состояния	Нет	4a26e5f6-c3d5-4775-9048-c7cbab744ba1	\N	Писарев Василий Вячеславович	Многомасштабное атомистическое компьютерное моделирование природных и синтетических оксидных и гидроксидных материалов для широкого класса актуальных научных и технологических приложений	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	f54a3ea6-61b5-4872-a7dd-02c655ec34c2	Физика конденсированного состояния
f104e02d-0202-4672-9471-27e91a0f8863	\N	Смирнов	Данил	Вадимович	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	f29d5814-6ef7-42da-8569-538ccc3c0b24	\N	Евсютин Олег Олегович	Эффективные алгоритмы обнаружения активности вредоносного программного обеспечения с помощью методов машинного обучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
d141c061-1bb3-4be5-88f3-ad1299c22bfa	\N	Воробьев	Иван	Александрович	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	d8943a07-6ded-46a4-bd9f-06467c9bd094	\N	Лось Алексей Борисович	Методы машинного обучения и искусственного интеллекта в задачах противодействия мошенничеству в кредитно-финансовой и банковской сфере	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
1b2b7258-4880-49b7-bd77-5ef80ed8566c	\N	Некрасов	Глеб	Александрович	\N	2020	4	Места, обеспеченные государственным финансированием	05.11.15 Метрология и метрологическое обеспечение	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Белов Александр Владимирович	Построение информационно-аналитических инструментов для организации оперативного геомониторинга опасных явлений	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
f0d4bb6a-7b82-4708-acca-243b358584db	\N	Святодух	Маргарита	Игоревна	\N	2018	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Квантовая томография сверхпроводникового однофотонного детектора	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
8d077f4f-edd8-4a0b-897d-d36830169c86	\N	Баранов	Роман	Геннадьевич	\N	2021	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Карпова Ирина Петровна	Модели противодействия угрозам нарушения информационной безопасности при эксплуатации баз данных в государственных автоматизированных информационных системах	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
e775f948-8162-4598-963c-137ed415cd33	\N	Толстиков	Семён	Юрьевич	\N	2020	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пожидаев Евгений Димитриевич	Исследование и разработка безразрядной изоляции проводов и кабелей космического применения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
280794c9-2b4b-4361-bc8e-5cc2b116a5bb	\N	Муллахметов	Ильшат	Рамилович	\N	2020	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Пожидаев Евгений Димитриевич	Исследование влияния низких температур на электризуемость полимерных диэлектриков космических аппаратов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
3d27e833-52e0-4c04-b78d-ff09a4ad7d33	\N	Чертенков	Владислав	Игоревич	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Щур Лев Николаевич	Исследование универсальности модели статистической механики методами машинного обучения	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
2ce5f75f-cb6d-4643-9fb8-197ce720edea	\N	Ибодулаев	Ибодуллоходжа	Мансурходжаевич	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.05 Элементы и устройства вычислительной техники и систем управления	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Сухов Андрей Михайлович	Исследование и разработка методов противодействия малозаметным сетевым атакам при помощи sdn технологий	Отчислен из аспирантуры по собственному желанию	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
9cd96be8-3509-498d-8a05-051bcf4bebb7	\N	Сорокин	Игорь	Михайлович	\N	2018	4	Места, обеспеченные государственным финансированием	05.13.05 Элементы и устройства вычислительной техники и систем управления	Нет	4d8ae49a-65f6-4185-b2c0-7c837f2e7ed5	\N	Старых Владимир Александрович	Методика обработки разнородных ресурсов в облачных вычислительных средах, реализуемых на основе модели интернета вещей	Отчислен из аспирантуры в связи с невыполнением индивидуального плана	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
53b8e096-52dd-42d8-bf09-fe4ee8036390	\N	Дрязгов	Михаил	Александрович	\N	2019	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Корнеев Александр Александрович	Детектор с разрешением числа фотонов на основе сверхпроводниковой полоски микрометровой ширины	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
e4e0d7ee-37f8-45de-9d86-53f3811a3922	\N	Приходько	Анатолий	Николаевич	\N	2019	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Чулкова Галина Меркурьевна	ТГц антенные решётки с использованием планарных диодов с барьером Шоттки	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
5a7fbec8-d3fb-4154-9a0a-b00cde114756	\N	Евтушенко	Лариса	Геннадьевна	\N	2019	4	Места, обеспеченные государственным финансированием	05.13.05 Элементы и устройства вычислительной техники и систем управления	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Каперко Алексей Федорович	Исследование и разработка масштабируемых методов и средств тестирования для компонентов телекоммуникационных систем	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	531f4512-958b-4d75-be7f-d0d9010fda32	Управление в технических системах
d8bd6f68-3834-41c6-ab9e-87cb49009c51	\N	Гаращук	Иван	Русланович	\N	2019	4	Места, обеспеченные государственным финансированием	05.13.18 Математическое моделирование, численные методы и комплексы программ	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Синельщиков Дмитрий Игоревич	Нелинейная динамика и бифуркации в моделях взаимодействующих микропузырьковых контрастных агентов	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6d7b9980-f9a4-4867-976c-432a79a3d438	Системы автоматизации проектирования
bc61a8f9-902e-4ba3-a0b2-ac16713eb06c	\N	Комракова	София	Андреевна	\N	2020	4	Места, обеспеченные государственным финансированием	05.27.01 Твердотельная электроника, радиоэлектронные компоненты, микро- и нано- электроника, приборы на квантовых эффектах	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Фотонные интегральные микросхемы с графеном и нанотрубками	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
f1e8e42c-3620-4650-a2a8-9f7a833923ad	\N	Артамонов	Дмитрий	Олегович	\N	2020	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Грачев Николай Николаевич	Разработка и исследование методов передачи информации в условиях превышения уровня помех над полезным сигналом	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
2acd72d8-6835-4108-a712-e25956f0eb50	\N	Уткин	Борис	Владимирович	\N	2020	4	Места, обеспеченные государственным финансированием	05.12.04 Радиотехника, в т.ч. системы и устройства телевидения	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Грачев Николай Николаевич	Разработка и исследование методов прогнозирования флуктуационных линейных и нелинейных контактных радиопомех в мобильных устройствах систем радиосвязи	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
9f3e9a0d-07f4-479f-9237-da9a2cdb0f57	\N	Газизов	Рустам	Рифатович	\N	2020	4	Места, обеспеченные государственным финансированием	05.13.19 Методы и системы защиты информации, информационная безопасность	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Елизаров Андрей Альбертович	Выявление и локализация экстремумов напряжения или тока в электрических цепях для уменьшения их уязвимости	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	6aba2945-38dd-414a-bb84-d5b5a581e55c	Информационная безопасность
ec48c18b-3a16-4d45-8f91-32e5cae2ff4a	bffd8b50-710c-4f49-b7b0-fd7d4eb4604f	Кузьминых	Илья	Олегович	iokuzminykh@hse.ru	2022	4	Места, обеспеченные государственным финансированием	2.2.2 Электронная компонентная база микро- и наноэлектроники, квантовых устройств	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Чулкова Галина Меркурьевна	Разработка и исследование фотонного газового сенсора для поиска энергетических утечек и экомониторинга	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
51779137-86cd-414f-a96a-bb877fb64970	\N	Али	Амджад	\N	\N	2021	4	По межправительственным соглашениям	2.2.15 Системы, сети и устройства телекоммуникаций	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Кучерявый Евгений Андреевич	Разработка алгоритмов отслеживания луча на основе федеративного обучения для сотовых сетей связи 5G NR	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
012c449a-8ef1-492f-a6f8-60adb13e8449	\N	Махлуф	Мазен	-	\N	2021	4	По межправительственным соглашениям	\N	Нет	13602113-fdee-4912-8329-134fe89ffd88	\N	Гольцман Григорий Наумович	Разработка лидарной системы на основе сверхпроводящего нанопроволочного однофотонного детектора (SSPD)	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
7ed426da-db28-4d74-9722-aeeada688bba	\N	Эбрахим	Али	-	\N	2021	4	По межправительственным соглашениям	05.13.12 Системы автоматизации проектирования	Нет	e3a042ed-2cc9-4755-bbda-bdd594886618	\N	Иванов Илья Александрович	Методика Проектирования Систем Промышленного Интернета Вещей	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	be77c523-864a-4e02-8527-93f8f8e0d2b0	Системный анализ. Математическое моделирование. Информационные технологии
f7f697e3-6475-4bd1-a607-b0b5a16842fd	\N	Якименко	Святослав	Игоревич	\N	2019	4	По межправительственным соглашениям	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	3c2dac42-42d2-4ef8-9c4e-ea69c8e2c0a2	\N	Кучерявый Евгений Андреевич	Разработка и исследование моделей и методов кэширования контента в сетях именованных данных	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
6386eecc-a6ee-4e7f-92f7-96cedbd56cd2	\N	Ладжал	Брахим	-	\N	2019	4	По межправительственным соглашениям	05.12.13 Системы, сети и устройства телекоммуникаций	Нет	642b1c9c-5b8f-4bdb-916e-fc72d1f103b7	\N	Афанасьев Валерий Николаевич	Управление ветроэнергетической установкой в условиях нестационарных возмущений	Отчислен из аспирантуры в связи с окончанием срока обучения	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03	1111111e-2743-4d27-98c2-c61b9631d8c7	Электроника, радиотехника и системы связи
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role_id, department_id, is_active, created_at, updated_at) FROM stdin;
2011ee42-9d2e-4b88-bc8d-7d001b3a48f3	668d28b4-14e7-4296-95a9-c9ecf27bae61	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3ed58551-b5c4-44a5-a109-70cd4bb9234d	e0594942-202d-4832-9e8b-0828ff81d905	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
238bde81-b8b6-4073-9bfd-93c1bccad63b	a69f4709-6530-4ae8-bd8c-3bfa49e50cc1	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d4b47eaf-fe40-466e-9772-b90b20fe2ad8	04205e4f-bc82-4e8e-a8e7-9b2371cac029	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
317569be-d5e8-4b77-995c-31461fe355be	35c23f03-3dad-4fe6-a4bd-7ddaadba055c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d472e2a3-fb89-43fc-a959-cba53cb54e7e	b96f0ac9-430f-40b2-8190-7c0ad7b5e2a0	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8c2d179c-1ada-42fd-804d-52126f23a11a	078ce397-1239-4c77-beac-367801223425	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cf93a799-f5f7-4eb0-9fb5-7ea9cff9a53b	51305486-d601-4d6e-9ede-ab24bbe6e8f8	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
5fbc0782-1ace-4bc4-8d97-93097b7cf838	0b175853-d521-4c3c-9530-21b8cd1582a7	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0ee53a51-df27-4a87-a389-fa98dd02912e	21cd79bf-40a5-4ba4-840f-30a1fea92137	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
b468da9e-fc0f-41b1-8303-8bf8cff234be	6318b483-1d92-4123-aecc-ce7c81a4a65b	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ee2a45f3-7955-427c-9a4e-0988aad8e506	7f3651d9-9840-450b-ae7b-b9ea81bac8c4	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
48b93291-6b2e-4b63-83ce-acb5cac6a3f3	49e6c3e9-f3f3-44e2-9cb0-84a13bc5c478	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f2f2aa06-d76a-40e9-ba87-e4abf70895c5	39225ba0-434a-44ed-b94f-833577f7fcdf	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4a769a4a-e712-44df-ad9d-c37263a2c626	3c77705c-7104-4889-b13d-ae848b2abf76	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8c5fb1bc-2b73-439d-ae93-a74d39e03ea8	cd2a7faa-0ffc-48a6-82b6-79d29208dc0c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d14679f4-88f5-41b5-9c88-403fa0247d31	57d4ed2b-3ce0-4b18-8711-0dd291f2b9d3	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cb8126fb-0726-4657-a289-fee614b99950	e9fadfd1-9a60-44c3-92f7-b8a3f808e91f	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ad6fd2ef-7265-420d-9994-2bedcfad843b	b51351d4-8d07-40d9-bcb1-afcc7fa0f795	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
af985e92-a946-4695-acd1-9737e4799fef	fb301a49-0ae0-4a25-9935-2b4114e150f4	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
00093de5-17b7-4d65-bf7a-578c7b7af08b	bce0a8c7-ece9-41bc-ad2a-cdac285d6700	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a07e7d1f-d43b-423c-855c-3d24d50555a8	366cc3db-2132-45b0-ba16-8fd74e3672f3	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6164177d-fa55-47a0-bfd5-1bef7026e0e1	ec81e681-7274-4b5e-8e67-9f09f92d6e9e	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cc16f9ec-2d40-4855-86bb-99884dae8f96	47f8bb24-e7bd-4b71-a916-253da3e913fe	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
60b1d99e-738c-4a13-8b4d-76ae05d73257	accced22-f429-4036-9445-598daeedab8f	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
531c2052-9b84-4ca1-94c3-3ef7a4354d94	0e8205d3-f1e4-48fc-ba8e-845893e92d00	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
941009bd-affc-4dc0-9cf4-edcc54086947	fbf01f3c-af72-45df-b166-5fb27177cc67	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
2d8a9cf9-1251-4363-a6a3-e3af4d3aab6a	1f118e86-d828-4156-9ce5-1e13e50d7f01	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
41064fdc-3c69-433e-bdb7-9fc31a83ba2b	dd12ab49-a88e-4ff4-bed3-53c317cbc437	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4f0e67d1-19a0-4b7b-842b-bd16b049ddcd	067de1a4-845c-472e-ab4c-9f2dc707110e	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bdad1a0d-f28c-4378-9de4-9037221d80af	656c5ead-3d8c-47f6-ac24-8d3decc821b2	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
2f14ca42-f339-430f-9a5b-ecde31701195	edbaefaa-87b2-44df-b9ee-cbeeeed89697	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bce157b9-1f9e-43d0-a3c4-ffd14e04cda4	6e17791f-d950-46ed-880d-573b9264f340	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
7fcca2ca-42d4-496f-a2e7-1a51fa13ce0b	ac90e7de-7a19-4d7f-82b4-1d8b705e1b34	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
2ee92a5a-6bf7-4c0b-ade2-402d33fe9476	d300fa5d-0067-43c6-becd-f40410c1e61f	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
1b77b3fb-ec6a-447a-b198-83027aa2a3d9	9f8301ac-ff6c-4d85-af36-357558e4f068	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9d423235-0fb0-443d-a0bc-4e6ff930c22e	4360f575-6088-456d-82fd-72c0bfc31af9	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
50f5d13d-46f5-4335-936f-f24bb5240a7f	4e8043d7-bcbe-4347-a77f-85c21d664700	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
b286eb23-31cd-4a2d-864a-2571787b7eea	0352128d-aa28-4fa8-a8a8-37975bb5a3b2	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bdf22a6e-7f6f-4eb5-9167-21b641797d17	3a10650c-cc82-436f-b474-4748a4cc4b95	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fab02650-f63c-4da6-9de8-344b8a2c750d	0dc084de-a19d-4418-83ae-ba5de9fa409e	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
78ca9c98-db7b-42a1-a318-d13834d113d0	799579a7-6504-4dfb-9b3c-9ca564e522cd	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d1f3c7f0-baf6-44ba-baae-2cef17aa54cd	d90dde7a-a9b5-4a43-92f1-1b9f123b0492	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
319fbc70-913b-4881-9356-baff3bbf1dee	dbee448c-525f-4aa9-94e5-3721be83afee	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
deb1aac1-a4f0-4834-b0e5-a138a2c8d4b2	a1c4465f-d094-4b9a-b17e-7978d835100a	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
59479a2e-a511-4bb8-912e-eba4df3f7368	c189f6a1-387d-450b-9cfc-4abfabff627c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
80b15a4a-adfd-4b75-bdf0-15386a51bd52	c1e54bc7-50e4-4dfc-b602-6a95f524b06c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a0b4f2e5-fb07-411e-8d50-e655f0f31f89	4e4258fa-2b32-4332-befc-17dfb3c643f8	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c5eca5ae-77c1-4c03-9e4e-472bbb7a8bad	de19a4d9-4979-4e02-b9b3-73019fd6e077	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
5df420d9-c3dd-4077-8880-1c1a58794246	593f35a4-8185-4174-86f0-d34f2dd887dc	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
45a8b033-cfb8-47ee-b8ef-d81a4118b75e	c1b76561-e334-40fd-bb39-11edb3e06779	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ecb472ea-daf4-46a2-8e29-db65e5eb8afd	0f6ff278-d8f1-453e-9ff6-129063586764	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ed97d9b7-a0a4-4057-9602-7689169add0d	0dda161c-2097-42d5-8ccd-93099a267883	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
7b6b4358-785a-4536-a1e2-18375b612e30	50f377a0-d51a-4848-bf90-096deacc6742	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ffd24fb5-8e93-4359-8118-77ecf151d110	ee4d2239-55fd-4535-8a5b-7aa4e378bc95	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
183796c1-c6a6-4972-8952-a86f8a5c319d	03d37926-7c62-47ae-8504-c3b4885b1f3b	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ba6177cf-fdd5-4168-b555-98d2466289c4	c45a242e-844a-420b-96ec-e78ce6799ff6	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
845f7183-d8b1-4bc1-b0c7-e7d437f38b32	d7633a37-3ac4-451a-83d5-5c757026c1ee	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bfc951cf-c096-45dc-aa66-51f3fed89446	85e18513-1b5e-4576-babf-4d68c4ee45e7	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a7220315-c397-4bd7-9a64-b5b81f2a6808	b3673547-f4b5-4930-8b9b-ba33cbd6cdd6	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f3bd619d-7e5d-4ada-b9ab-bf7018b1f5de	c8917b05-b915-4e7c-bb5c-929c8cd7743a	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
dc5be6b6-5554-4c0b-89bd-ce8616763ccb	ffce2c25-6209-4d52-a66a-516bef83cb58	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0fc91a52-d352-4cb3-bf7d-4bf4b79878d2	c79608ed-4ac5-42f1-a29f-15f615738d2f	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
38e7a875-3a8c-4f91-bfb0-e61f33d79970	0d2aa3ac-e2e6-4358-81f4-6582c3def86c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
afcab092-49b1-492d-9b7b-012597ba35c8	c000c72b-add0-4dcc-80eb-9cb20d5fb780	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
5e17ea53-1cdd-4ec1-bd00-25dafdc3841d	57435f10-1fbb-46e0-a4a1-d386ce4c4b90	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9c12780d-c1b9-47ad-8770-d88aa4b1e274	d43511d7-dae0-40e6-b2df-5f0ba37fe037	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c81f3025-20e9-4a05-ac98-f92460441b74	38c69e2d-c029-48e9-ab4e-79cacaf6a92d	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
2bf91b8e-0e21-47c3-b769-1399f5f496ba	9cfb520a-d9c9-4910-88d6-154c53f7037c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3807692e-b211-4fda-ac31-4d7fa6291baf	e02bea0f-73bf-48c4-a35b-3ee286daf320	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
14c50056-7d63-47d0-a1e5-87d82414fd9a	d9e44b42-0ea1-497c-b3a6-9fd2eda9400d	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
1194b1be-e67a-4020-a33f-43d0e761d0ff	943b9c16-1034-44b3-9d22-15e4f831acd6	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cb455335-774a-48b8-9950-1809444dcab2	a0fb7d3c-6325-4f2a-8f1f-3914e1386189	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8c7658ea-9ef6-4aba-ab47-a82a18f27809	1278eb85-2213-4e27-acc2-8012d68e4b52	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
99765b1c-603b-4761-bd43-c289785bb685	d5a53965-a2de-481b-985f-c0808524208e	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fddb6194-d2e5-4069-b42a-dac57f74bc8d	ddf93c63-c764-4d90-830d-240ea8ab9b5c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ffe4d57d-b1e5-42fc-8715-01e62c33d2dc	10de52a8-07be-4782-9c06-4b7a7572056a	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
df766ae0-9516-4589-af34-306bea776e57	9a480a59-9053-4816-a82e-6d244dec9dea	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
69300071-dc75-4289-90dc-88539ad3a94d	cb959407-ae40-4bf3-b2b2-270f37abe259	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a1736771-21d3-4df2-943a-757122c69b3a	95602f76-6dad-4f6b-b103-dff7915b60ce	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8cc52f36-1a4e-46b5-9c8f-2a4053e0dac1	f076f9a9-7f17-4b43-9961-bd4020e7dc05	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ac983619-d7d7-4086-8c01-20d460511665	f3931502-45d9-4262-8020-52d706ab2a09	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d0a6ee96-4b33-42c4-b7e5-c9b8a71a9f55	692b42ca-4ef3-4815-b248-e79c8701d797	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ac4b2e7c-1049-4f27-8d16-dbfe095bc7ca	8bd9e1f2-3d5a-4246-a66b-caa9dbaeb202	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fcca318e-3ca2-415b-8077-8277334ab10d	6bb6b9b8-9684-4f7c-afc2-7315922ef572	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
82fa6054-8e44-482a-bfe9-9993c85e6565	8b6ef1c7-8f74-4b29-8cfd-12518608e6ec	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
53bf28f3-2a95-480d-bb90-7a210a534e33	721dec2b-4138-468d-a852-3cff8717a185	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
110a3ad6-ffe7-4a0c-9c20-c14fd04b1eef	09feb343-31aa-46ad-a555-6981762d101d	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
08a24fea-a56b-42cb-b825-0a34c8616f49	61320c02-4bff-495b-a4fe-e17b6404c4c5	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
08d155b0-c09c-42ed-bfb6-ddc2517c7063	87026f63-1644-4539-b884-dbd9b91b4e23	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
45205005-232e-4b96-8a55-644ac3bc5cd6	9a110c9f-bfe6-4f3a-989e-a0f2544e0dac	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a03d581a-d1bd-418e-aac0-b67e245eaa49	58ac24be-f152-487b-8267-b8f53f35256c	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c32cb9de-ad95-4ae2-a5c2-abacb1b20db8	28ef5f30-6469-4231-bf4a-d4939d6b6593	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
526a8903-9748-4f79-ace5-8b9cb09e69b5	610cb0c7-1ccf-46a9-99b5-86af57e78858	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f847c2ac-54f2-4333-9204-5f614138129f	5cbd1260-28ff-4db1-9ca0-916e3c9be773	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e6e0685c-ea6d-4f77-9cb0-e0f6633084da	6dc4ccb6-a8a3-4f39-ae02-c0657a47bcc0	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
287f7c23-3d5f-46c6-a670-a774c080008a	f0361522-bb0f-4a2b-877c-be8ea5cea04d	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
368e09d8-963c-40a6-a928-474826296784	94d78893-2eeb-477d-b161-b98290e6da09	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8968afc4-3052-4b5b-be93-b05e409d3a97	e8128334-1a06-4f89-9258-411de4db0920	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
74d308e2-9747-4a24-98c8-c366d14a6f82	395bc909-e516-461f-9d28-ff0ef0a188f9	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
537d8cff-e923-44ac-9c86-59c607a24772	e477411e-ee98-4a07-802f-a6d309a23fc6	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c8e2de9e-629c-4ba8-ae6b-8b89ab9bd2eb	491a13e3-a627-48b5-89d3-004f21a9eccf	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
5671aa2f-cde1-4909-a651-f3e606602090	3957de6b-e99a-4d46-b9c7-e1fd9eeccefc	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
130ff795-de79-45ad-92c3-b6a611d85aaa	8819c290-93b3-45f3-9ef3-cc92d66488ae	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c8b9acd1-1916-414a-a132-0beb814d9423	1144cc4d-07ef-488a-9f58-ab7333a28d64	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f80ab7b1-0593-4ef0-b1af-155c740aac6a	fb501b82-16cb-466d-85c2-0f613971fd05	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
da903934-45cf-4bc3-99f7-394555a414f3	ed8dd5f9-c74f-4739-8e9b-d17620c84eb9	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
aee52adc-27fa-4559-ac35-f2a48683d915	f4161062-8cb1-41da-b1ea-591924139d3b	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f4fc3f4e-f9fc-4935-b6dd-fe6e2aef0ed2	48bd79cb-e485-49df-adb5-1fa8738251b0	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6262eee7-163d-4fb1-b70a-a4f71de2de47	241014d1-f549-487a-9664-f57ce19c98b9	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d69ebfc7-0f11-4dee-b58e-b1b7b62cf9cd	bffd8b50-710c-4f49-b7b0-fd7d4eb4604f	c9543ca4-9271-48d3-9b66-5fbe1926eb5f	\N	t	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, last_name, first_name, middle_name, is_active, is_deleted, last_login_at, created_at, updated_at) FROM stdin;
668d28b4-14e7-4296-95a9-c9ecf27bae61	buutay.p@hse.ru	\N	Буутай	Павел	Николаевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e0594942-202d-4832-9e8b-0828ff81d905	pi.glukhovtsev@hse.ru	\N	Глуховцев	Павел	Игоревич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a69f4709-6530-4ae8-bd8c-3bfa49e50cc1	rizmajlov@hse.ru	\N	Измайлов	Рамиль	Ильдарович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
04205e4f-bc82-4e8e-a8e7-9b2371cac029	ai.nazarin@hse.ru	\N	Назарьин	Артем	Игоревич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
35c23f03-3dad-4fe6-a4bd-7ddaadba055c	pikul.a@hse.ru	\N	Пикуль	Александр	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
b96f0ac9-430f-40b2-8190-7c0ad7b5e2a0	progozhin@hse.ru	\N	Рогожин	Платон	Дмитриевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
078ce397-1239-4c77-beac-367801223425	dgavrilov@hse.ru	\N	Гаврилов	Дмитрий	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
51305486-d601-4d6e-9ede-ab24bbe6e8f8	kuninets.a@hse.ru	\N	Кунинец	Артем	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0b175853-d521-4c3c-9530-21b8cd1582a7	tikhonov.r@hse.ru	\N	Тихонов	Руслан	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
21cd79bf-40a5-4ba4-840f-30a1fea92137	alvov@hse.ru	\N	Львов	Андрей	Валерьевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6318b483-1d92-4123-aecc-ce7c81a4a65b	sevriukov.d@hse.ru	\N	Севрюков	Дмитрий	Олегович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
7f3651d9-9840-450b-ae7b-b9ea81bac8c4	ivashentseva.i@hse.ru	\N	Ивашенцева	Ирина	Владимировна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
49e6c3e9-f3f3-44e2-9cb0-84a13bc5c478	makhmudov.t@hse.ru	\N	Махмудов	Тимур	Назимович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
39225ba0-434a-44ed-b94f-833577f7fcdf	pbondareva@hse.ru	\N	Бондарева	Полина	Игоревна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3c77705c-7104-4889-b13d-ae848b2abf76	ilyzhin@hse.ru	\N	Лыжин	Илья	Григорьевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cd2a7faa-0ffc-48a6-82b6-79d29208dc0c	demidov.i@hse.ru	\N	Демидов	Иван	Дмитриевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
57d4ed2b-3ce0-4b18-8711-0dd291f2b9d3	khazbulatov.a@hse.ru	\N	Хазбулатов	Артур	Тимурович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e9fadfd1-9a60-44c3-92f7-b8a3f808e91f	dobrina.d@hse.ru	\N	Добрина	Дарина	Николаевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
b51351d4-8d07-40d9-bcb1-afcc7fa0f795	bnikitin@hse.ru	\N	Никитин	Богдан	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fb301a49-0ae0-4a25-9935-2b4114e150f4	dgafurova@hse.ru	\N	Гафурова	Даниэлла	Рафиковна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bce0a8c7-ece9-41bc-ad2a-cdac285d6700	lchashkin@hse.ru	\N	Чашкин	Леонид	Борисович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
366cc3db-2132-45b0-ba16-8fd74e3672f3	ai.andrianova@hse.ru	\N	Андрианова	Анна	Ивановна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ec81e681-7274-4b5e-8e67-9f09f92d6e9e	lromanov@hse.ru	\N	Романов	Леонид	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
47f8bb24-e7bd-4b71-a916-253da3e913fe	fsmirnov@hse.ru	\N	Смирнов	Феликс	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
accced22-f429-4036-9445-598daeedab8f	ma.zhigalov@hse.ru	\N	Жигалов	Михаил	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0e8205d3-f1e4-48fc-ba8e-845893e92d00	azayakina@hse.ru	\N	Пискунова	Анастасия	Михайловна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fbf01f3c-af72-45df-b166-5fb27177cc67	vbaleskin@hse.ru	\N	Балескин	Виталий	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
1f118e86-d828-4156-9ce5-1e13e50d7f01	teregulov.t@hse.ru	\N	Терегулов	Тимур	Рафаэльевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
dd12ab49-a88e-4ff4-bed3-53c317cbc437	avshmelev@hse.ru	\N	Шмелев	Алексей	Валерьевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
067de1a4-845c-472e-ab4c-9f2dc707110e	av.soldatov@hse.ru	\N	Солдатов	Алексей	Валерьевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
656c5ead-3d8c-47f6-ac24-8d3decc821b2	iachernitcin@hse.ru	\N	Черницин	Игорь	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
edbaefaa-87b2-44df-b9ee-cbeeeed89697	fkotov@hse.ru	\N	Котов	Феодосий	Игоревич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6e17791f-d950-46ed-880d-573b9264f340	vavasileva@hse.ru	\N	Васильева	Виктория	Александровна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ac90e7de-7a19-4d7f-82b4-1d8b705e1b34	d.lyutkin@hse.ru	\N	Люткин	Дмитрий	Алексеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d300fa5d-0067-43c6-becd-f40410c1e61f	agurskii@hse.ru	\N	Гурский	Анатолий	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9f8301ac-ff6c-4d85-af36-357558e4f068	efremov.a@hse.ru	\N	Ефремов	Алексей	Максимович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4360f575-6088-456d-82fd-72c0bfc31af9	akuvshinov@hse.ru	\N	Кувшинов	Алексей	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4e8043d7-bcbe-4347-a77f-85c21d664700	dsukhoverkhova@hse.ru	\N	Суховерхова	Диана	Дмитриевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0352128d-aa28-4fa8-a8a8-37975bb5a3b2	dushenin.r.n@hse.ru	\N	Душенин	Родион	Николаевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3a10650c-cc82-436f-b474-4748a4cc4b95	azubkova@hse.ru	\N	Зубкова	Александра	Ильинична	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0dc084de-a19d-4418-83ae-ba5de9fa409e	dtkachev@hse.ru	\N	Ткачев	Даниил	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
799579a7-6504-4dfb-9b3c-9ca564e522cd	dmazur@hse.ru	\N	Мазур	Дарья	Александровна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d90dde7a-a9b5-4a43-92f1-1b9f123b0492	vpashkovskaia@hse.ru	\N	Пашковская	Валерия	Дмитриевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
dbee448c-525f-4aa9-94e5-3721be83afee	dkagramanyan@hse.ru	\N	Каграманян	Давид	Геворгович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a1c4465f-d094-4b9a-b17e-7978d835100a	aglushak@hse.ru	\N	Глушак	Артём	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c189f6a1-387d-450b-9cfc-4abfabff627c	marinin.n.d@hse.ru	\N	Маринин	Никита	Денисович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c1e54bc7-50e4-4dfc-b602-6a95f524b06c	naumov.v.v@hse.ru	\N	Наумов	Виктор	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
4e4258fa-2b32-4332-befc-17dfb3c643f8	mufazalova.a.o@hse.ru	\N	Муфазалова	Алена	Олеговна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
de19a4d9-4979-4e02-b9b3-73019fd6e077	doborschuk.v.v@hse.ru	\N	Доборщук	Владимир	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
593f35a4-8185-4174-86f0-d34f2dd887dc	chimitdorzhiev.n.b@hse.ru	\N	Чимитдоржиев	Нимбу	Баирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c1b76561-e334-40fd-bb39-11edb3e06779	bobrov.k.r@hse.ru	\N	Бобров	Кирилл	Романович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0f6ff278-d8f1-453e-9ff6-129063586764	dkobtsev@hse.ru	\N	Кобцев	Данил	Максимович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0dda161c-2097-42d5-8ccd-93099a267883	aerofeeva@hse.ru	\N	Ерофеева	Анастасия	Романовна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
50f377a0-d51a-4848-bf90-096deacc6742	romashikhin.m.y@hse.ru	\N	Ромашихин	Михаил	Юрьевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ee4d2239-55fd-4535-8a5b-7aa4e378bc95	tutaev.i.a@hse.ru	\N	Тутаев	Идар	Анзорович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
03d37926-7c62-47ae-8504-c3b4885b1f3b	korobok.m.a@hse.ru	\N	Коробок	Михаил	Алексеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c45a242e-844a-420b-96ec-e78ce6799ff6	dyrchenkova.y.a@hse.ru	\N	Дырченкова	Юлия	Александровна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d7633a37-3ac4-451a-83d5-5c757026c1ee	isemichasnov@hse.ru	\N	Семичаснов	Илья	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
85e18513-1b5e-4576-babf-4d68c4ee45e7	smikhaylova@hse.ru	\N	Марычева	Светлана	Олеговна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
b3673547-f4b5-4930-8b9b-ba33cbd6cdd6	volokh.a.i@hse.ru	\N	Волох	Андрей	Игоревич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c8917b05-b915-4e7c-bb5c-929c8cd7743a	dsegorov@hse.ru	\N	Егоров	Дмитрий	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ffce2c25-6209-4d52-a66a-516bef83cb58	ushakov.v.m@hse.ru	\N	Ушаков	Вадим	Михайлович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c79608ed-4ac5-42f1-a29f-15f615738d2f	mochalov.i.s@hse.ru	\N	Мочалов	Иван	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
0d2aa3ac-e2e6-4358-81f4-6582c3def86c	vtsvetkov@hse.ru	\N	Цветков	Вячеслав	Эдуардович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
c000c72b-add0-4dcc-80eb-9cb20d5fb780	lenvu.s.a@hse.ru	\N	Ленву	Султан	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
57435f10-1fbb-46e0-a4a1-d386ce4c4b90	vedenskiy.d.s@hse.ru	\N	Веденский	Денис	Станиславович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d43511d7-dae0-40e6-b2df-5f0ba37fe037	nakononova@hse.ru	\N	Кононова	Наталья	Алексеевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
38c69e2d-c029-48e9-ab4e-79cacaf6a92d	aischenko@hse.ru	\N	Ищенко	Анна	Романовна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9cfb520a-d9c9-4910-88d6-154c53f7037c	yakubov.v.y@hse.ru	\N	Якубов	Вячеслав	Юсупович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e02bea0f-73bf-48c4-a35b-3ee286daf320	liaskovskii.a.d@hse.ru	\N	Лясковский	Алексей	Дмитриевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d9e44b42-0ea1-497c-b3a6-9fd2eda9400d	urkunov.a.k@hse.ru	\N	Уркунов	Айвар	Кайратович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
943b9c16-1034-44b3-9d22-15e4f831acd6	am.litvinenko@hse.ru	\N	Литвиненко	Алексей	Михайлович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
a0fb7d3c-6325-4f2a-8f1f-3914e1386189	sirotinskiy.n.v@hse.ru	\N	Сиротинский	Никита	Вадимович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
1278eb85-2213-4e27-acc2-8012d68e4b52	nikitin.g.e@hse.ru	\N	Никитин	Георгий	Эдуардович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
d5a53965-a2de-481b-985f-c0808524208e	khalifekh.k@hse.ru	\N	Халифех	Кифах	\N	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ddf93c63-c764-4d90-830d-240ea8ab9b5c	nurmamatov.n.r@hse.ru	\N	Нурмаматов	Нуриддинжон	Рахматжон угли	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
10de52a8-07be-4782-9c06-4b7a7572056a	vg.stepanyants@hse.ru	\N	Степанянц	Виталий	Гургенович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9a480a59-9053-4816-a82e-6d244dec9dea	srumyanceva@hse.ru	\N	Румянцева	София	Васильевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
cb959407-ae40-4bf3-b2b2-270f37abe259	iovenediktov@hse.ru	\N	Венедиктов	Илия	Олегович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
95602f76-6dad-4f6b-b103-dff7915b60ce	ssvyatodukh@hse.ru	\N	Святодух	Сергей	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f076f9a9-7f17-4b43-9961-bd4020e7dc05	nlekomtsev@hse.ru	\N	Лекомцев	Никита	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f3931502-45d9-4262-8020-52d706ab2a09	erzaev@hse.ru	\N	Рзаев	Эдвард	Рамизович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
692b42ca-4ef3-4815-b248-e79c8701d797	pakhlynov@hse.ru	\N	Хлынов	Павел	Антонович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8bd9e1f2-3d5a-4246-a66b-caa9dbaeb202	msoldatenkova@hse.ru	\N	Солдатенкова	Мария	Дмитриевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6bb6b9b8-9684-4f7c-afc2-7315922ef572	nburov@hse.ru	\N	Буров	Никита	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8b6ef1c7-8f74-4b29-8cfd-12518608e6ec	adubelschikov@hse.ru	\N	Дубельщиков	Александр	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
721dec2b-4138-468d-a852-3cff8717a185	aokazachkov@hse.ru	\N	Казачков	Алексей	Олегович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
09feb343-31aa-46ad-a555-6981762d101d	avkalyagin@hse.ru	\N	Калягин	Александр	Витальевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
61320c02-4bff-495b-a4fe-e17b6404c4c5	daserebyannikov@hse.ru	\N	Серебренников	Дмитрий	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
87026f63-1644-4539-b884-dbd9b91b4e23	safedorov@hse.ru	\N	Федоров	Сергей	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
9a110c9f-bfe6-4f3a-989e-a0f2544e0dac	i.kovalev@hse.ru	\N	Ковалев	Иван	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
58ac24be-f152-487b-8267-b8f53f35256c	dvkrayushkin@hse.ru	\N	Краюшкин	Денис	Владиславович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
28ef5f30-6469-4231-bf4a-d4939d6b6593	vrserbaev@hse.ru	\N	Сербаев	Вадим	Русланович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
610cb0c7-1ccf-46a9-99b5-86af57e78858	rmbakhshaliev@hse.ru	\N	Бахшалиев	Руслан	Мухтарович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
5cbd1260-28ff-4db1-9ca0-916e3c9be773	yavinokurov@hse.ru	\N	Винокуров	Юрий	Андреевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
6dc4ccb6-a8a3-4f39-ae02-c0657a47bcc0	slevashov@hse.ru	\N	Левашов	Сергей	Дмитриевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f0361522-bb0f-4a2b-877c-be8ea5cea04d	bzinnurov@hse.ru	\N	Зиннуров	Булат	Дамирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
94d78893-2eeb-477d-b161-b98290e6da09	ag.kuznetsov@hse.ru	\N	Кузнецов	Антон	Гаврилович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e8128334-1a06-4f89-9258-411de4db0920	vsandreev@hse.ru	\N	Андреев	Владислав	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
395bc909-e516-461f-9d28-ff0ef0a188f9	msamatov@hse.ru	\N	Саматов	Михаил	Рустамович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
e477411e-ee98-4a07-802f-a6d309a23fc6	ksedykh@hse.ru	\N	Седых	Ксения	Олеговна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
491a13e3-a627-48b5-89d3-004f21a9eccf	mbubnova@hse.ru	\N	Бубнова	Мария	Андреевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
3957de6b-e99a-4d46-b9c7-e1fd9eeccefc	arsharapov@hse.ru	\N	Шарапов	Александр	Рауилович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
8819c290-93b3-45f3-9ef3-cc92d66488ae	vdborisov@hse.ru	\N	Борисов	Вячеслав	Дмитриевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
1144cc4d-07ef-488a-9f58-ab7333a28d64	dseleznyov@hse.ru	\N	Селезнёв	Дмитрий	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
fb501b82-16cb-466d-85c2-0f613971fd05	alyubchak@hse.ru	\N	Титченко	Анастасия	Николаевна	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
ed8dd5f9-c74f-4739-8e9b-d17620c84eb9	mikrennikov@hse.ru	\N	Икренников	Максим	Сергеевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
f4161062-8cb1-41da-b1ea-591924139d3b	vzavodilenko@hse.ru	\N	Заводиленко	Владимир	Владимирович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
48bd79cb-e485-49df-adb5-1fa8738251b0	asyropyatov@hse.ru	\N	Сыропятов	Александр	Анатольевич	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
241014d1-f549-487a-9664-f57ce19c98b9	afilyaev@hse.ru	\N	Филяев	Александр	Александрович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
bffd8b50-710c-4f49-b7b0-fd7d4eb4604f	iokuzminykh@hse.ru	\N	Кузьминых	Илья	Олегович	t	f	\N	2026-03-21 01:41:15.992209+03	2026-03-21 01:41:15.992209+03
\.


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: attestation_commissions attestation_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_commissions
    ADD CONSTRAINT attestation_commissions_pkey PRIMARY KEY (id);


--
-- Name: attestation_criteria attestation_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_criteria
    ADD CONSTRAINT attestation_criteria_pkey PRIMARY KEY (id);


--
-- Name: attestation_criterion_templates attestation_criterion_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_criterion_templates
    ADD CONSTRAINT attestation_criterion_templates_pkey PRIMARY KEY (id);


--
-- Name: attestation_periods attestation_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_periods
    ADD CONSTRAINT attestation_periods_pkey PRIMARY KEY (id);


--
-- Name: commission_member_criterion_evaluations commission_member_criterion_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_criterion_evaluations
    ADD CONSTRAINT commission_member_criterion_evaluations_pkey PRIMARY KEY (id);


--
-- Name: commission_member_evaluations commission_member_evaluations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_evaluations
    ADD CONSTRAINT commission_member_evaluations_pkey PRIMARY KEY (id);


--
-- Name: commission_members commission_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_members
    ADD CONSTRAINT commission_members_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: education_programs education_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.education_programs
    ADD CONSTRAINT education_programs_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: staff_members staff_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_members
    ADD CONSTRAINT staff_members_pkey PRIMARY KEY (id);


--
-- Name: staff_members staff_members_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_members
    ADD CONSTRAINT staff_members_user_id_key UNIQUE (user_id);


--
-- Name: student_attestation_criteria student_attestation_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestation_criteria
    ADD CONSTRAINT student_attestation_criteria_pkey PRIMARY KEY (id);


--
-- Name: student_attestations student_attestations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_pkey PRIMARY KEY (id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: attestation_commissions uq_attestation_commissions_period_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_commissions
    ADD CONSTRAINT uq_attestation_commissions_period_name UNIQUE (attestation_period_id, name);


--
-- Name: attestation_criteria uq_attestation_criteria_template_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_criteria
    ADD CONSTRAINT uq_attestation_criteria_template_code UNIQUE (template_id, code);


--
-- Name: attestation_criterion_templates uq_attestation_criterion_templates_lookup; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_criterion_templates
    ADD CONSTRAINT uq_attestation_criterion_templates_lookup UNIQUE (period_type, program_duration_years, course, season);


--
-- Name: attestation_periods uq_attestation_periods_type_year_season; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_periods
    ADD CONSTRAINT uq_attestation_periods_type_year_season UNIQUE (type, year, season);


--
-- Name: commission_members uq_commission_members_commission_staff_member; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_members
    ADD CONSTRAINT uq_commission_members_commission_staff_member UNIQUE (commission_id, staff_member_id);


--
-- Name: commission_member_criterion_evaluations uq_member_crit_evals_eval_criterion; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_criterion_evaluations
    ADD CONSTRAINT uq_member_crit_evals_eval_criterion UNIQUE (member_evaluation_id, student_attestation_criterion_id);


--
-- Name: commission_member_evaluations uq_member_evals_attestation_member; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_evaluations
    ADD CONSTRAINT uq_member_evals_attestation_member UNIQUE (student_attestation_id, commission_member_id);


--
-- Name: student_attestation_criteria uq_student_attestation_criteria_attestation_code; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestation_criteria
    ADD CONSTRAINT uq_student_attestation_criteria_attestation_code UNIQUE (student_attestation_id, code);


--
-- Name: student_attestations uq_student_attestations_period_student; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT uq_student_attestations_period_student UNIQUE (attestation_period_id, student_id);


--
-- Name: user_roles uq_user_roles_user_role_department; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT uq_user_roles_user_role_department UNIQUE (user_id, role_id, department_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_attestation_commissions_department_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_commissions_department_id ON public.attestation_commissions USING btree (department_id);


--
-- Name: ix_attestation_commissions_period_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_commissions_period_id ON public.attestation_commissions USING btree (attestation_period_id);


--
-- Name: ix_attestation_commissions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_commissions_status ON public.attestation_commissions USING btree (status);


--
-- Name: ix_attestation_criteria_sort_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_criteria_sort_order ON public.attestation_criteria USING btree (template_id, sort_order);


--
-- Name: ix_attestation_criteria_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_criteria_template_id ON public.attestation_criteria USING btree (template_id);


--
-- Name: ix_attestation_criterion_templates_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_criterion_templates_lookup ON public.attestation_criterion_templates USING btree (period_type, program_duration_years, course, season);


--
-- Name: ix_attestation_periods_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_periods_status ON public.attestation_periods USING btree (status);


--
-- Name: ix_attestation_periods_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_periods_type ON public.attestation_periods USING btree (type);


--
-- Name: ix_attestation_periods_year_season; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_attestation_periods_year_season ON public.attestation_periods USING btree (year, season);


--
-- Name: ix_commission_members_commission_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_commission_members_commission_id ON public.commission_members USING btree (commission_id);


--
-- Name: ix_commission_members_sort_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_commission_members_sort_order ON public.commission_members USING btree (commission_id, sort_order);


--
-- Name: ix_commission_members_staff_member_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_commission_members_staff_member_id ON public.commission_members USING btree (staff_member_id);


--
-- Name: ix_member_crit_evals_att_criterion_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_member_crit_evals_att_criterion_id ON public.commission_member_criterion_evaluations USING btree (student_attestation_criterion_id);


--
-- Name: ix_member_crit_evals_eval_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_member_crit_evals_eval_id ON public.commission_member_criterion_evaluations USING btree (member_evaluation_id);


--
-- Name: ix_member_evals_attestation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_member_evals_attestation_id ON public.commission_member_evaluations USING btree (student_attestation_id);


--
-- Name: ix_member_evals_commission_member_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_member_evals_commission_member_id ON public.commission_member_evaluations USING btree (commission_member_id);


--
-- Name: ix_member_evals_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_member_evals_status ON public.commission_member_evaluations USING btree (status);


--
-- Name: ix_staff_members_can_be_commission_member; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_staff_members_can_be_commission_member ON public.staff_members USING btree (can_be_commission_member);


--
-- Name: ix_staff_members_department_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_staff_members_department_id ON public.staff_members USING btree (department_id);


--
-- Name: ix_staff_members_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_staff_members_is_active ON public.staff_members USING btree (is_active);


--
-- Name: ix_staff_members_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_staff_members_user_id ON public.staff_members USING btree (user_id);


--
-- Name: ix_student_attestation_criteria_sort_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestation_criteria_sort_order ON public.student_attestation_criteria USING btree (student_attestation_id, sort_order);


--
-- Name: ix_student_attestation_criteria_student_attestation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestation_criteria_student_attestation_id ON public.student_attestation_criteria USING btree (student_attestation_id);


--
-- Name: ix_student_attestations_commission_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_commission_id ON public.student_attestations USING btree (commission_id);


--
-- Name: ix_student_attestations_criterion_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_criterion_template_id ON public.student_attestations USING btree (criterion_template_id);


--
-- Name: ix_student_attestations_department_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_department_id ON public.student_attestations USING btree (department_id);


--
-- Name: ix_student_attestations_period_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_period_id ON public.student_attestations USING btree (attestation_period_id);


--
-- Name: ix_student_attestations_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_status ON public.student_attestations USING btree (status);


--
-- Name: ix_student_attestations_student_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_student_attestations_student_id ON public.student_attestations USING btree (student_id);


--
-- Name: ix_students_academic_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_students_academic_status ON public.students USING btree (academic_status);


--
-- Name: ix_students_course; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_students_course ON public.students USING btree (course);


--
-- Name: ix_students_department_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_students_department_id ON public.students USING btree (department_id);


--
-- Name: ix_students_education_program_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_students_education_program_id ON public.students USING btree (education_program_id);


--
-- Name: ix_students_supervisor_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_students_supervisor_user_id ON public.students USING btree (supervisor_user_id);


--
-- Name: ix_user_roles_department_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_roles_department_id ON public.user_roles USING btree (department_id);


--
-- Name: ix_user_roles_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: ix_user_roles_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: ux_departments_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_departments_name ON public.departments USING btree (lower((name)::text));


--
-- Name: ux_departments_short_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_departments_short_name ON public.departments USING btree (lower((short_name)::text)) WHERE (short_name IS NOT NULL);


--
-- Name: ux_education_programs_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_education_programs_name ON public.education_programs USING btree (lower((name)::text));


--
-- Name: ux_roles_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_roles_code ON public.roles USING btree (code);


--
-- Name: ux_students_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_students_email ON public.students USING btree (lower((email)::text)) WHERE (email IS NOT NULL);


--
-- Name: ux_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_users_email ON public.users USING btree (lower((email)::text)) WHERE (is_deleted = false);


--
-- Name: attestation_commissions attestation_commissions_attestation_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_commissions
    ADD CONSTRAINT attestation_commissions_attestation_period_id_fkey FOREIGN KEY (attestation_period_id) REFERENCES public.attestation_periods(id) ON DELETE RESTRICT;


--
-- Name: attestation_commissions attestation_commissions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_commissions
    ADD CONSTRAINT attestation_commissions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: attestation_commissions attestation_commissions_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_commissions
    ADD CONSTRAINT attestation_commissions_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: attestation_criteria attestation_criteria_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_criteria
    ADD CONSTRAINT attestation_criteria_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.attestation_criterion_templates(id) ON DELETE CASCADE;


--
-- Name: attestation_periods attestation_periods_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attestation_periods
    ADD CONSTRAINT attestation_periods_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: commission_member_criterion_evaluations commission_member_criterion_e_student_attestation_criterio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_criterion_evaluations
    ADD CONSTRAINT commission_member_criterion_e_student_attestation_criterio_fkey FOREIGN KEY (student_attestation_criterion_id) REFERENCES public.student_attestation_criteria(id) ON DELETE RESTRICT;


--
-- Name: commission_member_criterion_evaluations commission_member_criterion_evaluatio_member_evaluation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_criterion_evaluations
    ADD CONSTRAINT commission_member_criterion_evaluatio_member_evaluation_id_fkey FOREIGN KEY (member_evaluation_id) REFERENCES public.commission_member_evaluations(id) ON DELETE CASCADE;


--
-- Name: commission_member_evaluations commission_member_evaluations_commission_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_evaluations
    ADD CONSTRAINT commission_member_evaluations_commission_member_id_fkey FOREIGN KEY (commission_member_id) REFERENCES public.commission_members(id) ON DELETE CASCADE;


--
-- Name: commission_member_evaluations commission_member_evaluations_student_attestation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_member_evaluations
    ADD CONSTRAINT commission_member_evaluations_student_attestation_id_fkey FOREIGN KEY (student_attestation_id) REFERENCES public.student_attestations(id) ON DELETE CASCADE;


--
-- Name: commission_members commission_members_commission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_members
    ADD CONSTRAINT commission_members_commission_id_fkey FOREIGN KEY (commission_id) REFERENCES public.attestation_commissions(id) ON DELETE CASCADE;


--
-- Name: commission_members commission_members_staff_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commission_members
    ADD CONSTRAINT commission_members_staff_member_id_fkey FOREIGN KEY (staff_member_id) REFERENCES public.staff_members(id) ON DELETE RESTRICT;


--
-- Name: student_attestations fk_student_attestations_commission_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT fk_student_attestations_commission_id FOREIGN KEY (commission_id) REFERENCES public.attestation_commissions(id) ON DELETE SET NULL;


--
-- Name: students fk_students_education_program_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_education_program_id FOREIGN KEY (education_program_id) REFERENCES public.education_programs(id) ON DELETE RESTRICT;


--
-- Name: staff_members staff_members_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_members
    ADD CONSTRAINT staff_members_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: staff_members staff_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_members
    ADD CONSTRAINT staff_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: student_attestation_criteria student_attestation_criteria_student_attestation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestation_criteria
    ADD CONSTRAINT student_attestation_criteria_student_attestation_id_fkey FOREIGN KEY (student_attestation_id) REFERENCES public.student_attestations(id) ON DELETE CASCADE;


--
-- Name: student_attestation_criteria student_attestation_criteria_template_criterion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestation_criteria
    ADD CONSTRAINT student_attestation_criteria_template_criterion_id_fkey FOREIGN KEY (template_criterion_id) REFERENCES public.attestation_criteria(id) ON DELETE RESTRICT;


--
-- Name: student_attestations student_attestations_attestation_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_attestation_period_id_fkey FOREIGN KEY (attestation_period_id) REFERENCES public.attestation_periods(id) ON DELETE RESTRICT;


--
-- Name: student_attestations student_attestations_criterion_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_criterion_template_id_fkey FOREIGN KEY (criterion_template_id) REFERENCES public.attestation_criterion_templates(id) ON DELETE RESTRICT;


--
-- Name: student_attestations student_attestations_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: student_attestations student_attestations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE RESTRICT;


--
-- Name: student_attestations student_attestations_supervisor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_attestations
    ADD CONSTRAINT student_attestations_supervisor_user_id_fkey FOREIGN KEY (supervisor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: students students_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: students students_supervisor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_supervisor_user_id_fkey FOREIGN KEY (supervisor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE RESTRICT;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict USbLq8dH2YmfvmmvSRGzNPGZTbqHzmQlWIqrkuvPgTve9rhrrRx32gzqkfQgF7y

