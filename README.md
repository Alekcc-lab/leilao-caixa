# Leilão Caixa — Painel de Análise

Aplicação web (HTML puro, sem build) para analisar imóveis de leilão/venda da
Caixa: carrega o CSV oficial, ranqueia por desconto, calcula À Vista / PRICE /
SAC, monta Checklist de due diligence e um Farol (verde/amarelo/vermelho) que só
fica verde quando os itens críticos estão resolvidos.

- **Roda sem servidor:** basta abrir o `index.html`. Sem configurar nada, salva
  tudo no navegador (localStorage).
- **Com login (opcional):** ao preencher o `config.js` com as chaves do Supabase,
  ganha login com Google e salva os dados na nuvem — os mesmos dados aparecem em
  qualquer computador onde você entrar.

O passo a passo abaixo é para publicar online (Render) com login e banco (Supabase).
Você faz as etapas de conta/senha; eu não tenho como criar contas nem digitar
suas credenciais.

---

## Visão geral

```
Navegador  →  Render (hospeda o site estático)
                 │
                 └─→ Supabase  (Login Google + banco Postgres com RLS)
```

- A **ANON KEY** do Supabase é pública de propósito — pode ficar no repositório.
  Quem protege os dados é o **RLS**: cada usuário só lê/grava a própria linha.
- O site é **estático**: o Render só publica os arquivos, não há build.

---

## Passo 1 — Criar o projeto no Supabase

1. Acesse https://supabase.com e faça login (pode ser com o GitHub).
2. **New project** → dê um nome (ex.: `leilao-caixa`), escolha uma senha de banco
   (guarde) e a região mais próxima (ex.: *South America (São Paulo)*).
3. Aguarde o provisionamento (~2 min).

## Passo 2 — Criar a tabela e o RLS

1. No projeto, menu lateral → **SQL Editor** → **New query**.
2. Cole todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique
   em **Run**. Deve retornar *Success*.
   - Isso cria a tabela `app_state` e as regras de segurança (cada pessoa só
     acessa os próprios dados).

## Passo 3 — Ativar o login com Google

1. No Supabase: **Authentication → Providers → Google** → ative (*Enable*).
2. Ele vai pedir **Client ID** e **Client Secret**. Para obtê-los, crie um
   OAuth Client no Google:
   - Acesse https://console.cloud.google.com → crie/escolha um projeto.
   - **APIs & Services → OAuth consent screen**: configure (tipo *External*,
     nome do app, seu e-mail). Adicione seu e-mail em *Test users* se deixar em
     modo de teste.
   - **APIs & Services → Credentials → Create Credentials → OAuth client ID** →
     tipo **Web application**.
   - Em **Authorized redirect URIs**, cole a URL que o Supabase mostra na tela do
     provider Google (algo como
     `https://SEU-PROJETO.supabase.co/auth/v1/callback`).
   - Salve e copie o **Client ID** e o **Client Secret**.
3. Volte ao Supabase, cole **Client ID** e **Client Secret** no provider Google e
   **Save**.

## Passo 4 — Pegar as chaves e preencher o `config.js`

1. No Supabase: **Project Settings → API**.
2. Copie **Project URL** e a **anon public key**.
3. Edite [`config.js`](config.js):

   ```js
   window.SUPABASE_URL      = "https://SEU-PROJETO.supabase.co";
   window.SUPABASE_ANON_KEY = "eyJhbGciOi...";  // anon public
   ```

## Passo 5 — Subir para o GitHub (repositório `leilao-caixa`)

Se for **substituir** um repositório existente (ex.: o antigo `bolao-copa`),
você pode reaproveitar o mesmo repo — apenas troque o conteúdo. Para começar do
zero neste repo novo:

```bash
cd leilao-caixa
git init
git add .
git commit -m "App de análise de leilão Caixa + Supabase"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/leilao-caixa.git
git push -u origin main
```

> Se o remoto já existir com outro conteúdo e você quiser sobrepor:
> `git push -u origin main --force` (isso apaga o histórico anterior do repo).

## Passo 6 — Publicar no Render

1. Acesse https://render.com → **New → Static Site** (ou **Blueprint**, que lê o
   `render.yaml`).
2. Conecte sua conta do GitHub e escolha o repositório `leilao-caixa`.
3. Configurações:
   - **Build Command:** *(vazio)*
   - **Publish Directory:** `.`
4. **Create Static Site**. Em ~1 min você recebe uma URL, algo como
   `https://leilao-caixa.onrender.com`.

## Passo 7 — Liberar a URL no Login (importante)

Para o login com Google funcionar no site publicado:

1. Supabase → **Authentication → URL Configuration**:
   - **Site URL:** `https://leilao-caixa.onrender.com`
   - **Redirect URLs:** adicione `https://leilao-caixa.onrender.com` (e, se for
     testar local, `http://localhost:3000` ou o caminho do arquivo).
2. Google Cloud Console → seu OAuth Client → **Authorized redirect URIs**: mantenha
   a URL de callback do Supabase (`.../auth/v1/callback`) — é ela que o Google usa.

Pronto. Abra a URL do Render, clique em **Entrar com Google** e seus dados passam
a ser salvos na nuvem.

---

## Uso do app

1. Baixe a lista da Caixa (CSV) em
   https://venda-imoveis.caixa.gov.br/sistema/download-lista.asp e carregue no
   painel (botão de arquivo na barra lateral).
2. Filtre por cidade / valor / tipo. A tabela ranqueia por desconto e mostra
   Lucro líquido, ROI e o Farol.
3. Clique num imóvel para ver Cálculos, À Vista/PRICE/SAC, Resultados, Farol e o
   Checklist. Ajuste premissas por imóvel se quiser.
4. Marque **finalistas** com a ★ e use *Exportar finalistas* para pedir ao Claude
   a leitura de matrícula/edital.

### Observações honestas do modelo
- A estimativa de lucro é **teto otimista** (assume revenda ao valor de avaliação
  da Caixa; reforma R$15k e desocupação R$5k embutidas).
- O **Farol só fica verde** quando os itens **críticos** do checklist estão
  resolvidos — ler os documentos não basta.
- O app **não dá lance** por você.

---

## Rodar local (sem publicar)

Basta abrir o `index.html` no navegador. Sem `config.js` preenchido, funciona em
modo local (localStorage). Para testar o login local, preencha o `config.js` e
sirva a pasta (ex.: `python3 -m http.server 3000`), depois inclua
`http://localhost:3000` nas *Redirect URLs* do Supabase.
