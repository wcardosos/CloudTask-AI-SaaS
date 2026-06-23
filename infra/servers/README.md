# `infra/servers/` — 3 servidores EC2 (Edge/HTTPS + API + Grafana)

Sobe a aplicação como em produção, com cada peça num **EC2 separado**, **só por
HTTPS** e com **certificado válido** (sem domínio próprio).

```text
  navegador ──HTTPS──► EDGE (Caddy)  ──HTTP interno──►  API   (:8000, Docker)
  (443)                <ip>.sslip.io  ├─ /api/*      ──►  Grafana (:3000)
                       serve o SPA    └─ /grafana/*
```

* **Edge/Caddy** tem um **Elastic IP** e usa o hostname `<ip>.sslip.io`. O Caddy
  obtém sozinho um **certificado válido** (Let's Encrypt, fallback ZeroSSL) e
  **redireciona 80→443**. Serve o SPA e faz proxy para API e Grafana.
* **API** e **Grafana** **não** ficam expostos à internet (portas 8000/3000 só
  dentro do security group) — tudo passa pelo Edge. Acaba o conteúdo misto e o
  acesso HTTP direto.
* **Swagger** (`/api/docs`, `/api/openapi.json`, `/api/redoc`) fica **atrás de
  senha** (HTTP Basic no Caddy: `admin` / `ADMIN_PASSWORD`).

Tutorial passo a passo na [prática 19](../../docs/praticas/19-servidores-ec2-grafana.md).

## Arquivos

| Arquivo | Papel |
| --- | --- |
| `userdata-api.sh` | Boot da API: Docker + (Postgres local **ou** RDS) + imagem `prod`. :8000 |
| `userdata-grafana.sh` | Boot do Grafana: datasource CloudWatch + dashboard como **home** + subpath `/grafana`. :3000 |
| `grafana-dashboard.json` | Dashboard (CPU/rede dos EC2, DynamoDB, RDS). Fonte única — embutido no boot. |
| `semana-06-servidores-subir.sh` | Aloca Elastic IP, cria o SG e sobe os 3 EC2; o **Edge** (Caddy) é gerado aqui com o SPA embutido e a config de TLS/proxy. |
| `semana-06-servidores-destruir.sh` | Termina os EC2, libera o Elastic IP e apaga o SG (tudo pela tag `project=cloudtask-demo`). |

> O `user-data` do **Edge** é gerado pelo `…-subir.sh` (precisa do hostname
> sslip.io, dos IPs privados da API/Grafana e do SPA embutido). Os `userdata-*.sh`
> e o `grafana-dashboard.json` mantêm o nome porque são lidos **por nome** pelo
> launcher e pela `ComputeStack`.

## Uso rápido

```bash
# subir (na raiz do repo, com o Learner Lab iniciado)
bash infra/servers/semana-06-servidores-subir.sh
# ...abra o link "App" (https://<ip>.sslip.io/). Login: admin / admin#123
# (o certificado pode levar ~1-3 min após o boot para ficar válido)

# derrubar (SEMPRE ao terminar)
bash infra/servers/semana-06-servidores-destruir.sh
```

## Variáveis úteis (todas têm default)

| Variável | Default | Onde |
| --- | --- | --- |
| `REGION` | `us-east-1` | launch/destroy |
| `KEY_NAME` | `vockey` | par de chaves SSH (o do Academy) |
| `PROFILE_NAME` | `LabInstanceProfile` | instance profile (role do lab) |
| `ADMIN_PASSWORD` | `admin#123` | senha do app/API, Swagger e Grafana |
| `DATABASE_URL` | *(vazio)* | se setada no `userdata-api.sh`, usa esse banco (ex.: RDS) e **não** sobe Postgres local |

> ⚠️ **Custo:** 3 EC2 pequenos + 1 Elastic IP (o EIP só cobra se ficar **ocioso**;
> associado a uma instância ligada é grátis). O `…-destruir.sh` libera o EIP.
> Destrua ao terminar.

> 🔒 **Certificado válido sem domínio:** usamos `sslip.io` (mapeia o IP num
> hostname) para o desafio ACME. Se o Let's Encrypt/ZeroSSL estiver com
> rate-limit, o Caddy pode demorar ou cair num cert próprio (aviso no
> navegador) — rode de novo mais tarde ou use um domínio real.
