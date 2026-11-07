-- ============================================================================
-- MODELAGEM DE DADOS: CLIENTE (1:N) VEÍCULOS (1:N) HISTÓRICO DE SERVIÇOS
-- DnD Serviços Automotivos
-- ============================================================================

-- 1. Tabela de Clientes
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  notes text,
  created_at timestamptz not null default now()
);

-- 2. Tabela de Veículos (1 Cliente tem N Veículos)
create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  brand text not null,                  -- Ex: Volkswagen, Honda, Chevrolet
  model text not null,                  -- Ex: Golf TSI 1.4, Civic 2.0
  plate text not null,                  -- Ex: BRA2E19, ABC-1234
  year integer,                         -- Ex: 2018
  color text,                           -- Ex: Preto, Prata
  created_at timestamptz not null default now()
);

-- Índice para buscas rápidas de carro por placa
create index if not exists idx_vehicles_plate on public.vehicles(plate);
create index if not exists idx_vehicles_customer on public.vehicles(customer_id);

-- 3. Tabela de Histórico de Serviços Executados no Carro (1 Veículo tem N Serviços)
create table if not exists public.service_orders (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  service_id uuid references public.services(id) on delete set null,
  service_name text not null,           -- Ex: Troca de Óleo, Diagnóstico, Coding VW
  description text,                     -- Detalhes do serviço feito no carro
  mileage integer,                      -- Km do veículo no momento do serviço
  price numeric(10,2),                  -- Valor cobrado (opcional)
  performed_at date not null default current_date,
  status text not null default 'concluido' check (status in ('em_andamento', 'concluido', 'garantia')),
  created_at timestamptz not null default now()
);

create index if not exists idx_service_orders_vehicle on public.service_orders(vehicle_id);

-- 4. Habilita RLS
alter table public.customers enable row level security;
alter table public.vehicles enable row level security;
alter table public.service_orders enable row level security;

-- Políticas de acesso (leitura e escrita permitidas para o app)
drop policy if exists "Permitir select customers" on public.customers;
create policy "Permitir select customers" on public.customers for select using (true);
drop policy if exists "Permitir insert customers" on public.customers;
create policy "Permitir insert customers" on public.customers for insert with check (true);
drop policy if exists "Permitir update customers" on public.customers;
create policy "Permitir update customers" on public.customers for update using (true);

drop policy if exists "Permitir select vehicles" on public.vehicles;
create policy "Permitir select vehicles" on public.vehicles for select using (true);
drop policy if exists "Permitir insert vehicles" on public.vehicles;
create policy "Permitir insert vehicles" on public.vehicles for insert with check (true);
drop policy if exists "Permitir update vehicles" on public.vehicles;
create policy "Permitir update vehicles" on public.vehicles for update using (true);

drop policy if exists "Permitir select service_orders" on public.service_orders;
create policy "Permitir select service_orders" on public.service_orders for select using (true);
drop policy if exists "Permitir insert service_orders" on public.service_orders;
create policy "Permitir insert service_orders" on public.service_orders for insert with check (true);
drop policy if exists "Permitir update service_orders" on public.service_orders;
create policy "Permitir update service_orders" on public.service_orders for update using (true);

-- 5. Atualiza o schema cache do Supabase
notify pgrst, 'reload schema';
