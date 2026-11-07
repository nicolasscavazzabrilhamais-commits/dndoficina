-- ============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS - DND SERVIÇOS AUTOMOTIVOS
-- Cole este script no SQL Editor do seu painel do Supabase e clique em "RUN"
-- ============================================================================

-- 1. Habilita extensão para UUIDs
create extension if not exists "uuid-ossp";

-- 2. Tabela de Serviços (Catálogo dinâmico)
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  short_description text not null,
  full_description text not null,
  icon text not null,
  image_url text not null,
  badge text,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- 3. Tabela de Clientes
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  vehicle_model text,
  vehicle_plate text,
  created_at timestamptz not null default now()
);

-- 4. Tabela de Agendamentos
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  preferred_date date not null,
  preferred_shift text not null check (preferred_shift in ('manha', 'tarde')),
  notes text,
  status text not null default 'pendente' check (status in ('pendente', 'confirmado', 'concluido', 'cancelado')),
  created_at timestamptz not null default now()
);

-- 5. Tabela de Leads / Contatos rápidos
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  name text,
  phone text,
  interested_service text,
  message text,
  origin text not null default 'site',
  created_at timestamptz not null default now()
);

-- ============================================================================
-- POLÍTICAS DE SEGURANÇA (Row Level Security - RLS)
-- ============================================================================
alter table public.services enable row level security;
alter table public.customers enable row level security;
alter table public.appointments enable row level security;
alter table public.leads enable row level security;

-- Serviços ativos podem ser lidos publicamente por qualquer visitante
drop policy if exists "Servicos ativos visiveis publicamente" on public.services;
create policy "Servicos ativos visiveis publicamente"
  on public.services for select
  using (is_active = true);

-- Visitantes do site podem enviar solicitações de contato (Leads)
drop policy if exists "Permitir insercao de leads" on public.leads;
create policy "Permitir insercao de leads"
  on public.leads for insert
  with check (true);

-- Visitantes do site podem enviar agendamentos
drop policy if exists "Permitir insercao de agendamentos" on public.appointments;
create policy "Permitir insercao de agendamentos"
  on public.appointments for insert
  with check (true);

-- Visitantes do site podem cadastrar seus dados de cliente
drop policy if exists "Permitir insercao de clientes" on public.customers;
create policy "Permitir insercao de clientes"
  on public.customers for insert
  with check (true);

-- ============================================================================
-- DADOS INICIAIS (SEED) - OS 12 SERVIÇOS ATUAIS DA DND
-- ============================================================================
insert into public.services (name, slug, short_description, full_description, icon, image_url, badge, display_order)
values
(
  'Diagnóstico Automotivo',
  'diagnostico',
  'Leitura de parâmetros, detecção de falhas e checagem computadorizada de sensores.',
  'Realizamos uma avaliação completa e detalhada do veículo utilizando scanners de alta precisão para identificar falhas intermitentes, ruídos, luzes de alerta acesas no painel e comportamentos anômalos. Nosso objetivo é descobrir a raiz exata do problema antes de desmontar ou trocar qualquer peça, garantindo economia, segurança e agilidade para o cliente.',
  'fa-magnifying-glass',
  'https://uautos.com.br/uploads/blog/quando-o-carro-comeca-a-falhar-o-que-pode-ser-e-como-agir.png',
  'Scanner',
  1
),
(
  'Arrefecimento',
  'arrefecimento',
  'Prevenção contra superaquecimento, teste de pressão, vazamentos e aditivação.',
  'O controle térmico é vital para a saúde do propulsor. Inspecionamos minuciosamente o radiador, bomba d''água, válvula termostática, reservatório de expansão, mangueiras, abraçadeiras, acionamento da ventoinha e a concentração do fluido com aditivo correto. Evitamos superaquecimentos que podem danificar gravemente a junta do cabeçote.',
  'fa-droplet',
  'https://motorcityoficina.com.br/wp-content/uploads/2024/04/sistema-arrefecimento-mantencao-protege-seu-carro.jpg',
  'Térmico',
  2
),
(
  'Embreagem',
  'embreagem',
  'Diagnóstico de desgaste, substituição do kit, platô, disco e atuadores hidráulicos.',
  'A embreagem transmite a potência do motor para a caixa de câmbio. Identificamos pedal duro ou pesado, patinação em subidas, marchas que ''arrunham'', trepidações ao sair da inércia ou estalos. Avaliamos o platô, disco, rolamento e atuadores hidráulicos para devolver maciez e precisão ao dirigir.',
  'fa-wrench',
  'https://f.magazynauto.pl/magazynauto_prod_2022_01/1643382565d5465b.jpg',
  'Câmbio',
  3
),
(
  'Suspensão',
  'suspensao',
  'Amortecedores, buchas, pivôs, bieletas e eliminação de ruídos e instabilidade.',
  'A suspensão absorve os impactos do solo e garante a estabilidade do veículo em curvas e frenagens. Avaliamos amortecedores, batentes, molas, buchas de bandeja, pivôs, bieletas e caixa de direção. Eliminamos barulhos metálicos, pancadas secas e desgaste irregular nos pneus.',
  'fa-circle-notch',
  'https://production.elevify-cdn.com/images/2026-05/2f17a800-5c42-4c57-9dcf-3c5492c18e70.jpg',
  'Estabilidade',
  4
),
(
  'Freios',
  'freios',
  'Troca de pastilhas, discos, fluido de freio sangrado por pressão e regulagens.',
  'Item primário de segurança ativa. Efetuamos a revisão completa: espessura de discos e pastilhas, lonas, tambores, flexíveis, cilindro mestre e teste de ponto de ebulição do fluido de freio (DOT 4 / DOT 5.1). Garantimos resposta imediata e firme no pedal.',
  'fa-circle-stop',
  'https://images.pexels.com/photos/30470930/pexels-photo-30470930.jpeg',
  'Crítico',
  5
),
(
  'Injeção Eletrônica',
  'injecao-eletronica',
  'Ajustes de mistura, sensores, atuadores, velas, cabos e corpo de borboleta.',
  'O cérebro do veículo. Fazemos diagnóstico minucioso da sonda lambda, sensor MAP/MAF, corpo de borboleta (TBI), velas de ignição, cabos e bobinas. Solucionamos perda de potência, marcha lenta oscilando, consumo elevado e luz da injeção acesa no painel.',
  'fa-laptop-code',
  'https://perthswedishauto.com.au/img/fuel.jpg',
  'Eletrônica',
  6
),
(
  'Correias & Tensores',
  'correias',
  'Troca preventiva da correia dentada, tensores, correia Poly-V e bomba d''água.',
  'A quebra da correia dentada pode provocar danos severos ao motor (como empenamento de válvulas e quebra de pistões). Inspecionamos a correia sincronizadora, tensionadores, polias e correia de acessórios (alternador e ar-condicionado), respeitando o manual de cada montadora.',
  'fa-arrows-spin',
  'https://www.roverspares.co.za/images/blog/serpentine-belt-replacement-hero.webp',
  'Sincronismo',
  7
),
(
  'Troca de Óleo',
  'troca-de-oleo',
  'Óleos sintéticos homologados e pacote de filtros para garantir a proteção do motor.',
  'Lubrificante correto é longevidade para o motor. Trabalhamos estritamente com as viscosidades e normas exigidas pelo fabricante (API, ACEA e aprovações OEM como VW 508.88/502.00, etc.). Trocamos o filtro de óleo, filtro de combustível, filtro de ar e filtro de cabine.',
  'fa-oil-can',
  'https://www.superiordieselandautocareinc.com/assets/img/blog/oil-change-maintenance-guide.png',
  'Manutenção',
  8
),
(
  'Ar Condicionado',
  'ar-condicionado',
  'Carga de gás, detecção de vazamentos, compressor e higienização do sistema.',
  'Manutenção completa do sistema de ar condicionado: teste de estanqueidade contra microvazamentos de gás refrigerante, revisão do compressor elétrico/mecânico, condensador, evaporador, recarga com gás R134a na quantidade exata e higienização com ozônio para eliminar ácaros e odores.',
  'fa-snowflake',
  'https://www.tecararcondicionado.com.br/wp-content/uploads/2019/12/manutencao-de-ar-condicionado.jpg',
  'Clima',
  9
),
(
  'Coding VW / Audi',
  'coding-vw-audi',
  'Ativações eletrônicas, ajustes em módulos e personalização exclusiva VAG.',
  'Serviço especializado para plataformas Volkswagen e Audi (VAG). Realizamos ativação de funções ocultas como varredura de ponteiros (needle sweep), rebatimento automático de retrovisores, fechamento de janelas com chuva, luzes de seta confort, desativação de start-stop e ajustes eletrônicos conforme os módulos do carro permitirem.',
  'fa-code',
  'https://www.awesomegti.com/product_images/uploaded_images/awesome-remap-3.jpg',
  'Especialidade',
  10
),
(
  'Limpeza de Bicos',
  'limpeza-de-bicos',
  'Equalização e ultrassom para queima perfeita e restauração da economia.',
  'Testamos a vazão, leque de pulverização e vedação dos bicos injetores em bancada computadorizada com cuba ultrassônica. Indicado quando há falhas em aceleração, marcha lenta irregular, aumento do consumo ou dificuldade para partida a frio.',
  'fa-filter',
  'https://www.canaldapeca.com.br/blog/wp-content/uploads/2018/07/limbic3.jpg',
  'Alimentação',
  11
),
(
  'Descarbonização',
  'descarbonizacao',
  'Remoção de depósitos de carbono em válvulas e coletores de admissão.',
  'Essencial em motores com injeção direta (TSI, TFSI, THP, etc.), onde o combustível não banha o verso das válvulas, provocando acúmulo de crostas de carvão. Efetuamos a limpeza técnica do coletor e dutos de admissão, restabelecendo o fluxo de ar, resposta imediata do acelerador e economia.',
  'fa-sparkles',
  'https://avusmotorsports.com.br/wp-content/uploads/2026/01/IMG_5250.JPG-1.webp',
  'Direta / TSI',
  12
)
on conflict (slug) do nothing;
